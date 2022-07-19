use anyhow::{bail, Context, Result};
use derive_builder::Builder;
use effektio_core::{
    models::{Faq, News},
    statics::{PURPOSE_FIELD, PURPOSE_FIELD_DEV, PURPOSE_TEAM_VALUE},
    RestoreToken,
};

#[cfg(feature = "with-mocks")]
use effektio_core::mocks::gen_mock_faqs;
use futures::{
    channel::mpsc::{channel, Receiver},
    stream, Stream, StreamExt,
};
use futures_signals::signal::{
    channel as signal_channel, Receiver as SignalReceiver, SignalExt, SignalStream,
};
use matrix_sdk::{
    config::SyncSettings,
    encryption::verification::{SasVerification, Verification},
    media::{MediaFormat, MediaRequest},
    ruma::{events::AnySyncRoomEvent, OwnedUserId, RoomId, UserId},
    Client as MatrixClient, LoopCtrl,
};
use parking_lot::{Mutex, RwLock};
use std::sync::{
    atomic::{AtomicBool, Ordering},
    Arc,
};

use super::{
    api::FfiBuffer,
    events::{
        handle_emoji_sync_msg_event, handle_emoji_to_device_event, handle_typing_notification,
        EmojiVerificationEvent, TypingNotification,
    },
    Account, Conversation, Group, Room, RUNTIME,
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
pub struct EmojiUnit {
    symbol: u32,
    description: String,
}

impl EmojiUnit {
    pub(crate) fn new(symbol: u32, description: String) -> Self {
        EmojiUnit {
            symbol,
            description,
        }
    }

    pub fn get_symbol(&self) -> u32 {
        self.symbol
    }

    pub fn get_description(&self) -> String {
        self.description.clone()
    }
}

#[derive(Clone)]
pub struct Client {
    pub(crate) client: MatrixClient,
    pub(crate) state: Arc<RwLock<ClientState>>,
}

impl std::ops::Deref for Client {
    type Target = MatrixClient;
    fn deref(&self) -> &MatrixClient {
        &self.client
    }
}

pub(crate) async fn devide_groups_from_common(
    client: MatrixClient,
) -> (Vec<Group>, Vec<Conversation>) {
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
                            client: client.clone(),
                        },
                    });
                } else {
                    conversations.push(Conversation {
                        inner: Room {
                            room,
                            client: client.clone(),
                        },
                    });
                }

                (groups, conversations, client)
            },
        )
        .await;
    (groups, convos)
}

#[derive(Clone)]
pub struct SyncState {
    emoji_verification_event_rx: Arc<Mutex<Option<Receiver<EmojiVerificationEvent>>>>, // mutex for sync, arc for clone. once called, it will become None, not Some
    typing_notification_rx: Arc<Mutex<Option<Receiver<TypingNotification>>>>, // mutex for sync, arc for clone. once called, it will become None, not Some
    first_synced_rx: Arc<Mutex<Option<SignalReceiver<bool>>>>,
}

impl SyncState {
    pub fn new(
        emoji_verification_event_rx: Receiver<EmojiVerificationEvent>,
        typing_notification_rx: Receiver<TypingNotification>,
        first_synced_rx: SignalReceiver<bool>,
    ) -> Self {
        Self {
            emoji_verification_event_rx: Arc::new(Mutex::new(Some(emoji_verification_event_rx))),
            typing_notification_rx: Arc::new(Mutex::new(Some(typing_notification_rx))),
            first_synced_rx: Arc::new(Mutex::new(Some(first_synced_rx))),
        }
    }

    pub fn get_emoji_verification_event_rx(&self) -> Option<Receiver<EmojiVerificationEvent>> {
        self.emoji_verification_event_rx.lock().take()
    }

    pub fn get_typing_notification_rx(&self) -> Option<Receiver<TypingNotification>> {
        self.typing_notification_rx.lock().take()
    }

    pub fn get_first_synced_rx(&self) -> Option<SignalStream<SignalReceiver<bool>>> {
        self.first_synced_rx.lock().take().map(|t| t.to_stream())
    }
}

impl Client {
    pub fn new(client: MatrixClient, state: ClientState) -> Self {
        Client {
            client,
            state: Arc::new(RwLock::new(state)),
        }
    }

    pub fn start_sync(&self) -> SyncState {
        let client = self.client.clone();
        let state = self.state.clone();

        let (emoji_verification_event_tx, emoji_verification_event_rx) =
            channel::<EmojiVerificationEvent>(10); // dropping after more than 10 items queued
        let emoji_verification_event_arc = Arc::new(emoji_verification_event_tx);

        let (typing_notification_tx, typing_notification_rx) = channel::<TypingNotification>(10); // dropping after more than 10 items queued
        let typing_notification_arc = Arc::new(typing_notification_tx);

        let (first_synced_tx, first_synced_rx) = signal_channel(false);
        let first_synced_arc = Arc::new(first_synced_tx);

        let sync_state = SyncState::new(
            emoji_verification_event_rx,
            typing_notification_rx,
            first_synced_rx,
        );
        let initial_sync = Arc::new(AtomicBool::from(true));

        RUNTIME.spawn(async move {
            let client = client.clone();
            let state = state.clone();

            client
                .clone()
                .sync_with_callback(SyncSettings::new(), move |response| {
                    let client = client.clone();
                    let state = state.clone();
                    let emoji_verification_event_arc = emoji_verification_event_arc.clone();
                    let typing_notification_arc = typing_notification_arc.clone();
                    let first_synced_arc = first_synced_arc.clone();
                    let initial_sync = initial_sync.clone();

                    async move {
                        let client = client.clone();
                        let state = state.clone();
                        let initial = initial_sync.clone();
                        let mut emoji_verification_event_tx =
                            (*emoji_verification_event_arc).clone();
                        let mut typing_notification_tx = (*typing_notification_arc).clone();

                        let user_id = client.user_id().unwrap();
                        let device_id = client.device_id().unwrap();
                        let device = client
                            .encryption()
                            .get_device(user_id, device_id)
                            .await
                            .unwrap()
                            .unwrap();

                        for event in response
                            .to_device
                            .events
                            .iter()
                            .filter_map(|e| e.deserialize().ok())
                        {
                            handle_emoji_to_device_event(
                                &event,
                                &client,
                                &mut emoji_verification_event_tx,
                            )
                            .await;
                        }

                        if !initial.load(Ordering::SeqCst) {
                            for (room_id, room_info) in response.rooms.join {
                                for event in room_info
                                    .timeline
                                    .events
                                    .iter()
                                    .filter_map(|ev| ev.event.deserialize().ok())
                                {
                                    if let AnySyncRoomEvent::MessageLike(evt) = event {
                                        handle_emoji_sync_msg_event(
                                            &room_id,
                                            &evt,
                                            &client,
                                            &mut emoji_verification_event_tx,
                                        )
                                        .await;
                                    }
                                }
                                for event in room_info.ephemeral.events {
                                    if let Some(ev) = event.deserialize().ok() {
                                        handle_typing_notification(
                                            &room_id,
                                            &ev,
                                            &client,
                                            &mut typing_notification_tx,
                                        )
                                        .await;
                                    }
                                }
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
                        // the lock is unlocked here when `s` goes out of scope.
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

    pub async fn accept_verification_request(
        &self,
        sender: String,
        event_id: String,
    ) -> Result<bool> {
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let sender = UserId::parse(sender).expect("Couldn't parse the MXID");
                let request = client
                    .encryption()
                    .get_verification_request(&sender, event_id.as_str())
                    .await
                    .expect("Request object wasn't created");
                request
                    .accept()
                    .await
                    .expect("Can't accept verification request");
                Ok(true)
            })
            .await?
    }

    pub async fn accept_verification_start(
        &self,
        sender: String,
        event_id: String,
    ) -> Result<bool> {
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let sender = UserId::parse(sender).expect("Couldn't parse the MXID");
                if let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, event_id.as_str())
                    .await
                {
                    sas.accept().await.unwrap();
                    Ok(true)
                } else {
                    Ok(false)
                }
            })
            .await?
    }

    pub async fn get_verification_emoji(
        &self,
        sender: String,
        event_id: String,
    ) -> Result<Vec<EmojiUnit>> {
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let sender = UserId::parse(sender).expect("Couldn't parse the MXID");
                if let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, event_id.as_str())
                    .await
                {
                    if let Some(items) = sas.emoji() {
                        let sequence = items
                            .iter()
                            .map(|e| {
                                EmojiUnit::new(
                                    e.symbol.chars().collect::<Vec<_>>()[0] as u32,
                                    e.description.to_string(),
                                )
                            })
                            .collect::<Vec<_>>();
                        return Ok(sequence);
                    }
                }
                Ok(vec![])
            })
            .await?
    }

    pub async fn confirm_verification_key(&self, sender: String, event_id: String) -> Result<bool> {
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let sender = UserId::parse(sender).expect("Couldn't parse the MXID");
                if let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, event_id.as_str())
                    .await
                {
                    sas.confirm().await.unwrap();
                    Ok(sas.is_done())
                } else {
                    Ok(false)
                }
            })
            .await?
    }

    pub async fn mismatch_verification_key(
        &self,
        sender: String,
        event_id: String,
    ) -> Result<bool> {
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let sender = UserId::parse(sender).expect("Couldn't parse the MXID");
                if let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, event_id.as_str())
                    .await
                {
                    sas.mismatch().await.unwrap();
                    Ok(true)
                } else {
                    Ok(false)
                }
            })
            .await?
    }

    pub async fn cancel_verification_key(&self, sender: String, event_id: String) -> Result<bool> {
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let sender = UserId::parse(sender).expect("Couldn't parse the MXID");
                if let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, event_id.as_str())
                    .await
                {
                    sas.cancel().await.unwrap();
                    Ok(true)
                } else {
                    Ok(false)
                }
            })
            .await?
    }

    pub async fn review_verification_mac(&self, sender: String, event_id: String) -> Result<bool> {
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let sender = UserId::parse(sender).expect("Couldn't parse the MXID");
                if let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, event_id.as_str())
                    .await
                {
                    Ok(sas.is_done())
                } else {
                    Ok(false)
                }
            })
            .await?
    }
}

async fn print_devices(user_id: &UserId, client: &MatrixClient) {
    println!("Devices of user {}", user_id);
    for device in client
        .encryption()
        .get_user_devices(user_id)
        .await
        .unwrap()
        .devices()
    {
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

#[cfg(test)]
mod tests {
    use anyhow::Result;
    use matrix_sdk::{
        config::SyncSettings,
        deserialized_responses::SyncResponse,
        encryption::verification::{SasVerification, Verification},
        ruma::{
            events::{
                room::message::MessageType, AnySyncMessageLikeEvent, AnySyncRoomEvent,
                AnyToDeviceEvent, SyncMessageLikeEvent,
            },
            UserId,
        },
        store::StateStore,
        Client as MatrixClient, LoopCtrl, Result as MatrixResult,
    };
    use std::{
        env, fs, io,
        path::Path,
        process::exit,
        sync::{
            atomic::{AtomicBool, Ordering},
            Arc,
        },
        time::Duration,
    };
    use tokio::time::sleep;
    use url::Url;
    use zenv::Zenv;

    use crate::api::{login_new_client, EmojiUnit};

    async fn wait_for_confirmation(client: MatrixClient, sas: SasVerification) {
        println!("Does the emoji match: {:?}", sas.emoji());
        if let Some(items) = sas.emoji() {
            let sequence = items
                .iter()
                .map(|e| {
                    EmojiUnit::new(
                        e.symbol.chars().collect::<Vec<_>>()[0] as u32,
                        e.description.to_string(),
                    )
                })
                .collect::<Vec<_>>();
            println!("{:?}", sequence);
        }

        let mut input = String::new();
        io::stdin()
            .read_line(&mut input)
            .expect("error: unable to read user input");

        match input.trim().to_lowercase().as_ref() {
            "yes" | "true" | "ok" => {
                sas.confirm().await.unwrap();

                if sas.is_done() {
                    print_result(&sas);
                    print_devices(sas.other_device().user_id(), &client).await;
                }
            }
            _ => sas.cancel().await.unwrap(),
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

    async fn print_devices(user_id: &UserId, client: &MatrixClient) {
        println!("Devices of user {}", user_id);

        for device in client
            .encryption()
            .get_user_devices(user_id)
            .await
            .unwrap()
            .devices()
        {
            println!(
                "   {:<10} {:<32} {:<}",
                device.device_id(),
                device.display_name().unwrap_or("-"),
                device.verified()
            );
        }
    }

    async fn test_handle_to_device_event(event: &AnyToDeviceEvent, client: &MatrixClient) {
        match event {
            AnyToDeviceEvent::KeyVerificationRequest(ev) => {
                println!("AnyToDeviceEvent::KeyVerificationRequest");
                println!("sender: {}", ev.sender);
                println!("from_device: {}", ev.content.from_device);
                println!("transaction_id: {}", ev.content.transaction_id);
                println!("methods: {:?}", ev.content.methods);
                println!("timestamp: {:?}", ev.content.timestamp);
                let request = client
                    .encryption()
                    .get_verification_request(&ev.sender, &ev.content.transaction_id)
                    .await
                    .expect("Request object wasn't created");
                request
                    .accept()
                    .await
                    .expect("Can't accept verification request");
            }
            AnyToDeviceEvent::KeyVerificationReady(ev) => {
                println!("AnyToDeviceEvent::KeyVerificationReady");
                println!("sender: {}", ev.sender);
                println!("from_device: {}", ev.content.from_device);
                println!("methods: {:?}", ev.content.methods);
                println!("transaction_id: {}", ev.content.transaction_id);
            }
            AnyToDeviceEvent::KeyVerificationStart(ev) => {
                println!("AnyToDeviceEvent::KeyVerificationStart");
                println!("sender: {}", ev.sender);
                println!("from_device: {}", ev.content.from_device);
                println!("transaction_id: {}", ev.content.transaction_id);
                println!("method: {:?}", ev.content.method);
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
            AnyToDeviceEvent::KeyVerificationCancel(ev) => {
                println!("AnyToDeviceEvent::KeyVerificationCancel");
                println!("sender: {}", ev.sender);
                println!("transaction_id: {}", ev.content.transaction_id);
                println!("reason: {}", ev.content.reason);
                println!("code: {:?}", ev.content.code);
            }
            AnyToDeviceEvent::KeyVerificationAccept(ev) => {
                println!("AnyToDeviceEvent::KeyVerificationAccept");
                println!("sender: {}", ev.sender);
                println!("transaction_id: {}", ev.content.transaction_id);
                println!("method: {:?}", ev.content.method);
            }
            AnyToDeviceEvent::KeyVerificationKey(ev) => {
                println!("AnyToDeviceEvent::KeyVerificationKey");
                println!("sender: {}", ev.sender);
                println!("transaction_id: {}", ev.content.transaction_id);
                println!("key: {:?}", ev.content.key);
                if let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&ev.sender, ev.content.transaction_id.as_str())
                    .await
                {
                    tokio::spawn(wait_for_confirmation((*client).clone(), sas));
                }
            }
            AnyToDeviceEvent::KeyVerificationMac(ev) => {
                println!("AnyToDeviceEvent::KeyVerificationMac");
                println!("sender: {}", ev.sender);
                println!("transaction_id: {}", ev.content.transaction_id);
                println!("mac: {:?}", ev.content.mac);
                println!("keys: {:?}", ev.content.keys);
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
            AnyToDeviceEvent::KeyVerificationDone(ev) => {
                println!("AnyToDeviceEvent::KeyVerificationDone");
                println!("sender: {}", ev.sender);
                println!("transaction_id: {}", ev.content.transaction_id);
                exit(0);
            }
            _ => (),
        }
    }

    async fn test_handle_any_sync_event(event: &AnySyncMessageLikeEvent, client: &MatrixClient) {
        match event {
            AnySyncMessageLikeEvent::RoomMessage(SyncMessageLikeEvent::Original(m)) => {
                println!("AnySyncMessageLikeEvent::RoomMessage");
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
            AnySyncMessageLikeEvent::KeyVerificationReady(SyncMessageLikeEvent::Original(ev)) => {
                println!("AnySyncMessageLikeEvent::KeyVerificationReady");
                println!("sender: {}", ev.sender);
                println!("from_device: {}", ev.content.from_device);
                println!("methods: {:?}", ev.content.methods);
                println!("relates_to: {:?}", ev.content.relates_to);
            }
            AnySyncMessageLikeEvent::KeyVerificationStart(SyncMessageLikeEvent::Original(ev)) => {
                println!("AnySyncMessageLikeEvent::KeyVerificationStart");
                println!("sender: {}", ev.sender);
                println!("from_device: {}", ev.content.from_device);
                println!("method: {:?}", ev.content.method);
                println!("relates_to: {:?}", ev.content.relates_to);
            }
            AnySyncMessageLikeEvent::KeyVerificationCancel(SyncMessageLikeEvent::Original(ev)) => {
                println!("AnySyncMessageLikeEvent::KeyVerificationCancel");
                println!("sender: {}", ev.sender);
                println!("reason: {}", ev.content.reason);
                println!("code: {:?}", ev.content.code);
                println!("relates_to: {:?}", ev.content.relates_to);
            }
            AnySyncMessageLikeEvent::KeyVerificationAccept(SyncMessageLikeEvent::Original(ev)) => {
                println!("AnySyncMessageLikeEvent::KeyVerificationAccept");
                println!("sender: {}", ev.sender);
                println!("method: {:?}", ev.content.method);
                println!("relates_to: {:?}", ev.content.relates_to);
            }
            AnySyncMessageLikeEvent::KeyVerificationKey(SyncMessageLikeEvent::Original(ev)) => {
                println!("AnySyncMessageLikeEvent::KeyVerificationKey");
                println!("sender: {}", ev.sender);
                println!("key: {:?}", ev.content.key);
                println!("relates_to: {:?}", ev.content.relates_to);
                if let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&ev.sender, ev.content.relates_to.event_id.as_str())
                    .await
                {
                    tokio::spawn(wait_for_confirmation((*client).clone(), sas));
                }
            }
            AnySyncMessageLikeEvent::KeyVerificationMac(SyncMessageLikeEvent::Original(ev)) => {
                println!("AnySyncMessageLikeEvent::KeyVerificationMac");
                println!("sender: {}", ev.sender);
                println!("mac: {:?}", ev.content.mac);
                println!("keys: {:?}", ev.content.keys);
                println!("relates_to: {:?}", ev.content.relates_to);
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
            AnySyncMessageLikeEvent::KeyVerificationDone(SyncMessageLikeEvent::Original(ev)) => {
                println!("AnySyncMessageLikeEvent::KeyVerificationDone");
                println!("sender: {}", ev.sender);
                println!("relates_to: {:?}", ev.content.relates_to);
            }
            _ => (),
        }
    }

    async fn login(
        homeserver_url: String,
        base_path: &str,
        username: &str,
        password: &str,
    ) -> MatrixResult<()> {
        let homeserver_url =
            Url::parse(&homeserver_url).expect("Couldn't parse the homeserver URL");
        let mut client_builder = MatrixClient::builder().homeserver_url(homeserver_url);

        let state_store = StateStore::open_with_path(base_path)?;
        client_builder = client_builder.state_store(state_store);
        let client = client_builder.build().await.unwrap();

        client
            .login_username(username, password)
            .initial_device_display_name("rust-sdk")
            .send()
            .await?;

        let client_ref = &client;
        let initial_sync = Arc::new(AtomicBool::new(true));
        let initial_ref = &initial_sync;

        client
            .sync_with_callback(SyncSettings::new(), |response| async move {
                let client = &client_ref;
                let initial = &initial_ref;

                let user_id = client.user_id().unwrap();
                let device_id = client.device_id().unwrap();
                let device = client
                    .encryption()
                    .get_device(&user_id, &device_id)
                    .await
                    .unwrap()
                    .unwrap();
                println!("Device {}'s verified: {:?}", &device_id, device.verified());

                for event in response
                    .to_device
                    .events
                    .iter()
                    .filter_map(|e| e.deserialize().ok())
                {
                    test_handle_to_device_event(&event, client).await;
                }

                if !initial.load(Ordering::SeqCst) {
                    for (room_id, room_info) in response.rooms.join {
                        for event in room_info
                            .timeline
                            .events
                            .iter()
                            .filter_map(|e| e.event.deserialize().ok())
                        {
                            if let AnySyncRoomEvent::MessageLike(event) = event {
                                test_handle_any_sync_event(&event, client).await;
                            }
                        }
                    }
                }

                initial.store(false, Ordering::SeqCst);
                LoopCtrl::Continue
            })
            .await;

        Ok(())
    }

    // #[tokio::test]
    async fn launch_emoji_verification_custom_login() -> Result<()> {
        let z = Zenv::new(".env", false).parse()?;
        let homeserver_url: String = z.get("HOMESERVER_URL").unwrap().to_owned();
        let base_path: &str = z.get("BASE_PATH").unwrap();
        let username: &str = z.get("USERNAME").unwrap();
        let password: &str = z.get("PASSWORD").unwrap();

        login(homeserver_url, base_path, username, password).await?;

        Ok(())
    }

    // #[tokio::test]
    async fn launch_emoji_verification_original_login() -> Result<()> {
        let z = Zenv::new(".env", false).parse()?;
        let base_path: &str = z.get("BASE_PATH").unwrap();
        let username: &str = z.get("USERNAME").unwrap();
        let password: &str = z.get("PASSWORD").unwrap();

        // once verified, that device should meet verification case no more
        // so it is needed to remove cache of verification
        // on every launch, delete storage directory
        // don't know why this is needed about only original login
        // this is not needed for my custom login
        let dir_path = Path::new(base_path).join(username.replace(':', "_"));
        if dir_path.exists() {
            fs::remove_dir_all(dir_path).unwrap();
        }

        let client = login_new_client(
            base_path.to_owned(),
            username.to_owned(),
            password.to_owned(),
        )
        .await?;
        sleep(Duration::from_secs(3600)).await;

        Ok(())
    }
}
