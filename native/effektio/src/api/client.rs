use super::{api, Account, Conversation, Group, Room, RUNTIME};
use anyhow::{bail, Context, Result};
use derive_builder::Builder;
use effektio_core::{
    mocks::{gen_mock_faqs, gen_mock_news},
    models::{Faq, News},
    RestoreToken,
};
use futures::{
    stream, Stream, StreamExt,
    channel::mpsc::{channel, Sender, Receiver},
};
use matrix_sdk::{
    config::SyncSettings,
    encryption::verification::{SasVerification, Verification},
    media::{MediaFormat, MediaRequest},
    ruma::{
        self,
        events::{
            room::message::MessageType,
            AnySyncMessageLikeEvent, AnySyncRoomEvent, AnyToDeviceEvent, SyncMessageLikeEvent,
        },
        RoomId, UserId,
    },
    Client as MatrixClient, LoopCtrl,
};
use parking_lot::{Mutex, RwLock};
use std::sync::{atomic::{AtomicBool, Ordering}, Arc};

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
    client: MatrixClient,
    state: Arc<RwLock<ClientState>>,
}

impl std::ops::Deref for Client {
    type Target = MatrixClient;
    fn deref(&self) -> &MatrixClient {
        &self.client
    }
}

static PURPOSE_FIELD: &str = "m.room.purpose";
static PURPOSE_FIELD_DEV: &str = "org.matrix.msc3088.room.purpose";
static PURPOSE_VALUE: &str = "org.effektio";

async fn devide_groups_from_common(client: MatrixClient) -> (Vec<Group>, Vec<Conversation>) {
    stream::iter(client.rooms().into_iter())
        .fold(
            (Vec::new(), Vec::new()),
            async move |(mut groups, mut conversations), room| {
                let is_effektio_group = {
                    #[allow(clippy::match_like_matches_macro)]
                    if let Ok(Some(_)) = room
                        .get_state_event(PURPOSE_FIELD.into(), PURPOSE_VALUE)
                        .await
                    {
                        true
                    } else if let Ok(Some(_)) = room
                        .get_state_event(PURPOSE_FIELD_DEV.into(), PURPOSE_VALUE)
                        .await
                    {
                        true
                    } else {
                        false
                    }
                };

                if is_effektio_group {
                    groups.push(Group {
                        inner: Room { room },
                    });
                } else {
                    conversations.push(Conversation {
                        inner: Room { room },
                    });
                }

                (groups, conversations)
            },
        )
        .await
}

async fn print_devices(user_id: &UserId, client: &MatrixClient) {
    println!("Devices of user {}", user_id);
    for device in client.encryption().get_user_devices(user_id).await.unwrap().devices() {
        println!(
            "   {:<10} {:<30} {:<}",
            device.device_id(),
            device.display_name().unwrap_or("-"),
            device.verified(),
        );
    }
}

fn print_result(sas: &SasVerification) {
    let device = sas.other_device();
    println!(
        "Successfully verified device {} {} {:?}",
        device.user_id(),
        device.device_id(),
        device.local_trust_state(),
    );
}

impl Client {
    pub(crate) fn new(client: MatrixClient, state: ClientState) -> Self {
        Client {
            client,
            state: Arc::new(RwLock::new(state)),
        }
    }

    pub(crate) fn start_sync(&self) -> Result<Receiver<SasVerification>> {
        let client = self.client.clone();
        let state = self.state.clone();
        let (tx, mut rx) = channel(10); // dropping after more than 10 items queued
        let sas_arc = Arc::new(Mutex::new(tx));

        RUNTIME.spawn(async move {
            let client_ref = &client;
            let state_ref = &state;
            let initial_sync = Arc::new(AtomicBool::from(true));
            let initial_ref = &initial_sync;

            client
                .sync_with_callback(SyncSettings::new(), move |response| {
                    let sas_arc = sas_arc.clone();
                    async move {
                        let s = sas_arc.lock();
                        let client = &client_ref;
                        let state = &state_ref;
                        let initial = &initial_ref;

                        for event in response.to_device.events.iter().filter_map(|ev| ev.deserialize().ok()) {
                            match event {
                                AnyToDeviceEvent::KeyVerificationStart(ev) => {
                                    if let Some(Verification::SasV1(sas)) = client
                                        .encryption()
                                        .get_verification(&ev.sender, ev.content.transaction_id.as_str())
                                        .await
                                    {
                                        println!(
                                            "Starting verification with {} {}",
                                            &sas.other_device().user_id(),
                                            &sas.other_device().device_id(),
                                        );
                                        print_devices(&ev.sender, client).await;
                                        sas.accept().await.unwrap();
                                    }
                                }
                                AnyToDeviceEvent::KeyVerificationKey(ev) => {
                                    if let Some(Verification::SasV1(sas)) = client
                                        .encryption()
                                        .get_verification(&ev.sender, ev.content.transaction_id.as_str())
                                        .await
                                    {}
                                }
                                AnyToDeviceEvent::KeyVerificationMac(ev) => {
                                    if let Some(Verification::SasV1(sas)) = client
                                        .encryption()
                                        .get_verification(&ev.sender, ev.content.transaction_id.as_str())
                                        .await
                                    {
                                        if sas.is_done() {
                                            print_result(&sas);
                                            print_devices(&ev.sender, client).await;
                                        }
                                    }
                                }
                                _ => {}
                            }
                        }

                        if !initial.load(Ordering::SeqCst) {
                            for (_room_id, room_info) in response.rooms.join {
                                for event in room_info.timeline.events.iter().filter_map(|ev| ev.event.deserialize().ok()) {
                                    if let AnySyncRoomEvent::MessageLike(event) = event {
                                        match event {
                                            AnySyncMessageLikeEvent::RoomMessage(
                                                SyncMessageLikeEvent::Original(m),
                                            ) => {
                                                if let MessageType::VerificationRequest(_) = &m.content.msgtype {
                                                    let request = client
                                                        .encryption()
                                                        .get_verification_request(&m.sender, &m.event_id)
                                                        .await
                                                        .expect("Request object wasn't created");
                                                    request
                                                        .accept()
                                                        .await
                                                        .expect("Can't accept verification request");
                                                }
                                            }
                                            AnySyncMessageLikeEvent::KeyVerificationKey(
                                                SyncMessageLikeEvent::Original(ev),
                                            ) => {
                                                if let Some(Verification::SasV1(sas)) = client
                                                    .encryption()
                                                    .get_verification(&ev.sender, ev.content.relates_to.event_id.as_str())
                                                    .await
                                                {}
                                            }
                                            AnySyncMessageLikeEvent::KeyVerificationMac(
                                                SyncMessageLikeEvent::Original(ev),
                                            ) => {
                                                if let Some(Verification::SasV1(sas)) = client
                                                    .encryption()
                                                    .get_verification(&ev.sender, ev.content.relates_to.event_id.as_str())
                                                    .await
                                                {
                                                    if sas.is_done() {
                                                        print_result(&sas);
                                                        print_devices(&ev.sender, client).await;
                                                    }
                                                }
                                            }
                                            _ => ()
                                        }
                                    }
                                }
                            }
                        }

                        initial.store(false, Ordering::SeqCst);

                        if !(*state).read().has_first_synced {
                            (*state).write().has_first_synced = true
                        }
                        if (*state).read().should_stop_syncing {
                            (*state).write().is_syncing = false;
                            return LoopCtrl::Break;
                        } else if !(*state).read().is_syncing {
                            (*state).write().is_syncing = true;
                        }
                        LoopCtrl::Continue
                        // the lock is unlocked here when `s` goes out of scope.
                    }
                })
                .await;
        });
        Ok(rx)
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
        let session = self.client.session().await.context("Missing session")?;
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
                let (_, conversations) = devide_groups_from_common(c).await;
                Ok(conversations)
            })
            .await?
    }

    pub async fn groups(&self) -> Result<Vec<Group>> {
        let c = self.client.clone();
        RUNTIME
            .spawn(async move {
                let (groups, _) = devide_groups_from_common(c).await;
                Ok(groups)
            })
            .await?
    }

    pub async fn latest_news(&self) -> Result<Vec<News>> {
        Ok(gen_mock_news())
    }

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

    pub async fn user_id(&self) -> Result<ruma::OwnedUserId> {
        let l = self.client.clone();
        RUNTIME
            .spawn(async move {
                let user_id = l.user_id().await.context("No User ID found")?;
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
                    return Ok(Room { room });
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
                let device_id = l.device_id().await.context("No Device ID found")?;
                Ok(device_id.as_str().to_string())
            })
            .await?
    }

    pub async fn avatar(&self) -> Result<api::FfiBuffer<u8>> {
        self.account().await?.avatar().await
    }
}
