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
    spaces::is_acter_space,
    statics::default_acter_space_states,
    templates::Engine,
};
use anyhow::{bail, Context, Result};
use futures::stream::StreamExt;
use log::warn;
use matrix_sdk::{
    deserialized_responses::EncryptionInfo,
    event_handler::{Ctx, EventHandlerHandle},
    room::{Messages, MessagesOptions, Room as SdkRoom},
    ruma::{
        api::client::state::send_state_event::v3::Request as SendStateEventRequest,
        events::{AnyStateEventContent, MessageLikeEvent, StateEventType},
        serde::Raw,
        OwnedRoomAliasId, OwnedRoomId, OwnedUserId,
    },
    Client as SdkClient,
};
use serde::{Deserialize, Serialize};
use std::ops::Deref;

use super::{
    client::{devide_spaces_from_convos, Client},
    room::Room,
    RUNTIME,
};

#[derive(Debug, Clone)]
pub struct Space {
    pub client: Client,
    pub(crate) inner: Room,
    task_list_event_handle: Option<EventHandlerHandle>,
    task_list_update_event_handle: Option<EventHandlerHandle>,
    task_event_handle: Option<EventHandlerHandle>,
    task_update_event_handle: Option<EventHandlerHandle>,
    comment_event_handle: Option<EventHandlerHandle>,
    comment_update_event_handle: Option<EventHandlerHandle>,
    pin_event_handle: Option<EventHandlerHandle>,
    pin_update_event_handle: Option<EventHandlerHandle>,
    calendar_event_event_handle: Option<EventHandlerHandle>,
    calendar_event_update_event_handle: Option<EventHandlerHandle>,
    news_entry_event_handle: Option<EventHandlerHandle>,
    news_entry_update_event_handle: Option<EventHandlerHandle>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct HistoryState {
    /// The last `end` send from the server
    seen: String,
}

impl Space {
    pub fn new(client: Client, inner: Room) -> Self {
        Space {
            client,
            inner,
            task_list_event_handle: None,
            task_list_update_event_handle: None,
            task_event_handle: None,
            task_update_event_handle: None,
            comment_event_handle: None,
            comment_update_event_handle: None,
            pin_event_handle: None,
            pin_update_event_handle: None,
            calendar_event_event_handle: None,
            calendar_event_update_event_handle: None,
            news_entry_event_handle: None,
            news_entry_update_event_handle: None,
        }
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

    // for only cli run_marking_space, not api.rsh
    pub async fn is_acter_space(&self) -> bool {
        is_acter_space(&self.inner).await
    }

    pub(crate) async fn add_handlers(&mut self) {
        self.room
            .client()
            .add_event_handler_context(self.client.executor().clone());
        tracing::trace!(room_id=?self.room.room_id(), "adding handlers");
        // FIXME: combine into one handler

        // Tasks
        let handle =
            self.room.add_event_handler(
                |ev: SyncTaskListEvent,
                 room: SdkRoom,
                 c: SdkClient,
                 Ctx(executor): Ctx<Executor>| async move {
                    let room_id = room.room_id().to_owned();
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                        executor.handle(AnyActerModel::TaskList(t.into())).await;
                    }
                },
            );
        self.task_list_event_handle = Some(handle);
        let handle = self.room.add_event_handler(
            |ev: SyncTaskListUpdateEvent,
             room: SdkRoom,
             c: SdkClient,
             Ctx(executor): Ctx<Executor>| async move {
                let room_id = room.room_id().to_owned();
                // FIXME: handle redactions
                if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                    executor
                        .handle(AnyActerModel::TaskListUpdate(t.into()))
                        .await;
                }
            },
        );
        self.task_list_update_event_handle = Some(handle);
        let handle = self.room.add_event_handler(
            |ev: SyncTaskEvent,
             room: SdkRoom,
             c: SdkClient,
             Ctx(executor): Ctx<Executor>| async move {
                let room_id = room.room_id().to_owned();
                // FIXME: handle redactions
                if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                    executor.handle(AnyActerModel::Task(t.into())).await;
                }
            },
        );
        self.task_event_handle = Some(handle);
        let handle =
            self.room.add_event_handler(
                |ev: SyncTaskUpdateEvent,
                 room: SdkRoom,
                 c: SdkClient,
                 Ctx(executor): Ctx<Executor>| async move {
                    let room_id = room.room_id().to_owned();
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                        executor.handle(AnyActerModel::TaskUpdate(t.into())).await;
                    }
                },
            );
        self.task_update_event_handle = Some(handle);

        // Comments
        let handle =
            self.room.add_event_handler(
                |ev: SyncCommentEvent,
                 room: SdkRoom,
                 c: SdkClient,
                 Ctx(executor): Ctx<Executor>| async move {
                    let room_id = room.room_id().to_owned();
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                        executor.handle(AnyActerModel::Comment(t.into())).await;
                    }
                },
            );
        self.comment_event_handle = Some(handle);
        let handle = self.room.add_event_handler(
            |ev: SyncCommentUpdateEvent,
             room: SdkRoom,
             c: SdkClient,
             Ctx(executor): Ctx<Executor>| async move {
                let room_id = room.room_id().to_owned();
                // FIXME: handle redactions
                if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                    executor
                        .handle(AnyActerModel::CommentUpdate(t.into()))
                        .await;
                }
            },
        );
        self.comment_update_event_handle = Some(handle);

        // Pins
        let handle = self.room.add_event_handler(
            |ev: SyncPinEvent,
             room: SdkRoom,
             c: SdkClient,
             Ctx(executor): Ctx<Executor>| async move {
                let room_id = room.room_id().to_owned();
                // FIXME: handle redactions
                if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                    executor.handle(AnyActerModel::Pin(t.into())).await;
                }
            },
        );
        self.pin_event_handle = Some(handle);
        let handle =
            self.room.add_event_handler(
                |ev: SyncPinUpdateEvent,
                 room: SdkRoom,
                 c: SdkClient,
                 Ctx(executor): Ctx<Executor>| async move {
                    let room_id = room.room_id().to_owned();
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                        executor.handle(AnyActerModel::PinUpdate(t.into())).await;
                    }
                },
            );
        self.pin_update_event_handle = Some(handle);

        // CalendarEvents
        let handle = self.room.add_event_handler(
            |ev: SyncCalendarEventEvent,
             room: SdkRoom,
             c: SdkClient,
             Ctx(executor): Ctx<Executor>| async move {
                let room_id = room.room_id().to_owned();
                // FIXME: handle redactions
                if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                    executor
                        .handle(AnyActerModel::CalendarEvent(t.into()))
                        .await;
                }
            },
        );
        self.calendar_event_event_handle = Some(handle);
        let handle = self.room.add_event_handler(
            |ev: SyncCalendarEventUpdateEvent,
             room: SdkRoom,
             c: SdkClient,
             Ctx(executor): Ctx<Executor>| async move {
                let room_id = room.room_id().to_owned();
                // FIXME: handle redactions
                if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                    executor
                        .handle(AnyActerModel::CalendarEventUpdate(t.into()))
                        .await;
                }
            },
        );
        self.calendar_event_update_event_handle = Some(handle);

        // NewsEntrys
        let handle =
            self.room.add_event_handler(
                |ev: SyncNewsEntryEvent,
                 room: SdkRoom,
                 c: SdkClient,
                 Ctx(executor): Ctx<Executor>| async move {
                    let room_id = room.room_id().to_owned();
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                        executor.handle(AnyActerModel::NewsEntry(t.into())).await;
                    }
                },
            );
        self.news_entry_event_handle = Some(handle);
        let handle = self.room.add_event_handler(
            |ev: SyncNewsEntryUpdateEvent,
             room: SdkRoom,
             c: SdkClient,
             Ctx(executor): Ctx<Executor>| async move {
                let room_id = room.room_id().to_owned();
                // FIXME: handle redactions
                if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                    executor
                        .handle(AnyActerModel::NewsEntryUpdate(t.into()))
                        .await;
                }
            },
        );
        self.news_entry_update_event_handle = Some(handle);
    }

    pub(crate) fn remove_handlers(&mut self) {
        let client = self.room.client();
        if let Some(handle) = self.task_list_event_handle.clone() {
            client.remove_event_handler(handle);
            self.task_list_event_handle = None;
        }
        if let Some(handle) = self.task_list_update_event_handle.clone() {
            client.remove_event_handler(handle);
            self.task_list_update_event_handle = None;
        }
        if let Some(handle) = self.task_event_handle.clone() {
            client.remove_event_handler(handle);
            self.task_event_handle = None;
        }
        if let Some(handle) = self.task_update_event_handle.clone() {
            client.remove_event_handler(handle);
            self.task_update_event_handle = None;
        }
        if let Some(handle) = self.comment_event_handle.clone() {
            client.remove_event_handler(handle);
            self.comment_event_handle = None;
        }
        if let Some(handle) = self.comment_update_event_handle.clone() {
            client.remove_event_handler(handle);
            self.comment_update_event_handle = None;
        }
        if let Some(handle) = self.pin_event_handle.clone() {
            client.remove_event_handler(handle);
            self.pin_event_handle = None;
        }
        if let Some(handle) = self.pin_update_event_handle.clone() {
            client.remove_event_handler(handle);
            self.pin_update_event_handle = None;
        }
        if let Some(handle) = self.calendar_event_event_handle.clone() {
            client.remove_event_handler(handle);
            self.calendar_event_event_handle = None;
        }
        if let Some(handle) = self.calendar_event_update_event_handle.clone() {
            client.remove_event_handler(handle);
            self.calendar_event_update_event_handle = None;
        }
        if let Some(handle) = self.news_entry_event_handle.clone() {
            client.remove_event_handler(handle);
            self.news_entry_event_handle = None;
        }
        if let Some(handle) = self.news_entry_update_event_handle.clone() {
            client.remove_event_handler(handle);
            self.news_entry_update_event_handle = None;
        }
    }

    pub fn get_room_id(&self) -> OwnedRoomId {
        self.room_id().to_owned()
    }

    pub async fn set_acter_space_states(&self) -> Result<()> {
        let SdkRoom::Joined(ref joined) = self.inner.room else {
            bail!("You can't convert a space you didn't join");
        };
        let client = joined.client();
        let my_id = client.user_id().context("User not found")?.to_owned();
        let member = joined
            .get_member(&my_id)
            .await?
            .context("Couldn't find me among room members")?;
        for state in default_acter_space_states() {
            println!("{:?}", state);
            let event_type = state.get_field("type")?.context("given")?;
            let state_key = state.get_field("state_key")?.unwrap_or_default();
            let body = state
                .get_field::<Raw<AnyStateEventContent>>("content")?
                .context("body is given")?;
            if !member.can_send_state(StateEventType::RoomAvatar) {
                bail!("No permission to change avatar of this room");
            }

            let request = SendStateEventRequest::new_raw(
                joined.room_id().to_owned(),
                event_type,
                state_key,
                body,
            );
            client.send(request, None).await?;
        }
        Ok(())
    }

    pub(crate) async fn refresh_history(&self) -> Result<()> {
        let name = self.room.name();
        let room_id = self.room.room_id();
        tracing::trace!(name, ?room_id, "refreshing history");
        let client = self.room.client();
        // self.room.sync_members().await.context("Couldn't sync members of room")?;

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
            } = self.room.messages(msg_options).await?;
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
                tracing::trace!(room_id = ?self.room.room_id(), "Done loading");
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

impl Deref for Space {
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
                .context("Room not found")
                .map(|room| Space::new(self.clone(), Room { room }))
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
