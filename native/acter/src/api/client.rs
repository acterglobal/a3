use acter_core::{
    client::CoreClient, executor::Executor, models::AnyActerModel, spaces::is_acter_space,
    store::Store, templates::Engine, RestoreToken,
};
use anyhow::{Context, Result};
use core::time::Duration;
use derive_builder::Builder;
use futures::{future::join_all, pin_mut, stream, Stream, StreamExt};
use futures_signals::signal::{
    channel, Mutable, MutableSignalCloned, Receiver, SignalExt, SignalStream,
};
use log::info;
use matrix_sdk::{
    config::SyncSettings,
    locks::{Mutex, RwLock},
    room::Room as MatrixRoom,
    ruma::{device_id, OwnedDeviceId, OwnedRoomId, OwnedUserId, RoomId, UserId},
    Client as MatrixClient, LoopCtrl, RumaApiError,
};
use std::{
    collections::BTreeMap,
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc,
    },
};
use tokio::task::JoinHandle;

use super::{
    account::Account,
    conversation::{Conversation, ConversationController},
    device::DeviceController,
    invitation::InvitationController,
    profile::UserProfile,
    receipt::ReceiptController,
    room::Room,
    spaces::Space,
    typing::TypingController,
    verification::VerificationController,
    RUNTIME,
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
    pub(crate) conversation_controller: ConversationController,
}

impl std::ops::Deref for Client {
    type Target = MatrixClient;
    fn deref(&self) -> &MatrixClient {
        self.core.client()
    }
}

pub(crate) async fn devide_spaces_from_convos(client: Client) -> (Vec<Space>, Vec<Conversation>) {
    let (spaces, convos, _) = stream::iter(client.clone().rooms().into_iter())
        .fold(
            (Vec::new(), Vec::new(), client),
            async move |(mut spaces, mut conversations, client), room| {
                let inner = Room { room: room.clone() };

                if inner.is_space() {
                    spaces.push(Space::new(client.clone(), inner));
                } else {
                    conversations.push(Conversation::new(inner));
                }

                (spaces, conversations, client)
            },
        )
        .await;
    (spaces, convos)
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
        tracing::trace!(?known_spaces, "Starting History loading");
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
        tracing::trace!(?room_id, loading = value, "Setting room for loading");
        self.known_spaces.insert(room_id, value).unwrap_or_default()
    }

    pub fn total_spaces(&self) -> usize {
        self.known_spaces.len()
    }
}

#[derive(Clone)]
pub struct SyncState {
    handle: Mutable<Option<JoinHandle<()>>>,
    first_synced_rx: Arc<Mutex<Option<Receiver<bool>>>>,
    history_loading: Mutable<HistoryLoadState>,
}

impl SyncState {
    pub fn new(first_synced_rx: Receiver<bool>) -> Self {
        let first_synced_rx = Arc::new(Mutex::new(Some(first_synced_rx)));
        Self {
            first_synced_rx,
            history_loading: Default::default(),
            handle: Default::default(),
        }
    }

    pub fn first_synced_rx(&self) -> Option<SignalStream<Receiver<bool>>> {
        match self.first_synced_rx.try_lock() {
            Ok(mut l) => l.take().map(|t| t.to_stream()),
            Err(e) => None,
        }
    }

    pub fn get_history_loading_rx(&self) -> SignalStream<MutableSignalCloned<HistoryLoadState>> {
        self.history_loading.signal_cloned().to_stream()
    }

    pub async fn await_has_synced_history(&self) -> Result<u32> {
        tracing::trace!("Waiting for history to sync");
        let signal = self.history_loading.signal_cloned().to_stream();
        pin_mut!(signal);
        while let Some(next_state) = signal.next().await {
            tracing::trace!(?next_state, "History updated");
            if next_state.is_done_loading() {
                tracing::trace!(?next_state, "History sync completed");
                return Ok(next_state.total_spaces() as u32);
            }
        }
        unimplemented!("We never reach this state")
    }

    pub fn is_running(&self) -> bool {
        if let Some(handle) = self.handle.lock_ref().as_ref() {
            !handle.is_finished()
        } else {
            false
        }
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

impl Client {
    pub async fn new(client: MatrixClient, state: ClientState) -> Result<Self> {
        let core = CoreClient::new(client)
            .await
            .context("Couldn't create core client")?;
        let cl = Client {
            core,
            state: Arc::new(RwLock::new(state)),
            invitation_controller: InvitationController::new(),
            verification_controller: VerificationController::new(),
            device_controller: DeviceController::new(),
            typing_controller: TypingController::new(),
            receipt_controller: ReceiptController::new(),
            conversation_controller: ConversationController::new(),
        };
        Ok(cl)
    }

    pub fn store(&self) -> &Store {
        self.core.store()
    }

    pub fn executor(&self) -> &Executor {
        self.core.executor()
    }

    pub async fn template_engine(&self, template: &str) -> Result<Engine> {
        let engine = self
            .core
            .template_engine(template)
            .await
            .context("Couldn't set up template engine")?;
        Ok(engine)
    }

    fn refresh_history_on_start(&self, history: Mutable<HistoryLoadState>) {
        let me = self.clone();
        RUNTIME.spawn(async move {
            tracing::trace!(user_id=?me.user_id_ref(), "refreshing history");
            let spaces = me
                .spaces()
                .await
                .context("Couldn't get spaces from client")?;
            let space_ids = spaces.iter().map(|r| r.room_id().to_owned()).collect();
            history.lock_mut().start(space_ids);

            join_all(spaces.iter().map(|g| async {
                if !g.is_acter_space().await {
                    tracing::trace!(room_id=?g.room_id(), "not an acter space");
                    history.lock_mut().unknow_room(&g.room_id().to_owned());
                    return;
                }

                g.add_handlers().await;

                if let Err(err) = g.refresh_history().await {
                    tracing::error!(?err, room_id=?g.room_id(),  "Loading space history failed");
                };
                history
                    .lock_mut()
                    .set_loading(g.room_id().to_owned(), false);
            }))
            .await;
            anyhow::Ok(())
        });
    }

    fn refresh_history_on_way(
        &self,
        history: Mutable<HistoryLoadState>,
        new_spaces: Vec<MatrixRoom>,
    ) {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                tracing::trace!(user_id=?me.user_id_ref(), count=?new_spaces.len(), "found new spaces");

                join_all(
                    new_spaces
                        .into_iter()
                        .map(|room| Space::new(me.clone(), Room { room }))
                        .map(|g| {
                            let history = history.clone();
                            async move {
                                {
                                    let room_id = g.room_id().to_owned();
                                    let mut history = history.lock_mut();
                                    if history.is_loading(&room_id) {
                                        tracing::trace!(room_id=?room_id, "Already loading room.");
                                        return;
                                    }
                                    history.set_loading(room_id, true);
                                }
                                g.add_handlers().await;
                                if let Err(err) = g.refresh_history().await {
                                    tracing::error!(?err, room_id=?g.room_id(), "refreshing history failed");
                                }
                                history.lock_mut().set_loading(g.room_id().to_owned(), false);
                            }
                        }
                    ),
                )
                .await;
                anyhow::Ok(())
            }
        );
    }

    pub fn start_sync(&mut self) -> SyncState {
        let state = self.state.clone();
        let me = self.clone();
        let executor = self.executor().clone();
        let client = self.core.client().clone();

        self.invitation_controller.add_event_handler(&client);
        self.typing_controller.add_event_handler(&client);
        self.receipt_controller.add_event_handler(&client);
        self.conversation_controller.add_event_handler(&client);

        self.verification_controller
            .add_to_device_event_handler(&client);
        // sync event is the event that my device was off so it may be timed out possibly
        // in fact, when user opens app, he sees old verification popup sometimes
        // in order to avoid this issue, comment out sync event
        // self.verification_controller.add_sync_event_handler(&client);

        let mut invitation_controller = self.invitation_controller.clone();
        let mut device_controller = self.device_controller.clone();
        let mut conversation_controller = self.conversation_controller.clone();

        let (first_synced_tx, first_synced_rx) = channel(false);
        let first_synced_arc = Arc::new(first_synced_tx);

        let initial_arc = Arc::new(AtomicBool::from(true));
        let sync_state = SyncState::new(first_synced_rx);
        let sync_state_history = sync_state.history_loading.clone();

        let handle = RUNTIME.spawn(async move {
            let client = client.clone();
            let state = state.clone();

            let mut invitation_controller = invitation_controller.clone();
            let mut device_controller = device_controller.clone();
            let mut conversation_controller = conversation_controller.clone();

            let sync_state_history = sync_state_history.clone();

            // fetch the events that received when offline
            client
                .clone()
                .sync_with_result_callback(SyncSettings::new(), |result| async {
                    let client = client.clone();
                    let me = me.clone();
                    let executor = executor.clone();
                    let state = state.clone();

                    let mut invitation_controller = invitation_controller.clone();
                    let mut device_controller = device_controller.clone();
                    let mut conversation_controller = conversation_controller.clone();

                    let first_synced_arc = first_synced_arc.clone();
                    let sync_state_history = sync_state_history.clone();
                    let initial = initial_arc.clone();

                    let response = match result {
                        Ok(response) => response,
                        Err(err) => {
                            if let Some(RumaApiError::ClientApi(e)) = err.as_ruma_api_error() {
                                tracing::warn!(?e, "Client error");
                                return Ok(LoopCtrl::Break);
                            }
                            tracing::warn!(?err, "Other error, continuing");
                            return Ok(LoopCtrl::Continue);
                        }
                    };

                    device_controller.process_device_lists(&client, &response);
                    tracing::trace!("post device controller");

                    if initial.compare_exchange(true, false, Ordering::Relaxed, Ordering::Relaxed)
                        == Ok(true)
                    {
                        tracing::trace!(user_id=?client.user_id(), "initial synced");
                        // divide_spaces_from_convos must be called after first sync
                        let (spaces, convos) = devide_spaces_from_convos(me.clone()).await;
                        conversation_controller.load_rooms(&convos).await;
                        // load invitations after first sync
                        invitation_controller.load_invitations(&client).await;

                        me.refresh_history_on_start(sync_state_history.clone());

                        initial.store(false, Ordering::SeqCst);
                        first_synced_arc.send(true);
                        if let Ok(mut w) = state.try_write() {
                            w.has_first_synced = true;
                        }
                    } else {
                        // see if we have new spaces to catch up upon
                        let mut new_spaces = Vec::new();
                        for (room_id, room) in response.rooms.join {
                            if sync_state_history.lock_mut().knows_room(&room_id) {
                                // we are already loading this room
                                continue;
                            }
                            let Some(full_room) = me.get_room(&room_id) else {
                                tracing::warn!("room not found. how can that be?");
                                continue;
                            };
                            if is_acter_space(&full_room).await {
                                new_spaces.push(full_room);
                            }
                        }

                        if !new_spaces.is_empty() {
                            me.refresh_history_on_way(sync_state_history.clone(), new_spaces);
                        }
                    }

                    if let Ok(mut w) = state.try_write() {
                        if w.should_stop_syncing {
                            w.is_syncing = false;
                            tracing::trace!("Stopping syncing upon user request");
                            return Ok(LoopCtrl::Break);
                        }
                    }
                    if let Ok(mut w) = state.try_write() {
                        if !w.is_syncing {
                            w.is_syncing = true;
                        }
                    }

                    tracing::trace!("ready for the next round");
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
            session,
            homeurl,
            is_guest,
        })?;
        Ok(result)
    }

    pub async fn conversations(&self) -> Result<Vec<Conversation>> {
        let client = self.clone();
        RUNTIME
            .spawn(async move {
                let (spaces, conversations) = devide_spaces_from_convos(client).await;
                Ok(conversations)
            })
            .await?
    }

    // pub async fn get_mxcuri_media(&self, uri: String) -> Result<Vec<u8>> {
    //     let client = self.core.clone();
    //     RUNTIME.spawn(async move {
    //         let user_id = client.user_id().await.context("No User ID found")?;
    //         Ok(user_id.to_string())
    //     }).await?
    // }

    pub fn user_id(&self) -> Result<OwnedUserId> {
        self.core
            .client()
            .user_id()
            .map(|x| x.to_owned())
            .context("UserId not found. Not logged in?")
    }

    fn user_id_ref(&self) -> Option<&UserId> {
        self.core.client().user_id()
    }

    pub(crate) fn room(&self, room_name: String) -> Result<Room> {
        let room_id = RoomId::parse(room_name)?;
        self.core
            .client()
            .get_room(&room_id)
            .map(|room| Room { room })
            .context("Room not found")
    }

    pub fn subscribe(&self, key: String) -> impl Stream<Item = bool> {
        self.executor().subscribe(key).map(|()| true)
    }

    pub(crate) async fn wait_for(
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
                Ok(tokio::time::timeout(*Box::leak(tm), waiter).await??)
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
            .context("No Device ID found")?;
        Ok(device_id.to_owned())
    }

    pub fn get_user_profile(&self) -> Result<UserProfile> {
        let client = self.core.client().clone();
        let user_id = self.user_id()?;
        Ok(UserProfile::new(client, user_id))
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
        self.conversation_controller.remove_event_handler(&client);

        RUNTIME
            .spawn(async move {
                match client.logout().await {
                    Ok(resp) => Ok(true),
                    Err(e) => {
                        info!("logout error: {:?}", e);
                        Ok(false)
                    }
                }
            })
            .await?
    }
}
