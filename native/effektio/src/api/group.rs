use super::client::{devide_groups_from_convos, Client};
use super::room::Room;
use crate::api::RUNTIME;
use anyhow::{bail, Result};
use derive_builder::Builder;
use effektio_core::executor::Executor;
use effektio_core::{
    events::AnyEffektioEvent,
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
        room::RoomType,
        serde::Raw,
        OwnedRoomAliasId, OwnedRoomId, OwnedUserId,
    },
    statics::{default_effektio_group_states, initial_state_for_alias},
};
use log::warn;
use matrix_sdk::room::{Messages, MessagesOptions};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone)]
pub struct Group {
    pub(crate) executor: Executor,
    pub(crate) inner: Room,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct HistoryState {
    /// The last `end` send from the server
    seen: String,
}

impl Group {
    pub(crate) async fn refresh_history(&self) -> anyhow::Result<()> {
        let name = self.inner.name();
        tracing::trace!(name, "refreshing history");
        let room = self.inner.clone();
        let client = room.client.clone();
        room.sync_members().await?;

        let custom_storage_key = format!("{:}_:history", room.room_id());

        let mut from = if let Some(Ok(h)) = client
            .store()
            .get_custom_value(custom_storage_key.as_bytes())
            .await?
            .map(|v| serde_json::from_slice::<HistoryState>(&v))
        {
            Some(h.seen.clone())
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
                if let Ok(event) = msg.event.deserialize_as::<AnyEffektioEvent>() {
                    warn!("{:} handling {:?}", room.room_id(), event);
                    // ...
                    if let Err(e) = self.executor.handle(event).await {
                        tracing::error!("Failure handling event: {:}", e);
                    }
                    warn!("done handling");
                } else {
                    tracing::trace!(?msg, "not an effektio msg");
                }
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
    #[builder(setter(strip_option))]
    alias: Option<String>,
}

// impl CreateGroupSettingsBuilder {
//     pub fn add_invite(&mut self, user_id: OwnedUserId) {
//         self.invites.get_or_insert_with(Vec::new).push(user_id);
//     }
// }

impl Client {
    pub async fn create_effektio_group(
        &self,
        settings: CreateGroupSettings,
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
        let c = self.client.clone();
        let e = self.executor.clone();
        RUNTIME
            .spawn(async move {
                let (groups, _) = devide_groups_from_convos(c, e).await;
                Ok(groups)
            })
            .await?
    }

    pub async fn get_group(&self, alias_or_id: String) -> Result<Group> {
        if let Ok(room_id) = OwnedRoomId::try_from(alias_or_id.clone()) {
            match self.get_room(&room_id) {
                Some(room) => Ok(Group {
                    executor: self.executor().clone(),
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
