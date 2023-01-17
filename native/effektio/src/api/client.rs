use anyhow::{bail, Context, Result};
use core::time::Duration;
use derive_builder::Builder;
use effektio_core::{
    executor::Executor,
    models::{AnyEffektioModel, Faq},
    statics::{PURPOSE_FIELD, PURPOSE_FIELD_DEV, PURPOSE_TEAM_VALUE},
    store::Store,
    RestoreToken,
};

#[cfg(feature = "with-mocks")]
use effektio_core::mocks::gen_mock_faqs;

use futures::{future::try_join_all, pin_mut, stream, Stream, StreamExt};
use futures_signals::signal::{
    channel, Mutable, MutableSignalCloned, Receiver, SignalExt, SignalStream,
};
use log::info;
use matrix_sdk::{
    config::SyncSettings,
    ruma::{api::client::error::ErrorKind, device_id, OwnedUserId, RoomId},
    Client as MatrixClient, Error, HttpError, LoopCtrl, RefreshTokenError, RumaApiError,
};
use parking_lot::{Mutex, RwLock};
use std::sync::{
    atomic::{AtomicBool, Ordering},
    Arc,
};
use tokio::task::JoinHandle;

use super::{
    account::Account,
    api::FfiBuffer,
    conversation::{Conversation, ConversationController},
    device::DeviceController,
    group::Group,
    invitation::InvitationController,
    profile::UserProfile,
    receipt::ReceiptController,
    room::Room,
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
    pub(crate) client: MatrixClient,
    pub(crate) store: Store,
    pub(crate) executor: Executor,
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
        &self.client
    }
}

pub(crate) async fn devide_groups_from_convos(client: Client) -> (Vec<Group>, Vec<Conversation>) {
    let (groups, convos, _) = stream::iter(client.clone().rooms().into_iter())
        .fold(
            (Vec::new(), Vec::new(), client),
            async move |(mut groups, mut conversations, client), room| {
                let inner = Room {
                    room: room.clone(),
                    client: client.client.clone(),
                };

                if inner.is_effektio_group().await {
                    groups.push(Group {
                        client: client.clone(),
                        inner,
                    });
                } else {
                    conversations.push(Conversation::new(inner));
                }

                (groups, conversations, client)
            },
        )
        .await;
    (groups, convos)
}

#[derive(Clone, Debug, Default)]
pub struct HistoryLoadState {
    pub has_started: bool,
    pub total_groups: usize,
    pub loaded_groups: usize,
}

impl HistoryLoadState {
    pub fn is_done_loading(&self) -> bool {
        self.has_started && self.total_groups == self.loaded_groups
    }

    pub fn start(&mut self, total: usize) {
        self.has_started = true;
        self.total_groups = total;
    }

    fn group_loaded(&mut self) {
        self.loaded_groups = self.loaded_groups.checked_add(1).unwrap_or(usize::MAX)
    }
}

#[derive(Clone)]
pub struct SyncState {
    handle: Mutable<Option<JoinHandle<()>>>,
    first_synced_rx: Arc<Mutex<Option<Receiver<bool>>>>,
    history_loading: futures_signals::signal::Mutable<HistoryLoadState>,
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
        self.first_synced_rx.lock().take().map(|t| t.to_stream())
    }

    pub fn get_history_loading_rx(&self) -> SignalStream<MutableSignalCloned<HistoryLoadState>> {
        self.history_loading.signal_cloned().to_stream()
    }

    pub async fn await_has_synced_history(&self) -> Result<u32> {
        tracing::trace!("Waiting for history to sync");
        let signal = self.history_loading.signal_cloned().to_stream();
        pin_mut!(signal);
        while let Some(next_state) = signal.next().await {
            if next_state.is_done_loading() {
                tracing::trace!(?next_state, "History sync completed");
                return Ok(next_state.loaded_groups as u32);
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
    fn user_id_ref(&self) -> Option<&matrix_sdk::ruma::UserId> {
        self.client.user_id()
    }
}

impl Client {
    pub async fn new(client: MatrixClient, state: ClientState) -> Result<Self> {
        let store = Store::new(client.clone()).await?;
        let executor = Executor::new(store.clone()).await?;
        client.add_event_handler_context(executor.clone());
        let cl = Client {
            client,
            store,
            executor,
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
        &self.store
    }

    /// Get access to the internal state
    pub fn executor(&self) -> &Executor {
        &self.executor
    }

    async fn refresh_history(
        &self,
        history: futures_signals::signal::Mutable<HistoryLoadState>,
    ) -> Result<()> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                tracing::trace!(user_id=?me.user_id_ref(), "refreshing history");
                let groups = me.groups().await?;
                history.lock_mut().start(groups.len());

                try_join_all(groups.iter().map(|g| async {
                    g.add_handlers().await;
                    let x = g.refresh_history().await;
                    history.lock_mut().group_loaded();
                    x
                }))
                .await?;
                Ok(())
            })
            .await?
    }

    fn refresh_history_on_start(
        &self,
        history: futures_signals::signal::Mutable<HistoryLoadState>,
    ) {
        let me = self.clone();
        RUNTIME.spawn(async move {
            if let Err(e) = me.refresh_history(history).await {
                tracing::error!("Refreshing history failed: {:}", e);
            }
        });
    }

    pub fn start_sync(&mut self) -> SyncState {
        let state = self.state.clone();
        let me = self.clone();
        let executor = self.executor.clone();
        let client = self.client.clone();

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
                .sync_with_result_callback(SyncSettings::new(), |result| {
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

                    async move {
                        Ok(if let Ok(response) = result {
                            device_controller.process_device_lists(&client, &response);

                            if initial.compare_exchange(
                                true,
                                false,
                                Ordering::Relaxed,
                                Ordering::Relaxed,
                            ) == Ok(true)
                            {
                                tracing::trace!(user_id=?client.user_id(), "initial synced");
                                // devide_groups_from_convos must be called after first sync
                                let (_, convos) = devide_groups_from_convos(me.clone()).await;
                                conversation_controller.load_rooms(&convos).await;
                                // load invitations after first sync
                                invitation_controller.load_invitations(&client).await;

                                me.refresh_history_on_start(sync_state_history.clone());

                                initial.store(false, Ordering::SeqCst);
                                let _ = first_synced_arc.send(true);
                                state.write().has_first_synced = true;
                            }

                            if state.read().should_stop_syncing {
                                state.write().is_syncing = false;
                                return Ok(LoopCtrl::Break);
                            } else if !state.read().is_syncing {
                                state.write().is_syncing = true;
                            }
                            LoopCtrl::Continue
                        } else {
                            let mut control = LoopCtrl::Continue;
                            if let Some(err) = result.err() {
                                if let Some(RumaApiError::ClientApi(e)) = err.as_ruma_api_error() {
                                    control = LoopCtrl::Break;
                                }
                            }
                            control
                        })
                    }
                })
                .await
                .unwrap();
        });
        sync_state.handle.set(Some(handle));
        sync_state
    }

    /// Indication whether we've received a first sync response since
    /// establishing the client (in memory)
    pub fn has_first_synced(&self) -> bool {
        self.state.read().has_first_synced
    }

    /// Indication whether we are currently syncing
    pub fn is_syncing(&self) -> bool {
        self.state.read().is_syncing
    }

    /// Is this a guest account?
    pub fn is_guest(&self) -> bool {
        self.state.read().is_guest
    }

    pub async fn restore_token(&self) -> Result<String> {
        let session = self.client.session().context("Missing session")?.clone();
        let homeurl = self.client.homeserver().await;
        let result = serde_json::to_string(&RestoreToken {
            session,
            homeurl,
            is_guest: self.state.read().is_guest,
        })?;
        Ok(result)
    }

    pub async fn conversations(&self) -> Result<Vec<Conversation>> {
        let client = self.clone();
        RUNTIME
            .spawn(async move {
                let (groups, conversations) = devide_groups_from_convos(client).await;
                Ok(conversations)
            })
            .await?
    }

    #[cfg(feature = "with-mocks")]
    pub async fn faqs(&self) -> Result<Vec<Faq>> {
        Ok(gen_mock_faqs())
    }

    // pub async fn get_mxcuri_media(&self, uri: String) -> Result<Vec<u8>> {
    //     let client = self.client.clone();
    //     RUNTIME.spawn(async move {
    //         let user_id = client.user_id().await.context("No User ID found")?;
    //         Ok(user_id.to_string())
    //     }).await?
    // }

    pub fn user_id(&self) -> Result<OwnedUserId> {
        self.client
            .user_id()
            .map(|x| x.to_owned())
            .context("UserId not found. Not logged in?")
    }

    pub async fn room(&self, room_name: String) -> Result<Room> {
        let room_id = RoomId::parse(room_name)?;
        let l = self.client.clone();
        RUNTIME
            .spawn(async move {
                if let Some(room) = l.get_room(&room_id) {
                    return Ok(Room {
                        room,
                        client: l.clone(),
                    });
                }
                bail!("Room not found")
            })
            .await?
    }

    pub fn subscribe(&self, key: String) -> impl Stream<Item = bool> {
        self.executor().subscribe(key).map(|()| true)
    }

    pub(crate) async fn wait_for(
        &self,
        key: String,
        timeout: Option<Box<Duration>>,
    ) -> Result<AnyEffektioModel> {
        let executor = self.executor.clone();

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
        Ok(Account::new(
            self.client.account(),
            self.user_id()?.to_string(),
        ))
    }

    pub fn device_id(&self) -> Result<String> {
        let device_id = self.client.device_id().context("No Device ID found")?;
        Ok(device_id.to_string())
    }

    pub async fn get_user_profile(&self) -> Result<UserProfile> {
        let client = self.client.clone();
        let user_id = client.user_id().unwrap().to_owned();
        RUNTIME
            .spawn(async move {
                let mut user_profile = UserProfile::new(client, user_id, None, None);
                user_profile.fetch().await;
                Ok(user_profile)
            })
            .await?
    }

    pub async fn verified_device(&self, dev_id: String) -> Result<bool> {
        let c = self.client.clone();
        RUNTIME
            .spawn(async move {
                let user_id = c.user_id().expect("guest user cannot request verification");
                let dev = c
                    .encryption()
                    .get_device(user_id, device_id!(dev_id.as_str()))
                    .await
                    .expect("client should get device")
                    .unwrap();
                Ok(dev.is_verified())
            })
            .await?
    }

    pub async fn logout(&mut self) -> Result<bool> {
        (*self.state).write().should_stop_syncing = true;
        let client = self.client.clone();

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
