use acter_matrix::referencing::{ExecuteReference, RoomParam};
use anyhow::Result;
use futures::{
    future::join_all,
    pin_mut,
    stream::{Stream, StreamExt},
};
use futures_signals::signal::Mutable;
use imbl::vector::Vector;
use matrix_sdk::room::Room as SdkRoom;
use matrix_sdk_base::{
    ruma::{api::client::sync::sync_events, assign, OwnedRoomId, RoomId},
    RoomState,
};
use matrix_sdk_ui::{
    encryption_sync_service::EncryptionSyncService,
    eyeball_im::{ObservableVector, VectorDiff},
    room_list_service::filters,
    sync_service::{State, SyncService},
    timeline::{RoomExt, Timeline as SdkTimeline, TimelineItem as SdkTimelineItem},
};
use std::{
    cmp::Ordering,
    collections::HashMap,
    fmt,
    ops::Deref,
    sync::{atomic::AtomicBool, Arc},
};
use tokio::{
    sync::{
        broadcast::{channel, Receiver},
        RwLock, RwLockWriteGuard,
    },
    task::JoinHandle,
};
use tokio_stream::wrappers::BroadcastStream;
use tracing::{error, info, trace, warn};

use super::{
    super::{
        timeline::TimelineItem,
        utils::{remap_for_diff, ApiVectorDiff},
        RUNTIME,
    },
    Client, Convo, Room, Space,
};

#[derive(Debug, Clone)]
pub(crate) struct Timeline {
    pub(crate) inner: Arc<SdkTimeline>,
    task: Arc<JoinHandle<()>>,
}

/// Extra room information, like its display name, etc.
#[derive(Debug, Clone)]
pub(crate) struct ExtraRoomInfo {
    /// Content of the raw m.room.name event, if available.
    raw_name: Option<String>,

    /// Calculated display name for the room.
    display_name: Option<String>,

    /// Is the room a DM?
    is_dm: Option<bool>,

    /// Latest message if exists, used in chat room list
    latest_msg: Option<TimelineItem>,
}

impl ExtraRoomInfo {
    pub fn display_name(&self) -> Option<String> {
        self.display_name.clone()
    }

    pub fn latest_msg(&self) -> Option<TimelineItem> {
        self.latest_msg.clone()
    }
}

#[derive(Clone)]
pub struct SyncController {
    /// The sync service used for synchronizing events.
    sync_service: Arc<Mutable<Option<SyncService>>>,

    pub(crate) rooms: Arc<RwLock<ObservableVector<SdkRoom>>>,

    /// Room list service rooms known to the app.
    pub(crate) ui_rooms: Arc<RwLock<HashMap<OwnedRoomId, SdkRoom>>>,

    /// Timelines data structures for each room.
    pub(crate) timelines: Arc<RwLock<HashMap<OwnedRoomId, Timeline>>>,

    /// Extra information about rooms.
    pub(crate) room_infos: Arc<RwLock<HashMap<OwnedRoomId, ExtraRoomInfo>>>,

    /// Task listening to room list service changes, and spawning timelines.
    main_listener: Arc<Mutable<Option<JoinHandle<()>>>>,
}

impl fmt::Debug for SyncController {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        f.debug_struct("SyncController").finish_non_exhaustive()
    }
}

impl Default for SyncController {
    fn default() -> Self {
        SyncController::new()
    }
}

impl SyncController {
    pub fn new() -> Self {
        SyncController {
            sync_service: Default::default(),
            rooms: Default::default(),
            ui_rooms: Default::default(),
            timelines: Default::default(),
            room_infos: Default::default(),
            main_listener: Default::default(),
        }
    }

    pub async fn cancel(&self) -> Result<bool> {
        let mut timelines = self.timelines.clone();
        let mut main_listener = self.main_listener.clone();
        let mut sync_service = self.sync_service.clone();
        RUNTIME
            .spawn(async move {
                for (room_id, timeline) in timelines.read().await.iter() {
                    info!("abort room timeline listener: {}", room_id);
                    timeline.task.abort();
                }
                timelines.write().await.clear();

                if let Some(main_listener) = main_listener.replace(None) {
                    main_listener.abort();
                }

                if let Some(sync_service) = sync_service.replace(None) {
                    sync_service.stop().await;
                }

                Ok(true)
            })
            .await?
    }
}

// external API
impl Client {
    pub(super) async fn start_sliding_sync(&self) -> Result<()> {
        info!("starting sliding sync");

        let me = self.clone();
        let client = self.core.client().clone();
        let sync_service = SyncService::builder(client).build().await?;
        let room_list = sync_service.room_list_service().all_rooms().await?;

        let rooms = self.sync_controller.rooms.clone();
        let room_infos = self.sync_controller.room_infos.clone();
        let ui_rooms = self.sync_controller.ui_rooms.clone();
        let timelines = self.sync_controller.timelines.clone();

        let main_listener = tokio::spawn(async move {
            let (room_stream, entries_controller) = room_list.entries_with_dynamic_adapters(50_000);
            entries_controller.set_filter(Box::new(filters::new_filter_non_left()));
            pin_mut!(room_stream);

            while let Some(diffs) = room_stream.next().await {
                let all_rooms = {
                    // Apply the diffs to the list of room entries.
                    let mut rooms = rooms.write().await;

                    for diff in diffs.clone() {
                        match diff {
                            VectorDiff::Append { values } => {
                                info!("rooms append");
                                rooms.append(values);
                            }
                            VectorDiff::Clear => {
                                info!("rooms clear");
                                rooms.clear();
                            }
                            VectorDiff::Insert { index, value } => {
                                info!("rooms insert");
                                rooms.insert(index, value);
                            }
                            VectorDiff::PopBack => {
                                info!("rooms pop back");
                                rooms.pop_back();
                            }
                            VectorDiff::PopFront => {
                                info!("rooms pop front");
                                rooms.pop_front();
                            }
                            VectorDiff::PushBack { value } => {
                                info!("rooms push back");
                                rooms.push_back(value);
                            }
                            VectorDiff::PushFront { value } => {
                                info!("rooms push front");
                                rooms.push_front(value);
                            }
                            VectorDiff::Remove { index } => {
                                info!("rooms remove");
                                rooms.remove(index);
                            }
                            VectorDiff::Reset { values } => {
                                info!("rooms reset");
                                rooms.clear();
                                rooms.append(values);
                            }
                            VectorDiff::Set { index, value } => {
                                info!("rooms set");
                                rooms.set(index, value);
                            }
                            VectorDiff::Truncate { length } => {
                                info!("rooms truncate");
                                rooms.truncate(length);
                            }
                        }
                    }

                    // Collect rooms early to release the room entries list lock.
                    (*rooms).clone()
                };

                // Clone the previous set of ui rooms to avoid keeping the ui_rooms lock (which
                // we couldn't do below, because it's a sync lock, and has to be
                // sync b/o rendering; and we'd have to cross await points
                // below).
                let prev_ui_rooms = ui_rooms.read().await;

                let mut new_ui_rooms = HashMap::new();
                let mut new_timelines = vec![];

                // Update all the room info for all rooms.
                for room in all_rooms.iter() {
                    let raw_name = room.name();
                    let display_name = room.cached_display_name().map(|d| d.to_string());
                    let is_dm = room
                        .is_direct()
                        .await
                        .map_err(|err| {
                            warn!("couldn't figure whether a room is a DM or not: {err}");
                        })
                        .ok();
                    room_infos.write().await.insert(
                        room.room_id().to_owned(),
                        ExtraRoomInfo {
                            raw_name,
                            display_name,
                            is_dm,
                            latest_msg: None,
                        },
                    );
                }

                // Initialize all the new rooms.
                for ui_room in all_rooms
                    .iter()
                    .filter(|room| !prev_ui_rooms.contains_key(room.room_id()))
                {
                    let mut found_latest_msg = me.load_latest_message(ui_room.room_id()).await;

                    // Save the timeline in the cache.
                    let sdk_timeline = match ui_room.timeline_builder().build().await {
                        Ok(tl) => tl,
                        Err(err) => {
                            error!("error when building timeline: {err}");
                            continue;
                        }
                    };
                    let (items, stream) = sdk_timeline.subscribe().await;
                    // Update the latest message if there is new msg in the first page
                    for item in items.into_iter().rev() {
                        if me.save_latest_message(ui_room.room_id(), item).await {
                            found_latest_msg = true;
                            break;
                        }
                    }

                    // Spawn a timeline task that will track the latest message.
                    // Will listen to msg history in TimelineStream::messages_stream().
                    let room_id = ui_room.room_id().to_owned();
                    let this = me.clone();
                    let timeline_task = tokio::spawn(async move {
                        pin_mut!(stream);
                        while let Some(diffs) = stream.next().await {
                            // Update the latest message of room.
                            for diff in diffs.clone() {
                                match diff {
                                    VectorDiff::Append { values } => {
                                        for value in values.into_iter().rev() {
                                            if this.save_latest_message(&room_id, value).await {
                                                break;
                                            }
                                        }
                                    }
                                    VectorDiff::Clear => {}
                                    VectorDiff::Insert { index, value } => {
                                        this.save_latest_message(&room_id, value).await;
                                    }
                                    VectorDiff::PopBack => {}
                                    VectorDiff::PopFront => {}
                                    VectorDiff::PushBack { value } => {
                                        this.save_latest_message(&room_id, value).await;
                                    }
                                    VectorDiff::PushFront { value } => {
                                        this.save_latest_message(&room_id, value).await;
                                    }
                                    VectorDiff::Remove { index } => {}
                                    VectorDiff::Reset { values } => {
                                        for value in values.into_iter().rev() {
                                            if this.save_latest_message(&room_id, value).await {
                                                break;
                                            }
                                        }
                                    }
                                    VectorDiff::Set { index, value } => {
                                        this.save_latest_message(&room_id, value).await;
                                    }
                                    VectorDiff::Truncate { length } => {}
                                }
                            }
                        }
                    });

                    // Paginate backwards, if the latest message was not found in the first page or cache
                    {
                        let ri = room_infos.read().await;
                        if let Some(room_info) = ri.get(ui_room.room_id()) {
                            if room_info.latest_msg.is_none() && !found_latest_msg {
                                // paginate_backwards passes execution flow to timeline_task
                                if let Err(err) = sdk_timeline.paginate_backwards(10).await {
                                    error!(?err, room_id=?ui_room.room_id(), "backpagination failed");
                                }
                            }
                        } else {
                            error!("Empty room info");
                            continue;
                        }
                    }

                    new_timelines.push((
                        ui_room.room_id().to_owned(),
                        Timeline {
                            inner: Arc::new(sdk_timeline),
                            task: Arc::new(timeline_task),
                        },
                    ));

                    // Save the room list service room in the cache.
                    new_ui_rooms.insert(ui_room.room_id().to_owned(), ui_room.clone());
                }

                drop(prev_ui_rooms); // release ui_rooms read lock prior to ui_rooms write lock
                ui_rooms.write().await.extend(new_ui_rooms);
                timelines.write().await.extend(new_timelines);

                me.update_rooms(&all_rooms.iter().cloned().collect()).await;

                trace!("ready for the next round");
            }
            trace!("sync stopped");
        });

        // This will sync (with encryption) until an error happens or the program is stopped.
        sync_service.start().await;

        let mut sync_service_cl = self.sync_controller.sync_service.lock_mut();
        *sync_service_cl = Some(sync_service);

        let mut main_listener_cl = self.sync_controller.main_listener.lock_mut();
        *main_listener_cl = Some(main_listener);

        Ok(())
    }

    async fn update_rooms(&self, changed_rooms: &Vector<SdkRoom>) {
        let update_keys = {
            let client = self.core.client();
            let mut updated: Vec<OwnedRoomId> = vec![];

            let mut convos = self.convos.write().await;
            let mut spaces = self.spaces.write().await;

            for room in changed_rooms {
                let r_id = room.room_id().to_owned();
                if !matches!(room.state(), RoomState::Joined) {
                    trace!(?r_id, "room gone");
                    // remove rooms we aren’t in (anymore)
                    remove_from(&mut spaces, &r_id);
                    remove_from_convo(&mut convos, &r_id);
                    if let Err(error) = self.executor().clear_room(&r_id).await {
                        error!(?error, "Error removing space {r_id}");
                    }
                    updated.push(r_id);
                    continue;
                }

                let inner = Room::new(
                    self.core.clone(),
                    room.clone(),
                    self.sync_controller.clone(),
                );

                if inner.is_space() {
                    if let Some(space_idx) = spaces.iter().position(|s| s.room_id() == r_id) {
                        let space = spaces.remove(space_idx).update_room(inner);
                        spaces.insert(space_idx, space);
                    } else {
                        spaces.push_front(Space::new(self.clone(), inner))
                    }
                    // also clear from convos if it was in there...
                    remove_from_convo(&mut convos, &r_id);
                    updated.push(r_id);
                } else {
                    if let Some(convo_idx) = convos.iter().position(|s| s.room_id() == r_id) {
                        let convo = convos.remove(convo_idx).update_room(inner);
                        // convo.update_latest_msg_ts().await;
                        let mut room_infos = self.sync_controller.room_infos.write().await;
                        insert_to_convo(&mut convos, convo, &mut room_infos);
                    } else {
                        let mut room_infos = self.sync_controller.room_infos.write().await;
                        insert_to_convo(
                            &mut convos,
                            Convo::new(self.clone(), inner),
                            &mut room_infos,
                        );
                    }
                    // also clear from convos if it was in there...
                    remove_from(&mut spaces, &r_id);
                    updated.push(r_id);
                }
            }

            updated
        };
        info!("refreshed room: {:?}", &update_keys);
        self.executor().notify(
            update_keys
                .into_iter()
                .map(ExecuteReference::Room)
                .collect(),
        );
    }

    async fn load_latest_message(&self, room_id: &RoomId) -> bool {
        let key = latest_message_storage_key(room_id).as_storage_key();
        let latest_message = self.store().get_raw::<TimelineItem>(&key).await.ok();
        if latest_message.is_none() {
            return false;
        }
        let mut room_infos = self.sync_controller.room_infos.write().await;
        if let Some(room_info) = (*room_infos).get_mut(room_id) {
            room_info.latest_msg = latest_message;
        }
        true
    }

    async fn save_latest_message(&self, room_id: &RoomId, item: Arc<SdkTimelineItem>) -> bool {
        if item.as_event().is_none() {
            return false;
        }
        let Ok(my_id) = self.user_id() else {
            return false;
        };
        let new_msg = TimelineItem::from((item, my_id));
        let mut room_infos = self.sync_controller.room_infos.write().await;
        let Some(room_info) = room_infos.get_mut(room_id) else {
            return false;
        };
        if let Some(prev_msg) = &room_info.latest_msg {
            if prev_msg.event_id() == new_msg.event_id()
                && prev_msg.event_type() == new_msg.event_type()
            {
                trace!("Nothing to update, room message stayed the same");
                return false;
            }
            // if prev_ts was None, replace prev msg with new msg unconditionally
            if let Some(prev_ts) = prev_msg.origin_server_ts() {
                match new_msg.origin_server_ts() {
                    Some(new_ts) => {
                        if new_ts <= prev_ts {
                            // new msg is not the latest
                            return false;
                        }
                    }
                    None => {
                        error!("new latest message should have timestamp");
                        return false;
                    }
                }
            }
        }

        let key = latest_message_storage_key(room_id);
        self.store().set_raw(&key.as_storage_key(), &new_msg).await;
        info!("******************** changed latest msg: {:?}", &key);
        self.executor().notify(vec![key]);

        trace!(?room_id, "Setting latest message");
        room_info.latest_msg = Some(new_msg);

        true
    }

    pub(crate) async fn load_from_cache(&self) {
        let (s, c) = self.get_spaces_and_chats();

        // FIXME for a lack of a better system, we just sort by room-id
        let mut spaces = s
            .into_iter()
            .map(|r| Space::new(self.clone(), r))
            .collect::<Vector<Space>>();
        {
            let room_infos = self.sync_controller.room_infos.read().await;
            spaces.sort_by(|a, b| {
                let a_ts = room_infos
                    .get(a.room_id())
                    .and_then(|info| info.latest_msg.as_ref().and_then(|x| x.origin_server_ts()));
                let b_ts = room_infos
                    .get(b.room_id())
                    .and_then(|info| info.latest_msg.as_ref().and_then(|x| x.origin_server_ts()));
                if a_ts.is_none() == b_ts.is_none() {
                    return Ordering::Equal;
                }
                if a_ts.is_some() == b_ts.is_none() {
                    return Ordering::Less;
                }
                if a_ts.is_none() == b_ts.is_some() {
                    return Ordering::Greater;
                }
                a_ts.unwrap().cmp(&b_ts.unwrap())
            });
            self.spaces
                .write()
                .await
                .append(spaces.iter().cloned().collect());
        }

        let mut convos = c
            .into_iter()
            .map(|r| Convo::new(self.clone(), r))
            .collect::<Vector<Convo>>();
        {
            let room_infos = self.sync_controller.room_infos.read().await;
            convos.sort_by(|a, b| {
                let a_ts = room_infos
                    .get(a.room_id())
                    .and_then(|info| info.latest_msg.as_ref().and_then(|x| x.origin_server_ts()));
                let b_ts = room_infos
                    .get(b.room_id())
                    .and_then(|info| info.latest_msg.as_ref().and_then(|x| x.origin_server_ts()));
                if a_ts.is_none() == b_ts.is_none() {
                    return Ordering::Equal;
                }
                if a_ts.is_some() == b_ts.is_none() {
                    return Ordering::Less;
                }
                if a_ts.is_none() == b_ts.is_some() {
                    return Ordering::Greater;
                }
                a_ts.unwrap().cmp(&b_ts.unwrap())
            });
            self.convos
                .write()
                .await
                .append(convos.iter().cloned().collect());
        }
    }
}

// helper methods for managing spaces and convos
fn remove_from(target: &mut RwLockWriteGuard<ObservableVector<Space>>, r_id: &OwnedRoomId) {
    if let Some(idx) = target.iter().position(|s| s.room_id() == r_id) {
        target.remove(idx);
    }
}

fn remove_from_convo(target: &mut RwLockWriteGuard<ObservableVector<Convo>>, r_id: &OwnedRoomId) {
    if let Some(idx) = target.iter().position(|s| s.room_id() == r_id) {
        target.remove(idx);
    }
}

// we expect convo to always stay sorted.
fn insert_to_convo(
    target: &mut RwLockWriteGuard<ObservableVector<Convo>>,
    convo: Convo,
    room_infos: &mut RwLockWriteGuard<HashMap<OwnedRoomId, ExtraRoomInfo>>,
) {
    if let Some(msg_ts) = room_infos
        .get(convo.deref().room_id())
        .and_then(|info| info.latest_msg.as_ref().and_then(|x| x.origin_server_ts()))
    {
        let result = target.iter().position(|convo| {
            let origin_server_ts = room_infos
                .get(convo.deref().room_id())
                .and_then(|info| info.latest_msg.as_ref().and_then(|x| x.origin_server_ts()));
            match origin_server_ts {
                Some(ts) => ts < msg_ts,
                None => false,
            }
        });
        if let Some(idx) = result {
            target.insert(idx, convo);
            return;
        }
    }

    // fallback: push at the end.
    target.push_back(convo);
}

fn latest_message_storage_key(room_id: &RoomId) -> ExecuteReference {
    ExecuteReference::RoomParam(room_id.to_owned(), RoomParam::LatestMessage)
}
