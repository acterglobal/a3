use anyhow::{bail, Context, Result};
use derive_builder::Builder;
use effektio_core::{
    executor::Executor,
    models::Faq,
    statics::{PURPOSE_FIELD, PURPOSE_FIELD_DEV, PURPOSE_TEAM_VALUE},
    store::Store,
    RestoreToken,
};

#[cfg(feature = "with-mocks")]
use effektio_core::mocks::gen_mock_faqs;
use futures::{future::try_join_all, stream, StreamExt};
use futures_signals::signal::{
    channel, MutableSignalCloned, Receiver as SignalReceiver, SignalExt, SignalStream,
};
use log::info;
use matrix_sdk::{
    config::SyncSettings,
    event_handler::Ctx,
    locks::RwLock as MatrixRwLock,
    room::Room as MatrixRoom,
    ruma::{
        device_id,
        events::{
            receipt::ReceiptEventContent, typing::TypingEventContent, SyncEphemeralRoomEvent,
        },
        OwnedUserId, RoomId,
    },
    Client as MatrixClient, LoopCtrl,
};
use parking_lot::{Mutex, RwLock};
use std::sync::{
    atomic::{AtomicBool, Ordering},
    Arc,
};

use super::{
    account::Account,
    api::FfiBuffer,
    conversation::{Conversation, ConversationController},
    device::DeviceController,
    group::Group,
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

pub(crate) async fn devide_groups_from_common(
    client: MatrixClient,
    executor: Executor,
) -> (Vec<Group>, Vec<Conversation>) {
    let (groups, convos, _) = stream::iter(client.clone().rooms().into_iter())
        .fold(
            (Vec::new(), Vec::new(), (client, executor)),
            async move |(mut groups, mut conversations, (client, executor)), room| {
                let inner = Room {
                    room: room.clone(),
                    client: client.clone(),
                };

                if inner.is_effektio_group().await {
                    groups.push(Group {
                        executor: executor.clone(),
                        inner,
                    });
                } else {
                    conversations.push(Conversation::new(inner));
                }

                (groups, conversations, (client, executor))
            },
        )
        .await;
    (groups, convos)
}

#[derive(Clone, Debug, Default)]
pub struct HistoryLoadState {
    pub total_groups: usize,
    pub loaded_groups: usize,
}

impl HistoryLoadState {
    pub fn is_done_loading(&self) -> bool {
        self.total_groups <= self.loaded_groups
    }

    fn group_loaded(&mut self) {
        self.loaded_groups = self.loaded_groups.checked_add(1).unwrap_or(usize::MAX)
    }
}

#[derive(Clone)]
pub struct SyncState {
    first_synced_rx: Arc<Mutex<Option<SignalReceiver<bool>>>>,
    history_loading: futures_signals::signal::Mutable<HistoryLoadState>,
}

impl SyncState {
    pub fn new(first_synced_rx: SignalReceiver<bool>) -> Self {
        let first_synced_rx = Arc::new(Mutex::new(Some(first_synced_rx)));
        Self {
            first_synced_rx,
            history_loading: Default::default(),
        }
    }

    pub fn first_synced_rx(&self) -> Option<SignalStream<SignalReceiver<bool>>> {
        self.first_synced_rx.lock().take().map(|t| t.to_stream())
    }

    pub fn get_history_loading_rx(&self) -> SignalStream<MutableSignalCloned<HistoryLoadState>> {
        self.history_loading.signal_cloned().to_stream()
    }
}

impl Client {
    pub async fn new(client: MatrixClient, state: ClientState) -> anyhow::Result<Self> {
        let store = Store::new(client.clone()).await?;
        let executor = Executor::new(client.clone(), store.clone()).await?;
        let cl = Client {
            client,
            executor,
            store,
            state: Arc::new(RwLock::new(state)),
            verification_controller: VerificationController::new(),
            device_controller: DeviceController::new(),
            typing_controller: TypingController::new(),
            receipt_controller: ReceiptController::new(),
            conversation_controller: ConversationController::new(),
        };

        cl.init_tasks().await;
        Ok(cl)
    }

    /// Get access to the internal state
    pub fn executor(&self) -> &Executor {
        &self.executor
    }

    async fn refresh_history(
        &self,
        history: futures_signals::signal::Mutable<HistoryLoadState>,
    ) -> anyhow::Result<()> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let groups = me.groups().await?;
                history.lock_mut().total_groups = groups.len();

                try_join_all(groups.iter().map(|g| g.refresh_history())).await?;
                Ok(())
            })
            .await?
    }

    async fn refresh_history_on_start(
        &self,
        history: futures_signals::signal::Mutable<HistoryLoadState>,
    ) {
        if let Err(e) = self.refresh_history(history).await {
            tracing::error!("Refreshing history failed: {:}", e);
        }
    }

    pub fn start_sync(&self) -> SyncState {
        let me = self.clone();
        let executor = self.executor.clone();
        let client = self.client.clone();
        let state = self.state.clone();
        let verification_controller = self.verification_controller.clone();
        let device_controller = self.device_controller.clone();
        self.typing_controller.setup(&client);
        self.receipt_controller.setup(&client);
        let conversation_controller = self.conversation_controller.clone();

        let (first_synced_tx, first_synced_rx) = channel(false);
        let first_synced_arc = Arc::new(first_synced_tx);

        let initial_arc = Arc::new(AtomicBool::from(true));
        let sync_state = SyncState::new(first_synced_rx);

        let sync_state_history = sync_state.history_loading.clone();

        RUNTIME.spawn(async move {
            let client = client.clone();
            let state = state.clone();
            let verification_controller = verification_controller.clone();
            let device_controller = device_controller.clone();
            let sync_state_history = sync_state_history.clone();
            conversation_controller
                .setup(&client, executor.clone())
                .await;

            client
                .clone()
                .sync_with_callback(SyncSettings::new(), move |response| {
                    let client = client.clone();
                    let me = me.clone();
                    let state = state.clone();
                    let verification_controller = verification_controller.clone();
                    let device_controller = device_controller.clone();
                    let first_synced_arc = first_synced_arc.clone();
                    let sync_state_history = sync_state_history.clone();
                    let initial_arc = initial_arc.clone();

                    async move {
                        let state = state.clone();
                        let initial = initial_arc.clone();

                        device_controller.process_events(&client, response.device_lists);

                        if !initial.load(Ordering::SeqCst) {
                            verification_controller.process_sync_messages(&client, &response.rooms);
                            me.refresh_history_on_start(sync_state_history.clone());
                        }

                        initial.store(false, Ordering::SeqCst);

                        let _ = first_synced_arc.send(true);
                        if !(*state).read().has_first_synced {
                            (*state).write().has_first_synced = true
                        }
                        if (*state).read().should_stop_syncing {
                            (*state).write().is_syncing = false;
                            // the lock is unlocked here when `s` goes out of scope.
                            return LoopCtrl::Break;
                        } else if !(*state).read().is_syncing {
                            (*state).write().is_syncing = true;
                        }

                        verification_controller
                            .process_to_device_messages(&client, response.to_device);
                        LoopCtrl::Continue
                    }
                })
                .await;
        });
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
        Ok(serde_json::to_string(&RestoreToken {
            session,
            homeurl,
            is_guest: self.state.read().is_guest,
        })?)
    }

    pub async fn conversations(&self) -> Result<Vec<Conversation>> {
        let c = self.client.clone();
        let e = self.executor.clone();
        RUNTIME
            .spawn(async move {
                let (_, conversations) = devide_groups_from_common(c, e).await;
                Ok(conversations)
            })
            .await?
    }

    #[cfg(feature = "with-mocks")]
    pub async fn faqs(&self) -> Result<Vec<Faq>> {
        Ok(gen_mock_faqs())
    }

    // pub async fn get_mxcuri_media(&self, uri: String) -> Result<Vec<u8>> {
    //     let l = self.client.clone();
    //     RUNTIME.spawn(async move {
    //         let user_id = l.user_id().await.expect("No User ID found");
    //         Ok(user_id.as_str().to_string())
    //     }).await?
    // }

    pub async fn user_id(&self) -> Result<OwnedUserId> {
        let l = self.client.clone();
        RUNTIME
            .spawn(async move {
                let user_id = l.user_id().context("No User ID found")?.to_owned();
                Ok(user_id)
            })
            .await?
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

    pub async fn account(&self) -> Result<Account> {
        Ok(Account::new(self.client.account()))
    }

    pub async fn display_name(&self) -> Result<String> {
        let l = self.client.clone();
        RUNTIME
            .spawn(async move {
                let display_name = l
                    .account()
                    .get_display_name()
                    .await?
                    .context("No User ID found")?;
                Ok(display_name.as_str().to_string())
            })
            .await?
    }

    pub async fn device_id(&self) -> Result<String> {
        let l = self.client.clone();
        RUNTIME
            .spawn(async move {
                let device_id = l.device_id().context("No Device ID found")?;
                Ok(device_id.as_str().to_string())
            })
            .await?
    }

    pub async fn avatar(&self) -> Result<FfiBuffer<u8>> {
        self.account().await?.avatar().await
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
}
