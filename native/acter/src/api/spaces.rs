pub use acter_core::spaces::{
    CreateSpaceSettings, CreateSpaceSettingsBuilder, RelationTargetType, SpaceRelation,
    SpaceRelations,
};
use acter_core::{
    events::{
        calendar::{SyncCalendarEventEvent, SyncCalendarEventUpdateEvent},
        comments::{SyncCommentEvent, SyncCommentUpdateEvent},
        news::{SyncNewsEntryEvent, SyncNewsEntryUpdateEvent},
        pins::{SyncPinEvent, SyncPinUpdateEvent},
        tasks::{SyncTaskEvent, SyncTaskListEvent, SyncTaskListUpdateEvent, SyncTaskUpdateEvent},
    },
    executor::Executor,
    models::AnyActerModel,
    ruma::{events::MessageLikeEvent, OwnedRoomAliasId, OwnedRoomId, OwnedUserId},
    spaces::is_acter_space,
    statics::default_acter_space_states,
    templates::Engine,
};
use anyhow::{bail, Context, Result};
use futures::stream::StreamExt;
use log::warn;
use matrix_sdk::{
    deserialized_responses::EncryptionInfo,
    event_handler::Ctx,
    room::{Messages, MessagesOptions, Room as MatrixRoom},
    Client as MatrixClient,
};
use ruma::{
    api::client::state::send_state_event,
    events::{AnyStateEventContent, StateEventContent, _custom::CustomStateEventContent},
    serde::Raw,
};
use serde::{Deserialize, Serialize};

use super::{
    client::{devide_spaces_from_convos, Client},
    room::Room,
};
use crate::api::RUNTIME;

#[derive(Debug, Clone)]
pub struct Space {
    pub client: Client,
    pub(crate) inner: Room,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct HistoryState {
    /// The last `end` send from the server
    seen: String,
}

impl Space {
    pub fn new(client: Client, inner: Room) -> Self {
        Space { client, inner }
    }

    pub async fn create_onboarding_data(&self) -> Result<()> {
        let mut engine = Engine::with_template(std::include_str!("../templates/onboarding.toml"))?;
        engine
            .add_user("main".to_owned(), self.client.core.clone())
            .await?;
        engine.add_ref(
            "space".to_owned(),
            "space".to_owned(),
            self.room.room_id().to_string(),
        )?;

        let mut executer = engine.execute()?;
        while let Some(i) = executer.next().await {
            i?
        }

        Ok(())
    }

    pub async fn is_acter_space(&self) -> bool {
        is_acter_space(&self.inner).await
    }

    pub(crate) async fn add_handlers(&self) {
        self.room
            .client()
            .add_event_handler_context(self.client.executor().clone());
        tracing::trace!(room_id=?self.room.room_id(), "adding handlers");
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
                        executor.handle(AnyActerModel::TaskList(t.into())).await;
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
                            .handle(AnyActerModel::TaskListUpdate(t.into()))
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
                        executor.handle(AnyActerModel::Task(t.into())).await;
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
                        executor.handle(AnyActerModel::TaskUpdate(t.into())).await;
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
                        executor.handle(AnyActerModel::Comment(t.into())).await;
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
                            .handle(AnyActerModel::CommentUpdate(t.into()))
                            .await;
                    }
                }
            },
        );

        // Pins
        let room_id = self.room_id().to_owned();
        self.room.add_event_handler(
            move |ev: SyncPinEvent, client: MatrixClient, Ctx(executor): Ctx<Executor>| {
                let room_id = room_id.clone();
                async move {
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id.clone()) {
                        executor.handle(AnyActerModel::Pin(t.into())).await;
                    }
                }
            },
        );
        let room_id = self.room_id().to_owned();
        self.room.add_event_handler(
            move |ev: SyncPinUpdateEvent, client: MatrixClient, Ctx(executor): Ctx<Executor>| {
                let room_id = room_id.clone();
                async move {
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id.clone()) {
                        executor.handle(AnyActerModel::PinUpdate(t.into())).await;
                    }
                }
            },
        );

        // CalendarEvents
        let room_id = self.room_id().to_owned();
        self.room.add_event_handler(
            move |ev: SyncCalendarEventEvent,
                  client: MatrixClient,
                  Ctx(executor): Ctx<Executor>| {
                let room_id = room_id.clone();
                async move {
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id.clone()) {
                        executor
                            .handle(AnyActerModel::CalendarEvent(t.into()))
                            .await;
                    }
                }
            },
        );
        let room_id = self.room_id().to_owned();
        self.room.add_event_handler(
            move |ev: SyncCalendarEventUpdateEvent,
                  client: MatrixClient,
                  Ctx(executor): Ctx<Executor>| {
                let room_id = room_id.clone();
                async move {
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id.clone()) {
                        executor
                            .handle(AnyActerModel::CalendarEventUpdate(t.into()))
                            .await;
                    }
                }
            },
        );

        // NewsEntrys
        let room_id = self.room_id().to_owned();
        self.room.add_event_handler(
            move |ev: SyncNewsEntryEvent, client: MatrixClient, Ctx(executor): Ctx<Executor>| {
                let room_id = room_id.clone();
                async move {
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id.clone()) {
                        executor.handle(AnyActerModel::NewsEntry(t.into())).await;
                    }
                }
            },
        );
        let room_id = self.room_id().to_owned();
        self.room.add_event_handler(
            move |ev: SyncNewsEntryUpdateEvent,
                  client: MatrixClient,
                  Ctx(executor): Ctx<Executor>| {
                let room_id = room_id.clone();
                async move {
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id.clone()) {
                        executor
                            .handle(AnyActerModel::NewsEntryUpdate(t.into()))
                            .await;
                    }
                }
            },
        );
    }

    pub fn get_room_id(&self) -> String {
        self.room_id().to_string()
    }

    pub async fn set_acter_space_states(&self) -> Result<()> {
        let MatrixRoom::Joined(ref joined) = self.inner.room else {
            bail!("You can't convert a space you didn't join");
        };
        for state in default_acter_space_states() {
            println!("{:?}", state);
            let event_type = state.get_field("type")?.context("given")?;
            let state_key = state.get_field("state_key")?.unwrap_or_default();
            let body = state
                .get_field::<Raw<AnyStateEventContent>>("content")?
                .context("body is given")?;

            let request = send_state_event::v3::Request::new_raw(
                joined.room_id().to_owned(),
                event_type,
                state_key,
                body,
            );
            joined.client().send(request, None).await?;
        }
        Ok(())
    }

    pub(crate) async fn refresh_history(&self) -> Result<()> {
        let name = self.inner.name();
        let room = self.inner.clone();
        let room_id = room.room_id();
        tracing::trace!(name, ?room_id, "refreshing history");
        let client = room.room.client();
        // room.sync_members().await?;

        let custom_storage_key = format!("{room_id}::history");

        let mut from = if let Ok(h) = self
            .client
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
                let model = match AnyActerModel::from_raw_tlevent(&msg.event) {
                    Ok(model) => model,
                    Err(m) => {
                        if let Ok(state_key) = msg.event.get_field::<String>("state_key") {
                            tracing::trace!(state_key, "ignoring state event");
                            // ignore state keys
                        } else {
                            tracing::warn!(event=?msg.event, "Model didn't parse {:}", m);
                        }
                        continue;
                    }
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

    pub async fn space_relations(&self) -> Result<SpaceRelations> {
        let c = self.client.core.clone();
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                let relations = c.space_relations(&room).await?;
                Ok(relations)
            })
            .await?
    }
}

impl std::ops::Deref for Space {
    type Target = Room;
    fn deref(&self) -> &Room {
        &self.inner
    }
}

// impl CreateSpaceSettingsBuilder {
//     pub fn add_invite(&mut self, user_id: OwnedUserId) {
//         self.invites.get_or_insert_with(Vec::new).push(user_id);
//     }
// }

pub fn new_space_settings(name: String) -> CreateSpaceSettings {
    CreateSpaceSettingsBuilder::default()
        .name(name)
        .build()
        .unwrap()
}

impl Client {
    pub async fn create_acter_space(
        &self,
        settings: Box<CreateSpaceSettings>,
    ) -> Result<OwnedRoomId> {
        let c = self.core.clone();
        RUNTIME
            .spawn(async move {
                let room_id = c.create_acter_space(Box::into_inner(settings)).await?;
                Ok(room_id)
            })
            .await?
    }

    pub async fn spaces(&self) -> Result<Vec<Space>> {
        let c = self.clone();
        RUNTIME
            .spawn(async move {
                let (spaces, convos) = devide_spaces_from_convos(c).await;
                Ok(spaces)
            })
            .await?
    }

    pub async fn get_space(&self, alias_or_id: String) -> Result<Space> {
        if let Ok(room_id) = OwnedRoomId::try_from(alias_or_id.clone()) {
            self.get_room(&room_id)
                .map(|room| Space::new(self.clone(), Room { room }))
                .context("Room not found")
        } else if let Ok(alias_id) = OwnedRoomAliasId::try_from(alias_or_id) {
            for space in self.spaces().await?.into_iter() {
                if let Some(space_alias) = space.inner.room.canonical_alias() {
                    if space_alias == alias_id {
                        return Ok(space);
                    }
                }
            }
            bail!("Room with alias not found");
        } else {
            bail!("Neither roomId nor alias provided");
        }
    }
}
