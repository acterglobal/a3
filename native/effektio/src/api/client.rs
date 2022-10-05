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

#[derive(Clone)]
pub struct Client {
    pub(crate) client: MatrixClient,
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

pub(crate) async fn divide_groups_from_common(
    client: MatrixClient,
) -> (Vec<Group>, Vec<Conversation>) {
    let (groups, convos, _) = stream::iter(client.clone().rooms().into_iter())
        .fold(
            (Vec::new(), Vec::new(), client),
            async move |(mut groups, mut conversations, client), room| {
                let r = Room {
                    room: room.clone(),
                    client: client.clone(),
                };
                if r.is_effektio_group().await {
                    groups.push(Group { inner: r });
                } else {
                    conversations.push(Conversation::new(r));
                }

                (groups, conversations, client)
            },
        )
        .await;
    (groups, convos)
}

#[derive(Clone)]
pub struct SyncState {
    first_synced_rx: Arc<Mutex<Option<Receiver<bool>>>>,
}

impl SyncState {
    pub fn new(first_synced_rx: Receiver<bool>) -> Self {
        let first_synced_rx = Arc::new(Mutex::new(Some(first_synced_rx)));
        Self { first_synced_rx }
    }

    pub fn first_synced_rx(&self) -> Option<SignalStream<Receiver<bool>>> {
        self.first_synced_rx.lock().take().map(|t| t.to_stream())
    }
}

impl Client {
    pub fn new(client: MatrixClient, state: ClientState) -> Self {
        Client {
            client,
            state: Arc::new(RwLock::new(state)),
            verification_controller: VerificationController::new(),
            device_controller: DeviceController::new(),
            typing_controller: TypingController::new(),
            receipt_controller: ReceiptController::new(),
            conversation_controller: ConversationController::new(),
        }
    }

    pub fn start_sync(&self) -> SyncState {
        let client = self.client.clone();
        let state = self.state.clone();
        let mut verification_controller = self.verification_controller.clone();
        let mut device_controller = self.device_controller.clone();
        self.typing_controller.setup(&client);
        self.receipt_controller.setup(&client);
        let conversation_controller = self.conversation_controller.clone();

        let (first_synced_tx, first_synced_rx) = channel(false);
        let first_synced_arc = Arc::new(first_synced_tx);

        let initial_arc = Arc::new(AtomicBool::from(true));
        let sync_state = SyncState::new(first_synced_rx);

        RUNTIME.spawn(async move {
            let client = client.clone();
            let state = state.clone();
            let mut verification_controller = verification_controller.clone();
            let mut device_controller = device_controller.clone();
            conversation_controller.setup(&client).await;

            client
                .clone()
                .sync_with_callback(SyncSettings::new(), move |response| {
                    let client = client.clone();
                    let state = state.clone();
                    let mut verification_controller = verification_controller.clone();
                    let mut device_controller = device_controller.clone();
                    let first_synced_arc = first_synced_arc.clone();
                    let initial_arc = initial_arc.clone();

                    async move {
                        let state = state.clone();
                        let initial = initial_arc.clone();

                        device_controller.process_events(&client, response.device_lists);

                        if !initial.load(Ordering::SeqCst) {
                            verification_controller.process_sync_messages(&client, &response.rooms);
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
        RUNTIME
            .spawn(async move {
                let (_, conversations) = divide_groups_from_common(c).await;
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
    //         Ok(user_id.to_string())
    //     }).await?
    // }

    pub fn user_id(&self) -> Result<OwnedUserId> {
        let user_id = self
            .client
            .user_id()
            .context("No User ID found")?
            .to_owned();
        Ok(user_id)
    }

    pub(crate) fn room(&self, room_name: String) -> Result<Room> {
        let room_id = RoomId::parse(room_name)?;
        if let Some(room) = self.client.get_room(&room_id) {
            return Ok(Room {
                room,
                client: self.client.clone(),
            });
        }
        bail!("Room not found")
    }

    pub fn account(&self) -> Result<Account> {
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
                Ok(display_name.to_string())
            })
            .await?
    }

    pub fn device_id(&self) -> Result<String> {
        let device_id = self.client.device_id().context("No Device ID found")?;
        Ok(device_id.to_string())
    }

    pub async fn avatar(&self) -> Result<FfiBuffer<u8>> {
        self.account()?.avatar().await
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
