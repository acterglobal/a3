pub use acter_core::spaces::{
    CreateSpaceSettings, CreateSpaceSettingsBuilder, RelationTargetType, SpaceRelation,
    SpaceRelations as CoreSpaceRelations,
};
use acter_core::{
    error::Error,
    events::{
        attachments::{SyncAttachmentEvent, SyncAttachmentUpdateEvent},
        calendar::{SyncCalendarEventEvent, SyncCalendarEventUpdateEvent},
        comments::{SyncCommentEvent, SyncCommentUpdateEvent},
        news::{SyncNewsEntryEvent, SyncNewsEntryUpdateEvent},
        pins::{SyncPinEvent, SyncPinUpdateEvent},
        rsvp::SyncRsvpEvent,
        tasks::{SyncTaskEvent, SyncTaskListEvent, SyncTaskListUpdateEvent, SyncTaskUpdateEvent},
    },
    executor::Executor,
    models::AnyActerModel,
    statics::default_acter_space_states,
    templates::Engine,
};
use anyhow::{bail, Context, Result};
use futures::stream::StreamExt;
use matrix_sdk::{
    deserialized_responses::SyncOrStrippedState,
    event_handler::{Ctx, EventHandlerHandle},
    media::{MediaFormat, MediaRequest},
    room::{Messages, MessagesOptions, Room as SdkRoom},
    ruma::{api::client::state::send_state_event, assign},
    RoomState,
};
use ruma_common::{
    directory::RoomTypeFilter, room::RoomType, serde::Raw, space::SpaceRoomJoinRule, OwnedMxcUri,
    OwnedRoomAliasId, OwnedRoomId, OwnedRoomOrAliasId,
};
use ruma_events::{
    room::MediaSource, space::child::SpaceChildEventContent, AnyStateEventContent,
    MessageLikeEvent, StateEventType,
};
use serde::{Deserialize, Serialize};
use std::ops::Deref;
use tokio::sync::broadcast::Receiver;
use tokio_stream::{wrappers::BroadcastStream, Stream};
use tracing::{error, trace, warn};

use super::{
    client::Client,
    common::OptionBuffer,
    room::Room,
    search::PublicSearchResult,
    utils::{remap_for_diff, ApiVectorDiff},
    RUNTIME,
};

#[derive(Debug, Clone)]
pub struct Space {
    pub client: Client,
    pub(crate) inner: Room,
}

impl PartialEq for Space {
    fn eq(&self, other: &Self) -> bool {
        self.inner.room_id() == other.inner.room_id()
    }
}

impl Eq for Space {}

impl PartialOrd for Space {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        self.room_id().partial_cmp(other.room_id())
    }
}

impl Ord for Space {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        self.room_id().cmp(other.room_id())
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
struct HistoryState {
    /// The last `end` send from the server
    seen: String,
}

// internal API
impl Space {
    pub(crate) fn update_room(self, room: Room) -> Self {
        let Space { client, .. } = self;
        Space {
            client,
            inner: room,
        }
    }
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
                 Ctx(executor): Ctx<Executor>| async move {
                    let room_id = room.room_id().to_owned();
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                        if let Err(error) = executor
                            .handle(AnyActerModel::TaskListUpdate(t.into()))
                            .await
                        {
                            error!(?error, "execution failed");
                        }
                    }
                },
            ),
            self.room.add_event_handler(
                |ev: SyncTaskEvent,
                 room: SdkRoom,
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
                 Ctx(executor): Ctx<Executor>| async move {
                    let room_id = room.room_id().to_owned();
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                        if let Err(error) = executor
                            .handle(AnyActerModel::CommentUpdate(t.into()))
                            .await
                        {
                            error!(?error, "execution failed");
                        }
                    }
                },
            ),

            // Attachments
            self.room.add_event_handler(
                |ev: SyncAttachmentEvent,
                 room: SdkRoom,
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
                 Ctx(executor): Ctx<Executor>| async move {
                    let room_id = room.room_id().to_owned();
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                        if let Err(error) = executor
                            .handle(AnyActerModel::AttachmentUpdate(t.into()))
                            .await
                        {
                            error!(?error, "execution failed");
                        }
                    }
                },
            ),

            // Pin
            self.room.add_event_handler(
                |ev: SyncPinEvent,
                 room: SdkRoom,
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
                 Ctx(executor): Ctx<Executor>| async move {
                    let room_id = room.room_id().to_owned();
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                        if let Err(error) = executor
                            .handle(AnyActerModel::CalendarEvent(t.into()))
                            .await
                        {
                            error!(?error, "execution failed");
                        }
                    }
                },
            ),
            self.room.add_event_handler(
                |ev: SyncCalendarEventUpdateEvent,
                 room: SdkRoom,
                 Ctx(executor): Ctx<Executor>| async move {
                    let room_id = room.room_id().to_owned();
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                        if let Err(error) = executor
                            .handle(AnyActerModel::CalendarEventUpdate(t.into()))
                            .await
                        {
                            error!(?error, "execution failed");
                        }
                    }
                },
            ),

            // RSVPs
            self.room.add_event_handler(
                |ev: SyncRsvpEvent,
                 room: SdkRoom,
                 Ctx(executor): Ctx<Executor>| async move {
                    let room_id = room.room_id().to_owned();
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                        if let Err(error) = executor
                            .handle(AnyActerModel::Rsvp(t.into()))
                            .await
                        {
                            error!(?error, "execution failed");
                        }
                    }
                },
            ),

            // NewsEntrys
            self.room.add_event_handler(
                |ev: SyncNewsEntryEvent,
                 room: SdkRoom,
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
                 Ctx(executor): Ctx<Executor>| async move {
                    let room_id = room.room_id().to_owned();
                    // FIXME: handle redactions
                    if let MessageLikeEvent::Original(t) = ev.into_full_event(room_id) {
                        if let Err(error) = executor
                            .handle(AnyActerModel::NewsEntryUpdate(t.into()))
                            .await
                        {
                            error!(?error, "execution failed");
                        }
                    }
                },
            )
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
                match AnyActerModel::try_from(&msg.event) {
                    Ok(model) => {
                        trace!(?room_id, user_id=?client.user_id(), ?model, "handling timeline event");
                        if let Err(e) = self.client.executor().handle(model).await {
                            error!("Failure handling event: {:}", e);
                        }
                    }
                    Err(Error::ModelRedacted {
                        model_type,
                        meta,
                        reason,
                    }) => {
                        trace!(?room_id, user_id=?client.user_id(), model_type, ?meta.event_id, "redacted event");
                        if let Err(e) = self
                            .client
                            .executor()
                            .redact(model_type, meta, reason)
                            .await
                        {
                            error!("Failure redacting {:}", e);
                        }
                    }
                    Err(Error::UnknownModel(inner)) => {
                        trace!(?room_id, user_id=?client.user_id(), ?inner, "ignoring event");
                    }
                    Err(m) => {
                        if let Ok(state_key) = msg.event.get_field::<String>("state_key") {
                            trace!(state_key=?state_key, "ignoring state event");
                            // ignore state keys
                        } else {
                            error!(event=?msg.event, "Model didn't parse {:}", m);
                        }
                    }
                };
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

    pub fn subscribe_stream(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.subscribe()).map(|_| true)
    }

    pub fn subscribe(&self) -> Receiver<()> {
        self.client.subscribe(format!("{}", self.room_id()))
    }

    // for only cli run_marking_space, not api.rsh
    pub fn get_room_id(&self) -> OwnedRoomId {
        self.room_id().to_owned()
    }

    pub fn get_room_id_str(&self) -> String {
        self.room_id().to_string()
    }

    pub async fn set_acter_space_states(&self) -> Result<bool> {
        if !self.inner.is_joined() {
            bail!("You can't convert a space you didn't join");
        }
        let room = self.inner.room.clone();
        RUNTIME
            .spawn(async move {
                let client = room.client();
                let my_id = client.user_id().context("User not found")?.to_owned();
                let room_id = room.room_id().to_owned();
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;

                let mut requests = Vec::new();

                for state in default_acter_space_states() {
                    println!("{:?}", state);
                    let event_type: StateEventType = state.get_field("type")?.context("given")?;
                    let state_key = state.get_field("state_key")?.unwrap_or_default();
                    let body = state
                        .get_field::<Raw<AnyStateEventContent>>("content")?
                        .context("body is given")?;
                    if !member.can_send_state(event_type.clone()) {
                        bail!(
                            "No permission to set {event_type} states of this room. Can't convert"
                        );
                    }

                    requests.push(send_state_event::v3::Request::new_raw(
                        room_id.clone(),
                        event_type,
                        state_key,
                        body,
                    ));
                }

                for request in requests {
                    client.send(request, None).await?;
                }

                Ok(true)
            })
            .await?
    }

    pub async fn add_child_room(&self, room_id: String) -> Result<String> {
        if !self.inner.is_joined() {
            bail!("You can't update a space you aren't part of");
        }
        let room_id = OwnedRoomId::try_from(room_id)?;
        if !self
            .get_my_membership()
            .await?
            .can(crate::MemberPermission::CanLinkSpaces)
        {
            bail!("You don't have permissions to add child to space");
        }
        let room = self.inner.room.clone();
        let client = self.client.clone();

        RUNTIME
            .spawn(async move {
                let Some(Ok(homeserver)) = client.homeserver().host_str().map(|h| h.try_into()) else {
                    return Err(Error::HomeserverMissesHostname)?;
                };
                let response = room
                    .send_state_event_for_key(
                        &room_id,
                        SpaceChildEventContent::new(vec![homeserver]),
                    )
                    .await?;
                Ok(response.event_id.to_string())
            })
            .await?
    }

    pub async fn remove_child_room(&self, room_id: String, reason: Option<String>) -> Result<bool> {
        if !self.inner.is_joined() {
            bail!("You can't update a space you aren't part of");
        }
        let room_id = OwnedRoomId::try_from(room_id)?;
        if !self
            .get_my_membership()
            .await?
            .can(crate::MemberPermission::CanLinkSpaces)
        {
            bail!("You don't have permissions to remove child from space");
        }
        let room = self.inner.room.clone();

        RUNTIME
            .spawn(async move {
                let response = room
                    .get_state_event_static_for_key::<SpaceChildEventContent, OwnedRoomId>(&room_id)
                    .await?;
                let Some(raw_state) = response else {
                    warn!("Room {} is not a child", room_id);
                    return Ok(false);
                };
                let Ok(state) = raw_state.deserialize() else {
                    bail!("Invalid space child event")
                };
                let event_id = match state {
                    SyncOrStrippedState::Stripped(ev) => {
                        bail!("Couldn't get event id about stripped event")
                    }
                    SyncOrStrippedState::Sync(ev) => ev.event_id().to_owned(),
                };
                room.redact(&event_id, reason.as_deref(), None).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn is_child_space_of(&self, room_id: String) -> bool {
        let Ok(room_id) = OwnedRoomId::try_from(room_id) else {
            warn!("Asked for a not proper room id");
            return false
        };

        let space_relations = match self.space_relations().await {
            Ok(s) => s,
            Err(error) => {
                error!(?error, room_id=?self.room_id(), "Fetching space relation failed");
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

pub fn new_space_settings_builder() -> CreateSpaceSettingsBuilder {
    CreateSpaceSettingsBuilder::default()
}

pub type SpaceDiff = ApiVectorDiff<Space>;

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
        self.search_public(search_term, server, since, Some(RoomTypeFilter::Space))
            .await
    }

    pub async fn spaces(&self) -> Result<Vec<Space>> {
        Ok(self.spaces.read().await.clone().into_iter().collect())
    }

    pub fn spaces_stream(&self) -> impl Stream<Item = SpaceDiff> {
        let spaces = self.spaces.clone();
        async_stream::stream! {
            let (current_items, stream) = {
                let locked = spaces.read().await;
                (
                    SpaceDiff::current_items(locked.clone().into_iter().collect()),
                    locked.subscribe(),
                )
            };
            let mut remap = stream.into_stream().map(move |diff| remap_for_diff(diff, |x| x));
            yield current_items;

            while let Some(d) = remap.next().await {
                yield d
            }
        }
    }

    pub async fn space_typed(&self, room_id: &OwnedRoomId) -> Option<Space> {
        self.spaces
            .read()
            .await
            .iter()
            .find(|s| s.room_id() == room_id)
            .map(Clone::clone)
    }

    pub async fn space_by_alias_typed(&self, room_alias: OwnedRoomAliasId) -> Result<Space> {
        let space = self
            .spaces
            .read()
            .await
            .iter()
            .find(|s| {
                if let Some(con_alias) = s.canonical_alias() {
                    if con_alias == room_alias {
                        return true;
                    }
                }
                for alt_alias in s.alt_aliases() {
                    if alt_alias == room_alias {
                        return true;
                    }
                }
                false
            })
            .map(Clone::clone);
        match space {
            Some(space) => Ok(space),
            None => {
                let room_id = self.resolve_room_alias(room_alias.clone()).await?;
                self.space_typed(&room_id).await.context(format!(
                    "Space with alias {room_alias} ({room_id}) not found"
                ))
            }
        }
    }

    pub async fn space(&self, room_id_or_alias: String) -> Result<Space> {
        let either = OwnedRoomOrAliasId::try_from(room_id_or_alias.as_str())?;
        if either.is_room_id() {
            let room_id = OwnedRoomId::try_from(either.as_str())?;
            self.space_typed(&room_id)
                .await
                .context(format!("Space {room_id} not found"))
        } else if either.is_room_alias_id() {
            let room_alias = OwnedRoomAliasId::try_from(either.as_str())?;
            self.space_by_alias_typed(room_alias).await
        } else {
            bail!("{room_id_or_alias} isn't a valid room id or alias...");
        }
    }
}
