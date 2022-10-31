use anyhow::{bail, Context, Result};
use derive_builder::Builder;
use effektio_core::statics::default_effektio_conversation_states;
use futures::{
    channel::mpsc::{channel, Receiver, Sender},
    pin_mut, StreamExt,
};
use futures_signals::signal::{
    Mutable, MutableSignal, MutableSignalCloned, SignalExt, SignalStream,
};
use log::{error, info, warn};
use matrix_sdk::{
    event_handler::{Ctx, EventHandlerHandle},
    room::Room as MatrixRoom,
    ruma::{
        api::client::room::{
            create_room::v3::{CreationContent, Request as CreateRoomRequest},
            Visibility,
        },
        assign,
        events::room::{
            member::{MembershipState, OriginalSyncRoomMemberEvent},
            message::OriginalSyncRoomMessageEvent,
        },
        serde::Raw,
        OwnedRoomId, OwnedUserId,
    },
    Client as MatrixClient,
};
use parking_lot::Mutex;
use std::sync::Arc;

use super::{
    client::Client,
    message::{sync_event_to_message, RoomMessage},
    receipt::ReceiptRecord,
    room::Room,
    RUNTIME,
};

#[derive(Clone, Debug)]
pub struct Conversation {
    inner: Room,
    latest_message: Option<RoomMessage>,
}

impl Conversation {
    pub(crate) fn new(inner: Room) -> Self {
        Conversation {
            inner,
            latest_message: Default::default(),
        }
    }

    pub async fn fetch_latest_message(&mut self) -> Result<bool> {
        let room = self.room.clone();
        let mut me = self.clone();

        RUNTIME
            .spawn(async move {
                let (forward, backward) = room
                    .timeline()
                    .await
                    .context("Failed acquiring timeline streams")
                    .unwrap();

                pin_mut!(backward);
                // try to find the last message in the past.
                loop {
                    info!("conversation backward: {:?}", room);
                    match backward.next().await {
                        Some(Ok(ev)) => {
                            if let Some(msg) = sync_event_to_message(ev, room.clone()) {
                                me.set_latest_message(msg);
                                return Ok(true);
                            }
                        }
                        Some(Err(e)) => {
                            error!("Error fetching messages {:}", e);
                            break;
                        }
                        None => {
                            warn!("No old messages found");
                            break;
                        }
                    }
                }

                // pin_mut!(forward);
                // // now continue to poll for incoming messages
                // loop {
                //     match forward.next().await {
                //         Some(ev) => {
                //             if let Some(msg) = sync_event_to_message(ev, room.clone()) {
                //                 me.set_latest_message(msg);
                //                 return Ok(true);
                //             }
                //         }
                //         None => {
                //             warn!("Messages stream stopped");
                //             break;
                //         }
                //     }
                // }

                Ok(false)
            })
            .await?
    }

    fn set_latest_message(&mut self, msg: RoomMessage) {
        self.latest_message = Some(msg);
        info!("updated latest message: {:?}", self);
    }

    pub fn latest_message(&self) -> Option<RoomMessage> {
        self.latest_message.clone()
    }

    pub fn get_room_id(&self) -> String {
        self.room_id().to_string()
    }

    pub async fn user_receipts(&self) -> Result<Vec<ReceiptRecord>> {
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                let mut records: Vec<ReceiptRecord> = vec![];
                for member in room.active_members().await? {
                    let user_id = member.user_id();
                    if let Some((event_id, receipt)) = room.user_read_receipt(user_id).await? {
                        let record = ReceiptRecord::new(event_id, user_id.to_owned(), receipt.ts);
                        records.push(record);
                    }
                }
                Ok(records)
            })
            .await?
    }
}

impl std::ops::Deref for Conversation {
    type Target = Room;
    fn deref(&self) -> &Room {
        &self.inner
    }
}

#[derive(Clone)]
pub(crate) struct ConversationController {
    conversations: Mutable<Vec<Conversation>>,
    incoming_event_tx: Sender<RoomMessage>,
    incoming_event_rx: Arc<Mutex<Option<Receiver<RoomMessage>>>>,
    message_event_handle: Option<EventHandlerHandle>,
    member_event_handle: Option<EventHandlerHandle>,
}

impl ConversationController {
    pub fn new() -> Self {
        let (incoming_tx, incoming_rx) = channel::<RoomMessage>(10); // dropping after more than 10 items queued
        ConversationController {
            conversations: Default::default(),
            incoming_event_tx: incoming_tx,
            incoming_event_rx: Arc::new(Mutex::new(Some(incoming_rx))),
            message_event_handle: None,
            member_event_handle: None,
        }
    }

    pub fn add_event_handler(&mut self, client: &MatrixClient) {
        info!("sync room message event handler");
        let me = self.clone();

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: OriginalSyncRoomMessageEvent,
             room: MatrixRoom,
             c: MatrixClient,
             Ctx(me): Ctx<ConversationController>| async move {
                info!("sync room message event handler");
                me.clone().process_room_message(ev, &room, &c);
            },
        );
        self.message_event_handle = Some(handle);

        client.add_event_handler_context(me);
        let handle = client.add_event_handler(
            |ev: OriginalSyncRoomMemberEvent,
             room: MatrixRoom,
             c: MatrixClient,
             Ctx(me): Ctx<ConversationController>| async move {
                // user accepted invitation or left room
                me.clone().process_room_member(ev, &room, &c);
            },
        );
        self.member_event_handle = Some(handle);
    }

    pub fn remove_event_handler(&mut self, client: &MatrixClient) {
        if let Some(handle) = self.message_event_handle.clone() {
            client.remove_event_handler(handle);
            self.message_event_handle = None;
        }
        if let Some(handle) = self.member_event_handle.clone() {
            client.remove_event_handler(handle);
            self.member_event_handle = None;
        }
    }

    pub fn load_rooms(&mut self, convos: &Vec<Conversation>) {
        self.conversations.lock_mut().clone_from(&convos);
    }

    fn process_room_message(
        &mut self,
        ev: OriginalSyncRoomMessageEvent,
        room: &MatrixRoom,
        client: &MatrixClient,
    ) {
        info!("original sync room message event: {:?}", ev);
        if let MatrixRoom::Joined(joined) = room {
            let mut convos = self.conversations.lock_mut();
            let room_id = room.room_id();
            if let Some(idx) = convos.iter().position(|x| x.room_id() == room_id) {
                info!("existing convo index: {}", idx);
                let mut convo = Conversation::new(Room {
                    client: client.clone(),
                    room: room.clone(),
                });
                let fallback = ev.content.body().to_string();
                let msg = RoomMessage::new(ev, room.clone(), fallback);
                convo.set_latest_message(msg.clone());
                convos.remove(idx);
                convos.insert(0, convo);
                if let Err(e) = self.incoming_event_tx.try_send(msg) {
                    warn!("Dropping ephemeral event for {}: {}", room_id, e);
                }
            }
        }
    }

    fn process_room_member(
        &self,
        ev: OriginalSyncRoomMemberEvent,
        room: &MatrixRoom,
        client: &MatrixClient,
    ) {
        // filter only event for me
        let user_id = client.user_id().expect("You seem to be not logged in");
        if ev.state_key != *user_id {
            return;
        }

        let evt = ev.clone();
        // info!("conversation - original sync room member event: {:?}", ev);
        let mut conversations = self.conversations.lock_mut();
        if let Some(prev_content) = ev.unsigned.prev_content {
            match (prev_content.membership, ev.content.membership) {
                (MembershipState::Invite, MembershipState::Join) => {
                    // when user accepted invitation, this event is called twice
                    // i don't know that reason
                    // anyway i prevent this event from being called twice
                    if let None = conversations
                        .iter()
                        .position(|x| x.room_id() == room.room_id())
                    {
                        info!("conversation - original sync room member event: {:?}", evt);
                        // add new room
                        let conversation = Conversation::new(Room {
                            client: client.clone(),
                            room: room.clone(),
                        });
                        conversations.insert(0, conversation);
                    }
                }
                (MembershipState::Join, MembershipState::Leave) => {
                    // remove existing room
                    let room_id = room.room_id();
                    if let Some(idx) = conversations.iter().position(|x| x.room_id() == room_id) {
                        conversations.remove(idx);
                    }
                }
                _ => {}
            }
        }
    }
}

#[derive(Builder, Default, Clone)]
pub struct CreateConversationSettings {
    #[builder(setter(into, strip_option), default)]
    name: Option<String>,
    // #[builder(default = "Visibility::Private")]
    // visibility: Visibility,
    #[builder(default = "Vec::new()")]
    invites: Vec<OwnedUserId>,
    #[builder(setter(into, strip_option), default)]
    alias: Option<String>,
}

impl Client {
    pub async fn create_conversation(
        &self,
        settings: CreateConversationSettings,
    ) -> Result<OwnedRoomId> {
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let initial_states = default_effektio_conversation_states();
                let request = assign!(CreateRoomRequest::new(), {
                    creation_content: Some(Raw::new(&CreationContent::new())?),
                    initial_state: &initial_states,
                    is_direct: true,
                    invite: &settings.invites,
                    room_alias_name: settings.alias.as_deref(),
                    name: settings.name.as_ref().map(|x| x.as_ref()),
                    visibility: Visibility::Private,
                });
                let response = client.create_room(request).await?;
                Ok(response.room_id().to_owned())
            })
            .await?
    }

    pub(crate) async fn conversation(&self, name_or_id: String) -> Result<Conversation> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                if let Ok(room) = me.room(name_or_id) {
                    if !room.is_effektio_group().await {
                        Ok(Conversation::new(room))
                    } else {
                        bail!("Not a regular conversation but an effektio group!")
                    }
                } else {
                    bail!("Neither roomId nor alias provided")
                }
            })
            .await?
    }

    pub fn conversations_rx(&self) -> SignalStream<MutableSignalCloned<Vec<Conversation>>> {
        self.conversation_controller
            .conversations
            .signal_cloned()
            .to_stream()
    }

    pub fn incoming_message_rx(&self) -> Option<Receiver<RoomMessage>> {
        self.conversation_controller.incoming_event_rx.lock().take()
    }
}
