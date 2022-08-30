use anyhow::{bail, Context, Result};
use derive_builder::Builder;
use effektio_core::{
    models::Faq,
    statics::{PURPOSE_FIELD, PURPOSE_FIELD_DEV, PURPOSE_TEAM_VALUE},
    RestoreToken,
};

#[cfg(feature = "with-mocks")]
use effektio_core::mocks::gen_mock_faqs;
use futures::{stream, StreamExt};
use futures_signals::signal::{channel, Receiver, SignalExt, SignalStream};
use matrix_sdk::{
    config::SyncSettings,
    event_handler::Ctx,
    locks::RwLock as MatrixRwLock,
    media::{MediaFormat, MediaRequest},
    room::Room as MatrixRoom,
    ruma::{
        device_id,
        events::{
            receipt::ReceiptEventContent, typing::TypingEventContent, SyncEphemeralRoomEvent,
        },
        OwnedRoomAliasId, OwnedRoomId, OwnedUserId, RoomId,
    },
    Client as MatrixClient, LoopCtrl,
};
use parking_lot::{Mutex, RwLock};
use std::sync::{
    atomic::{AtomicBool, Ordering},
    Arc,
};
use tokio::task::JoinHandle;
use tracing::info;

use super::{
    api::FfiBuffer, Account, Conversation, DeviceListsController, Group,
    ReceiptNotificationController, Room, SessionVerificationController,
    TypingNotificationController, RUNTIME,
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

#[derive(Clone)]
pub struct Client {
    pub(crate) client: MatrixClient,
    pub(crate) state: Arc<RwLock<ClientState>>,
    pub(crate) session_verification_controller:
        Arc<MatrixRwLock<Option<SessionVerificationController>>>,
    pub(crate) device_lists_controller: Arc<MatrixRwLock<Option<DeviceListsController>>>,
    pub(crate) typing_notification_controller: TypingNotificationController,
    pub(crate) receipt_notification_controller:
        Arc<MatrixRwLock<Option<ReceiptNotificationController>>>,
}

impl std::ops::Deref for Client {
    type Target = MatrixClient;
    fn deref(&self) -> &MatrixClient {
        &self.client
    }
}

pub(crate) async fn devide_groups_from_common(client: Client) -> (Vec<Group>, Vec<Conversation>) {
    info!("collecting");
    let (groups, convos, _) = stream::iter(client.clone().rooms().into_iter())
        .fold(
            (Vec::new(), Vec::new(), client),
            async move |(mut groups, mut conversations, client), room| {
                let is_effektio_group = {
                    #[allow(clippy::match_like_matches_macro)]
                    if let Ok(Some(_)) = room
                        .get_state_event(PURPOSE_FIELD.into(), PURPOSE_TEAM_VALUE)
                        .await
                    {
                        true
                    } else if let Ok(Some(_)) = room
                        .get_state_event(PURPOSE_FIELD_DEV.into(), PURPOSE_TEAM_VALUE)
                        .await
                    {
                        true
                    } else {
                        false
                    }
                };

                if is_effektio_group {
                    groups.push(Group {
                        inner: Room {
                            room,
                            client: client.client.clone(),
                        },
                    });
                } else {
                    conversations.push(Conversation::new(
                        Room {
                            room,
                            client: client.client.clone(),
                        },
                        &client,
                    ));
                }
                info!("iteration: {:}, {:}", groups.len(), conversations.len());

                (groups, conversations, client)
            },
        )
        .await;
    info!("done collecting: {:}, {:}", groups.len(), convos.len());
    (groups, convos)
}

#[derive(Clone)]
pub struct SyncState {
    first_synced_rx: Arc<Mutex<Option<Receiver<bool>>>>,
    handle: Arc<Mutex<JoinHandle<()>>>,
}

impl SyncState {
    pub fn new(first_synced_rx: Receiver<bool>, handle: JoinHandle<()>) -> Self {
        let first_synced_rx = Arc::new(Mutex::new(Some(first_synced_rx)));
        Self {
            first_synced_rx,
            handle: Arc::new(Mutex::new(handle)),
        }
    }

    pub fn get_first_synced_rx(&self) -> Option<SignalStream<Receiver<bool>>> {
        self.first_synced_rx.lock().take().map(|t| t.to_stream())
    }

    pub fn is_done(&self) -> bool {
        self.handle.lock().is_finished()
    }

    pub fn abort(&self) {
        let mut handle = self.handle.lock();
        if !handle.is_finished() {
            handle.abort();
        }
    }
}

impl Client {
    pub fn new(client: MatrixClient, state: ClientState) -> Self {
        Client {
            client,
            state: Arc::new(RwLock::new(state)),
            session_verification_controller: Arc::new(MatrixRwLock::new(None)),
            device_lists_controller: Arc::new(MatrixRwLock::new(None)),
            typing_notification_controller: TypingNotificationController::new(),
            receipt_notification_controller: Arc::new(MatrixRwLock::new(None)),
        }
    }

    pub fn start_sync(&self) -> SyncState {
        let me = self.clone();
        let (first_synced_tx, first_synced_rx) = channel(false);

        let handle = RUNTIME.spawn(async move {
            let me = me.clone();
            let state = me.state.clone();
            let client = me.client.clone();
            let initial_arc = Arc::new(AtomicBool::from(true));
            let first_synced_arc = Arc::new(first_synced_tx);

            me.typing_notification_controller.setup(&client).await;

            client
                .clone()
                .sync_with_callback(SyncSettings::new(), move |response| {
                    let client = client.clone();
                    let state = me.state.clone();
                    let session_verification_controller =
                        me.session_verification_controller.clone();
                    let device_lists_controller = me.device_lists_controller.clone();
                    let first_synced_arc = first_synced_arc.clone();
                    let initial_arc = initial_arc.clone();

                    async move {
                        let state = state.clone();
                        let initial = initial_arc.clone();

                        if let Some(dlc) = &*device_lists_controller.read().await {
                            dlc.process_events(&client, response.device_lists);
                        }

                        if !initial.load(Ordering::SeqCst) {
                            if let Some(svc) = &*session_verification_controller.read().await {
                                svc.process_sync_messages(&client, &response.rooms);
                            }
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

                        if let Some(svc) = &*session_verification_controller.read().await {
                            svc.process_to_device_messages(&client, response.to_device);
                        }
                        // the lock is unlocked here when `s` goes out of scope.
                        LoopCtrl::Continue
                    }
                })
                .await;
        });

        SyncState::new(first_synced_rx, handle)
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
        let c = self.clone();
        RUNTIME
            .spawn(async move {
                let (_, conversations) = devide_groups_from_common(c).await;
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

    pub async fn room(&self, name: String) -> Result<Room> {
        let room_id = RoomId::parse(name)?;
        let l = self.clone();
        RUNTIME
            .spawn(async move {
                if let Some(room) = l.get_room(&room_id) {
                    return Ok(Room {
                        room,
                        client: l.client.clone(),
                    });
                }
                bail!("Room not found")
            })
            .await?
    }

    pub async fn conversation(&self, alias_or_id: String) -> Result<Conversation> {
        if let Ok(room_id) = OwnedRoomId::try_from(alias_or_id.clone()) {
            match self.get_room(&room_id) {
                Some(room) => Ok(Conversation::new(
                    Room {
                        room,
                        client: self.client.clone(),
                    },
                    &self,
                )),
                None => bail!("Room not found"),
            }
        } else if let Ok(alias_id) = OwnedRoomAliasId::try_from(alias_or_id) {
            for conv in self.conversations().await?.into_iter() {
                if let Some(conv_alias) = conv.inner.room.canonical_alias() {
                    if conv_alias == alias_id {
                        return Ok(conv);
                    }
                }
            }
            bail!("Conversation with alias not found")
        } else {
            bail!("Neither roomId nor alias provided")
        }
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
                Ok(dev.verified())
            })
            .await?
    }

    pub async fn get_session_verification_controller(
        &self,
    ) -> Result<SessionVerificationController> {
        // if not exists, create new controller and return it.
        // thus Result is necessary but Option is not necessary.
        let c = self.client.clone();
        let session_verification_controller = self.session_verification_controller.clone();
        RUNTIME
            .spawn(async move {
                if let Some(svc) = &*session_verification_controller.read().await {
                    return Ok(svc.clone());
                }
                let svc = SessionVerificationController::new();
                *session_verification_controller.write().await = Some(svc.clone());
                Ok(svc)
            })
            .await?
    }

    pub async fn get_device_lists_controller(&self) -> Result<DeviceListsController> {
        // if not exists, create new controller and return it.
        // thus Result is necessary but Option is not necessary.
        let c = self.client.clone();
        let device_lists_controller = self.device_lists_controller.clone();
        RUNTIME
            .spawn(async move {
                if let Some(dlc) = &*device_lists_controller.read().await {
                    return Ok(dlc.clone());
                }
                let dlc = DeviceListsController::new();
                *device_lists_controller.write().await = Some(dlc.clone());
                Ok(dlc)
            })
            .await?
    }

    pub async fn get_receipt_notification_controller(
        &self,
    ) -> Result<ReceiptNotificationController> {
        // if not exists, create new controller and return it.
        // thus Result is necessary but Option is not necessary.
        let client = self.client.clone();
        let receipt_notification_controller = self.receipt_notification_controller.clone();
        RUNTIME
            .spawn(async move {
                if let Some(rnc) = &*receipt_notification_controller.read().await {
                    return Ok(rnc.clone());
                }
                let rnc = ReceiptNotificationController::new();
                client
                    .register_event_handler_context(rnc.clone())
                    .register_event_handler(
                        |ev: SyncEphemeralRoomEvent<ReceiptEventContent>,
                         room: MatrixRoom,
                         Ctx(rnc): Ctx<ReceiptNotificationController>| async move {
                            rnc.process_ephemeral_event(ev, &room);
                        },
                    )
                    .await;
                *receipt_notification_controller.write().await = Some(rnc.clone());
                Ok(rnc)
            })
            .await?
    }
}
