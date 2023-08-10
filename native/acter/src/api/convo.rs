use acter_core::{statics::default_acter_convo_states, Error};
use anyhow::{bail, Result};
use derive_builder::Builder;
use futures_signals::signal::{Mutable, MutableSignalCloned, SignalExt, SignalStream};
use matrix_sdk::{
    deserialized_responses::SyncTimelineEvent,
    event_handler::{Ctx, EventHandlerHandle},
    room::{MessagesOptions, Room as SdkRoom},
    ruma::{
        api::client::room::{
            create_room::v3::{CreationContent, Request as CreateRoomRequest},
            Visibility,
        },
        assign,
        events::{
            receipt::{ReceiptThread, ReceiptType},
            room::{
                avatar::{ImageInfo, InitialRoomAvatarEvent, RoomAvatarEventContent},
                encrypted::OriginalSyncRoomEncryptedEvent,
                join_rules::{AllowRule, InitialRoomJoinRulesEvent, RoomJoinRulesEventContent},
                member::{MembershipState, OriginalSyncRoomMemberEvent},
                message::OriginalSyncRoomMessageEvent,
                redaction::SyncRoomRedactionEvent,
            },
            space::parent::SpaceParentEventContent,
            AnySyncTimelineEvent, InitialStateEvent,
        },
        serde::Raw,
        MxcUri, OwnedRoomId, OwnedUserId, RoomId, UserId,
    },
    Client as SdkClient, RoomMemberships,
};
use std::{ops::Deref, path::PathBuf};
use tracing::info;

use super::{
    client::Client,
    message::{sync_event_to_message, RoomMessage},
    receipt::ReceiptRecord,
    room::Room,
    RUNTIME,
};

#[derive(Clone, Debug)]
pub struct Convo {
    inner: Room,
    latest_message: Option<RoomMessage>,
}

impl Convo {
    pub(crate) fn new(inner: Room) -> Self {
        Convo {
            inner,
            latest_message: Default::default(),
        }
    }

    async fn fetch_latest_message(&mut self) {
        let room = self.room.clone();
        let options = MessagesOptions::backward();
        if let Ok(messages) = room.messages(options).await {
            let events = messages
                .chunk
                .into_iter()
                .map(SyncTimelineEvent::from)
                .collect::<Vec<SyncTimelineEvent>>();
            for event in events {
                // show only message event as latest message in chat room list
                // skip the state event
                // if let Ok(AnySyncTimelineEvent::MessageLike(m)) = event.event.deserialize() {
                if let Some(msg) = sync_event_to_message(&event.event, room.room_id().to_owned()) {
                    self.set_latest_message(msg);
                    return;
                }
                // }
            }
        }
    }

    fn set_latest_message(&mut self, mut msg: RoomMessage) {
        if let Some(mut event_item) = msg.event_item() {
            msg.set_event_item(Some(event_item));
        }
        self.latest_message = Some(msg);
    }

    pub fn latest_message(&self) -> Option<RoomMessage> {
        self.latest_message.clone()
    }

    pub fn get_room_id(&self) -> OwnedRoomId {
        self.room_id().to_owned()
    }

    pub fn get_room_id_str(&self) -> String {
        self.room_id().to_string()
    }

    pub async fn user_receipts(&self) -> Result<Vec<ReceiptRecord>> {
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                let mut records: Vec<ReceiptRecord> = vec![];
                for member in room.members(RoomMemberships::ACTIVE).await? {
                    let user_id = member.user_id();
                    if let Some((event_id, receipt)) = room
                        .user_receipt(ReceiptType::Read, ReceiptThread::Main, user_id)
                        .await?
                    {
                        let record = ReceiptRecord::new(event_id, user_id.to_owned(), receipt.ts);
                        records.push(record);
                    }
                }
                Ok(records)
            })
            .await?
    }
}

impl Deref for Convo {
    type Target = Room;
    fn deref(&self) -> &Room {
        &self.inner
    }
}

#[derive(Clone, Debug)]
pub(crate) struct ConvoController {
    convos: Mutable<Vec<Convo>>,
    encrypted_event_handle: Option<EventHandlerHandle>,
    message_event_handle: Option<EventHandlerHandle>,
    member_event_handle: Option<EventHandlerHandle>,
    redaction_event_handle: Option<EventHandlerHandle>,
}

impl ConvoController {
    pub fn new() -> Self {
        ConvoController {
            convos: Default::default(),
            encrypted_event_handle: None,
            message_event_handle: None,
            member_event_handle: None,
            redaction_event_handle: None,
        }
    }

    pub fn add_event_handler(&mut self, client: &SdkClient) {
        info!("sync room message event handler added");
        let me = self.clone();

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: Raw<OriginalSyncRoomEncryptedEvent>,
             room: SdkRoom,
             c: SdkClient,
             Ctx(me): Ctx<ConvoController>| async move {
                me.clone().process_room_encrypted(ev, &room, &c);
            },
        );
        self.encrypted_event_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: OriginalSyncRoomMessageEvent,
             room: SdkRoom,
             c: SdkClient,
             Ctx(me): Ctx<ConvoController>| async move {
                me.clone().process_room_message(ev, &room, &c);
            },
        );
        self.message_event_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: OriginalSyncRoomMemberEvent,
             room: SdkRoom,
             c: SdkClient,
             Ctx(me): Ctx<ConvoController>| async move {
                // user accepted invitation or left room
                me.clone().process_room_member(ev, &room, &c);
            },
        );
        self.member_event_handle = Some(handle);

        client.add_event_handler_context(me);
        let handle = client.add_event_handler(
            |ev: SyncRoomRedactionEvent,
             room: SdkRoom,
             c: SdkClient,
             Ctx(me): Ctx<ConvoController>| async move {
                me.clone().process_room_redaction(ev, &room, &c);
            },
        );
        self.redaction_event_handle = Some(handle);
    }

    pub fn remove_event_handler(&mut self, client: &SdkClient) {
        if let Some(handle) = self.encrypted_event_handle.clone() {
            client.remove_event_handler(handle);
            self.encrypted_event_handle = None;
        }
        if let Some(handle) = self.message_event_handle.clone() {
            client.remove_event_handler(handle);
            self.message_event_handle = None;
        }
        if let Some(handle) = self.member_event_handle.clone() {
            client.remove_event_handler(handle);
            self.member_event_handle = None;
        }
        if let Some(handle) = self.redaction_event_handle.clone() {
            client.remove_event_handler(handle);
            self.redaction_event_handle = None;
        }
    }

    pub async fn load_rooms(&mut self, convos: &Vec<Convo>) {
        let mut rooms: Vec<Convo> = vec![];
        for convo in convos {
            let mut convo = convo.clone();
            convo.fetch_latest_message().await;
            rooms.push(convo);
        }
        self.convos.lock_mut().clone_from(&rooms);
    }

    // reorder room list on OriginalSyncRoomEncryptedEvent
    async fn process_room_encrypted(
        &mut self,
        raw_event: Raw<OriginalSyncRoomEncryptedEvent>,
        room: &SdkRoom,
        client: &SdkClient,
    ) {
        info!("original sync room encrypted event: {:?}", raw_event);
        if let SdkRoom::Joined(joined) = room {
            let mut convos = self.convos.lock_mut();
            let room_id = room.room_id();

            let mut convo = Convo::new(Room { room: room.clone() });
            if let Ok(decrypted) = joined.decrypt_event(&raw_event).await {
                let ev = raw_event
                    .deserialize_as::<OriginalSyncRoomEncryptedEvent>()
                    .unwrap();
                let msg = RoomMessage::room_encrypted_from_sync_event(ev, room_id.to_owned());
                convo.set_latest_message(msg.clone());

                if let Some(idx) = convos.iter().position(|x| x.room_id() == room_id) {
                    convos.remove(idx);
                    convos.insert(0, convo);
                } else {
                    convos.insert(0, convo);
                }
            }
        }
    }

    // reorder room list on OriginalSyncRoomMessageEvent
    fn process_room_message(
        &mut self,
        ev: OriginalSyncRoomMessageEvent,
        room: &SdkRoom,
        client: &SdkClient,
    ) {
        info!("original sync room message event: {:?}", ev);
        if let SdkRoom::Joined(joined) = room {
            let mut convos = self.convos.lock_mut();
            let room_id = room.room_id();
            let sent_by_me = if let Some(user_id) = room.client().user_id() {
                ev.sender == user_id
            } else {
                false
            };

            let mut convo = Convo::new(Room { room: room.clone() });
            let msg = RoomMessage::room_message_from_sync_event(ev, room_id.to_owned(), sent_by_me);
            convo.set_latest_message(msg.clone());

            if let Some(idx) = convos.iter().position(|x| x.room_id() == room_id) {
                convos.remove(idx);
                convos.insert(0, convo);
            } else {
                convos.insert(0, convo);
            }
        }
    }

    // reorder room list on OriginalSyncRoomMemberEvent
    fn process_room_member(
        &mut self,
        ev: OriginalSyncRoomMemberEvent,
        room: &SdkRoom,
        client: &SdkClient,
    ) {
        // filter only event for me
        let user_id = client.user_id().expect("You seem to be not logged in");
        if ev.state_key != *user_id {
            if let SdkRoom::Joined(joined) = room {
                let mut convos = self.convos.lock_mut();
                let room_id = room.room_id();

                let mut convo = Convo::new(Room { room: room.clone() });
                let msg = RoomMessage::room_member_from_sync_event(ev, room_id.to_owned());
                convo.set_latest_message(msg.clone());

                if let Some(idx) = convos.iter().position(|x| x.room_id() == room_id) {
                    convos.remove(idx);
                    convos.insert(0, convo);
                } else {
                    convos.insert(0, convo);
                }
            }
            return;
        }

        let evt = ev.clone();
        let mut convos = self.convos.lock_mut();

        if let Some(prev_content) = ev.unsigned.prev_content {
            let room_id = room.room_id();
            match (prev_content.membership, ev.content.membership) {
                (MembershipState::Invite, MembershipState::Join) => {
                    // when user accepted invitation, this event is called twice
                    // i don't know that reason
                    // anyway i prevent this event from being called twice
                    if !convos.iter().any(|x| x.room_id() == room_id) {
                        // add new room
                        let convo = Convo::new(Room { room: room.clone() });
                        convos.insert(0, convo);
                    }
                }
                (MembershipState::Join, MembershipState::Leave) => {
                    // remove existing room
                    if let Some(idx) = convos.iter().position(|x| x.room_id() == room_id) {
                        convos.remove(idx);
                    }
                }
                _ => {}
            }
        }
    }

    // reorder room list on OriginalSyncRoomRedactionEvent
    fn process_room_redaction(
        &mut self,
        ev: SyncRoomRedactionEvent,
        room: &SdkRoom,
        client: &SdkClient,
    ) {
        info!("original sync room redaction event: {:?}", ev);
        if let SdkRoom::Joined(joined) = room {
            let mut convos = self.convos.lock_mut();
            let room_id = room.room_id();

            let mut convo = Convo::new(Room { room: room.clone() });
            let msg = RoomMessage::room_redaction_from_sync_event(ev, room_id.to_owned());
            convo.set_latest_message(msg.clone());

            if let Some(idx) = convos.iter().position(|x| x.room_id() == room_id) {
                convos.remove(idx);
                convos.insert(0, convo);
            } else {
                convos.insert(0, convo);
            }
        }
    }
}

#[derive(Builder, Default, Clone)]
pub struct CreateConvoSettings {
    #[builder(setter(into, strip_option), default)]
    name: Option<String>,

    // #[builder(default = "Visibility::Private")]
    // visibility: Visibility,
    #[builder(default = "Vec::new()")]
    invites: Vec<OwnedUserId>,

    #[builder(setter(into, strip_option), default)]
    alias: Option<String>,

    #[builder(setter(into, strip_option), default)]
    topic: Option<String>,

    #[builder(setter(strip_option), default)]
    avatar_uri: Option<String>,

    #[builder(setter(strip_option), default)]
    parent: Option<OwnedRoomId>,
}

// helper for built-in setters
impl CreateConvoSettingsBuilder {
    pub fn set_name(&mut self, value: String) {
        self.name(value);
    }

    pub fn set_alias(&mut self, value: String) {
        self.alias(value);
    }

    pub fn set_topic(&mut self, value: String) {
        self.topic(value);
    }

    pub fn add_invitee(&mut self, value: String) -> Result<()> {
        if let Ok(user_id) = UserId::parse(value) {
            if let Some(mut invites) = self.invites.clone() {
                invites.push(user_id);
                self.invites = Some(invites);
            } else {
                self.invites = Some(vec![user_id]);
            }
        }
        Ok(())
    }

    pub fn set_avatar_uri(&mut self, value: String) {
        self.avatar_uri(value);
    }

    pub fn set_parent(&mut self, value: String) {
        if let Ok(parent) = RoomId::parse(value) {
            self.parent(parent);
        }
    }
}

pub fn new_convo_settings_builder() -> CreateConvoSettingsBuilder {
    CreateConvoSettingsBuilder::default()
}

impl Client {
    pub async fn create_convo(&self, settings: Box<CreateConvoSettings>) -> Result<OwnedRoomId> {
        let client = self.core.client().clone();

        RUNTIME
            .spawn(async move {
                let mut initial_states = default_acter_convo_states();

                if let Some(avatar_uri) = settings.avatar_uri {
                    let uri = Box::<MxcUri>::from(avatar_uri.as_str());
                    let avatar_content = if uri.is_valid() {
                        // remote uri
                        assign!(RoomAvatarEventContent::new(), {
                            url: Some((*uri).to_owned()),
                        })
                    } else {
                        // local uri
                        let path = PathBuf::from(avatar_uri);
                        let guess = mime_guess::from_path(path.clone());
                        let content_type = guess.first().expect("MIME type should be given");
                        let buf = std::fs::read(path).expect("File should be read");
                        let upload_resp = client.media().upload(&content_type, buf).await?;

                        let info = assign!(ImageInfo::new(), {
                            blurhash: upload_resp.blurhash,
                            mimetype: Some(content_type.to_string()),
                        });
                        assign!(RoomAvatarEventContent::new(), {
                            url: Some(upload_resp.content_uri),
                            info: Some(Box::new(info)),
                        })
                    };
                    initial_states.push(InitialRoomAvatarEvent::new(avatar_content).to_raw_any());
                }

                if let Some(parent) = settings.parent {
                    let Some(Ok(homeserver)) = client.homeserver().await.host_str().map(|h|h.try_into()) else {
                      return Err(Error::HomeserverMissesHostname)?;
                    };
                    let parent_event = InitialStateEvent::<SpaceParentEventContent> {
                        content: assign!(SpaceParentEventContent::new(true), {
                            via: Some(vec![homeserver]),
                        }),
                        state_key: parent.clone(),
                    };
                    initial_states.push(parent_event.to_raw_any());
                    // if we have a parent, by default we allow access to the subspace.
                    let join_rule =
                        InitialRoomJoinRulesEvent::new(RoomJoinRulesEventContent::restricted(vec![
                            AllowRule::room_membership(parent),
                        ]));
                    initial_states.push(join_rule.to_raw_any());
                };

                let request = assign!(CreateRoomRequest::new(), {
                    creation_content: Some(Raw::new(&CreationContent::new())?),
                    initial_state: initial_states,
                    is_direct: true,
                    invite: settings.invites,
                    room_alias_name: settings.alias,
                    name: settings.name,
                    visibility: Visibility::Private,
                    topic: settings.topic,
                });
                let room = client.create_room(request).await?;
                Ok(room.room_id().to_owned())
            })
            .await?
    }

    pub async fn join_convo(
        &self,
        room_id_or_alias: String,
        server_name: Option<String>,
    ) -> Result<Convo> {
        let room = self
            .join_room(
                room_id_or_alias,
                server_name.map(|s| vec![s]).unwrap_or_default(),
            )
            .await?;
        Ok(Convo {
            latest_message: None,
            inner: room,
        })
    }

    pub async fn convo(&self, room_id_or_alias: String) -> Result<Convo> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let Ok(room) = me.room(room_id_or_alias).await else {
                    bail!("Neither roomId nor alias provided");
                };
                if room.is_space() {
                    bail!("Not a regular convo but an (acter) space!");
                }
                Ok(Convo::new(room))
            })
            .await?
    }

    pub fn convos_rx(&self) -> SignalStream<MutableSignalCloned<Vec<Convo>>> {
        self.convo_controller.convos.signal_cloned().to_stream()
    }
}
