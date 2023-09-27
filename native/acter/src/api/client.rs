use acter_core::{
    client::CoreClient, executor::Executor, models::AnyActerModel, spaces::is_acter_space,
    store::Store, templates::Engine, CustomAuthSession, RestoreToken,
};
use anyhow::{bail, Context, Result};
use core::time::Duration;
use derive_builder::Builder;
use eyeball_im::{ObservableVector, Vector, VectorSubscriber};
use futures::{
    future::join_all,
    pin_mut,
    stream::{Stream, StreamExt},
};
use futures_signals::{
    signal::{Mutable, MutableLockMut, MutableSignalCloned, SignalExt, SignalStream},
    signal_vec::{MutableVec, MutableVecLockMut},
};
use matrix_sdk::{
    config::SyncSettings,
    event_handler::EventHandlerHandle,
    media::{MediaFormat, MediaRequest},
    room::Room as SdkRoom,
    ruma::api::client::{
        error::{ErrorBody, ErrorKind},
        push::get_notifications::v3::Notification as RumaNotification,
        Error,
    },
    Client as SdkClient, LoopCtrl, RoomState, RumaApiError,
};
use ruma_common::{
    device_id, events::room::MediaSource, OwnedDeviceId, OwnedMxcUri, OwnedRoomAliasId,
    OwnedRoomId, OwnedRoomOrAliasId, OwnedServerName, OwnedUserId, RoomOrAliasId, UserId,
};
use std::{
    collections::{BTreeMap, HashMap},
    ops::Deref,
    path::PathBuf,
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc,
    },
};
use tokio::{
    sync::{
        broadcast::{channel, Receiver, Sender},
        Mutex, RwLock, RwLockWriteGuard,
    },
    task::JoinHandle,
    time,
};
use tokio_stream::wrappers::BroadcastStream;
use tracing::{error, info, trace, warn};

use crate::Notification;

use super::{
    account::Account, api::FfiBuffer, convo::Convo, device::DeviceController,
    invitation::InvitationController, profile::UserProfile, receipt::ReceiptController, room::Room,
    spaces::Space, typing::TypingController, verification::VerificationController, RUNTIME,
};

#[derive(Default, Builder, Debug)]
pub struct ClientState {
    #[builder(default)]
    pub is_guest: bool,

    #[builder(default)]
    pub has_first_synced: bool,

    #[builder(default)]
    pub is_syncing: bool,

    #[builder(default)]
    pub should_stop_syncing: bool,
}

#[derive(Clone, Debug)]
pub struct Client {
    pub(crate) core: CoreClient,
    pub(crate) state: Arc<RwLock<ClientState>>,
    pub(crate) invitation_controller: InvitationController,
    pub(crate) verification_controller: VerificationController,
    pub(crate) device_controller: DeviceController,
    pub(crate) typing_controller: TypingController,
    pub(crate) receipt_controller: ReceiptController,
    pub spaces: Arc<RwLock<eyeball_im::ObservableVector<Space>>>,
    pub convos: Arc<RwLock<eyeball_im::ObservableVector<Convo>>>,
    pub(crate) notifications: Arc<Sender<RumaNotification>>,
}

impl Deref for Client {
    type Target = SdkClient;
    fn deref(&self) -> &SdkClient {
        self.core.client()
    }
}

#[derive(Debug, Builder)]
pub struct SpaceFilter {
    #[builder(default = "true")]
    include_joined: bool,
    #[builder(default = "false")]
    include_left: bool,
    #[builder(default = "true")]
    include_invited: bool,
}

impl SpaceFilter {
    pub fn should_include(&self, room: &SdkRoom) -> bool {
        match room.state() {
            RoomState::Joined => self.include_joined,
            RoomState::Left => self.include_left,
            RoomState::Invited => self.include_invited,
        }
    }
}

impl Default for SpaceFilter {
    fn default() -> Self {
        SpaceFilter {
            include_joined: true,
            include_left: true,
            include_invited: true,
        }
    }
}

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

    pub fn sync_error_rx_typed(&self) -> BroadcastStream<SyncError> {
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

    // for only cli and integration tests, not api.rsh
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
        history: Mutable<HistoryLoadState>,
        room_handles: RoomHandlers,
    ) -> JoinHandle<Result<()>> {
        let me = self.clone();
        tokio::spawn(async move {
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
            Ok(())
        })
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

    pub(crate) async fn source_binary(&self, source: MediaSource) -> Result<FfiBuffer<u8>> {
        // any variable in self can't be called directly in spawn
        let client = self.clone();
        let request = MediaRequest {
            source,
            format: MediaFormat::File,
        };
        trace!(?request, "tasked to get source binary");
        RUNTIME
            .spawn(async move {
                let buf = client.media().get_media_content(&request, true).await?;
                Ok(FfiBuffer::new(buf))
            })
            .await?
    }

    pub(crate) async fn join_room(
        &self,
        room_id_or_alias: String,
        server_names: Vec<String>,
    ) -> Result<Room> {
        let alias = OwnedRoomOrAliasId::try_from(room_id_or_alias)?;
        let server_names = server_names
            .into_iter()
            .map(OwnedServerName::try_from)
            .collect::<Result<Vec<OwnedServerName>, ruma_common::IdParseError>>()?;
        let c = self.clone();
        RUNTIME
            .spawn(async move {
                let joined = c
                    .join_room_by_id_or_alias(alias.as_ref(), server_names.as_slice())
                    .await?;
                Ok(Room::new(c.core.clone(), joined.into()))
            })
            .await?
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
    pub async fn new(client: SdkClient, state: ClientState) -> Result<Self> {
        let core = CoreClient::new(client).await?;
        let mut cl = Client {
            core,
            state: Arc::new(RwLock::new(state)),
            spaces: Default::default(),
            convos: Default::default(),
            invitation_controller: InvitationController::new(),
            verification_controller: VerificationController::new(),
            device_controller: DeviceController::new(),
            typing_controller: TypingController::new(),
            receipt_controller: ReceiptController::new(),
            notifications: Arc::new(channel(25).0),
        };
        cl.load_from_cache().await;
        Ok(cl)
    }

    async fn load_from_cache(&self) {
        let (spaces, chats) = self.get_spaces_and_chats(None).await;
        // FIXME for a lack of a better system, we just sort by room-id
        let mut space_types: Vector<Space> = spaces
            .into_iter()
            .map(|r| Space::new(self.clone(), r))
            .collect();
        space_types.sort();

        self.spaces.write().await.append(space_types);
        let mut values = join_all(chats.into_iter().map(|r| Convo::new(self.clone(), r))).await;
        values.sort();
        self.convos.write().await.append(values.into());
    }

    async fn get_spaces_and_chats(&self, filter: Option<SpaceFilter>) -> (Vec<Room>, Vec<Room>) {
        let filter = filter.unwrap_or_default();
        let client = self.core.clone();
        self.rooms()
            .into_iter()
            .filter(|room| filter.should_include(room))
            .fold(
                (Vec::new(), Vec::new()),
                move |(mut spaces, mut convos), room| {
                    if matches!(room.state(), RoomState::Left) {
                        // ignore rooms we aren't in anymore ... maybe make them available somewhere else at some point
                        return (spaces, convos);
                    }
                    let inner = Room::new(client.clone(), room);

                    if inner.is_space() {
                        spaces.push(inner);
                    } else {
                        convos.push(inner);
                    }
                    (spaces, convos)
                },
            )
    }

    async fn refresh_rooms(&self, changed_rooms: Vec<&OwnedRoomId>) {
        let update_keys = {
            let mut updated: Vec<String> = vec![];

            let mut chats = self.convos.write().await;
            let mut spaces = self.spaces.write().await;

            for r_id in changed_rooms {
                let Some(room) = self.core.client().get_room(r_id) else {
                    remove_from(&mut spaces, r_id);
                    remove_from_chat(&mut chats, r_id);
                    continue
                };

                if matches!(room.state(), RoomState::Left) {
                    // remove rooms we aren't in anymore
                    remove_from(&mut spaces, r_id);
                    remove_from_chat(&mut chats, r_id);
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

    pub async fn resolve_room_alias(&self, alias_id: OwnedRoomAliasId) -> Result<OwnedRoomId> {
        let client = self.core.client().clone();
        RUNTIME
            .spawn(async move { anyhow::Ok(client.resolve_room_alias(&alias_id).await?.room_id) })
            .await?
    }

    pub fn store(&self) -> &Store {
        self.core.store()
    }

    pub fn executor(&self) -> &Executor {
        self.core.executor()
    }

    pub async fn template_engine(&self, template: &str) -> Result<Engine> {
        let engine = self.core.template_engine(template).await?;
        Ok(engine)
    }

    pub fn start_sync(&mut self) -> SyncState {
        info!("starting sync");
        let state = self.state.clone();
        let me = self.clone();
        let executor = self.executor().clone();
        let client = self.core.client().clone();

        self.invitation_controller.add_event_handler(&client);
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
        let notifications = self.notifications.clone();

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
            let notifications = notifications.clone();

            // fetch the events that received when offline
            client
                .clone()
                .sync_with_result_callback(SyncSettings::new(), |result| async {
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

                    // device_controller.process_device_lists(&client, &response);
                    trace!("post device controller");

                    if initial.compare_exchange(true, false, Ordering::Relaxed, Ordering::Relaxed)
                        == Ok(true)
                    {
                        info!("received first sync");
                        trace!(user_id=?client.user_id(), "initial synced");
                        invitation_controller.load_invitations(&client).await;

                        initial.store(false, Ordering::SeqCst);

                        info!("issuing first sync update");
                        first_synced_arc.send(true);
                        if let Ok(mut w) = state.try_write() {
                            w.has_first_synced = true;
                        };
                        // background and keep the handle around.
                        let history_first_sync = me.refresh_history_on_start(
                            history_loading.clone(),
                            room_handles.clone(),
                        );
                        first_sync_task.set(Some(history_first_sync)); // keep task in global variable to avoid too early free of temporary varible in release build
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
                        me.refresh_rooms(changed_rooms).await;
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
                    for ev in response.notifications.into_values() {
                        for item in ev {
                            trace!("Sending notification");
                            notifications.send(item);
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

    /// Is this a guest account?
    pub fn is_guest(&self) -> bool {
        match self.state.try_read() {
            Ok(r) => r.is_guest,
            Err(e) => false,
        }
    }

    pub async fn restore_token(&self) -> Result<String> {
        let session = self.session().context("Missing session")?.clone();
        let homeurl = self.homeserver().await;
        let is_guest = match self.state.try_read() {
            Ok(r) => r.is_guest,
            Err(e) => false,
        };
        let result = serde_json::to_string(&RestoreToken {
            session: CustomAuthSession {
                user_id: session.meta().user_id.clone(),
                device_id: session.meta().device_id.clone(),
                access_token: session.access_token().to_string(),
            },
            homeurl,
            is_guest,
        })?;
        Ok(result)
    }

    // pub async fn get_mxcuri_media(&self, uri: String) -> Result<Vec<u8>> {
    //     let client = self.core.clone();
    //     RUNTIME.spawn(async move {
    //         let user_id = client.user_id().await.context("No User ID found")?;
    //         Ok(user_id.to_string())
    //     }).await?
    // }

    pub async fn upload_media(&self, uri: String) -> Result<OwnedMxcUri> {
        let client = self.core.client().clone();
        let path = PathBuf::from(uri);

        RUNTIME
            .spawn(async move {
                let guess = mime_guess::from_path(path.clone());
                let content_type = guess.first().context("MIME type should be given")?;
                let buf = std::fs::read(path).context("File should be read")?;
                let response = client.media().upload(&content_type, buf).await?;
                Ok(response.content_uri)
            })
            .await?
    }

    pub fn user_id(&self) -> Result<OwnedUserId> {
        self.core
            .client()
            .user_id()
            .context("UserId not found. Not logged in?")
            .map(|x| x.to_owned())
    }

    fn user_id_ref(&self) -> Option<&UserId> {
        self.core.client().user_id()
    }

    pub async fn room(&self, room_id_or_alias: String) -> Result<Room> {
        let id_or_alias = OwnedRoomOrAliasId::try_from(room_id_or_alias).expect("just checked");
        self.room_typed(&id_or_alias).await
    }

    pub async fn room_typed(&self, room_id_or_alias: &RoomOrAliasId) -> Result<Room> {
        if room_id_or_alias.is_room_id() {
            let room_id = OwnedRoomId::try_from(room_id_or_alias.as_str()).expect("just checked");
            return self.room_by_id_typed(&room_id).context("Room not found");
        }

        let room_alias =
            OwnedRoomAliasId::try_from(room_id_or_alias.as_str()).expect("just checked");
        self.room_by_alias_typed(&room_alias).await
    }

    pub fn room_by_id_typed(&self, room_id: &OwnedRoomId) -> Option<Room> {
        self.core
            .client()
            .get_room(room_id)
            .map(|room| Room::new(self.core.clone(), room))
    }

    pub async fn room_by_alias_typed(&self, room_alias: &OwnedRoomAliasId) -> Result<Room> {
        for r in self.core.client().rooms() {
            // looping locally first
            if let Some(con_alias) = r.canonical_alias() {
                if &con_alias == room_alias {
                    return Ok(Room::new(self.core.clone(), r));
                }
            }
            for alt_alias in r.alt_aliases() {
                if &alt_alias == room_alias {
                    return Ok(Room::new(self.core.clone(), r));
                }
            }
        }
        // nothing found, try remote:
        let response = self.core.client().resolve_room_alias(room_alias).await?;
        self.room_by_id_typed(&response.room_id)
            .context("Room not found")
    }

    pub fn notifications_stream(&self) -> impl Stream<Item = Notification> {
        let client = self.clone();
        BroadcastStream::new(self.notifications.subscribe())
            .then(move |r| {
                let client = client.clone();
                RUNTIME.spawn(async move {
                    let res = Notification::new(r?, client.clone()).await;
                    anyhow::Ok(res)
                })
            })
            .filter_map(|r| async {
                match r {
                    Ok(Ok(n)) => Some(n),
                    Ok(Err(e)) => {
                        error!(?e, "Failure in notifications stream");
                        None
                    }
                    Err(e) => {
                        error!(?e, "Failure in notifications stream processing");
                        None
                    }
                }
            })
    }

    pub fn subscribe_stream(&self, key: String) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.subscribe(key)).map(|_| true)
    }

    pub fn subscribe(&self, key: String) -> Receiver<()> {
        self.executor().subscribe(key)
    }

    pub async fn wait_for(
        &self,
        key: String,
        timeout: Option<Box<Duration>>,
    ) -> Result<AnyActerModel> {
        let executor = self.core.executor().clone();

        RUNTIME
            .spawn(async move {
                let waiter = executor.wait_for(key);
                let Some(tm) = timeout else {
                    return Ok(waiter.await?);
                };
                Ok(time::timeout(*Box::leak(tm), waiter).await??)
            })
            .await?
    }

    pub fn account(&self) -> Result<Account> {
        let account = self.core.client().account();
        let user_id = self.user_id()?;
        Ok(Account::new(account, user_id))
    }

    pub fn device_id(&self) -> Result<OwnedDeviceId> {
        let device_id = self
            .core
            .client()
            .device_id()
            .context("No Device ID found")?
            .to_owned();
        Ok(device_id)
    }

    pub fn get_user_profile(&self) -> Result<UserProfile> {
        let client = self.core.client();
        let user_id = client
            .user_id()
            .context("Couldn't get user id from client")?
            .to_owned();
        Ok(UserProfile::from_account(client.account(), user_id))
    }

    pub async fn verified_device(&self, dev_id: String) -> Result<bool> {
        let c = self.core.client().clone();
        let user_id = self.user_id()?;
        RUNTIME
            .spawn(async move {
                let dev = c
                    .encryption()
                    .get_device(&user_id, device_id!(dev_id.as_str()))
                    .await?
                    .context("client should get device")?;
                Ok(dev.is_verified())
            })
            .await?
    }

    pub async fn logout(&mut self) -> Result<bool> {
        match self.state.try_write() {
            Ok(mut w) => {
                w.should_stop_syncing = true;
            }
            Err(e) => {}
        }
        let client = self.core.client().clone();

        self.invitation_controller.remove_event_handler(&client);
        self.verification_controller
            .remove_to_device_event_handler(&client);
        self.verification_controller
            .remove_sync_event_handler(&client);
        self.typing_controller.remove_event_handler(&client);
        self.receipt_controller.remove_event_handler(&client);

        RUNTIME
            .spawn(async move {
                match client.matrix_auth().logout().await {
                    Ok(resp) => Ok(true),
                    Err(e) => {
                        error!("logout error: {:?}", e);
                        Ok(false)
                    }
                }
            })
            .await?
    }
}
