use anyhow::{bail, Result};
use derive_builder::Builder;
use effektio_core::{
    events::{
        comments::{SyncCommentEvent, SyncCommentUpdateEvent},
        tasks::{SyncTaskEvent, SyncTaskListEvent, SyncTaskListUpdateEvent, SyncTaskUpdateEvent},
    },
    executor::Executor,
    models::AnyEffektioModel,
    ruma::{
        api::client::{
            account::register::v3::Request as RegistrationRequest,
            room::{
                create_room::v3::CreationContent, create_room::v3::Request as CreateRoomRequest,
                Visibility,
            },
            uiaa,
        },
        assign,
        events::{AnySyncTimelineEvent, MessageLikeEvent},
        room::RoomType,
        serde::Raw,
        OwnedRoomAliasId, OwnedRoomId, OwnedUserId, UserId,
    },
    statics::{default_effektio_group_states, initial_state_for_alias},
};
use log::warn;
use matrix_sdk::{
    deserialized_responses::EncryptionInfo,
    event_handler::Ctx,
    room::{Messages, MessagesOptions},
    Client as MatrixClient,
};
use serde::{Deserialize, Serialize};

use super::client::{devide_groups_from_convos, Client};
use super::room::Room;

use crate::api::RUNTIME;

#[derive(Debug, Clone)]
pub struct Group {
    pub client: Client,
    pub(crate) inner: Room,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct HistoryState {
    /// The last `end` send from the server
    seen: String,
}

impl Group {
    pub(crate) async fn add_handlers(&self) {
        self.room
            .client()
            .add_event_handler_context(self.client.executor.clone());
        let room_id = self.room_id().to_owned();
        // FIXME: combine into one handler

        // Tasks
        self.room.add_event_handler(
            move |ev: SyncTaskListEvent,
                  client: MatrixClient,
                  //  room: Room,
                  encryption_info: Option<EncryptionInfo>,
                  Ctx(executor): Ctx<Executor>| {
                let room_id = room_id.clone();
                async move {
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id.clone()) {
                        executor.handle(AnyEffektioModel::TaskList(t.into())).await;
                    }
                }
            },
        );
        let room_id = self.room_id().to_owned();
        self.room.add_event_handler(
            move |ev: SyncTaskListUpdateEvent,
                  client: MatrixClient,
                  Ctx(executor): Ctx<Executor>| {
                let room_id = room_id.clone();
                async move {
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id.clone()) {
                        executor
                            .handle(AnyEffektioModel::TaskListUpdate(t.into()))
                            .await;
                    }
                }
            },
        );
        let room_id = self.room_id().to_owned();
        self.room.add_event_handler(
            move |ev: SyncTaskEvent, client: MatrixClient, Ctx(executor): Ctx<Executor>| {
                let room_id = room_id.clone();
                async move {
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id.clone()) {
                        executor.handle(AnyEffektioModel::Task(t.into())).await;
                    }
                }
            },
        );
        let room_id = self.room_id().to_owned();
        self.room.add_event_handler(
            move |ev: SyncTaskUpdateEvent, client: MatrixClient, Ctx(executor): Ctx<Executor>| {
                let room_id = room_id.clone();
                async move {
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id.clone()) {
                        executor
                            .handle(AnyEffektioModel::TaskUpdate(t.into()))
                            .await;
                    }
                }
            },
        );

        // Comments
        let room_id = self.room_id().to_owned();
        self.room.add_event_handler(
            move |ev: SyncCommentEvent, client: MatrixClient, Ctx(executor): Ctx<Executor>| {
                let room_id = room_id.clone();
                async move {
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id.clone()) {
                        executor.handle(AnyEffektioModel::Comment(t.into())).await;
                    }
                }
            },
        );
        let room_id = self.room_id().to_owned();
        self.room.add_event_handler(
            move |ev: SyncCommentUpdateEvent,
                  client: MatrixClient,
                  Ctx(executor): Ctx<Executor>| {
                let room_id = room_id.clone();
                async move {
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id.clone()) {
                        executor
                            .handle(AnyEffektioModel::CommentUpdate(t.into()))
                            .await;
                    }
                }
            },
        );
    }

    pub fn get_room_id(&self) -> String {
        self.room_id().to_string()
    }

    pub(crate) async fn refresh_history(&self) -> anyhow::Result<()> {
        let name = self.inner.name();
        tracing::trace!(name, "refreshing history");
        let room = self.inner.clone();
        let room_id = room.room_id();
        let client = room.client.clone();
        room.sync_members().await?;

        let custom_storage_key = format!("{room_id}::history");

        let mut from = if let Ok(h) = self
            .client
            .executor
            .store()
            .get_raw::<HistoryState>(&custom_storage_key)
            .await
        {
            tracing::trace!(name, state=?h.seen, "found history state");
            Some(h.seen)
        } else {
            None
        };

        let mut msg_options = MessagesOptions::forward().from(from.as_deref());
        if from.is_none() {
            // minor hack to load lots in case we start from absolute zero
            msg_options.limit = 100u32.into();
        }

        loop {
            tracing::trace!(name, ?msg_options, "fetching messages");
            let Messages {
                end, chunk, state, ..
            } = room.messages(msg_options).await?;
            tracing::trace!(name, ?chunk, end, "messages received");

            let has_chunks = !chunk.is_empty();

            for msg in chunk {
                let Some(model) = AnyEffektioModel::from_raw_tlevent(&msg.event) else {
                    continue
                };
                // match event {
                //     MessageLikeEvent::Original(o) => {
                tracing::trace!(?room_id, user_id=?client.user_id(), ?model, "handling timeline event");
                if let Err(e) = self.client.executor().handle(model).await {
                    tracing::error!("Failure handling event: {:}", e);
                }
                //     }
                //     MessageLikeEvent::Redacted(r) => {
                //         tracing::trace!(redaction = ?r, "redaction ignored");
                //     }
                // }
            }

            // Todo: Do we want to do something with the states, too?

            if let Some(seen) = end {
                from = Some(seen.clone());
                msg_options = MessagesOptions::forward().from(from.as_deref());
                client
                    .store()
                    .set_custom_value(
                        custom_storage_key.as_bytes(),
                        serde_json::to_vec(&HistoryState { seen })?,
                    )
                    .await?;
            } else {
                // how do we want to understand this case?
                tracing::trace!(room_id = ?room.room_id(), "Done loading");
                break;
            }

            if !has_chunks && state.is_empty() {
                // nothing new to process, we are done catching up
                break;
            }
        }
        tracing::trace!(name, "history loaded");
        Ok(())
    }
}

impl std::ops::Deref for Group {
    type Target = Room;
    fn deref(&self) -> &Room {
        &self.inner
    }
}

#[derive(Builder, Default, Clone)]
pub struct CreateGroupSettings {
    #[builder(setter(strip_option))]
    name: Option<String>,
    #[builder(default = "Visibility::Private")]
    visibility: Visibility,
    #[builder(default = "Vec::new()")]
    invites: Vec<OwnedUserId>,
    #[builder(setter(strip_option), default)]
    alias: Option<String>,
}

impl CreateGroupSettings {
    pub fn visibility(&mut self, value: String) {
        match value.as_str() {
            "Public" => {
                self.visibility = Visibility::Public;
            }
            "Private" => {
                self.visibility = Visibility::Private;
            }
            _ => {}
        }
    }

    pub fn add_invitee(&mut self, value: String) {
        if let Ok(user_id) = UserId::parse(value) {
            self.invites.push(user_id);
        }
    }

    pub fn alias(&mut self, value: String) {
        self.alias = Some(value);
    }
}

// impl CreateGroupSettingsBuilder {
//     pub fn add_invite(&mut self, user_id: OwnedUserId) {
//         self.invites.get_or_insert_with(Vec::new).push(user_id);
//     }
// }

pub fn new_group_settings(name: String) -> CreateGroupSettings {
    CreateGroupSettingsBuilder::default()
        .name(name)
        .build()
        .unwrap()
}

impl Client {
    pub async fn create_effektio_group(
        &self,
        settings: Box<CreateGroupSettings>,
    ) -> Result<OwnedRoomId> {
        let c = self.client.clone();
        RUNTIME
            .spawn(async move {
                let initial_states = default_effektio_group_states();

                Ok(c.create_room(assign!(CreateRoomRequest::new(), {
                    creation_content: Some(Raw::new(&assign!(CreationContent::new(), {
                        room_type: Some(RoomType::Space)
                    }))?),
                    initial_state: initial_states,
                    is_direct: false,
                    invite: settings.invites,
                    room_alias_name: settings.alias,
                    name: settings.name,
                    visibility: settings.visibility,
                }))
                .await?
                .room_id()
                .to_owned())
            })
            .await?
    }

    pub async fn groups(&self) -> Result<Vec<Group>> {
        let c = self.clone();
        RUNTIME
            .spawn(async move {
                let (groups, _) = devide_groups_from_convos(c).await;
                Ok(groups)
            })
            .await?
    }

    pub async fn get_group(&self, alias_or_id: String) -> Result<Group> {
        if let Ok(room_id) = OwnedRoomId::try_from(alias_or_id.clone()) {
            match self.get_room(&room_id) {
                Some(room) => Ok(Group {
                    client: self.clone(),
                    inner: Room {
                        room,
                        client: self.client.clone(),
                    },
                }),
                None => bail!("Room not found"),
            }
        } else if let Ok(alias_id) = OwnedRoomAliasId::try_from(alias_or_id) {
            for group in self.groups().await?.into_iter() {
                if let Some(group_alias) = group.inner.room.canonical_alias() {
                    if group_alias == alias_id {
                        return Ok(group);
                    }
                }
            }
            bail!("Room with alias not found")
        } else {
            bail!("Neither roomId nor alias provided")
        }
    }
}
