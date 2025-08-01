pub mod categories;

pub use acter_matrix::spaces::{
    new_app_permissions_builder, AppPermissionsBuilder, CreateSpaceSettings,
    CreateSpaceSettingsBuilder, RelationTargetType, SpaceRelation,
    SpaceRelations as CoreSpaceRelations,
};
use acter_matrix::{
    error::Error, events::AnyActerEvent, models::AnyActerModel,
    statics::default_acter_space_states, store::Store, templates::Engine,
};
use anyhow::{bail, Context, Result};
use futures::stream::StreamExt;
use matrix_sdk::room::{Messages, MessagesOptions};
use matrix_sdk_base::{
    deserialized_responses::SyncOrStrippedState,
    ruma::{
        api::client::state::send_state_event,
        assign,
        events::{
            space::child::SpaceChildEventContent, AnyStateEventContent, MessageLikeEventType,
            StateEventType,
        },
        serde::Raw,
        OwnedRoomAliasId, OwnedRoomId, RoomAliasId, RoomId, RoomOrAliasId, ServerName,
    },
};
use matrix_sdk_ui::timeline::RoomExt;
use serde::{Deserialize, Serialize};
use std::{ops::Deref, sync::Arc};
use tokio::sync::broadcast::Receiver;
use tokio_stream::{wrappers::BroadcastStream, Stream};
use tracing::{error, info, trace, warn};

use crate::{Client, Room, TimelineStream, RUNTIME};

use super::utils::{remap_for_diff, ApiVectorDiff};

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
        Some(self.cmp(other))
    }
}

impl Ord for Space {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        self.room_id().cmp(other.room_id())
    }
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub(crate) struct HistoryState {
    /// The last `end` send from the server
    seen: String,
}

impl HistoryState {
    pub fn new(last_seen: String) -> HistoryState {
        HistoryState { seen: last_seen }
    }
    pub(crate) fn storage_key(room_id: &RoomId) -> String {
        format!("{room_id}::history")
    }

    pub(crate) async fn load(store: &Store, room_id: &RoomId) -> Result<HistoryState> {
        let history = store
            .get_raw::<HistoryState>(&HistoryState::storage_key(room_id))
            .await?;
        trace!(?room_id, seen = history.seen, "Loading history key");
        Ok(history)
    }
    pub(crate) async fn store(store: &Store, room_id: &RoomId, seen: String) -> Result<()> {
        trace!(?room_id, ?seen, "Storing history key");
        Ok(store
            .set_raw(&HistoryState::storage_key(room_id), &HistoryState { seen })
            .await?)
    }
}

// internal API
impl Space {
    pub(crate) fn new(client: Client, inner: Room) -> Self {
        Space { client, inner }
    }

    pub(crate) fn update_room(self, room: Room) -> Self {
        let Space { client, .. } = self;
        Space {
            client,
            inner: room,
        }
    }

    pub(crate) async fn refresh_history(&self) -> Result<()> {
        let name = self.room.name();
        let room_id = self.room.room_id();
        trace!(name, ?room_id, "refreshing history");
        let client = self.room.client();
        // self.room.sync_members().await.context("Unable to sync members of room")?;

        let mut from = if let Ok(h) = HistoryState::load(self.client.store(), room_id).await {
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

        let executor = self.client.executor();

        loop {
            trace!(?room_id, name, ?msg_options, "fetching messages");
            let Messages {
                end, chunk, state, ..
            } = self.room.messages(msg_options).await?;
            trace!(?room_id, name, ?chunk, end, "messages received");

            let has_chunks = !chunk.is_empty();

            for msg in chunk {
                let event = match msg.kind.raw().deserialize_as::<AnyActerEvent>() {
                    Ok(AnyActerEvent::RegularTimelineEvent(event)) => {
                        info!(?event, "Received regular event. Ignoring for now");
                        continue;
                    }
                    Ok(e) => e,
                    Err(error) => {
                        error!(?error, ?room_id, "Not a proper acter event");
                        continue;
                    }
                };

                AnyActerModel::execute(executor, event).await;
            }

            // Todo: Do we want to do something with the states, too?

            if let Some(seen) = end {
                from = Some(seen.clone());
                msg_options = MessagesOptions::forward().from(from.as_deref());
                HistoryState::store(self.client.store(), room_id, seen).await?;
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
    #[cfg(feature = "testing")]
    pub async fn timeline_stream(&self) -> TimelineStream {
        let room = self.inner.clone();
        let timeline = Arc::new(
            self.inner
                .deref()
                .timeline()
                .await
                .expect("Timeline creation doesn’t fail"),
        );
        TimelineStream::new(room, timeline)
    }

    pub async fn create_onboarding_data(&self) -> Result<bool> {
        let mut engine = Engine::with_template(std::include_str!("../templates/onboarding.toml"))?;
        let core = self.client.core.clone();
        let room_id = self.room.room_id().to_string();
        RUNTIME
            .spawn(async move {
                engine.add_user("main".to_owned(), core).await?;
                engine.add_ref("space".to_owned(), "space".to_owned(), room_id)?;

                let mut executer = engine.execute()?;
                while let Some(i) = executer.next().await {
                    i?
                }
                Ok(true)
            })
            .await?
    }

    pub fn subscribe_stream(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.subscribe()).map(|_| true)
    }

    pub fn subscribe(&self) -> Receiver<()> {
        self.client.subscribe(self.room_id())
    }

    // for only cli run_marking_space, not api.rsh
    pub fn get_room_id(&self) -> OwnedRoomId {
        self.room_id().to_owned()
    }

    pub fn get_room_id_str(&self) -> String {
        self.room_id().to_string()
    }

    pub fn is_bookmarked(&self) -> bool {
        self.inner.room.is_favourite()
    }

    pub async fn set_bookmarked(&self, is_bookmarked: bool) -> Result<bool> {
        let room = self.inner.room.clone();
        Ok(RUNTIME
            .spawn(async move {
                room.set_is_favourite(is_bookmarked, None)
                    .await
                    .map(|()| true)
            })
            .await??)
    }

    pub async fn set_acter_space_states(&self) -> Result<bool> {
        if !self.inner.is_joined() {
            bail!("Unable to convert a space you didn’t join");
        }
        let room = self.inner.room.clone();
        let my_id = self.client.user_id()?;
        let client = self.client.deref().clone();
        RUNTIME
            .spawn(async move {
                let room_id = room.room_id().to_owned();
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Unable to find me in room")?;

                let mut requests = Vec::new();

                for state in default_acter_space_states() {
                    let event_type = state
                        .get_field::<StateEventType>("type")?
                        .context("Unable to get state event type")?;
                    let state_key = state.get_field("state_key")?.unwrap_or_default();
                    let body = state
                        .get_field::<Raw<AnyStateEventContent>>("content")?
                        .context("Unable to get state content")?;
                    if !member.can_send_state(event_type.clone()) {
                        bail!(
                            "No permissions to set {event_type} states of this room. Unable to convert"
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
                    client.send(request).await?;
                }

                Ok(true)
            })
            .await?
    }

    pub async fn add_child_room(&self, room_id: String, suggested: bool) -> Result<String> {
        if !self.inner.is_joined() {
            bail!("Unable to update a space you aren’t part of");
        }
        let room_id = RoomId::parse(room_id)?;
        if !self
            .get_my_membership()
            .await?
            .can(crate::MemberPermission::CanLinkSpaces)
        {
            bail!("No permissions to add child to space");
        }
        let room = self.inner.room.clone();
        let my_id = self.client.user_id()?;
        let client = self.client.clone();

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::SpaceChild)
                    .await?;
                if !permitted {
                    bail!("No permissions to change children of this room");
                }
                let Some(Ok(homeserver)) = client.homeserver().host_str().map(ServerName::parse)
                else {
                    return Err(Error::HomeserverMissesHostname)?;
                };
                let response = room
                    .send_state_event_for_key(
                        &room_id,
                        assign!(SpaceChildEventContent::new(vec![homeserver]), { suggested }),
                    )
                    .await?;
                Ok(response.event_id.to_string())
            })
            .await?
    }

    pub async fn remove_child_room(&self, room_id: String, reason: Option<String>) -> Result<bool> {
        if !self.inner.is_joined() {
            bail!("Unable to update a space you aren’t part of");
        }
        let room_id = RoomId::parse(room_id)?;
        if !self
            .get_my_membership()
            .await?
            .can(crate::MemberPermission::CanLinkSpaces)
        {
            bail!("No permissions to remove child from space");
        }
        let room = self.inner.room.clone();
        let my_id = self.client.user_id()?;

        RUNTIME
            .spawn(async move {
                let response = room
                    .get_state_event_static_for_key::<SpaceChildEventContent, OwnedRoomId>(&room_id)
                    .await?;
                let Some(raw_state) = response else {
                    warn!("Room {} is not a child", room_id);
                    return Ok(true);
                };
                let event_id = match raw_state.deserialize()? {
                    SyncOrStrippedState::Stripped(ev) => {
                        bail!("Unable to get event id about stripped event")
                    }
                    SyncOrStrippedState::Sync(ev) => ev.event_id().to_owned(),
                };
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::RoomMessage)
                    .await?;
                if !permitted {
                    bail!("No permissions to send message in this room");
                }
                room.redact(&event_id, reason.as_deref(), None).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn is_child_space_of(&self, room_id: String) -> bool {
        let Ok(room_id) = RoomId::parse(room_id) else {
            warn!("Asked for a not proper room id");
            return false;
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

    // ***_typed fn accepts rust-typed input, not string-based one
    async fn space_typed(&self, room_id: &RoomId) -> Option<Space> {
        self.spaces
            .read()
            .await
            .iter()
            .find(|s| s.room_id() == room_id)
            .cloned()
    }

    // ***_typed fn accepts rust-typed input, not string-based one
    async fn space_by_alias_typed(&self, room_alias: OwnedRoomAliasId) -> Result<Space> {
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
            .cloned();
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
        let either = RoomOrAliasId::parse(&room_id_or_alias)?;
        if either.is_room_id() {
            let room_id = RoomId::parse(either.as_str())?;
            self.space_typed(&room_id)
                .await
                .context(format!("Space {room_id} not found"))
        } else if either.is_room_alias_id() {
            let room_alias = RoomAliasId::parse(either.as_str())?;
            self.space_by_alias_typed(room_alias).await
        } else {
            bail!("{room_id_or_alias} isn’t a valid room id or alias...");
        }
    }
}
