use anyhow::Context;
use anyhow::{bail, Result};
use derive_builder::Builder;
use effektio_core::statics::default_effektio_conversation_states;
use futures::{pin_mut, StreamExt};
use futures_signals::{
    signal::{Mutable, SignalExt, SignalStream},
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
            message::{MessageType, OriginalSyncRoomMessageEvent, TextMessageEventContent},
        },
        serde::Raw,
        OwnedRoomId, OwnedUserId,
    },
    Client as MatrixClient,
};

use super::{
    client::{devide_groups_from_common, Client},
    message::{sync_event_to_message, RoomMessage},
    room::Room,
    RUNTIME,
};

#[derive(Clone)]
pub struct Conversation {
    inner: Room,
    latest_message: Mutable<Option<RoomMessage>>,
}

impl Conversation {
    pub(crate) fn new(inner: Room) -> Self {
        let room = inner.room.clone();
        let res = Conversation {
            inner,
            latest_message: Default::default(),
        };

        let me = res.clone();
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
                        info!("conversation timeline backward");
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

        res
    }

    pub(crate) fn set_latest_message(&self, msg: RoomMessage) {
        self.latest_message.set(Some(msg));
    }

    pub fn latest_message(&self) -> Option<RoomMessage> {
        self.latest_message.lock_mut().take()
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
    conversations: MutableVec<Conversation>,
}

impl ConversationController {
    pub(crate) fn new() -> Self {
        ConversationController {
            conversations: Default::default(),
        }
    }

    pub(crate) async fn setup(&self, client: &MatrixClient) {
        let (_, convos) = devide_groups_from_common(client.clone()).await;
        self.conversations.lock_mut().replace_cloned(convos);

        let me = self.clone();
        client
            .register_event_handler_context(me.clone())
            .register_event_handler_context(client.clone())
            .register_event_handler(
                |ev: OriginalSyncRoomMessageEvent,
                 room: MatrixRoom,
                 Ctx(me): Ctx<ConversationController>,
                 Ctx(client): Ctx<MatrixClient>| async move {
                    me.clone().process_room_message(ev, &room, &client);
                },
            )
            .await
            .register_event_handler_context(me)
            .register_event_handler_context(client.clone())
            .register_event_handler(
                |ev: OriginalSyncRoomMemberEvent,
                 room: MatrixRoom,
                 Ctx(me): Ctx<ConversationController>,
                 Ctx(client): Ctx<MatrixClient>| async move {
                    me.clone().process_room_member(ev, &room, &client);
                },
            )
            .await;
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
                let convo = Conversation::new(Room {
                    client: client.clone(),
                    room: room.clone(),
                });
                let msg = RoomMessage::new(ev.clone(), room.clone(), ev.content.body().to_string());
                convo.set_latest_message(msg);
                convos.set_cloned(idx, convo);
                convos.move_from_to(idx, 0);
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
                    convos.push_cloned(convo);
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
        let c = self.client.clone();
        RUNTIME
            .spawn(async move {
                let initial_states = default_effektio_conversation_states();
                let res = c
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
                Ok(res.room_id)
            })
            .await?
    }

    pub fn conversations_rx(&self) -> SignalStream<ToSignalCloned<MutableSignalVec<Conversation>>> {
        self.conversations_diff_rx().to_signal_cloned().to_stream()
    }

    pub fn conversations_diff_rx(&self) -> MutableSignalVec<Conversation> {
        self.conversation_controller
            .conversations
            .signal_vec_cloned()
    }
}
