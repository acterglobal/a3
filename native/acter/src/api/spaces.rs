pub use acter_core::spaces::{
    CreateSpaceSettings, CreateSpaceSettingsBuilder, RelationTargetType, SpaceRelation,
    SpaceRelations,
};
use acter_core::{
    events::{
        attachments::{SyncAttachmentEvent, SyncAttachmentUpdateEvent},
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
use async_broadcast::Receiver;
use futures::stream::StreamExt;
use matrix_sdk::{
    deserialized_responses::EncryptionInfo,
    event_handler::{Ctx, EventHandlerHandle},
    room::{Messages, MessagesOptions, Room as SdkRoom},
    ruma::{
        api::client::state::send_state_event::v3::Request as SendStateEventRequest,
        events::{
            space::child::SpaceChildEventContent, AnyStateEventContent, MessageLikeEvent,
            StateEventType,
        },
        serde::Raw,
        OwnedRoomAliasId, OwnedRoomId, OwnedUserId,
    },
    Client as SdkClient,
};
use ruma::assign;
use serde::{Deserialize, Serialize};
use std::{ops::Deref, thread::JoinHandle};
use tracing::{error, trace};

use crate::Conversation;

use super::{
    client::{devide_spaces_from_convos, Client, SpaceFilter, SpaceFilterBuilder},
    room::{Member, Room},
    search::PublicSearchResult,
    RUNTIME,
};

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

// internal API
impl Space {
    pub(crate) async fn setup_handles(&self) -> Vec<EventHandlerHandle> {
        self.room
            .client()
            .add_event_handler_context(self.client.executor().clone());
        trace!(room_id=?self.room.room_id(), "adding handles");
        // FIXME: combine into one handler
        // Tasks
        vec![
            self.room.add_event_handler(
                |ev: SyncTaskListEvent,
                    room: SdkRoom,
                    c: SdkClient,
                    Ctx(executor): Ctx<Executor>| async move {
                    let room_id = room.room_id().to_owned();
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                        if let Err(error) = executor.handle(AnyActerModel::TaskList(t.into())).await {
                            error!(?error, "execution failed");
                        }
                    }
                },
            ),
            self.room.add_event_handler(
                |ev: SyncTaskListUpdateEvent,
                room: SdkRoom,
                c: SdkClient,
                Ctx(executor): Ctx<Executor>| async move {
                    let room_id = room.room_id().to_owned();
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                        if let Err(error) = executor
                            .handle(AnyActerModel::TaskListUpdate(t.into()))
                            .await {
                                error!(?error, "execution failed");

                            }
                    }
                },
            ),
            self.room.add_event_handler(
                |ev: SyncTaskEvent,
                room: SdkRoom,
                c: SdkClient,
                Ctx(executor): Ctx<Executor>| async move {
                    let room_id = room.room_id().to_owned();
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                        if let Err(error) = executor.handle(AnyActerModel::Task(t.into())).await {
                            error!(?error, "execution failed");
                        }
                    }
                },
            ),
            self.room.add_event_handler(
                |ev: SyncTaskUpdateEvent,
                    room: SdkRoom,
                    c: SdkClient,
                    Ctx(executor): Ctx<Executor>| async move {
                    let room_id = room.room_id().to_owned();
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                        if let Err(error) = executor.handle(AnyActerModel::TaskUpdate(t.into())).await {
                            error!(?error, "execution failed");
                        }
                    }
                },
            ),
            // Comments
            self.room.add_event_handler(
                |ev: SyncCommentEvent,
                    room: SdkRoom,
                    c: SdkClient,
                    Ctx(executor): Ctx<Executor>| async move {
                    let room_id = room.room_id().to_owned();
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                        if let Err(error) = executor.handle(AnyActerModel::Comment(t.into())).await {
                            error!(?error, "execution failed");
                        }
                    }
                },
            ),
            self.room.add_event_handler(
                |ev: SyncCommentUpdateEvent,
                room: SdkRoom,
                c: SdkClient,
                Ctx(executor): Ctx<Executor>| async move {
                    let room_id = room.room_id().to_owned();
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                        if let Err(error) = executor
                            .handle(AnyActerModel::CommentUpdate(t.into()))
                            .await  {
                            error!(?error, "execution failed");
                        }
                    }
                },
            ),

            // Attachments
            self.room.add_event_handler(
                |ev: SyncAttachmentEvent,
                    room: SdkRoom,
                    c: SdkClient,
                    Ctx(executor): Ctx<Executor>| async move {
                    let room_id = room.room_id().to_owned();
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                        if let Err(error) = executor.handle(AnyActerModel::Attachment(t.into())).await {
                            error!(?error, "execution failed");
                        }
                    }
                },
            ),
            self.room.add_event_handler(
                |ev: SyncAttachmentUpdateEvent,
                room: SdkRoom,
                c: SdkClient,
                Ctx(executor): Ctx<Executor>| async move {
                    let room_id = room.room_id().to_owned();
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                        if let Err(error) = executor
                            .handle(AnyActerModel::AttachmentUpdate(t.into()))
                            .await  {
                            error!(?error, "execution failed");
                        }
                    }
                },
            ),

            // Pin
            self.room.add_event_handler(
                |ev: SyncPinEvent,
                room: SdkRoom,
                c: SdkClient,
                Ctx(executor): Ctx<Executor>| async move {
                    let room_id = room.room_id().to_owned();
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                        if let Err(error) = executor.handle(AnyActerModel::Pin(t.into())).await {
                            error!(?error, "execution failed");
                        }
                    }
                },
            ),
            self.room.add_event_handler(
                |ev: SyncPinUpdateEvent,
                    room: SdkRoom,
                    c: SdkClient,
                    Ctx(executor): Ctx<Executor>| async move {
                    let room_id = room.room_id().to_owned();
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                        if let Err(error) = executor.handle(AnyActerModel::PinUpdate(t.into())).await {
                            error!(?error, "execution failed");
                        }
                    }
                },
            ),

            // CalendarEvents
            self.room.add_event_handler(
                |ev: SyncCalendarEventEvent,
                room: SdkRoom,
                c: SdkClient,
                Ctx(executor): Ctx<Executor>| async move {
                    let room_id = room.room_id().to_owned();
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                        if let Err(error) = executor
                            .handle(AnyActerModel::CalendarEvent(t.into()))
                            .await  {
                            error!(?error, "execution failed");
                        }
                    }
                },
            ),
            self.room.add_event_handler(
                |ev: SyncCalendarEventUpdateEvent,
                room: SdkRoom,
                c: SdkClient,
                Ctx(executor): Ctx<Executor>| async move {
                    let room_id = room.room_id().to_owned();
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                        if let Err(error) = executor
                            .handle(AnyActerModel::CalendarEventUpdate(t.into()))
                            .await  {
                            error!(?error, "execution failed");
                        }
                    }
                },
            ),

            // NewsEntrys
            self.room.add_event_handler(
                |ev: SyncNewsEntryEvent,
                    room: SdkRoom,
                    c: SdkClient,
                    Ctx(executor): Ctx<Executor>| async move {
                    let room_id = room.room_id().to_owned();
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                        if let Err(error) = executor.handle(AnyActerModel::NewsEntry(t.into())).await {
                            error!(?error, "execution failed");
                        }
                    }
                },
            ),
            self.room.add_event_handler(
            |ev: SyncNewsEntryUpdateEvent,
                room: SdkRoom,
                c: SdkClient,
                Ctx(executor): Ctx<Executor>| async move {
                let room_id = room.room_id().to_owned();
                // FIXME: handle redactions
                if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                    if let Err(error) = executor
                        .handle(AnyActerModel::NewsEntryUpdate(t.into()))
                        .await  {
                            error!(?error, "execution failed");
                        }
                }
            })
        ]
    }

    pub(crate) async fn refresh_history(&self) -> Result<()> {
        let name = self.room.name();
        let room_id = self.room.room_id();
        trace!(name, ?room_id, "refreshing history");
        let client = self.room.client();
        // self.room.sync_members().await.context("Couldn't sync members of room")?;

        let custom_storage_key = format!("{room_id}::history");

        let mut from = if let Ok(h) = self
            .client
            .store()
            .get_raw::<HistoryState>(&custom_storage_key)
            .await
        {
            trace!(name, state=?h.seen, "found history state");
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
            trace!(name, ?msg_options, "fetching messages");
            let Messages {
                end, chunk, state, ..
            } = self.room.messages(msg_options).await?;
            trace!(name, ?chunk, end, "messages received");

            let has_chunks = !chunk.is_empty();

            for msg in chunk {
                let model = match AnyActerModel::from_raw_tlevent(&msg.event) {
                    Ok(model) => model,
                    Err(m) => {
                        if let Ok(state_key) = msg.event.get_field::<String>("state_key") {
                            trace!(state_key, "ignoring state event");
                            // ignore state keys
                        } else {
                            error!(event=?msg.event, "Model didn't parse {:}", m);
                        }
                        continue;
                    }
                };
                // match event {
                //     MessageLikeEvent::Original(o) => {
                trace!(?room_id, user_id=?client.user_id(), ?model, "handling timeline event");
                if let Err(e) = self.client.executor().handle(model).await {
                    error!("Failure handling event: {:}", e);
                }
                //     }
                //     MessageLikeEvent::Redacted(r) => {
                //         trace!(redaction = ?r, "redaction ignored");
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
                trace!(room_id = ?self.room.room_id(), "Done loading");
                break;
            }

            if !has_chunks && state.is_empty() {
                // nothing new to process, we are done catching up
                break;
            }
        }
        trace!(name, "history loaded");
        Ok(())
    }
}

// External API

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

    pub fn subscribe(&self) -> Receiver<()> {
        self.client.subscribe(format!("{}", self.room_id()))
    }

    // for only cli run_marking_space, not api.rsh
    pub async fn is_acter_space(&self) -> bool {
        is_acter_space(&self.inner).await
    }

    pub fn get_room_id(&self) -> OwnedRoomId {
        self.room_id().to_owned()
    }

    pub fn get_room_id_str(&self) -> String {
        self.room_id().to_string()
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

    pub async fn add_child_space(&self, room_id: String) -> Result<String> {
        let room_id = OwnedRoomId::try_from(room_id)?;
        if !self
            .get_my_membership()
            .await?
            .can(crate::MemberPermission::CanLinkSpaces)
        {
            bail!("You don't have permissions to add child-spaces");
        }
        let SdkRoom::Joined(joined) = &self.inner.room else {
            bail!("You can't update a space you aren't part of");
        };
        let room = joined.clone();

        let mut room_child_event = SpaceChildEventContent::new();
        RUNTIME
            .spawn(async move {
                let res_id = room
                    .send_state_event_for_key(&room_id, SpaceChildEventContent::new())
                    .await?;
                Ok(res_id.event_id.to_string())
            })
            .await?
    }

    pub async fn is_child_space_of(&self, room_id: String) -> bool {
        let Ok(room_id) = OwnedRoomId::try_from(room_id) else {
            tracing::warn!("Asked for a not proper room id");
            return false
        };

        let space_relations = match self.space_relations().await {
            Ok(s) => s,
            Err(error) => {
                tracing::error!(?error, room_id=?self.room_id(), "Fetching space relation failed");
                return false;
            }
        };
        if let Some(e) = space_relations.main_parent() {
            return e.room_id() == room_id;
        }
        false
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

pub fn new_space_settings(
    name: String,
    topic: Option<String>,
    avatar_uri: Option<String>,
    parent: Option<String>,
) -> Result<CreateSpaceSettings> {
    let mut builder = CreateSpaceSettingsBuilder::default();
    builder.name(name);
    if let Some(topic) = topic {
        builder.topic(topic);
    }
    if let Some(avatar_uri) = avatar_uri {
        builder.avatar_uri(avatar_uri);
    }
    if let Some(parent) = parent {
        let owned_parent = OwnedRoomId::try_from(parent)?;
        builder.parent(owned_parent);
    }
    Ok(builder.build()?)
}

// External API
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

    pub async fn join_space(
        &self,
        room_id_or_alias: String,
        server_name: Option<String>,
    ) -> Result<Space> {
        let room = self
            .join_room(
                room_id_or_alias,
                server_name.map(|s| vec![s]).unwrap_or_default(),
            )
            .await?;
        Ok(Space {
            client: self.clone(),
            inner: room,
        })
    }
    pub async fn public_spaces(
        &self,
        search_term: Option<String>,
        server: Option<String>,
        since: Option<String>,
    ) -> Result<PublicSearchResult> {
        self.search_public(
            search_term,
            server,
            since,
            Some(ruma::directory::RoomTypeFilter::Space),
        )
        .await
    }

    pub async fn spaces(&self) -> Result<Vec<Space>> {
        let c = self.clone();
        let filter = SpaceFilterBuilder::default().include_left(false).build()?;
        RUNTIME
            .spawn(async move {
                let (spaces, convos) = devide_spaces_from_convos(c, Some(filter)).await;
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
