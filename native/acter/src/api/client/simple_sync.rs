use anyhow::Result;
use eyeball_im::{ObservableVector, VectorDiff};
use futures::{
    pin_mut,
    stream::{Stream, StreamExt},
};
use futures_signals::signal::Mutable;
use imbl::vector::Vector;
use matrix_sdk::RumaApiError;
use matrix_sdk_base::{
    ruma::{api::client::sync::sync_events, assign, OwnedRoomId},
    RoomState,
};
use matrix_sdk_ui::{
    encryption_sync_service::EncryptionSyncService,
    room_list_service,
    sync_service::{State, SyncService},
    timeline::{Timeline as SdkTimeline, TimelineItem},
};
use std::{
    collections::HashMap,
    ops::Deref,
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc, Mutex,
    },
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
        message::RoomMessage,
        spaces::SpaceDiff,
        utils::{remap_for_diff, ApiVectorDiff},
        RUNTIME,
    },
    simple_convo::SimpleConvo,
    Client, Room, Space,
};

struct Timeline {
    inner: Arc<SdkTimeline>,
    items: Arc<Mutex<Vector<Arc<TimelineItem>>>>,
    task: JoinHandle<()>,
}

/// Extra room information, like its display name, etc.
#[derive(Debug, Clone)]
struct ExtraRoomInfo {
    /// Content of the raw m.room.name event, if available.
    raw_name: Option<String>,

    /// Calculated display name for the room.
    display_name: Option<String>,

    /// Is the room a DM?
    is_dm: Option<bool>,

    /// Latest message if exists, used in chat room list
    latest_msg: Option<RoomMessage>,
}

#[derive(Clone)]
pub struct SyncController {
    client: Client,

    /// The sync service used for synchronizing events.
    sync_service: Arc<SyncService>,

    rooms: Arc<RwLock<ObservableVector<room_list_service::Room>>>,

    /// Room list service rooms known to the app.
    ui_rooms: Arc<Mutex<HashMap<OwnedRoomId, room_list_service::Room>>>,

    /// Timelines data structures for each room.
    timelines: Arc<Mutex<HashMap<OwnedRoomId, Timeline>>>,

    /// Extra information about rooms.
    room_infos: Arc<Mutex<HashMap<OwnedRoomId, ExtraRoomInfo>>>,

    /// Task listening to room list service changes, and spawning timelines.
    main_listener: Arc<JoinHandle<()>>,

    first_sync_task: Mutable<Option<JoinHandle<Result<()>>>>,

    /// Whether or not sync occurred once at least
    first_synced_rx: Arc<Receiver<bool>>,
}

impl SyncController {
    pub fn cancel(&self) {
        self.main_listener.abort();
    }

    pub fn first_synced_rx(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.first_synced_rx.resubscribe()).map(|o| o.unwrap_or_default())
    }

    pub fn spaces_stream(&self) -> impl Stream<Item = SpaceDiff> {
        let rooms = self.rooms.clone();
        let client = self.client.clone();
        async_stream::stream! {
            let (current_items, stream) = {
                let locked = rooms.read().await;
                let values: Vec<Space> = locked
                    .iter()
                    .filter(|room| room.is_space())
                    .map(|room| Room::new(client.core.clone(), room.inner_room().clone()))
                    .map(|inner| Space::new(client.clone(), inner))
                    .collect();
                (
                    SpaceDiff::current_items(values),
                    locked.subscribe(),
                )
            };
            let mut remap = stream.into_stream().map(move |diff| remap_for_diff(
                diff,
                |x| {
                    let inner = Room::new(client.core.clone(), x.inner_room().clone());
                    Space::new(client.clone(), inner)
                },
            ));
            yield current_items;

            while let Some(d) = remap.next().await {
                yield d
            }
        }
    }
}

// external API
impl Client {
    pub async fn start_simple_sync(&self) -> Result<SyncController> {
        info!("starting simplified sync");

        let me = self.clone();
        let client = self.core.client().clone();
        let user_id = client
            .clone()
            .user_id()
            .expect("User must be logged in")
            .to_owned();

        RUNTIME
            .spawn(async move {
                let config = assign!(sync_events::v5::request::AccountData::default(), {
                    enabled: Some(true),
                });
                let account_sync = client
                    .clone()
                    .sliding_sync("account-data")?
                    .with_account_data_extension(config)
                    .build()
                    .await?;
                let account_listener = tokio::spawn(async move {
                    let stream = account_sync.sync();
                    pin_mut!(stream);
                    while let Some(result) = stream.next().await {
                        info!("received account sync callback");

                        let response = match result {
                            Ok(response) => response,
                            Err(err) => {
                                if let Some(RumaApiError::ClientApi(e)) = err.as_ruma_api_error() {
                                    error!(?e, "Client error");
                                    // sync_error_arc.send(e.into());
                                    return;
                                }
                                error!(?err, "Other error, continuing");
                                continue;
                            }
                        };
                    }
                });

                let sync_service = Arc::new(SyncService::builder(client.clone()).build().await?);
                let room_list = sync_service.room_list_service().all_rooms().await?;

                let (first_synced_tx, first_synced_rx) = channel::<bool>(1);
                let first_synced_arc = Arc::new(first_synced_tx);

                let initial = Arc::new(AtomicBool::from(true));

                let rooms = Arc::new(RwLock::new(
                    ObservableVector::<room_list_service::Room>::new(),
                ));
                let room_infos = Arc::new(Mutex::new(HashMap::<OwnedRoomId, ExtraRoomInfo>::new()));
                let ui_rooms = Arc::new(Mutex::new(
                    HashMap::<OwnedRoomId, room_list_service::Room>::new(),
                ));
                let timelines = Arc::new(Mutex::new(HashMap::<OwnedRoomId, Timeline>::new()));

                let m = me.clone();
                let r = rooms.clone();
                let ri = room_infos.clone();
                let ur = ui_rooms.clone();
                let t = timelines.clone();

                let main_listener = tokio::spawn(async move {
                    let me = m.clone();
                    let rooms = r.clone();
                    let room_infos = ri.clone();
                    let ui_rooms = ur.clone();
                    let timelines = t.clone();

                    let (room_stream, entries_controller) =
                        room_list.entries_with_dynamic_adapters(50_000);
                    entries_controller
                        .set_filter(Box::new(room_list_service::filters::new_filter_non_left()));
                    pin_mut!(room_stream);

                    while let Some(diffs) = room_stream.next().await {
                        if initial.compare_exchange(
                            true,
                            false,
                            Ordering::Relaxed,
                            Ordering::Relaxed,
                        ) == Ok(true)
                        {
                            info!("received first sync");
                            initial.store(false, Ordering::SeqCst);

                            info!("issuing first sync update");
                            first_synced_arc.send(true);
                        } else {
                            // see if we have new spaces to catch up upon
                        }

                        let all_rooms = {
                            // Apply the diffs to the list of room entries.
                            let mut rooms = rooms.write().await;

                            for diff in diffs {
                                match diff {
                                    VectorDiff::Append { values } => {
                                        rooms.append(values);
                                    }
                                    VectorDiff::Clear => {
                                        rooms.clear();
                                    }
                                    VectorDiff::Insert { index, value } => {
                                        rooms.insert(index, value);
                                    }
                                    VectorDiff::PopBack => {
                                        rooms.pop_back();
                                    }
                                    VectorDiff::PopFront => {
                                        rooms.pop_front();
                                    }
                                    VectorDiff::PushBack { value } => {
                                        rooms.push_back(value);
                                    }
                                    VectorDiff::PushFront { value } => {
                                        rooms.push_front(value);
                                    }
                                    VectorDiff::Remove { index } => {
                                        rooms.remove(index);
                                    }
                                    VectorDiff::Reset { values } => {
                                        rooms.clear();
                                        rooms.append(values);
                                    }
                                    VectorDiff::Set { index, value } => {
                                        rooms.set(index, value);
                                    }
                                    VectorDiff::Truncate { length } => {
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
                        let prev_ui_rooms = ui_rooms.lock().unwrap().clone();

                        let mut new_ui_rooms = HashMap::new();
                        let mut new_timelines = vec![];

                        // Update all the room info for all rooms.
                        for room in all_rooms.iter() {
                            let raw_name = room.name();
                            let display_name = room.cached_display_name();
                            let is_dm = room
                                .is_direct()
                                .await
                                .map_err(|err| {
                                    warn!("couldn't figure whether a room is a DM or not: {err}");
                                })
                                .ok();
                            room_infos.lock().unwrap().insert(
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
                            // Initialize the timeline.
                            let Ok(builder) = ui_room.default_room_timeline_builder().await else {
                                error!("Failed to get default timeline builder");
                                continue;
                            };

                            if let Err(err) = ui_room.init_timeline_with_builder(builder).await {
                                error!("error when creating default timeline: {err}");
                                continue;
                            }

                            // Save the timeline in the cache.
                            let Some(sdk_timeline) = ui_room.timeline() else {
                                error!("Empty timeline of room");
                                continue;
                            };
                            let (items, stream) = sdk_timeline.subscribe().await;
                            let items = Arc::new(Mutex::new(items));

                            // Spawn a timeline task that will listen to all the timeline item changes.
                            let room_id = ui_room.room_id().to_owned();
                            let i = items.clone();
                            let ri = room_infos.clone();
                            let my_id = user_id.clone();
                            let timeline_task = tokio::spawn(async move {
                                pin_mut!(stream);
                                let items = i;
                                let room_infos = ri;
                                while let Some(diff) = stream.next().await {
                                    let mut items = items.lock().unwrap();
                                    diff.apply(&mut items);
                                    if let Some(item) = items.last() {
                                        if item.as_event().is_some() {
                                            let full_event =
                                                RoomMessage::from((item.clone(), my_id.clone()));
                                            let mut ri = room_infos.lock().unwrap();
                                            if let Some(info) = ri.get_mut(&room_id) {
                                                info.latest_msg = Some(full_event);
                                            }
                                        }
                                    }
                                }
                            });

                            new_timelines.push((
                                ui_room.room_id().to_owned(),
                                Timeline {
                                    inner: sdk_timeline,
                                    items,
                                    task: timeline_task,
                                },
                            ));

                            // Save the room list service room in the cache.
                            new_ui_rooms.insert(ui_room.room_id().to_owned(), ui_room.clone());
                        }

                        ui_rooms.lock().unwrap().extend(new_ui_rooms);
                        timelines.lock().unwrap().extend(new_timelines);

                        me.update_rooms(&all_rooms).await;
                    }
                });

                // This will sync (with encryption) until an error happens or the program is stopped.
                sync_service.start().await;

                Ok(SyncController {
                    client: me,
                    sync_service,
                    rooms,
                    room_infos,
                    ui_rooms,
                    timelines,
                    main_listener: Arc::new(main_listener),
                    first_sync_task: Default::default(),
                    first_synced_rx: Arc::new(first_synced_rx),
                })
            })
            .await?
    }

    async fn update_rooms(&self, changed_rooms: &Vector<room_list_service::Room>) {
        let update_keys = {
            let client = self.core.client();
            let mut updated: Vec<String> = vec![];

            let mut simple_convos = self.simple_convos.write().await;
            let mut spaces = self.spaces.write().await;

            for room in changed_rooms {
                let r_id = room.room_id().to_owned();
                if !matches!(room.state(), RoomState::Joined) {
                    trace!(?r_id, "room gone");
                    // remove rooms we aren’t in (anymore)
                    remove_from(&mut spaces, &r_id);
                    remove_from_convo(&mut simple_convos, &r_id);
                    if let Err(error) = self.executor().clear_room(&r_id).await {
                        error!(?error, "Error removing space {r_id}");
                    }
                    updated.push(r_id.to_string());
                    continue;
                }

                let inner = Room::new(self.core.clone(), room.inner_room().clone());

                if inner.is_space() {
                    if let Some(space_idx) = spaces.iter().position(|s| s.room_id() == r_id) {
                        let space = spaces.remove(space_idx).update_room(inner);
                        spaces.insert(space_idx, space);
                    } else {
                        spaces.push_front(Space::new(self.clone(), inner))
                    }
                    // also clear from convos if it was in there...
                    remove_from_convo(&mut simple_convos, &r_id);
                    updated.push(r_id.to_string());
                } else {
                    if let Some(convo_idx) = simple_convos.iter().position(|s| s.room_id() == r_id)
                    {
                        let convo = simple_convos.remove(convo_idx).update_room(inner);
                        // convo.update_latest_msg_ts().await;
                        insert_to_convo(&mut simple_convos, convo);
                    } else {
                        insert_to_convo(&mut simple_convos, SimpleConvo::new(self.clone(), inner));
                    }
                    // also clear from convos if it was in there...
                    remove_from(&mut spaces, &r_id);
                    updated.push(r_id.to_string());
                }
            }

            updated
        };
        info!("refreshed room: {:?}", update_keys.clone());
        self.executor().notify(update_keys);
    }
}

// helper methods for managing spaces and convos
fn remove_from(target: &mut RwLockWriteGuard<ObservableVector<Space>>, r_id: &OwnedRoomId) {
    if let Some(idx) = target.iter().position(|s| s.room_id() == r_id) {
        target.remove(idx);
    }
}

fn remove_from_convo(
    target: &mut RwLockWriteGuard<ObservableVector<SimpleConvo>>,
    r_id: &OwnedRoomId,
) {
    if let Some(idx) = target.iter().position(|s| s.room_id() == r_id) {
        target.remove(idx);
    }
}

// we expect convo to always stay sorted.
fn insert_to_convo(
    target: &mut RwLockWriteGuard<ObservableVector<SimpleConvo>>,
    convo: SimpleConvo,
) {
    if let Some(msg_ts) = convo.latest_message_ts() {
        if let Some(idx) = target.iter().position(|s| match s.latest_message_ts() {
            Some(ts) => ts < msg_ts,
            None => false,
        }) {
            target.insert(idx, convo);
            return;
        }
    }

    // fallback: push at the end.
    target.push_back(convo);
}
