use anyhow::Result;
use futures::{
    channel::mpsc::{channel, Receiver, Sender},
    StreamExt,
};
use log::{info, warn};
use matrix_sdk::{
    config::SyncSettings,
    deserialized_responses::Rooms,
    encryption::{
        identities::UserIdentity,
        verification::{SasVerification, Verification, VerificationRequest},
    },
    ruma::{
        api::client::sync::sync_events::v3::ToDevice,
        events::{
            key::verification::{cancel::CancelCode, VerificationMethod},
            room::message::MessageType,
            AnySyncMessageLikeEvent, AnySyncTimelineEvent, AnyToDeviceEvent, SyncMessageLikeEvent,
        },
        OwnedDeviceId, OwnedUserId, UserId,
    },
    Client as MatrixClient,
};
use parking_lot::Mutex;
use std::sync::Arc;

use super::{client::Client, RUNTIME};

#[derive(Clone, Debug)]
pub struct VerificationEvent {
    client: MatrixClient,
    event_type: String,
    /// EventId for ToDevice event, TransactionId for sync message
    flow_id: String,
    sender: OwnedUserId,
    /// for request/ready/start events
    launcher: Option<OwnedDeviceId>,
    /// for cancel event
    cancel_code: Option<CancelCode>,
    /// for cancel event
    reason: Option<String>,
}

impl VerificationEvent {
    pub(crate) fn new(
        client: &MatrixClient,
        event_type: String,
        flow_id: String,
        sender: OwnedUserId,
        launcher: Option<OwnedDeviceId>,
        cancel_code: Option<CancelCode>,
        reason: Option<String>,
    ) -> Self {
        VerificationEvent {
            client: client.clone(),
            event_type,
            flow_id,
            sender,
            launcher,
            cancel_code,
            reason,
        }
    }

    pub fn event_type(&self) -> String {
        self.event_type.clone()
    }

    pub fn flow_id(&self) -> String {
        self.flow_id.clone()
    }

    pub fn sender(&self) -> String {
        self.sender.to_string()
    }

    pub fn cancel_code(&self) -> Option<String> {
        self.cancel_code.clone().map(|e| e.to_string())
    }

    pub fn reason(&self) -> Option<String> {
        self.reason.clone()
    }

    pub async fn accept_verification_request(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = UserId::parse(self.sender.clone()).expect("Couldn't parse the user id");
        let flow_id = self.flow_id.clone();
        RUNTIME
            .spawn(async move {
                let request = client
                    .encryption()
                    .get_verification_request(&sender, flow_id.as_str())
                    .await
                    .expect("Could not get request object");
                request
                    .accept()
                    .await
                    .expect("Can't accept verification request");
                Ok(true)
            })
            .await?
    }

    pub async fn cancel_verification_request(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = UserId::parse(self.sender.clone()).expect("Couldn't parse the user id");
        let flow_id = self.flow_id.clone();
        RUNTIME
            .spawn(async move {
                let request = client
                    .encryption()
                    .get_verification_request(&sender, flow_id.as_str())
                    .await
                    .expect("Could not get request object");
                request
                    .cancel()
                    .await
                    .expect("Can't cancel verification request");
                Ok(true)
            })
            .await?
    }

    pub async fn accept_verification_request_with_methods(
        &self,
        methods: &mut Vec<String>,
    ) -> Result<bool> {
        let client = self.client.clone();
        let sender = UserId::parse(self.sender.clone()).expect("Couldn't parse the user id");
        let flow_id = self.flow_id.clone();
        let _methods: Vec<VerificationMethod> =
            (*methods).iter().map(|e| e.as_str().into()).collect();
        RUNTIME
            .spawn(async move {
                let request = client
                    .encryption()
                    .get_verification_request(&sender, flow_id.as_str())
                    .await
                    .expect("Could not get request object");
                request
                    .accept_with_methods(_methods)
                    .await
                    .expect("Can't accept verification request");
                Ok(true)
            })
            .await?
    }

    pub async fn start_sas_verification(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = UserId::parse(self.sender.clone()).expect("Couldn't parse the user id");
        let flow_id = self.flow_id.clone();
        RUNTIME
            .spawn(async move {
                let request = client
                    .encryption()
                    .get_verification_request(&sender, flow_id.as_str())
                    .await
                    .expect("Could not get request object");
                let sas_verification = request
                    .start_sas()
                    .await
                    .expect("Can't accept verification request");
                Ok(sas_verification.is_some())
            })
            .await?
    }

    pub fn was_triggered_from_this_device(&self) -> Option<bool> {
        let device_id = self
            .client
            .device_id()
            .expect("guest user cannot get device id");
        self.launcher.clone().map(|dev_id| dev_id == *device_id)
    }

    pub async fn accept_sas_verification(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = UserId::parse(self.sender.clone()).expect("Couldn't parse the user id");
        let flow_id = self.flow_id.clone();
        RUNTIME
            .spawn(async move {
                if let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, flow_id.as_str())
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

    pub async fn cancel_sas_verification(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = UserId::parse(self.sender.clone()).expect("Couldn't parse the user id");
        let flow_id = self.flow_id.clone();
        RUNTIME
            .spawn(async move {
                if let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, flow_id.as_str())
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

    pub async fn send_verification_key(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = UserId::parse(self.sender.clone()).expect("Couldn't parse the user id");
        let flow_id = self.flow_id.clone();
        RUNTIME
            .spawn(async move {
                client.sync_once(SyncSettings::default()).await?; // send_outgoing_requests is called there
                Ok(true)
            })
            .await?
    }

    pub async fn cancel_verification_key(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = UserId::parse(self.sender.clone()).expect("Couldn't parse the user id");
        let flow_id = self.flow_id.clone();
        RUNTIME
            .spawn(async move {
                if let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, flow_id.as_str())
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

    pub async fn get_verification_emoji(&self) -> Result<Vec<VerificationEmoji>> {
        let client = self.client.clone();
        let sender = UserId::parse(self.sender.clone()).expect("Couldn't parse the user id");
        let flow_id = self.flow_id.clone();
        RUNTIME
            .spawn(async move {
                if let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, flow_id.as_str())
                    .await
                {
                    if let Some(items) = sas.emoji() {
                        let sequence = items
                            .iter()
                            .map(|e| VerificationEmoji {
                                symbol: e.symbol.chars().collect::<Vec<_>>()[0] as u32,
                                description: e.description.to_string(),
                            })
                            .collect::<Vec<_>>();
                        return Ok(sequence);
                    }
                }
                Ok(vec![])
            })
            .await?
    }

    pub async fn confirm_sas_verification(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = UserId::parse(self.sender.clone()).expect("Couldn't parse the user id");
        let flow_id = self.flow_id.clone();
        RUNTIME
            .spawn(async move {
                if let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, flow_id.as_str())
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

    pub async fn mismatch_sas_verification(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = UserId::parse(self.sender.clone()).expect("Couldn't parse the user id");
        let flow_id = self.flow_id.clone();
        RUNTIME
            .spawn(async move {
                if let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, flow_id.as_str())
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

    pub async fn review_verification_mac(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = UserId::parse(self.sender.clone()).expect("Couldn't parse the user id");
        let flow_id = self.flow_id.clone();
        RUNTIME
            .spawn(async move {
                if let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, flow_id.as_str())
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

#[derive(Clone, Debug)]
pub struct VerificationEmoji {
    symbol: u32,
    description: String,
}

impl VerificationEmoji {
    pub fn symbol(&self) -> u32 {
        self.symbol
    }

    pub fn description(&self) -> String {
        self.description.clone()
    }
}

#[derive(Clone)]
pub(crate) struct VerificationController {
    event_tx: Sender<VerificationEvent>,
    event_rx: Arc<Mutex<Option<Receiver<VerificationEvent>>>>,
}

impl VerificationController {
    pub fn new() -> Self {
        let (tx, rx) = channel::<VerificationEvent>(10); // dropping after more than 10 items queued
        VerificationController {
            event_tx: tx,
            event_rx: Arc::new(Mutex::new(Some(rx))),
        }
    }

    fn handle_sync_messages(&mut self, client: &MatrixClient, evt: &AnySyncMessageLikeEvent) {
        match evt {
            AnySyncMessageLikeEvent::RoomMessage(SyncMessageLikeEvent::Original(ev)) => {
                if let MessageType::VerificationRequest(_) = &ev.content.msgtype {
                    let dev_id = client.device_id().expect("guest user cannot get device id");
                    info!("{} got {}", dev_id.to_string(), evt.event_type());
                    let flow_id = ev.event_id.to_string();
                    let msg = VerificationEvent::new(
                        client,
                        evt.event_type().to_string(),
                        flow_id.clone(),
                        ev.sender.clone(),
                        None,
                        None,
                        None,
                    );
                    if let Err(e) = self.event_tx.try_send(msg) {
                        warn!("Dropping event for {}: {}", flow_id, e);
                    }
                }
            }
            AnySyncMessageLikeEvent::KeyVerificationReady(SyncMessageLikeEvent::Original(ev)) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let flow_id = ev.content.relates_to.event_id.to_string();
                let msg = VerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    flow_id.clone(),
                    ev.sender.clone(),
                    Some(ev.content.from_device.clone()),
                    None,
                    None,
                );
                if let Err(e) = self.event_tx.try_send(msg) {
                    warn!("Dropping event for {}: {}", flow_id, e);
                }
            }
            AnySyncMessageLikeEvent::KeyVerificationStart(SyncMessageLikeEvent::Original(ev)) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let flow_id = ev.content.relates_to.event_id.to_string();
                let msg = VerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    flow_id.clone(),
                    ev.sender.clone(),
                    Some(ev.content.from_device.clone()),
                    None,
                    None,
                );
                if let Err(e) = self.event_tx.try_send(msg) {
                    warn!("Dropping event for {}: {}", flow_id, e);
                }
            }
            AnySyncMessageLikeEvent::KeyVerificationAccept(SyncMessageLikeEvent::Original(ev)) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let flow_id = ev.content.relates_to.event_id.to_string();
                let msg = VerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    flow_id.clone(),
                    ev.sender.clone(),
                    None,
                    None,
                    None,
                );
                if let Err(e) = self.event_tx.try_send(msg) {
                    warn!("Dropping event for {}: {}", flow_id, e);
                }
            }
            AnySyncMessageLikeEvent::KeyVerificationCancel(SyncMessageLikeEvent::Original(ev)) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let flow_id = ev.content.relates_to.event_id.to_string();
                let msg = VerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    flow_id.clone(),
                    ev.sender.clone(),
                    None,
                    Some(ev.content.code.clone()),
                    Some(ev.content.reason.clone()),
                );
                if let Err(e) = self.event_tx.try_send(msg) {
                    warn!("Dropping event for {}: {}", flow_id, e);
                }
            }
            AnySyncMessageLikeEvent::KeyVerificationKey(SyncMessageLikeEvent::Original(ev)) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let flow_id = ev.content.relates_to.event_id.to_string();
                let msg = VerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    flow_id.clone(),
                    ev.sender.clone(),
                    None,
                    None,
                    None,
                );
                if let Err(e) = self.event_tx.try_send(msg) {
                    warn!("Dropping event for {}: {}", flow_id, e);
                }
            }
            AnySyncMessageLikeEvent::KeyVerificationMac(SyncMessageLikeEvent::Original(ev)) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let flow_id = ev.content.relates_to.event_id.to_string();
                let msg = VerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    flow_id.clone(),
                    ev.sender.clone(),
                    None,
                    None,
                    None,
                );
                if let Err(e) = self.event_tx.try_send(msg) {
                    warn!("Dropping event for {}: {}", flow_id, e);
                }
            }
            AnySyncMessageLikeEvent::KeyVerificationDone(SyncMessageLikeEvent::Original(ev)) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let flow_id = ev.content.relates_to.event_id.to_string();
                let msg = VerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    flow_id.clone(),
                    ev.sender.clone(),
                    None,
                    None,
                    None,
                );
                if let Err(e) = self.event_tx.try_send(msg) {
                    warn!("Dropping event for {}: {}", flow_id, e);
                }
            }
            _ => {}
        }
    }

    pub fn process_sync_messages(&mut self, client: &MatrixClient, rooms: &Rooms) {
        for (room_id, room_info) in rooms.join.iter() {
            for event in room_info
                .timeline
                .events
                .iter()
                .filter_map(|ev| ev.event.deserialize().ok())
            {
                if let AnySyncTimelineEvent::MessageLike(ref evt) = event {
                    self.handle_sync_messages(client, evt);
                }
            }
        }
    }

    fn handle_to_device_messages(&mut self, client: &MatrixClient, evt: &AnyToDeviceEvent) {
        match evt {
            AnyToDeviceEvent::KeyVerificationRequest(ref ev) => {
                let dev_id = client
                    .device_id()
                    .expect("guest user cannot get device id")
                    .to_string();
                info!("{} got {}", dev_id, evt.event_type());
                let flow_id = ev.content.transaction_id.to_string();
                let msg = VerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    flow_id.clone(),
                    ev.sender.clone(),
                    Some(ev.content.from_device.clone()),
                    None,
                    None,
                );
                if let Err(e) = self.event_tx.try_send(msg) {
                    warn!("Dropping transaction for {}: {}", flow_id, e);
                }
            }
            AnyToDeviceEvent::KeyVerificationReady(ref ev) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let flow_id = ev.content.transaction_id.to_string();
                let msg = VerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    flow_id.clone(),
                    ev.sender.clone(),
                    Some(ev.content.from_device.clone()),
                    None,
                    None,
                );
                if let Err(e) = self.event_tx.try_send(msg) {
                    warn!("Dropping transaction for {}: {}", flow_id, e);
                }
            }
            AnyToDeviceEvent::KeyVerificationStart(ref ev) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let flow_id = ev.content.transaction_id.to_string();
                let msg = VerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    flow_id.clone(),
                    ev.sender.clone(),
                    Some(ev.content.from_device.clone()),
                    None,
                    None,
                );
                if let Err(e) = self.event_tx.try_send(msg) {
                    warn!("Dropping transaction for {}: {}", flow_id, e);
                }
            }
            AnyToDeviceEvent::KeyVerificationAccept(ref ev) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let flow_id = ev.content.transaction_id.to_string();
                let msg = VerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    flow_id.clone(),
                    ev.sender.clone(),
                    None,
                    None,
                    None,
                );
                if let Err(e) = self.event_tx.try_send(msg) {
                    warn!("Dropping transaction for {}: {}", flow_id, e);
                }
            }
            AnyToDeviceEvent::KeyVerificationCancel(ref ev) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let flow_id = ev.content.transaction_id.to_string();
                let msg = VerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    flow_id.clone(),
                    ev.sender.clone(),
                    None,
                    Some(ev.content.code.clone()),
                    Some(ev.content.reason.clone()),
                );
                if let Err(e) = self.event_tx.try_send(msg) {
                    warn!("Dropping transaction for {}: {}", flow_id, e);
                }
            }
            AnyToDeviceEvent::KeyVerificationKey(ref ev) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let flow_id = ev.content.transaction_id.to_string();
                let msg = VerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    flow_id.clone(),
                    ev.sender.clone(),
                    None,
                    None,
                    None,
                );
                if let Err(e) = self.event_tx.try_send(msg) {
                    warn!("Dropping transaction for {}: {}", flow_id, e);
                }
            }
            AnyToDeviceEvent::KeyVerificationMac(ref ev) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let flow_id = ev.content.transaction_id.to_string();
                let msg = VerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    flow_id.clone(),
                    ev.sender.clone(),
                    None,
                    None,
                    None,
                );
                if let Err(e) = self.event_tx.try_send(msg) {
                    warn!("Dropping transaction for {}: {}", flow_id, e);
                }
            }
            AnyToDeviceEvent::KeyVerificationDone(ref ev) => {
                let dev_id = client.device_id().expect("guest user cannot get device id");
                info!("{} got {}", dev_id.to_string(), evt.event_type());
                let flow_id = ev.content.transaction_id.to_string();
                let msg = VerificationEvent::new(
                    client,
                    evt.event_type().to_string(),
                    flow_id.clone(),
                    ev.sender.clone(),
                    None,
                    None,
                    None,
                );
                if let Err(e) = self.event_tx.try_send(msg) {
                    warn!("Dropping transaction for {}: {}", flow_id, e);
                }
            }
            _ => {}
        }
    }

    pub fn process_to_device_messages(&mut self, client: &MatrixClient, to_device: ToDevice) {
        for evt in to_device
            .events
            .into_iter()
            .filter_map(|e| e.deserialize().ok())
        {
            self.handle_to_device_messages(client, &evt);
        }
    }
}

impl Client {
    pub fn verification_event_rx(&self) -> Option<Receiver<VerificationEvent>> {
        self.verification_controller.event_rx.lock().take()
    }
}
