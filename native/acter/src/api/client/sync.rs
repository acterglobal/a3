use acter_core::{
    events::SyncAnyActerEvent, executor::Executor, models::AnyActerModel,
    referencing::ExecuteReference, spaces::is_acter_space,
};
use anyhow::Result;
use core::time::Duration;
use futures::{
    future::join_all,
    pin_mut,
    stream::{Stream, StreamExt},
};
use futures_signals::signal::{Mutable, MutableSignalCloned, SignalExt, SignalStream};
use matrix_sdk::{config::SyncSettings, event_handler::Ctx, room::Room as SdkRoom, RumaApiError};
use matrix_sdk_base::{
    ruma::{
        api::client::{
            error::{ErrorBody, ErrorKind},
            Error,
        },
        events::room::redaction::{RoomRedactionEvent, SyncRoomRedactionEvent},
        OwnedRoomId,
    },
    RoomState,
};
use std::{
    borrow::Cow,
    collections::BTreeMap,
    io::Write,
    ops::Deref,
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc,
    },
    time::Instant,
};
use tokio::{
    sync::{
        broadcast::{channel, Receiver},
        RwLockWriteGuard,
    },
    task::JoinHandle,
};
use tokio_stream::wrappers::BroadcastStream;
use tracing::{error, info, trace, warn};

use crate::{Convo, Room, Space, RUNTIME};

use super::{Client, SyncController};

#[derive(Clone, Debug, Default)]
pub struct HistoryLoadState {
    pub has_started: bool,
    loading_spaces: BTreeMap<OwnedRoomId, bool>,
    done_spaces: Vec<OwnedRoomId>,
}

// internal API
impl HistoryLoadState {
    fn initialize(&mut self, loading_spaces: Vec<OwnedRoomId>) {
        trace!(?loading_spaces, "Starting History loading");
        self.has_started = true;
        self.loading_spaces.clear();
        for space_id in loading_spaces.into_iter() {
            self.loading_spaces.insert(space_id, false);
        }
    }

    fn forget_room(&mut self, room_id: &OwnedRoomId) {
        self.loading_spaces.remove(room_id);
        self.done_spaces.retain(|v| v != room_id);
    }

    fn knows_room(&self, room_id: &OwnedRoomId) -> bool {
        self.done_spaces.contains(room_id) || self.loading_spaces.contains_key(room_id)
    }

    // start the loading process. If we are already loading return false
    fn start_loading(&mut self, room_id: OwnedRoomId) -> bool {
        !matches!(self.loading_spaces.insert(room_id, true), Some(true))
    }

    fn done_loading(&mut self, room_id: OwnedRoomId) {
        trace!(?room_id, "Setting room as done loading");
        if self.loading_spaces.remove(&room_id).is_some() {
            self.done_spaces.push(room_id);
        }
    }
}

// Public API
impl HistoryLoadState {
    pub fn is_done_loading(&self) -> bool {
        self.has_started && self.loading_spaces.is_empty()
    }

    pub fn loaded_spaces(&self) -> usize {
        self.done_spaces.len()
    }

    pub fn total_spaces(&self) -> usize {
        self.loading_spaces.len() + self.done_spaces.len()
    }
}

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
    pub(crate) fn ffi_string(&self) -> String {
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
    pub(super) handle: Mutable<Option<JoinHandle<()>>>,
    pub(super) first_sync_task: Mutable<Option<JoinHandle<Result<()>>>>,
    first_synced_rx: Arc<Receiver<bool>>,
    sync_error: Arc<Receiver<SyncError>>,
    pub(super) history_loading: Mutable<HistoryLoadState>,
}

impl SyncState {
    pub fn new(first_synced_rx: Receiver<bool>, sync_error: Receiver<SyncError>) -> Self {
        Self {
            first_synced_rx: Arc::new(first_synced_rx),
            sync_error: Arc::new(sync_error),
            history_loading: Default::default(),
            first_sync_task: Default::default(),
            handle: Default::default(),
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
        {
            let current = self.history_loading.lock_ref();
            if (current.is_done_loading()) {
                return Ok(current.total_spaces() as u32);
            }
        }
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
        if let Some(first_sync_task) = self.first_sync_task.replace(None) {
            first_sync_task.abort();
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
    pub(crate) fn setup_handlers(&self) {
        // setup the space handlers
        let executor = self.executor().clone();

        self.add_event_handler_context(executor);
        // generic redaction management
        self.add_event_handler(
            |ev: SyncRoomRedactionEvent, room: SdkRoom, Ctx(executor): Ctx<Executor>| async move {
                let room_id = room.room_id();

                if let RoomRedactionEvent::Original(t) = ev.into_full_event(room_id.to_owned()) {
                    trace!(?room_id, "received redaction");
                    if let Err(error) = executor.live_redact(t).await {
                        error!(?room_id, ?error, "redaction failed");
                    }
                } else {
                    warn!(?room_id, "redaction redaction isn’t supported yet");
                }
            },
        );

        // Any
        self.add_event_handler(
            |ev: SyncAnyActerEvent, room: SdkRoom, Ctx(executor): Ctx<Executor>| async move {
                let room_id = room.room_id().to_owned();
                let acter_event = ev.into_full_any_acter_event(room_id);
                AnyActerModel::execute(&executor, acter_event).await;
            },
        );
    }

    fn refresh_history_on_start(
        &self,
        sync_keys: Vec<OwnedRoomId>,
        first_sync_task: Mutable<Option<JoinHandle<Result<()>>>>,
        history: Mutable<HistoryLoadState>,
        start: Instant,
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
            info!("first sync - 666666 - {:?}", start.elapsed());
            let initial_space_setup = spaces
                .iter()
                .map(|r| r.room_id().to_owned())
                .filter(|id| sync_keys.contains(id))
                .collect();
            history.lock_mut().initialize(initial_space_setup);

            futures::future::join_all(spaces.iter_mut().map(|space| async {
                let room_id = space.room_id();
                let is_acter_space = match space.is_acter_space().await {
                    Ok(b) => b,
                    Err(error) => {
                        error!(
                            ?room_id,
                            ?error,
                            "checking for is-acter-space status failed"
                        );
                        false
                    }
                };
                if !is_acter_space {
                    trace!(?room_id, "not an acter space");
                    history.lock_mut().forget_room(&room_id.to_owned());
                    return;
                }

                if let Err(err) = space.refresh_history().await {
                    error!(?err, ?room_id, "Loading space history failed");
                };

                history.lock_mut().done_loading(room_id.to_owned());
            }))
            .await;
            info!("first sync - 777777 - {:?}", start.elapsed());
            // once done, let’s reset the first_sync_task to clear it from memory
            first_sync_task_inner.set(None);
            Ok(())
        }));
    }

    async fn refresh_history_on_way(
        &self,
        history: Mutable<HistoryLoadState>,
        new_spaces: Vec<SdkRoom>,
    ) -> Result<()> {
        trace!(user_id=?self.user_id_ref(), count=?new_spaces.len(), "found new spaces");

        futures::future::join_all(
            new_spaces
                .into_iter()
                .map(|room| {
                    Space::new(
                        self.clone(),
                        Room::new(self.core.clone(), room, self.sync_controller.clone()),
                    )
                })
                .map(|mut space| {
                    let history = history.clone();
                    async move {
                        let room_id = space.room_id().to_owned();
                        {
                            let mut history = history.lock_mut();
                            if !history.start_loading(room_id.clone()) {
                                trace!(?room_id, "Already loading room.");
                                return;
                            }
                        }

                        if let Err(err) = space.refresh_history().await {
                            error!(?err, ?room_id, "refreshing history failed");
                        }
                        history.lock_mut().done_loading(room_id.clone());
                    }
                }),
        )
        .await;
        Ok(())
    }
}

static SYNC_TOKEN_KEY: &str = "sync_token";

// external API
impl Client {
    pub async fn start_sync(&mut self) -> Result<SyncState> {
        info!("starting sync");
        let state = self.state.clone();
        let me = self.clone();
        let executor = self.executor().clone();
        let client = self.core.client().clone();

        self.invitation_controller.add_event_handler();
        self.typing_controller.add_event_handler(&client);

        self.verification_controller
            .add_to_device_event_handler(&client);
        // sync event is the event that my device was off so it may be timed out possibly
        // in fact, when user opens app, he sees old verification popup sometimes
        // in order to avoid this issue, comment out sync event
        self.verification_controller.add_sync_event_handler(&client);

        let mut invitation_controller = self.invitation_controller.clone();
        let mut device_controller = self.device_controller.clone();

        RUNTIME
            .spawn(async move {
                let start = Instant::now();
                let (first_synced_tx, first_synced_rx) = channel(1);
                let first_synced_arc = Arc::new(first_synced_tx);

                let (sync_error_tx, sync_error_rx) = channel(1);
                let sync_error_arc = Arc::new(sync_error_tx);

                let initial = Arc::new(AtomicBool::from(true));
                let sync_state = SyncState::new(first_synced_rx, sync_error_rx);
                let history_loading = sync_state.history_loading.clone();
                let first_sync_task = sync_state.first_sync_task.clone();

                let me_cl = me.clone();
                let handle = tokio::spawn(async move {
                    info!("spawning sync callback");

                    let mut sync_settings = SyncSettings::new().timeout(Duration::from_secs(25));

                    match me_cl.store().get_raw::<Option<String>>(SYNC_TOKEN_KEY).await {
                        Ok(Some(token)) => {
                            trace!(?token, "sync found token!");
                            sync_settings = sync_settings.token(token);
                        }
                        Err(acter_core::Error::ModelNotFound(_)) => {
                            trace!("First start, no sync token");
                        }
                        Err(error) => {
                            error!(?error, "Problem loading sync token");
                        }
                        _ => {}
                    }
                    info!("first sync - 111111 - {:?}", start.elapsed());

                    // keep the sync timeout below the actual connection timeout to ensure we receive it
                    // back before the server timeout occurred

                    let mut sync_stream = Box::pin(client.sync_stream(sync_settings).await);
                    info!("first sync - 222222 - {:?}", start.elapsed());

                    // fetch the events that received when offline
                    while let Some(result) = sync_stream.next().await {
                        info!("received sync callback");

                        let response = match result {
                            Ok(response) => response,
                            Err(err) => {
                                if let Some(RumaApiError::ClientApi(e)) = err.as_ruma_api_error() {
                                    error!(?e, "Client error");
                                    sync_error_arc.send(e.into());
                                    return;
                                }
                                error!(?err, "Other error, continuing");
                                continue;
                            }
                        };

                        trace!(target: "acter::sync_response::full", "sync response: {:#?}", response);

                        if initial.compare_exchange(true, false, Ordering::Relaxed, Ordering::Relaxed)
                            == Ok(true)
                        {
                            info!("received first sync");
                            trace!(user_id=?client.user_id(), "initial synced");
                            invitation_controller.load_invitations().await;
                            info!("first sync - 333333 - {:?}", start.elapsed());

                            initial.store(false, Ordering::SeqCst);

                            info!("issuing first sync update");
                            first_synced_arc.send(true);
                            if let Ok(mut w) = state.try_write() {
                                w.has_first_synced = true;
                            };
                            let sync_keys = response.rooms.join.keys().cloned().collect();
                            // background and keep the handle around.
                            me_cl.refresh_history_on_start(
                                sync_keys,
                                first_sync_task.clone(),
                                history_loading.clone(),
                                start,
                            );
                        } else {
                            // see if we have new spaces to catch up upon
                            let mut new_spaces = Vec::new();
                            for (room_id, joined_state) in response.rooms.join.iter() {
                                if history_loading.lock_mut().knows_room(room_id) {
                                    continue;
                                }
                                let Some(full_room) = me_cl.get_room(room_id) else {
                                    error!("room not found. how can that be?");
                                    continue;
                                };
                                if is_acter_space(&full_room).await {
                                    new_spaces.push(full_room);
                                }
                            }

                            if !new_spaces.is_empty() {
                                me_cl.refresh_history_on_way(history_loading.clone(), new_spaces)
                                    .await;
                            }
                        }

                        if !response.account_data.is_empty() {
                            info!("account data found!");
                            // account data has been updated, inform the listeners
                            let keys: Vec<ExecuteReference> = response
                                .account_data
                                .iter()
                                .filter_map(|raw| {
                                    raw.get_field::<String>("type")
                                        .ok()
                                        .flatten()
                                        .map(|s| ExecuteReference::AccountData(Cow::Owned(s)))
                                })
                                .collect();
                            if !keys.is_empty() {
                                info!("account data keys: {keys:?}");
                                me_cl.executor().notify(keys);
                            }
                        }

                        if let Ok(mut w) = state.try_write() {
                            if w.should_stop_syncing {
                                w.is_syncing = false;
                                info!("first sync - 444444 - {:?}", start.elapsed());
                                trace!("Stopping syncing upon user request");
                                return;
                            }
                        }
                        if let Ok(mut w) = state.try_write() {
                            if !w.is_syncing {
                                w.is_syncing = true;
                            }
                        }

                        trace!(token = response.next_batch, "storing sync token");
                        if let Err(error) = me_cl
                            .store()
                            .set_raw(SYNC_TOKEN_KEY, &response.next_batch)
                            .await
                        {
                            error!(?error, "Error writing sync_token");
                        }

                        trace!("ready for the next round");
                    }
                    trace!("sync stopped");

                    if let Ok(mut w) = state.try_write() {
                        w.is_syncing = false;
                    };
                });

                me.start_sliding_sync().await?;
                info!("first sync - 555555 - {:?}", start.elapsed());

                sync_state.handle.set(Some(handle));
                Ok(sync_state)
            })
            .await?
    }

    /// Indication whether we’ve received a first sync response since
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
