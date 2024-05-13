use acter_core::spaces::is_acter_space;
use anyhow::{Context, Result};
use base64ct::{Base64UrlUnpadded, Encoding};
use core::time::Duration;
use eyeball_im::{ObservableVector, Vector};
use futures::{
    future::join_all,
    pin_mut,
    stream::{Stream, StreamExt},
};
use futures_signals::signal::{Mutable, MutableSignalCloned, SignalExt, SignalStream};
use matrix_sdk::{
    config::SyncSettings, event_handler::EventHandlerHandle, media::MediaRequest,
    room::Room as SdkRoom, LoopCtrl, RoomState, RumaApiError,
};
use matrix_sdk_base::media::UniqueKey;
use ruma_client_api::{
    error::{ErrorBody, ErrorKind},
    Error,
};
use ruma_common::{OwnedRoomId, RoomId};
use std::{
    collections::{BTreeMap, HashMap},
    io::Write,
    ops::Deref,
    path::PathBuf,
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc,
    },
};
use tokio::{
    sync::{
        broadcast::{channel, Receiver},
        Mutex, RwLock, RwLockWriteGuard,
    },
    task::JoinHandle,
    time,
};
use tokio_stream::wrappers::BroadcastStream;
use tracing::{error, info, trace, warn};

use crate::{Account, Convo, OptionString, Room, Space, ThumbnailSize, RUNTIME};

use super::{
    super::{
        api::FfiBuffer, device::DeviceController, invitation::InvitationController,
        receipt::ReceiptController, typing::TypingController, verification::VerificationController,
    },
    Client,
};

#[derive(Clone, Debug, Default)]
pub struct HistoryLoadState {
    pub has_started: bool,
    pub known_spaces: BTreeMap<OwnedRoomId, bool>,
}

impl HistoryLoadState {
    pub fn is_done_loading(&self) -> bool {
        self.has_started && !self.known_spaces.values().any(|x| *x)
    }

    pub fn start(&mut self, known_spaces: Vec<OwnedRoomId>) {
        trace!(?known_spaces, "Starting History loading");
        self.has_started = true;
        self.known_spaces.clear();
        for space in known_spaces.into_iter() {
            self.known_spaces.insert(space, true);
        }
    }

    pub fn unknow_room(&mut self, room_id: &OwnedRoomId) -> bool {
        self.known_spaces.remove(room_id).unwrap_or_default()
    }

    pub fn knows_room(&self, room_id: &OwnedRoomId) -> bool {
        self.known_spaces.contains_key(room_id)
    }

    pub fn is_loading(&mut self, room_id: &OwnedRoomId) -> bool {
        self.known_spaces.get(room_id).cloned().unwrap_or(false)
    }

    pub fn set_loading(&mut self, room_id: OwnedRoomId, value: bool) -> bool {
        trace!(?room_id, loading = value, "Setting room for loading");
        self.known_spaces.insert(room_id, value).unwrap_or_default()
    }

    pub fn total_spaces(&self) -> usize {
        self.known_spaces.len()
    }
}

type RoomHandlers = Arc<Mutex<HashMap<OwnedRoomId, Vec<EventHandlerHandle>>>>;

#[derive(Clone)]
pub enum SyncError {
    Unauthorized { soft_logout: bool },
    Other { msg: Option<String> },
    DeserializationFailed,
}

impl From<&Error> for SyncError {
    fn from(value: &Error) -> Self {
        match &value.body {
            ErrorBody::Standard {
                kind: ErrorKind::UnknownToken { soft_logout },
                ..
            } => SyncError::Unauthorized {
                soft_logout: *soft_logout,
            },
            ErrorBody::Standard { ref message, .. } => SyncError::Other {
                msg: Some(message.clone()),
            },
            ErrorBody::Json(value) => SyncError::Other { msg: None },
            ErrorBody::NotJson { .. } => SyncError::DeserializationFailed,
        }
    }
}

impl SyncError {
    fn ffi_string(&self) -> String {
        match &self {
            SyncError::Unauthorized { soft_logout } => {
                if *soft_logout {
                    "SoftLogout".to_owned()
                } else {
                    "Unauthorized".to_owned()
                }
            }
            SyncError::DeserializationFailed => "DeserializationFailed".to_owned(),
            SyncError::Other { msg } => msg.clone().unwrap_or("Other".to_owned()),
        }
    }
}

#[derive(Clone)]
pub struct SyncState {
    handle: Mutable<Option<JoinHandle<()>>>,
    first_sync_task: Mutable<Option<JoinHandle<Result<()>>>>,
    first_synced_rx: Arc<Receiver<bool>>,
    sync_error: Arc<Receiver<SyncError>>,
    history_loading: Mutable<HistoryLoadState>,
    room_handles: RoomHandlers,
}

impl SyncState {
    pub fn new(first_synced_rx: Receiver<bool>, sync_error: Receiver<SyncError>) -> Self {
        Self {
            first_synced_rx: Arc::new(first_synced_rx),
            sync_error: Arc::new(sync_error),
            history_loading: Default::default(),
            first_sync_task: Default::default(),
            handle: Default::default(),
            room_handles: Default::default(),
        }
    }

    pub fn first_synced_rx(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.first_synced_rx.resubscribe()).map(|o| o.unwrap_or_default())
    }

    // ***_typed fn exposes rust-typed output, not string-based one
    fn sync_error_rx_typed(&self) -> BroadcastStream<SyncError> {
        BroadcastStream::new(self.sync_error.resubscribe())
    }

    pub fn sync_error_rx(&self) -> impl Stream<Item = String> {
        self.sync_error_rx_typed()
            .map(|o| o.map(|f| f.ffi_string()).unwrap_or_default())
    }

    // FIXE: This is not save. History state is copied and thus not all known_spaces are tracked
    // for only tui, not api.rsh
    pub fn get_history_loading_rx(&self) -> SignalStream<MutableSignalCloned<HistoryLoadState>> {
        self.history_loading.signal_cloned().to_stream()
    }

    #[cfg(feature = "testing")]
    #[doc(hidden)]
    pub async fn await_has_synced_history(&self) -> Result<u32> {
        trace!("Waiting for history to sync");
        let signal = self.history_loading.signal_cloned().to_stream();
        pin_mut!(signal);
        while let Some(next_state) = signal.next().await {
            trace!(?next_state, "History updated");
            if next_state.is_done_loading() {
                trace!(?next_state, "History sync completed");
                return Ok(next_state.total_spaces() as u32);
            }
        }
        unimplemented!("We never reach this state")
    }

    pub fn cancel(&self) {
        if let Some(handle) = self.handle.replace(None) {
            handle.abort();
        }
    }
}

impl Drop for SyncState {
    fn drop(&mut self) {
        self.cancel();
    }
}

// internal API
impl Client {
    fn refresh_history_on_start(
        &self,
        first_sync_task: Mutable<Option<JoinHandle<Result<()>>>>,
        history: Mutable<HistoryLoadState>,
        room_handles: RoomHandlers,
    ) {
        let me = self.clone();
        let first_sync_task_inner = first_sync_task.clone();
        let mut first_sync_inner = first_sync_task.lock_mut();
        if let Some(inner) = first_sync_inner.deref() {
            // we drop the existing;
            inner.abort();
        }

        *first_sync_inner = Some(tokio::spawn(async move {
            trace!(user_id=?me.user_id_ref(), "refreshing history");
            let mut spaces = me.spaces().await?;
            let space_ids = spaces.iter().map(|r| r.room_id().to_owned()).collect();
            history.lock_mut().start(space_ids);

            futures::future::join_all(spaces.iter_mut().map(|space| async {
                let is_acter_space = match space.is_acter_space().await {
                    Ok(b) => b,
                    Err(error) => {
                        error!(room_id=?space.room_id(), ?error, "checking for is-acter-space status failed");
                        false
                    }
                };
                if !is_acter_space {
                    trace!(room_id=?space.room_id(), "not an acter space");
                    history.lock_mut().unknow_room(&space.room_id().to_owned());
                    return;
                }

                let space_handles = space.setup_handles().await;
                {
                    let mut handles = room_handles.lock().await;
                    if let Some(h) = handles.insert(space.room_id().to_owned(), space_handles) {
                        warn!(room_id=?space.room_id(), "handles overwritten. Might cause issues?!?");
                    }
                }

                if let Err(err) = space.refresh_history().await {
                    error!(?err, room_id=?space.room_id(), "Loading space history failed");
                };
                history
                    .lock_mut()
                    .set_loading(space.room_id().to_owned(), false);
            }))
            .await;
            // once done, let's reset the first_sync_task to clear it from memory
            first_sync_task_inner.set(None);
            Ok(())
        }));
    }

    async fn refresh_history_on_way(
        &self,
        history: Mutable<HistoryLoadState>,
        room_handles: RoomHandlers,
        new_spaces: Vec<SdkRoom>,
    ) -> Result<()> {
        trace!(user_id=?self.user_id_ref(), count=?new_spaces.len(), "found new spaces");

        futures::future::join_all(
            new_spaces
                .into_iter()
                .map(|room| Space::new(self.clone(), Room::new( self.core.clone(), room )))
                .map(|mut space| {
                    let history = history.clone();
                    let room_handles = room_handles.clone();
                    async move {
                        {
                            let room_id = space.room_id().to_owned();
                            let mut history = history.lock_mut();
                            if history.is_loading(&room_id) {
                                trace!(room_id=?room_id, "Already loading room.");
                                return;
                            }
                            history.set_loading(room_id, true);
                        }

                        let space_handles = space.setup_handles().await;
                        {
                            let mut handles = room_handles.lock().await;
                            if let Some(h) = handles.insert(space.room_id().to_owned(), space_handles) {
                                warn!(room_id=?space.room_id(), "handles overwritten. Might cause issues?!?");
                            }
                        }

                        if let Err(err) = space.refresh_history().await {
                            error!(?err, room_id=?space.room_id(), "refreshing history failed");
                        }
                        history
                            .lock_mut()
                            .set_loading(space.room_id().to_owned(), false);
                    }
                }),
        )
        .await;
        Ok(())
    }

    async fn refresh_rooms(&self, changed_rooms: Vec<&OwnedRoomId>) {
        let update_keys = {
            let client = self.core.client();
            let mut updated: Vec<String> = vec![];

            let mut chats = self.convos.write().await;
            let mut spaces = self.spaces.write().await;

            for r_id in changed_rooms {
                let Some(room) = client.get_room(r_id) else {
                    trace!(?r_id, "room not known");
                    remove_from(&mut spaces, r_id);
                    remove_from_chat(&mut chats, r_id);
                    if let Err(error) = self.executor().clear_room(r_id).await {
                        error!(?error, "Error removing space {r_id}");
                    }
                    continue;
                };

                if !matches!(room.state(), RoomState::Joined) {
                    trace!(?r_id, "room gone");
                    // remove rooms we aren't in (anymore)
                    remove_from(&mut spaces, r_id);
                    remove_from_chat(&mut chats, r_id);
                    if let Err(error) = self.executor().clear_room(r_id).await {
                        error!(?error, "Error removing space {r_id}");
                    }
                    updated.push(r_id.to_string());
                    continue;
                }

                let inner = Room::new(self.core.clone(), room.clone());

                if inner.is_space() {
                    if let Some(space_idx) = spaces.iter().position(|s| s.room_id() == r_id) {
                        let space = spaces.remove(space_idx).update_room(inner);
                        spaces.insert(space_idx, space);
                    } else {
                        spaces.push_front(Space::new(self.clone(), inner))
                    }
                    // also clear from convos if it was in there...
                    remove_from_chat(&mut chats, r_id);
                    updated.push(r_id.to_string());
                } else {
                    if let Some(chat_idx) = chats.iter().position(|s| s.room_id() == r_id) {
                        let chat = chats.remove(chat_idx).update_room(inner);
                        // chat.update_latest_msg_ts().await;
                        insert_to_chat(&mut chats, chat);
                    } else {
                        insert_to_chat(&mut chats, Convo::new(self.clone(), inner).await);
                    }
                    // also clear from convos if it was in there...
                    remove_from(&mut spaces, r_id);
                    updated.push(r_id.to_string());
                }
            }

            updated
        };
        self.executor().notify(update_keys);
    }
}

// helper methods for managing spaces and chats
fn remove_from(target: &mut RwLockWriteGuard<ObservableVector<Space>>, r_id: &OwnedRoomId) {
    if let Some(idx) = target.iter().position(|s| s.room_id() == r_id) {
        target.remove(idx);
    }
}

fn remove_from_chat(target: &mut RwLockWriteGuard<ObservableVector<Convo>>, r_id: &OwnedRoomId) {
    if let Some(idx) = target.iter().position(|s| s.room_id() == r_id) {
        target.remove(idx);
    }
}

// we expect chat to always stay sorted.
fn insert_to_chat(target: &mut RwLockWriteGuard<ObservableVector<Convo>>, convo: Convo) {
    let msg_ts = convo.latest_message_ts();
    if (msg_ts > 0) {
        if let Some(idx) = target.iter().position(|s| s.latest_message_ts() < msg_ts) {
            target.insert(idx, convo);
            return;
        }
    }

    // fallback: push at the end.
    target.push_back(convo);
}

// external API
impl Client {
    pub fn start_sync(&mut self) -> SyncState {
        info!("starting sync");
        let state = self.state.clone();
        let me = self.clone();
        let executor = self.executor().clone();
        let client = self.core.client().clone();

        self.invitation_controller.add_event_handler();
        self.typing_controller.add_event_handler(&client);
        self.receipt_controller.add_event_handler(&client);

        self.verification_controller
            .add_to_device_event_handler(&client);
        // sync event is the event that my device was off so it may be timed out possibly
        // in fact, when user opens app, he sees old verification popup sometimes
        // in order to avoid this issue, comment out sync event
        self.verification_controller.add_sync_event_handler(&client);

        let mut invitation_controller = self.invitation_controller.clone();
        let mut device_controller = self.device_controller.clone();

        let (first_synced_tx, first_synced_rx) = channel(1);
        let first_synced_arc = Arc::new(first_synced_tx);

        let (sync_error_tx, sync_error_rx) = channel(1);
        let sync_error_arc = Arc::new(sync_error_tx);

        let initial_arc = Arc::new(AtomicBool::from(true));
        let sync_state = SyncState::new(first_synced_rx, sync_error_rx);
        let history_loading = sync_state.history_loading.clone();
        let first_sync_task = sync_state.first_sync_task.clone();
        let room_handles = sync_state.room_handles.clone();

        let handle = RUNTIME.spawn(async move {
            info!("spawning sync callback");
            let client = client.clone();
            let state = state.clone();

            let mut invitation_controller = invitation_controller.clone();
            let mut device_controller = device_controller.clone();

            let history_loading = history_loading.clone();
            let first_sync_task = first_sync_task.clone();
            let room_handles = room_handles.clone();

            // keep the sync timeout below the actual connection timeout to ensure we receive it
            // back before the server timeout occured
            let sync_settings = SyncSettings::new().timeout(Duration::from_secs(25));
            // fetch the events that received when offline
            client
                .clone()
                .sync_with_result_callback(sync_settings, |result| async {
                    info!("received sync callback");
                    let client = client.clone();
                    let me = me.clone();
                    let executor = executor.clone();
                    let state = state.clone();

                    let mut invitation_controller = invitation_controller.clone();
                    let mut device_controller = device_controller.clone();

                    let first_synced_arc = first_synced_arc.clone();
                    let sync_error_arc = sync_error_arc.clone();
                    let history_loading = history_loading.clone();
                    let initial = initial_arc.clone();

                    let response = match result {
                        Ok(response) => response,
                        Err(err) => {
                            if let Some(RumaApiError::ClientApi(e)) = err.as_ruma_api_error() {
                                error!(?e, "Client error");
                                sync_error_arc.send(e.into());
                                return Ok(LoopCtrl::Break);
                            }
                            error!(?err, "Other error, continuing");
                            return Ok(LoopCtrl::Continue);
                        }
                    };
                    trace!(target: "acter::sync_response::full", "sync response: {:#?}", response);

                    if initial.compare_exchange(true, false, Ordering::Relaxed, Ordering::Relaxed)
                        == Ok(true)
                    {
                        info!("received first sync");
                        trace!(user_id=?client.user_id(), "initial synced");
                        invitation_controller.load_invitations().await;

                        initial.store(false, Ordering::SeqCst);

                        info!("issuing first sync update");
                        first_synced_arc.send(true);
                        if let Ok(mut w) = state.try_write() {
                            w.has_first_synced = true;
                        };
                        // background and keep the handle around.
                        me.refresh_history_on_start(
                            first_sync_task.clone(),
                            history_loading.clone(),
                            room_handles.clone(),
                        );
                    } else {
                        // see if we have new spaces to catch up upon
                        let mut new_spaces = Vec::new();
                        for room_id in response.rooms.join.keys() {
                            if history_loading.lock_mut().knows_room(room_id) {
                                // we are already loading this room
                                continue;
                            }
                            let Some(full_room) = me.get_room(room_id) else {
                                error!("room not found. how can that be?");
                                continue;
                            };
                            if is_acter_space(&full_room).await {
                                new_spaces.push(full_room);
                            }
                        }

                        if !new_spaces.is_empty() {
                            me.refresh_history_on_way(
                                history_loading.clone(),
                                room_handles.clone(),
                                new_spaces,
                            )
                            .await;
                        }
                    }

                    let mut changed_rooms = response
                        .rooms
                        .join
                        .keys()
                        .chain(response.rooms.leave.keys())
                        .chain(response.rooms.invite.keys())
                        .collect::<Vec<_>>();

                    if (!changed_rooms.is_empty()) {
                        trace!(?changed_rooms, "changed rooms");
                        me.refresh_rooms(changed_rooms).await;
                    }

                    if (!response.account_data.is_empty()) {
                        info!("account data found!");
                        // account data has been updated, inform the listeners
                        let keys = response
                            .account_data
                            .iter()
                            .filter_map(|raw| raw.get_field::<String>("type").ok().flatten())
                            .collect::<Vec<String>>();
                        if (!keys.is_empty()) {
                            info!("account data keys: {keys:?}");
                            me.executor().notify(keys);
                        }
                    }

                    if let Ok(mut w) = state.try_write() {
                        if w.should_stop_syncing {
                            w.is_syncing = false;
                            trace!("Stopping syncing upon user request");
                            return Ok(LoopCtrl::Break);
                        }
                    }
                    if let Ok(mut w) = state.try_write() {
                        if !w.is_syncing {
                            w.is_syncing = true;
                        }
                    }

                    trace!("ready for the next round");
                    Ok(LoopCtrl::Continue)
                })
                .await;
        });
        sync_state.handle.set(Some(handle));
        sync_state
    }

    /// Indication whether we've received a first sync response since
    /// establishing the client (in memory)
    pub fn has_first_synced(&self) -> bool {
        match self.state.try_read() {
            Ok(r) => r.has_first_synced,
            Err(e) => false,
        }
    }

    /// Indication whether we are currently syncing
    pub fn is_syncing(&self) -> bool {
        match self.state.try_read() {
            Ok(r) => r.is_syncing,
            Err(e) => false,
        }
    }
}
