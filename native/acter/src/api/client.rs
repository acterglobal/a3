use acter_core::{
    client::CoreClient, executor::Executor, models::AnyActerModel, spaces::is_acter_space,
    store::Store, templates::Engine, RestoreToken,
};
use anyhow::{Context, Result};
use core::time::Duration;
use derive_builder::Builder;
use futures::{
    future::{join_all, ready},
    pin_mut, stream, Stream, StreamExt,
};
use futures_signals::signal::{
    channel, Mutable, MutableSignalCloned, Receiver, SignalExt, SignalStream,
};
use matrix_sdk::{
    config::SyncSettings,
    event_handler::{Ctx, EventHandlerHandle},
    media::{MediaFormat, MediaRequest},
    room::Room as SdkRoom,
    Client as SdkClient, LoopCtrl, RumaApiError,
};
use ruma::{
    device_id, events::room::MediaSource, OwnedDeviceId, OwnedRoomId, OwnedRoomOrAliasId,
    OwnedServerName, OwnedUserId, RoomId, UserId,
};
use std::{
    collections::{BTreeMap, HashMap},
    ops::Deref,
    sync::{
        atomic::{AtomicBool, Ordering},
        Arc,
    },
};
use tokio::{
    sync::{Mutex, RwLock},
    task::JoinHandle,
};
use tracing::{error, info, trace, warn};

use super::{
    account::Account,
    api::FfiBuffer,
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
use crate::FileDesc;

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
    pub fn should_include(&self, room: &matrix_sdk::room::Room) -> bool {
        match room {
            matrix_sdk::room::Room::Joined(_) => self.include_joined,
            matrix_sdk::room::Room::Left(_) => self.include_left,
            matrix_sdk::room::Room::Invited(_) => self.include_invited,
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

pub(crate) async fn devide_spaces_from_convos(
    client: Client,
    filter: Option<SpaceFilter>,
) -> (Vec<Space>, Vec<Conversation>) {
    let filter = filter.unwrap_or_default();
    let (spaces, convos, _) = stream::iter(client.clone().rooms().into_iter())
        .filter(|room| ready(filter.should_include(room)))
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
pub struct SyncState {
    handle: Mutable<Option<JoinHandle<()>>>,
    history_sync_handle: Mutable<Option<JoinHandle<Result<()>>>>,
    first_synced_rx: Arc<Mutex<Option<Receiver<bool>>>>,
    history_loading: Mutable<HistoryLoadState>,
    room_handles: RoomHandlers,
}

impl SyncState {
    pub fn new(first_synced_rx: Receiver<bool>) -> Self {
        let first_synced_rx = Arc::new(Mutex::new(Some(first_synced_rx)));
        Self {
            first_synced_rx,
            history_loading: Default::default(),
            history_sync_handle: Default::default(),
            handle: Default::default(),
            room_handles: Default::default(),
        }
    }

    pub fn first_synced_rx(&self) -> Option<SignalStream<Receiver<bool>>> {
        match self.first_synced_rx.try_lock() {
            Ok(mut l) => l.take().map(|t| t.to_stream()),
            Err(e) => None,
        }
    }

    // FIXE: This is not save. History state is copied and thus not all known_spaces are tracked
    pub fn get_history_loading_rx(&self) -> SignalStream<MutableSignalCloned<HistoryLoadState>> {
        self.history_loading.signal_cloned().to_stream()
    }

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

// internal API
impl Client {
    async fn refresh_history_on_start(
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

            join_all(spaces.iter_mut().map(|space| async {
                if !space.is_acter_space().await {
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

        join_all(
            new_spaces
                .into_iter()
                .map(|room| Space::new(self.clone(), Room { room }))
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
        RUNTIME
            .spawn(async move {
                let buf = client.media().get_media_content(&request, false).await?;
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
        let server_names: Vec<OwnedServerName> = server_names
            .into_iter()
            .map(OwnedServerName::try_from)
            .collect::<Result<Vec<OwnedServerName>, ruma::IdParseError>>()?;
        let c = self.clone();
        RUNTIME
            .spawn(async move {
                let joined = c
                    .join_room_by_id_or_alias(alias.as_ref(), server_names.as_slice())
                    .await?;
                Ok(Room {
                    room: joined.into(),
                })
            })
            .await?
    }
}

// external API
impl Client {
    pub async fn new(client: SdkClient, state: ClientState) -> Result<Self> {
        let core = CoreClient::new(client).await?;
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
        let sync_state_history_sync_handle = sync_state.history_sync_handle.clone();
        let room_handles = sync_state.room_handles.clone();

        let handle = RUNTIME.spawn(async move {
            info!("spawning sync callback");
            let client = client.clone();
            let state = state.clone();

            let mut invitation_controller = invitation_controller.clone();
            let mut device_controller = device_controller.clone();
            let mut conversation_controller = conversation_controller.clone();

            let sync_state_history = sync_state_history.clone();
            let sync_state_history_sync_handle = sync_state_history_sync_handle.clone();
            let room_handles = room_handles.clone();

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
                    let mut conversation_controller = conversation_controller.clone();

                    let first_synced_arc = first_synced_arc.clone();
                    let sync_state_history = sync_state_history.clone();
                    let initial = initial_arc.clone();

                    let response = match result {
                        Ok(response) => response,
                        Err(err) => {
                            if let Some(RumaApiError::ClientApi(e)) = err.as_ruma_api_error() {
                                error!(?e, "Client error");
                                return Ok(LoopCtrl::Break);
                            }
                            error!(?err, "Other error, continuing");
                            return Ok(LoopCtrl::Continue);
                        }
                    };
                    trace!(target: "acter::sync_response::full", "sync response: {:#?}", response);

                    device_controller.process_device_lists(&client, &response);
                    trace!("post device controller");

                    if initial.compare_exchange(true, false, Ordering::Relaxed, Ordering::Relaxed)
                        == Ok(true)
                    {
                        info!("received first sync");
                        trace!(user_id=?client.user_id(), "initial synced");
                        let filter = SpaceFilterBuilder::default()
                            .build()
                            .expect("Builder SpaceFilter doesn't fail");
                        // divide_spaces_from_convos must be called after first sync
                        let (spaces, convos) =
                            devide_spaces_from_convos(me.clone(), Some(filter)).await;
                        conversation_controller.load_rooms(&convos).await;
                        // load invitations after first sync
                        invitation_controller.load_invitations(&client).await;

                        initial.store(false, Ordering::SeqCst);

                        info!("issuing first sync update");
                        first_synced_arc.send(true);
                        if let Ok(mut w) = state.try_write() {
                            w.has_first_synced = true;
                        };
                        // background and keep the handle around.
                        let history_first_sync = me
                            .refresh_history_on_start(sync_state_history.clone(), room_handles.clone())
                            .await;
                        sync_state_history_sync_handle.set(Some(history_first_sync));
                    } else {
                        // see if we have new spaces to catch up upon
                        let mut new_spaces = Vec::new();
                        for room_id in response.rooms.join.keys() {
                            if sync_state_history.lock_mut().knows_room(room_id) {
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
                            me.refresh_history_on_way(sync_state_history.clone(), room_handles.clone(), new_spaces)
                                .await;
                        }
                    }

                    let mut changed_rooms = response
                        .rooms
                        .join
                        .keys()
                        .chain(response.rooms.leave.keys())
                        .chain(response.rooms.invite.keys())
                        .map(|id| id.to_string()) // FIXME: handle aliases, too?!?
                        .collect::<Vec<_>>();

                    if (!changed_rooms.is_empty()) {
                        changed_rooms.push("SPACES".to_owned());
                        me.executor().notify(changed_rooms);
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
        let filter = SpaceFilterBuilder::default().build()?;
        RUNTIME
            .spawn(async move {
                let (spaces, conversations) = devide_spaces_from_convos(client, Some(filter)).await;
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
            .context("UserId not found. Not logged in?")
            .map(|x| x.to_owned())
    }

    fn user_id_ref(&self) -> Option<&UserId> {
        self.core.client().user_id()
    }

    pub(crate) fn room(&self, room_name: String) -> Result<Room> {
        let room_id = RoomId::parse(room_name)?;
        self.core
            .client()
            .get_room(&room_id)
            .context("Room not found")
            .map(|room| Room { room })
    }

    pub fn subscribe(&self, key: String) -> async_broadcast::Receiver<()> {
        self.executor().subscribe(key)
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
        self.conversation_controller.remove_event_handler(&client);

        RUNTIME
            .spawn(async move {
                match client.logout().await {
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
