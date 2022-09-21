use anyhow::{bail, Context, Result};
use derive_builder::Builder;
use effektio_core::statics::default_effektio_conversation_states;
use futures::{pin_mut, StreamExt};
use futures_signals::{
    signal::{Mutable, MutableSignal, MutableSignalCloned, SignalExt, SignalStream},
    signal_vec::{MutableSignalVec, MutableVec, SignalVecExt, ToSignalCloned},
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

use super::{
    client::{devide_groups_from_common, Client},
    message::{sync_event_to_message, RoomMessage},
    receipt::UserReceipt,
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
        let me = self.clone();

        // FIXME: hold this handler!
        RUNTIME.spawn(async move {
            let (forward, backward) = room
                .timeline()
                .await
                .context("Failed acquiring timeline streams")
                .unwrap();

            pin_mut!(backward);
            // try to find the last message in the past.
            loop {
                match backward.next().await {
                    Some(Ok(ev)) => {
                        info!("conversation timeline backward");
                        if let Some(msg) = sync_event_to_message(ev, room.clone()) {
                            me.set_latest_message(msg);
                            break;
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

            pin_mut!(forward);
            // now continue to poll for incoming messages
            loop {
                match forward.next().await {
                    Some(ev) => {
                        info!("conversation timeline forward");
                        if let Some(msg) = sync_event_to_message(ev, room.clone()) {
                            me.set_latest_message(msg);
                            break;
                        }
                    }
                    None => {
                        warn!("Messages stream stopped");
                        break;
                    }
                }
            }
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

    pub async fn user_receipts(&self) -> Result<Vec<UserReceipt>> {
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                let mut records: Vec<UserReceipt> = vec![];
                for member in room.active_members().await? {
                    let user_id = member.user_id();
                    if let Some((event_id, receipt)) = room.user_read_receipt(user_id).await? {
                        let record = UserReceipt::new(event_id, user_id.to_owned(), receipt.ts);
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
}

impl ConversationController {
    pub fn new() -> Self {
        ConversationController {
            conversations: Default::default(),
        }
    }

    pub async fn setup(&self, client: &MatrixClient) {
        let (_, convos) = devide_groups_from_common(client.clone()).await;
        for convo in convos.iter() {
            convo.load_latest_message();
        }
        self.conversations.lock_mut().clone_from(&convos);

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
                me.clone().process_room_member(ev, &room, &client);
            },
        );
    }

    fn process_room_message(
        &self,
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
                let msg = RoomMessage::new(ev.clone(), room.clone(), ev.content.body().to_string());
                convo.set_latest_message(msg);
                convos.remove(idx);
                convos.insert(0, convo);
            }
        }
    }

    fn process_room_member(
        &self,
        ev: OriginalSyncRoomMemberEvent,
        room: &MatrixRoom,
        client: &MatrixClient,
    ) {
        info!("original sync room member event: {:?}", ev);
        let mut convos = self.conversations.lock_mut();
        if let Some(prev_content) = ev.unsigned.prev_content {
            match (prev_content.membership, ev.content.membership) {
                (MembershipState::Invite, MembershipState::Join) => {
                    // add new room
                    let convo = Conversation::new(Room {
                        client: client.clone(),
                        room: room.clone(),
                    });
                    convos.push(convo);
                }
                (MembershipState::Join, MembershipState::Leave) => {
                    // remove existing room
                    let room_id = room.room_id();
                    if let Some(idx) = convos.iter().position(|x| x.room_id() == room_id) {
                        convos.remove(idx);
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
                let res = client
                    .create_room(assign!(CreateRoomRequest::new(), {
                        creation_content: Some(Raw::new(&CreationContent::new())?),
                        initial_state: &initial_states,
                        is_direct: true,
                        invite: &settings.invites,
                        room_alias_name: settings.alias.as_deref(),
                        name: settings.name.as_ref().map(|x| x.as_ref()),
                        visibility: Visibility::Private,
                    }))
                    .await?;
                Ok(res.room_id().to_owned())
            })
            .await?
    }

    pub async fn conversation(&self, name_or_id: String) -> Result<Option<Conversation>> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                if let Ok(room) = me.room(name_or_id).await {
                    if !room.is_effektio_group().await {
                        Ok(Some(Conversation::new(room)))
                    } else {
                        bail!("Not a regular conversation but an effektio group!")
                    }
                } else {
                    Ok(None)
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
}
