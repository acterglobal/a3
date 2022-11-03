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
use js_int::uint;
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
    message::{sync_event_to_message, timeline_item_to_message, RoomMessage},
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

    pub(crate) fn load_latest_message(&self) {
        let room = self.room.clone();
        let mut me = self.clone();

        // FIXME: hold this handler!
        RUNTIME.spawn(async move {
            let timeline = room.timeline();
            let outcome = timeline.paginate_backwards(uint!(10)).await.unwrap();
            let mut stream = timeline.signal().to_stream();

            while let Some(diff) = stream.next().await {
                match (diff) {
                    VecDiff::Replace { values } => {
                        info!("conversation timeline replace");
                        let value = values.last().unwrap().clone();
                        if let Some(msg) = timeline_item_to_message(value, room.clone()) {
                            me.set_latest_message(msg);
                        }
                        break;
                    }
                    VecDiff::InsertAt { index, value } => {
                        info!("conversation timeline insert_at");
                        if let Some(msg) = timeline_item_to_message(value, room.clone()) {
                            me.set_latest_message(msg);
                        }
                        break;
                    }
                    VecDiff::UpdateAt { index, value } => {
                        info!("conversation timeline update_at");
                        if let Some(msg) = timeline_item_to_message(value, room.clone()) {
                            me.set_latest_message(msg);
                        }
                        break;
                    }
                    VecDiff::Push { value } => {
                        info!("conversation timeline push");
                        if let Some(msg) = timeline_item_to_message(value, room.clone()) {
                            me.set_latest_message(msg);
                        }
                        break;
                    }
                    VecDiff::RemoveAt { index } => {
                        info!("conversation timeline remove_at");
                        break;
                    }
                    VecDiff::Move {
                        old_index,
                        new_index,
                    } => {
                        info!("conversation timeline move");
                        break;
                    }
                    VecDiff::Pop {} => {
                        info!("conversation timeline pop");
                        break;
                    }
                    VecDiff::Clear {} => {
                        info!("conversation timeline clear");
                        break;
                    }
                }
            }
        });
    }

    pub(crate) fn set_latest_message(&mut self, msg: RoomMessage) {
        self.latest_message = Some(msg);
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
    event_tx: Sender<RoomMessage>,
    event_rx: Arc<Mutex<Option<Receiver<RoomMessage>>>>,
    message_event_handle: Option<EventHandlerHandle>,
    member_event_handle: Option<EventHandlerHandle>,
}

impl ConversationController {
    pub fn new() -> Self {
        let (tx, rx) = channel::<RoomMessage>(10); // dropping after more than 10 items queued
        ConversationController {
            conversations: Default::default(),
            event_tx: tx,
            event_rx: Arc::new(Mutex::new(Some(rx))),
            message_event_handle: None,
            member_event_handle: None,
        }
    }

    pub async fn add_event_handler(&mut self, client: &MatrixClient) {
        let me = self.clone();

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: OriginalSyncRoomMessageEvent,
             room: MatrixRoom,
             c: MatrixClient,
             Ctx(me): Ctx<ConversationController>| async move {
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

    pub fn load_rooms(&self, new_convos: &Vec<Conversation>) {
        let mut convos = self.conversations.lock_mut();
        for convo in new_convos.iter() {
            let room_id = convo.room_id();
            // exlcude room that was synced via OriginalSyncRoomMessageEvent
            if let None = convos.iter().position(|x| x.room_id() == room_id) {
                convo.load_latest_message();
                convos.insert(0, convo.clone());
            }
        }
    }

    // this callback is called prior to load_rooms
    fn process_room_message(
        &mut self,
        ev: OriginalSyncRoomMessageEvent,
        room: &MatrixRoom,
        client: &MatrixClient,
    ) {
        info!("original sync room message event: {:?}", ev);
        let mut convos = self.conversations.lock_mut();
        let room_id = room.room_id();

        let mut convo = Conversation::new(Room {
            client: client.clone(),
            room: room.clone(),
        });
        let msg = RoomMessage::from_original(&ev, room.clone());
        convo.set_latest_message(msg.clone());

        if let Some(idx) = convos.iter().position(|x| x.room_id() == room_id) {
            info!("existing convo index: {}", idx);
            convos.remove(idx);
            convos.insert(0, convo);
            if let Err(e) = self.event_tx.try_send(msg) {
                warn!("Dropping ephemeral event for {}: {}", room_id, e);
            }
        } else {
            convos.insert(0, convo);
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
                        info!("original sync room member event: {:?}", evt);
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
