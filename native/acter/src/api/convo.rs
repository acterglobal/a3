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
use std::{
    ops::Deref,
    path::PathBuf,
    sync::{Arc, RwLock},
};
use tracing::{error, info};

use super::{
    client::Client,
    message::{sync_event_to_message, RoomMessage},
    receipt::ReceiptRecord,
    room::Room,
    RUNTIME,
};

#[derive(Clone, Debug)]
pub struct Convo {
    client: Client,
    inner: Room,
    latest_message: Arc<RwLock<Option<RoomMessage>>>,
}

impl Convo {
    pub(crate) fn new(client: Client, inner: Room) -> Self {
        Convo {
            inner,
            client,
            latest_message: Default::default(),
        }
    }

    async fn fetch_latest_message(&self) {
        let room = self.room.clone();
        if let Ok(msg) = self
            .client
            .store()
            .get_raw(&self.latest_msg_storage_key())
            .await
        {
            self.set_latest_message(msg, false, true).await;
            return;
        }

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
                    self.set_latest_message(msg, true, true).await;
                    return;
                }
                // }
            }
        }
    }

    fn latest_msg_storage_key(&self) -> String {
        format!("{}::latest_msg", self.room.room_id())
    }

    async fn set_latest_message(&self, msg: RoomMessage, update_store: bool, only_if_empty: bool) {
        match self.latest_message.write() {
            Err(e) => error!(
                ?e,
                id = ?self.room.room_id(),
                "Acquiring the latest message rw lock failed"
            ),
            Ok(mut e) => {
                if e.is_some() && only_if_empty {
                    // we do not do anything
                    info!("Skipping: already set and we aren't supposed to overwrite");
                    return;
                }
                *e = Some(msg.clone());
            }
        };

        if (update_store) {
            if let Err(e) = self
                .client
                .store()
                .set_raw(&self.latest_msg_storage_key(), &msg)
                .await
            {
                error!(room_id = ?self.room.room_id(), error=?e, "Error saving latest message")
            }
        }
    }

    pub fn latest_message_ts(&self) -> u64 {
        match self.latest_message.read() {
            Err(e) => {
                error!(
                    ?e,
                    id = ?self.room.room_id(),
                    "Acquiring the latest message read lock failed"
                );
                return 0;
            }
            Ok(o) => o
                .as_ref()
                .and_then(|m| m.event_item())
                .map(|e| e.origin_server_ts())
                .unwrap_or_default(),
        }
    }

    pub fn latest_message(&self) -> Option<RoomMessage> {
        let latest_message = match self.latest_message.read() {
            Err(e) => {
                error!(
                    ?e,
                    id = ?self.room.room_id(),
                    "Acquiring the latest message read lock failed"
                );
                return None;
            }
            Ok(o) => o.clone(),
        };
        latest_message
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

    pub fn add_event_handler(&mut self, client: &Client) {
        info!("sync room message event handler added");
        let me = self.clone();

        client.add_event_handler_context(me.clone());
        client.add_event_handler_context(client.clone());
        let handle = client.add_event_handler(
            |ev: Raw<OriginalSyncRoomEncryptedEvent>,
             room: SdkRoom,
             c: SdkClient,
             Ctx(client): Ctx<Client>,
             Ctx(me): Ctx<ConvoController>| async move {
                me.process_room_encrypted(ev, &room, &client);
            },
        );
        self.encrypted_event_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: OriginalSyncRoomMessageEvent,
             room: SdkRoom,
             c: SdkClient,
             Ctx(client): Ctx<Client>,
             Ctx(me): Ctx<ConvoController>| async move {
                me.process_room_message(ev, &room, &client);
            },
        );
        self.message_event_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: OriginalSyncRoomMemberEvent,
             room: SdkRoom,
             c: SdkClient,
             Ctx(client): Ctx<Client>,
             Ctx(me): Ctx<ConvoController>| async move {
                // user accepted invitation or left room
                me.process_room_member(ev, &room, &client);
            },
        );
        self.member_event_handle = Some(handle);

        client.add_event_handler_context(me);
        let handle = client.add_event_handler(
            |ev: SyncRoomRedactionEvent,
             room: SdkRoom,
             c: SdkClient,
             Ctx(client): Ctx<Client>,
             Ctx(me): Ctx<ConvoController>| async move {
                me.process_room_redaction(ev, &room, &client);
            },
        );
        self.redaction_event_handle = Some(handle);
    }

    pub fn convos(&self) -> Vec<Convo> {
        self.convos.get_cloned()
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

    pub async fn load_rooms(&self, mut convos: Vec<Convo>) {
        for convo in convos.iter_mut() {
            convo.fetch_latest_message().await;
        }
        self.convos.lock_mut().clone_from(&convos);
    }

    // reorder room list on OriginalSyncRoomEncryptedEvent
    async fn process_room_encrypted(
        &self,
        raw_event: Raw<OriginalSyncRoomEncryptedEvent>,
        room: &SdkRoom,
        client: &Client,
    ) {
        info!("original sync room encrypted event: {:?}", raw_event);
        if let SdkRoom::Joined(joined) = room {
            let mut convos = self.convos.lock_mut();
            let room_id = room.room_id();

            if let Ok(decrypted) = joined.decrypt_event(&raw_event).await {
                let ev = raw_event
                    .deserialize_as::<OriginalSyncRoomEncryptedEvent>()
                    .unwrap();
                let msg = RoomMessage::room_encrypted_from_sync_event(ev, room_id.to_owned());

                if let Some(idx) = convos.iter().position(|x| x.room_id() == room_id) {
                    let mut convo = convos.remove(idx);
                    convo.set_latest_message(msg, true, false);
                    convos.insert(0, convo.clone());
                } else {
                    let mut convo = Convo::new(client.clone(), Room { room: room.clone() });
                    convo.set_latest_message(msg, true, false);
                    convos.insert(0, convo);
                }
            }
        }
    }

    // reorder room list on OriginalSyncRoomMessageEvent
    fn process_room_message(
        &self,
        ev: OriginalSyncRoomMessageEvent,
        room: &SdkRoom,
        client: &Client,
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

            let msg = RoomMessage::room_message_from_sync_event(ev, room_id.to_owned(), sent_by_me);

            if let Some(idx) = convos.iter().position(|x| x.room_id() == room_id) {
                let mut convo = convos.remove(idx);
                convo.set_latest_message(msg, true, false);
                convos.insert(0, convo.clone());
            } else {
                let mut convo = Convo::new(client.clone(), Room { room: room.clone() });
                convo.set_latest_message(msg, true, false);
                convos.insert(0, convo);
            }
        }
    }

    // reorder room list on OriginalSyncRoomMemberEvent
    fn process_room_member(
        &self,
        ev: OriginalSyncRoomMemberEvent,
        room: &SdkRoom,
        client: &Client,
    ) {
        // filter only event for me
        let user_id = client.user_id().expect("You seem to be not logged in");
        if ev.state_key != *user_id {
            if let SdkRoom::Joined(joined) = room {
                let mut convos = self.convos.lock_mut();
                let room_id = room.room_id();

                let msg = RoomMessage::room_member_from_sync_event(ev, room_id.to_owned());

                if let Some(idx) = convos.iter().position(|x| x.room_id() == room_id) {
                    let mut convo = convos.remove(idx);
                    convo.set_latest_message(msg, true, false);
                    convos.insert(0, convo.clone());
                } else {
                    let mut convo = Convo::new(client.clone(), Room { room: room.clone() });
                    convo.set_latest_message(msg, true, false);
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
                        let convo = Convo::new(client.clone(), Room { room: room.clone() });
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
    fn process_room_redaction(&self, ev: SyncRoomRedactionEvent, room: &SdkRoom, client: &Client) {
        info!("original sync room redaction event: {:?}", ev);
        if let SdkRoom::Joined(joined) = room {
            let mut convos = self.convos.lock_mut();
            let room_id = room.room_id();

            let msg = RoomMessage::room_redaction_from_sync_event(ev, room_id.to_owned());

            if let Some(idx) = convos.iter().position(|x| x.room_id() == room_id) {
                let mut convo = convos.remove(idx);
                convo.set_latest_message(msg, true, false);
                convos.insert(0, convo.clone());
            } else {
                let mut convo = Convo::new(client.clone(), Room { room: room.clone() });
                convo.set_latest_message(msg, true, false);
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
            client: self.clone(),
            latest_message: Default::default(),
            inner: room,
        })
    }

    pub async fn convo(&self, room_id_or_alias: String) -> Result<Convo> {
        let room_str = room_id_or_alias.as_str();
        for convo in self.convo_controller.convos.lock_ref().iter() {
            if convo.get_room_id().as_str() == room_str {
                return Ok(convo.clone());
            }
        }
        bail!("Room not found");
    }

    pub fn convos_rx(&self) -> SignalStream<MutableSignalCloned<Vec<Convo>>> {
        self.convo_controller.convos.signal_cloned().to_stream()
    }
}
