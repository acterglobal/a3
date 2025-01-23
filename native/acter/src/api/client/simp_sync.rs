use anyhow::Result;
use futures::{
    pin_mut,
    stream::{Stream, StreamExt},
};
use futures_signals::signal::Mutable;
use imbl::vector::Vector;
use matrix_sdk_base::ruma::OwnedRoomId;
use matrix_sdk_ui::{
    encryption_sync_service::EncryptionSyncService,
    room_list_service::{filters::new_filter_non_left, Room, RoomListService},
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
    sync::broadcast::{channel, Receiver},
    task::JoinHandle,
};
use tokio_stream::wrappers::BroadcastStream;
use tracing::{error, info, trace, warn};

use super::{super::RUNTIME, Client};

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
}

#[derive(Clone)]
pub struct SyncController {
    /// The sync service used for synchronizing events.
    sync_service: Arc<SyncService>,

    /// Room list service rooms known to the app.
    ui_rooms: Arc<Mutex<HashMap<OwnedRoomId, Room>>>,

    /// Timelines data structures for each room.
    timelines: Arc<Mutex<HashMap<OwnedRoomId, Timeline>>>,

    /// Extra information about rooms.
    room_infos: Arc<Mutex<HashMap<OwnedRoomId, ExtraRoomInfo>>>,

    /// Task listening to room list service changes, and spawning timelines.
    listen_task: Arc<JoinHandle<()>>,

    first_sync_task: Mutable<Option<JoinHandle<Result<()>>>>,

    /// Whether or not sync occurred once at least
    first_synced_rx: Arc<Receiver<bool>>,
}

impl SyncController {
    pub fn cancel(&self) {
        self.listen_task.abort();
    }

    pub fn first_synced_rx(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.first_synced_rx.resubscribe()).map(|o| o.unwrap_or_default())
    }
}

// external API
impl Client {
    pub async fn start_simp_sync(&self) -> Result<SyncController> {
        info!("starting simplified sync");

        let client = self.core.client().clone();

        RUNTIME
            .spawn(async move {
                let sync_service = Arc::new(SyncService::builder(client.clone()).build().await?);
                let room_list = sync_service.room_list_service().all_rooms().await?;

                let (first_synced_tx, first_synced_rx) = channel(1);
                let first_synced_arc = Arc::new(first_synced_tx);

                let initial = Arc::new(AtomicBool::from(true));

                let rooms = Arc::new(Mutex::new(Vector::<Room>::new()));
                let room_infos = Arc::new(Mutex::new(HashMap::<OwnedRoomId, ExtraRoomInfo>::new()));
                let ui_rooms = Arc::new(Mutex::new(HashMap::<OwnedRoomId, Room>::new()));
                let timelines = Arc::new(Mutex::new(HashMap::<OwnedRoomId, Timeline>::new()));

                let ri = room_infos.clone();
                let ur = ui_rooms.clone();
                let t = timelines.clone();

                let listen_task = tokio::spawn(async move {
                    let room_infos = ri.clone();
                    let ui_rooms = ur.clone();
                    let timelines = t.clone();

                    let (room_stream, entries_controller) =
                        room_list.entries_with_dynamic_adapters(50_000);
                    entries_controller.set_filter(Box::new(new_filter_non_left()));
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
                        } else {
                            // see if we have new spaces to catch up upon
                        }

                        let all_rooms = {
                            // Apply the diffs to the list of room entries.
                            let mut rooms = rooms.lock().unwrap();

                            for diff in diffs {
                                diff.apply(&mut rooms);
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
                                },
                            );
                        }

                        // Initialize all the new rooms.
                        for ui_room in all_rooms
                            .into_iter()
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
                            let i = items.clone();
                            let timeline_task = tokio::spawn(async move {
                                pin_mut!(stream);
                                let items = i;
                                while let Some(diff) = stream.next().await {
                                    let mut items = items.lock().unwrap();
                                    diff.apply(&mut items);
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
                            new_ui_rooms.insert(ui_room.room_id().to_owned(), ui_room);
                        }

                        ui_rooms.lock().unwrap().extend(new_ui_rooms);
                        timelines.lock().unwrap().extend(new_timelines);
                    }
                });

                // This will sync (with encryption) until an error happens or the program is stopped.
                sync_service.start().await;

                Ok(SyncController {
                    sync_service,
                    ui_rooms,
                    timelines,
                    room_infos,
                    listen_task: Arc::new(listen_task),
                    first_sync_task: Default::default(),
                    first_synced_rx: Arc::new(first_synced_rx),
                })
            })
            .await?
    }
}
