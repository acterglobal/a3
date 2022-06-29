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
    channel::mpsc::{Receiver, Sender},
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
use std::sync::{
    atomic::{AtomicBool, Ordering},
    Arc,
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
pub struct CrossSigningEvent {
    event_name: String,
    event_id: String,
    sender: String,
}

impl CrossSigningEvent {
    pub fn new(
        event_name: String,
        event_id: String,
        sender: String,
    ) -> Self {
        CrossSigningEvent {
            event_name,
            event_id,
            sender,
        }
    }

    pub fn get_event_name(&self) -> String {
        self.event_name.clone()
    }

    pub fn get_event_id(&self) -> String {
        self.event_id.clone()
    }

    pub fn get_sender(&self) -> String {
        self.sender.clone()
    }
}

#[derive(Clone)]
pub struct Client {
    client: MatrixClient,
    state: Arc<RwLock<ClientState>>,
    to_device_rx: Arc<Mutex<Receiver<CrossSigningEvent>>>, // mutex for sync, arc for clone
    sync_msg_like_rx: Arc<Mutex<Receiver<CrossSigningEvent>>>, // mutex for sync, arc for clone
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

impl Client {
    pub(crate) fn new(
        client: MatrixClient,
        state: ClientState,
        to_device_rx: Receiver<CrossSigningEvent>,
        sync_msg_like_rx: Receiver<CrossSigningEvent>,
    ) -> Self {
        let to_device_arc = Arc::new(Mutex::new(to_device_rx));
        let sync_msg_like_arc = Arc::new(Mutex::new(sync_msg_like_rx));
        Client {
            client,
            state: Arc::new(RwLock::new(state)),
            to_device_rx: Arc::clone(&to_device_arc),
            sync_msg_like_rx: Arc::clone(&sync_msg_like_arc),
        }
    }

    pub(crate) fn start_sync(&self, to_device_tx: Sender<CrossSigningEvent>, sync_msg_like_tx: Sender<CrossSigningEvent>) {
        let client = self.client.clone();
        let state = self.state.clone();
        let to_device_arc = Arc::new(to_device_tx);
        let sync_msg_like_arc = Arc::new(sync_msg_like_tx);
        let initial_sync = Arc::new(AtomicBool::from(true));

        RUNTIME.spawn(async move {
            let client = client.clone();
            let state = state.clone();
            let to_device_arc = Arc::clone(&to_device_arc); // can't clone Sender so will wrap with Arc
            let sync_msg_like_arc = Arc::clone(&sync_msg_like_arc); // can't clone Sender so will wrap with Arc
            let initial_sync = initial_sync.clone();

            client
                .clone()
                .sync_with_callback(SyncSettings::new(), move |response| {
                    let client = client.clone();
                    let state = state.clone();
                    let to_device_arc = to_device_arc.clone();
                    let sync_msg_like_arc = sync_msg_like_arc.clone();
                    let initial_sync = initial_sync.clone();

                    async move {
                        let client = client.clone();
                        let state = state.clone();
                        let initial = initial_sync.clone();
                        let mut to_device_tx = (*to_device_arc).clone();
                        let mut sync_msg_like_tx = (*sync_msg_like_arc).clone();

                        for event in response.to_device.events.iter().filter_map(|e| e.deserialize().ok()) {
                            match event {
                                AnyToDeviceEvent::KeyVerificationRequest(ev) => {
                                    let sender = ev.sender.to_string();
                                    let txn_id = ev.content.transaction_id.to_string();
                                    let evt = CrossSigningEvent::new(
                                        "AnyToDeviceEvent::KeyVerificationRequest".to_owned(),
                                        txn_id.clone(),
                                        sender,
                                    );
                                    if let Err(e) = to_device_tx.try_send(evt) {
                                        log::warn!("Dropping transaction for {}: {}", txn_id, e);
                                    }
                                }
                                AnyToDeviceEvent::KeyVerificationReady(ev) => {
                                    let sender = ev.sender.to_string();
                                    let txn_id = ev.content.transaction_id.to_string();
                                    let evt = CrossSigningEvent::new(
                                        "AnyToDeviceEvent::KeyVerificationReady".to_owned(),
                                        txn_id.clone(),
                                        sender,
                                    );
                                    if let Err(e) = to_device_tx.try_send(evt) {
                                        log::warn!("Dropping transaction for {}: {}", txn_id, e);
                                    }
                                }
                                AnyToDeviceEvent::KeyVerificationStart(ev) => {
                                    let sender = ev.sender.to_string();
                                    let txn_id = ev.content.transaction_id.to_string();
                                    let evt = CrossSigningEvent::new(
                                        "AnyToDeviceEvent::KeyVerificationStart".to_owned(),
                                        txn_id.clone(),
                                        sender,
                                    );
                                    if let Err(e) = to_device_tx.try_send(evt) {
                                        log::warn!("Dropping transaction for {}: {}", txn_id, e);
                                    }
                                }
                                AnyToDeviceEvent::KeyVerificationCancel(ev) => {
                                    let sender = ev.sender.to_string();
                                    let txn_id = ev.content.transaction_id.to_string();
                                    let evt = CrossSigningEvent::new(
                                        "AnyToDeviceEvent::KeyVerificationCancel".to_owned(),
                                        txn_id.clone(),
                                        sender,
                                    );
                                    if let Err(e) = to_device_tx.try_send(evt) {
                                        log::warn!("Dropping transaction for {}: {}", txn_id, e);
                                    }
                                }
                                AnyToDeviceEvent::KeyVerificationAccept(ev) => {
                                    let sender = ev.sender.to_string();
                                    let txn_id = ev.content.transaction_id.to_string();
                                    let evt = CrossSigningEvent::new(
                                        "AnyToDeviceEvent::KeyVerificationAccept".to_owned(),
                                        txn_id.clone(),
                                        sender,
                                    );
                                    if let Err(e) = to_device_tx.try_send(evt) {
                                        log::warn!("Dropping transaction for {}: {}", txn_id, e);
                                    }
                                }
                                AnyToDeviceEvent::KeyVerificationKey(ev) => {
                                    let sender = ev.sender.to_string();
                                    let txn_id = ev.content.transaction_id.to_string();
                                    let evt = CrossSigningEvent::new(
                                        "AnyToDeviceEvent::KeyVerificationKey".to_owned(),
                                        txn_id.clone(),
                                        sender,
                                    );
                                    if let Err(e) = to_device_tx.try_send(evt) {
                                        log::warn!("Dropping transaction for {}: {}", txn_id, e);
                                    }
                                }
                                AnyToDeviceEvent::KeyVerificationMac(ev) => {
                                    let sender = ev.sender.to_string();
                                    let txn_id = ev.content.transaction_id.to_string();
                                    let evt = CrossSigningEvent::new(
                                        "AnyToDeviceEvent::KeyVerificationMac".to_owned(),
                                        txn_id.clone(),
                                        sender,
                                    );
                                    if let Err(e) = to_device_tx.try_send(evt) {
                                        log::warn!("Dropping transaction for {}: {}", txn_id, e);
                                    }
                                }
                                AnyToDeviceEvent::KeyVerificationDone(ev) => {
                                    let sender = ev.sender.to_string();
                                    let txn_id = ev.content.transaction_id.to_string();
                                    let evt = CrossSigningEvent::new(
                                        "AnyToDeviceEvent::KeyVerificationDone".to_owned(),
                                        txn_id.clone(),
                                        sender,
                                    );
                                    if let Err(e) = to_device_tx.try_send(evt) {
                                        log::warn!("Dropping transaction for {}: {}", txn_id, e);
                                    }
                                }
                                _ => {}
                            }
                        }

                        if !initial.load(Ordering::SeqCst) {
                            for (room_id, room_info) in response.rooms.join {
                                for event in room_info.timeline.events.iter().filter_map(|ev| ev.event.deserialize().ok()) {
                                    if let AnySyncRoomEvent::MessageLike(event) = event {
                                        match event {
                                            AnySyncMessageLikeEvent::RoomMessage(
                                                SyncMessageLikeEvent::Original(m),
                                            ) => {
                                                if let MessageType::VerificationRequest(_) = &m.content.msgtype {
                                                    let sender = m.sender.to_string();
                                                    let evt_id = m.event_id.to_string();
                                                    let evt = CrossSigningEvent::new(
                                                        "AnySyncMessageLikeEvent::RoomMessage".to_owned(),
                                                        evt_id.clone(),
                                                        sender,
                                                    );
                                                    if let Err(e) = sync_msg_like_tx.try_send(evt) {
                                                        log::warn!("Dropping event for {}: {}", evt_id, e);
                                                    }
                                                }
                                            }
                                            AnySyncMessageLikeEvent::KeyVerificationReady(
                                                SyncMessageLikeEvent::Original(ev),
                                            ) => {
                                                let sender = ev.sender.to_string();
                                                let evt_id = ev.event_id.to_string();
                                                let evt = CrossSigningEvent::new(
                                                    "AnySyncMessageLikeEvent::KeyVerificationReady".to_owned(),
                                                    evt_id.clone(),
                                                    sender,
                                                );
                                                if let Err(e) = sync_msg_like_tx.try_send(evt) {
                                                    log::warn!("Dropping event for {}: {}", evt_id, e);
                                                }
                                            }
                                            AnySyncMessageLikeEvent::KeyVerificationStart(
                                                SyncMessageLikeEvent::Original(ev),
                                            ) => {
                                                let sender = ev.sender.to_string();
                                                let evt_id = ev.event_id.to_string();
                                                let evt = CrossSigningEvent::new(
                                                    "AnySyncMessageLikeEvent::KeyVerificationReady".to_owned(),
                                                    evt_id.clone(),
                                                    sender,
                                                );
                                                if let Err(e) = sync_msg_like_tx.try_send(evt) {
                                                    log::warn!("Dropping event for {}: {}", evt_id, e);
                                                }
                                            }
                                            AnySyncMessageLikeEvent::KeyVerificationCancel(
                                                SyncMessageLikeEvent::Original(ev),
                                            ) => {
                                                let sender = ev.sender.to_string();
                                                let evt_id = ev.event_id.to_string();
                                                let evt = CrossSigningEvent::new(
                                                    "AnySyncMessageLikeEvent::KeyVerificationReady".to_owned(),
                                                    evt_id.clone(),
                                                    sender,
                                                );
                                                if let Err(e) = sync_msg_like_tx.try_send(evt) {
                                                    log::warn!("Dropping event for {}: {}", evt_id, e);
                                                }
                                            }
                                            AnySyncMessageLikeEvent::KeyVerificationAccept(
                                                SyncMessageLikeEvent::Original(ev),
                                            ) => {
                                                let sender = ev.sender.to_string();
                                                let evt_id = ev.event_id.to_string();
                                                let evt = CrossSigningEvent::new(
                                                    "AnySyncMessageLikeEvent::KeyVerificationAccept".to_owned(),
                                                    evt_id.clone(),
                                                    sender,
                                                );
                                                if let Err(e) = sync_msg_like_tx.try_send(evt) {
                                                    log::warn!("Dropping event for {}: {}", evt_id, e);
                                                }
                                            }
                                            AnySyncMessageLikeEvent::KeyVerificationKey(
                                                SyncMessageLikeEvent::Original(ev),
                                            ) => {
                                                let sender = ev.sender.to_string();
                                                let evt_id = ev.event_id.to_string();
                                                let evt = CrossSigningEvent::new(
                                                    "AnySyncMessageLikeEvent::KeyVerificationKey".to_owned(),
                                                    evt_id.clone(),
                                                    sender,
                                                );
                                                if let Err(e) = sync_msg_like_tx.try_send(evt) {
                                                    log::warn!("Dropping event for {}: {}", evt_id, e);
                                                }
                                            }
                                            AnySyncMessageLikeEvent::KeyVerificationMac(
                                                SyncMessageLikeEvent::Original(ev),
                                            ) => {
                                                let sender = ev.sender.to_string();
                                                let evt_id = ev.event_id.to_string();
                                                let evt = CrossSigningEvent::new(
                                                    "AnySyncMessageLikeEvent::KeyVerificationMac".to_owned(),
                                                    evt_id.clone(),
                                                    sender,
                                                );
                                                if let Err(e) = sync_msg_like_tx.try_send(evt) {
                                                    log::warn!("Dropping event for {}: {}", evt_id, e);
                                                }
                                            }
                                            AnySyncMessageLikeEvent::KeyVerificationDone(
                                                SyncMessageLikeEvent::Original(ev),
                                            ) => {
                                                let sender = ev.sender.to_string();
                                                let evt_id = ev.event_id.to_string();
                                                let evt = CrossSigningEvent::new(
                                                    "AnySyncMessageLikeEvent::KeyVerificationReady".to_owned(),
                                                    evt_id.clone(),
                                                    sender,
                                                );
                                                if let Err(e) = sync_msg_like_tx.try_send(evt) {
                                                    log::warn!("Dropping event for {}: {}", evt_id, e);
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

    pub fn get_to_device_rx(&self) -> Result<Receiver<CrossSigningEvent>> {
        Ok(*Arc::clone(&self.to_device_rx).lock())
    }

    pub fn get_sync_msg_like_rx(&self) -> Result<Receiver<CrossSigningEvent>> {
        Ok(*Arc::clone(&self.sync_msg_like_rx).lock())
    }
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

#[cfg(test)]
mod tests {
    use anyhow::Result;
    use matrix_sdk::{
        config::SyncSettings,
        encryption::verification::{SasVerification, Verification},
        ruma::{
            events::{
                room::message::MessageType,
                AnySyncMessageLikeEvent, AnySyncRoomEvent, AnyToDeviceEvent,
            },
            UserId,
        },
        store::StateStore,
        Client as MatrixClient, LoopCtrl, Result as MatrixResult,
    };
    use ruma::{
        api::client::sync::sync_events::v3::{DeviceLists, ToDevice},
        events::SyncMessageLikeEvent,
    };
    use std::{
        env, io,
        process::exit,
        sync::{atomic::{AtomicBool, Ordering}, Arc},
    };
    use url::Url;
    use zenv::Zenv;

    async fn wait_for_confirmation(client: MatrixClient, sas: SasVerification) {
        println!("Does the emoji match: {:?}", sas.emoji());

        let mut input = String::new();
        io::stdin().read_line(&mut input).expect("error: unable to read user input");

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

        for device in client.encryption().get_user_devices(user_id).await.unwrap().devices() {
            println!(
                "   {:<10} {:<32} {:<}",
                device.device_id(),
                device.display_name().unwrap_or("-"),
                device.verified()
            );
        }
    }

    async fn login(homeserver_url: String, base_path: &str, username: &str, password: &str) -> MatrixResult<()> {
        let homeserver_url = Url::parse(&homeserver_url).expect("Couldn't parse the homeserver URL");
        let mut client_builder = MatrixClient::builder().homeserver_url(homeserver_url);

        let state_store = StateStore::open_with_path(base_path)?;
        client_builder = client_builder.state_store(Box::new(state_store));
        let client = client_builder.build().await.unwrap();

        client.login(username, password, None, Some("rust-sdk")).await?;

        let client_ref = &client;
        let initial_sync = Arc::new(AtomicBool::new(true));
        let initial_ref = &initial_sync;

        client
            .sync_with_callback(SyncSettings::new(), |response| async move {
                let client = &client_ref;
                let initial = &initial_ref;

                let user_id = client.user_id().await.unwrap();
                let device_id = client.device_id().await.unwrap();
                let device = client
                    .encryption()
                    .get_device(&user_id, &device_id)
                    .await
                    .unwrap()
                    .unwrap();
                println!("Device {}'s verified: {:?}", &device_id, device.verified());

                for event in response.to_device.events.iter().filter_map(|e| e.deserialize().ok()) {
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
                        }
                        _ => (),
                    }
                }

                if !initial.load(Ordering::SeqCst) {
                    for (room_id, room_info) in response.rooms.join {
                        for event in room_info.timeline.events.iter().filter_map(|e| e.event.deserialize().ok()) {
                            if let AnySyncRoomEvent::MessageLike(event) = event {
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
                        }
                    }
                }

                initial.store(false, Ordering::SeqCst);
                LoopCtrl::Continue
            })
            .await;

        Ok(())
    }

    #[tokio::test]
    async fn test_emoji_verification() -> Result<()> {
        let z = Zenv::new(".env", false).parse()?;
        let homeserver_url: String = z.get("HOMESERVER_URL").unwrap().to_owned();
        let base_path: &str = z.get("BASE_PATH").unwrap();
        let username: &str = z.get("USERNAME").unwrap();
        let password: &str = z.get("PASSWORD").unwrap();

        login(homeserver_url, base_path, username, password).await?;

        Ok(())
    }
}
