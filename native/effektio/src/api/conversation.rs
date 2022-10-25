use anyhow::{bail, Context, Result};
use derive_builder::Builder;
use effektio_core::statics::default_effektio_conversation_states;
use futures::{
    channel::mpsc::{channel, Receiver, Sender},
    pin_mut, StreamExt,
};
use futures_signals::{
    signal::{Mutable, MutableSignalCloned, SignalExt, SignalStream},
    signal_vec::{SignalVecExt, VecDiff},
};
use log::{error, info, warn};
use matrix_sdk::{
    event_handler::Ctx,
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
    message::{sync_event_to_message, timeline_item_to_message, RoomMessage},
    receipt::ReceiptRecord,
    room::Room,
    RUNTIME,
};

#[derive(Clone, Debug)]
pub struct Conversation {
    inner: Room,
    latest_message: Mutable<Option<RoomMessage>>,
}

impl Conversation {
    pub(crate) fn new(inner: Room) -> Self {
        Conversation {
            inner,
            latest_message: Default::default(),
        }
    }

    pub(crate) fn load_latest_message(&self) {
        let room = self.room.clone();
        let timeline = room.timeline();
        let mut stream = timeline.signal().to_stream();
        let me = self.clone();

        // FIXME: hold this handler!
        RUNTIME.spawn(async move {
            while let Some(diff) = stream.next().await {
                match (diff) {
                    VecDiff::Replace { values } => {
                        info!("conversation timeline replace");
                    }
                    VecDiff::InsertAt { index, value } => {
                        info!("conversation timeline insert_at");
                    }
                    VecDiff::UpdateAt { index, value } => {
                        info!("conversation timeline update_at");
                    }
                    VecDiff::Push { value } => {
                        info!("conversation timeline push");
                        if let Some(inner) = timeline_item_to_message(value, room.clone()) {
                            me.set_latest_message(inner);
                            break;
                        }
                    }
                    VecDiff::RemoveAt { index } => {
                        info!("conversation timeline remove_at");
                    }
                    VecDiff::Move {
                        old_index,
                        new_index,
                    } => {
                        info!("conversation timeline move");
                    }
                    VecDiff::Pop {} => {
                        info!("conversation timeline pop");
                    }
                    VecDiff::Clear {} => {
                        info!("conversation timeline clear");
                    }
                }
            }

            // let (forward, backward) = room
            //     .timeline()
            //     .await
            //     .context("Failed acquiring timeline streams")
            //     .unwrap();

            // pin_mut!(backward);
            // // try to find the last message in the past.
            // loop {
            //     match backward.next().await {
            //         Some(Ok(ev)) => {
            //             info!("conversation timeline backward");
            //             if let Some(msg) = sync_event_to_message(ev, room.clone()) {
            //                 me.set_latest_message(msg);
            //                 break;
            //             }
            //         }
            //         Some(Err(e)) => {
            //             error!("Error fetching messages {:}", e);
            //             break;
            //         }
            //         None => {
            //             warn!("No old messages found");
            //             break;
            //         }
            //     }
            // }

            // pin_mut!(forward);
            // // now continue to poll for incoming messages
            // loop {
            //     match forward.next().await {
            //         Some(ev) => {
            //             info!("conversation timeline forward");
            //             if let Some(msg) = sync_event_to_message(ev, room.clone()) {
            //                 me.set_latest_message(msg);
            //                 break;
            //             }
            //         }
            //         None => {
            //             warn!("Messages stream stopped");
            //             break;
            //         }
            //     }
            // }
        });
    }

    pub(crate) fn set_latest_message(&self, msg: RoomMessage) {
        self.latest_message.set(Some(msg));
    }

    pub fn latest_message(&self) -> Option<RoomMessage> {
        self.latest_message.lock_mut().take()
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
    event_tx: Sender<RoomMessage>,
    event_rx: Arc<Mutex<Option<Receiver<RoomMessage>>>>,
}

impl ConversationController {
    pub fn new() -> Self {
        let (tx, rx) = channel::<RoomMessage>(10); // dropping after more than 10 items queued
        ConversationController {
            conversations: Default::default(),
            event_tx: tx,
            event_rx: Arc::new(Mutex::new(Some(rx))),
        }
    }

    pub async fn setup(&self, client: &MatrixClient) {
        let me = self.clone();
        client.add_event_handler_context(client.clone());
        client.add_event_handler_context(me.clone());
        client.add_event_handler(
            |ev: OriginalSyncRoomMessageEvent,
             room: MatrixRoom,
             Ctx(client): Ctx<MatrixClient>,
             Ctx(me): Ctx<ConversationController>| async move {
                me.clone().process_room_message(ev, &room, &client);
            },
        );
        client.add_event_handler_context(client.clone());
        client.add_event_handler_context(me);
        client.add_event_handler(
            |ev: OriginalSyncRoomMemberEvent,
             room: MatrixRoom,
             Ctx(client): Ctx<MatrixClient>,
             Ctx(me): Ctx<ConversationController>| async move {
                // user accepted invitation or left room
                me.clone().process_room_member(ev, &room, &client);
            },
        );
    }

    pub fn load_rooms(&self, convos: &Vec<Conversation>) {
        for convo in convos.iter() {
            convo.load_latest_message();
        }
        self.conversations.lock_mut().clone_from(convos);
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
                let convo = Conversation::new(Room {
                    client: client.clone(),
                    room: room.clone(),
                });
                let fallback = ev.content.body().to_string();
                let msg = RoomMessage::from_original(&ev, room.clone());
                convo.set_latest_message(msg.clone());
                convos.remove(idx);
                convos.insert(0, convo);
                if let Err(e) = self.event_tx.try_send(msg) {
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
                    let idx = conversations
                        .iter()
                        .position(|x| x.room_id() == room.room_id());
                    if idx.is_none() {
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
                Ok(response.room_id)
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

    pub fn message_event_rx(&self) -> Option<Receiver<RoomMessage>> {
        self.conversation_controller.event_rx.lock().take()
    }
}
