use anyhow::Result;
use futures::{
    channel::mpsc::{channel, Receiver, Sender},
    StreamExt,
};
use log::{info, warn};
use matrix_sdk::{
    config::SyncSettings,
    encryption::verification::{Verification, VerificationRequest},
    event_handler::{Ctx, EventHandlerHandle},
    ruma::{
        events::{
            forwarded_room_key::ToDeviceForwardedRoomKeyEvent,
            key::verification::{
                accept::{
                    OriginalSyncKeyVerificationAcceptEvent, ToDeviceKeyVerificationAcceptEvent,
                },
                cancel::{
                    CancelCode, OriginalSyncKeyVerificationCancelEvent,
                    ToDeviceKeyVerificationCancelEvent,
                },
                done::{OriginalSyncKeyVerificationDoneEvent, ToDeviceKeyVerificationDoneEvent},
                key::{OriginalSyncKeyVerificationKeyEvent, ToDeviceKeyVerificationKeyEvent},
                mac::{OriginalSyncKeyVerificationMacEvent, ToDeviceKeyVerificationMacEvent},
                ready::{OriginalSyncKeyVerificationReadyEvent, ToDeviceKeyVerificationReadyEvent},
                request::ToDeviceKeyVerificationRequestEvent,
                start::{OriginalSyncKeyVerificationStartEvent, ToDeviceKeyVerificationStartEvent},
                VerificationMethod,
            },
            room::{
                encrypted::{OriginalSyncRoomEncryptedEvent, ToDeviceRoomEncryptedEvent},
                message::{MessageType, OriginalSyncRoomMessageEvent},
            },
            room_key::ToDeviceRoomKeyEvent,
            room_key_request::ToDeviceRoomKeyRequestEvent,
            secret::{
                request::{RequestAction, ToDeviceSecretRequestEvent},
                send::ToDeviceSecretSendEvent,
            },
            EventContent,
        },
        OwnedDeviceId, OwnedEventId, OwnedTransactionId, OwnedUserId,
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
    /// for ToDevice event
    event_id: Option<OwnedEventId>,
    /// for sync message
    txn_id: Option<OwnedTransactionId>,
    sender: OwnedUserId,
    /// for request/ready/start events
    launcher: Option<OwnedDeviceId>,
    /// for cancel event
    cancel_code: Option<CancelCode>,
    /// for cancel event
    reason: Option<String>,
}

impl VerificationEvent {
    #[allow(clippy::too_many_arguments)]
    pub(crate) fn new(
        client: &MatrixClient,
        event_type: String,
        event_id: Option<OwnedEventId>,
        txn_id: Option<OwnedTransactionId>,
        sender: OwnedUserId,
        launcher: Option<OwnedDeviceId>,
        cancel_code: Option<CancelCode>,
        reason: Option<String>,
    ) -> Self {
        VerificationEvent {
            client: client.clone(),
            event_type,
            event_id,
            txn_id,
            sender,
            launcher,
            cancel_code,
            reason,
        }
    }

    pub fn event_type(&self) -> String {
        self.event_type.clone()
    }

    pub fn flow_id(&self) -> Option<String> {
        if let Some(event_id) = &self.event_id {
            Some(event_id.to_string())
        } else {
            self.txn_id.as_ref().map(|x| x.to_string())
        }
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
        let sender = self.sender.clone();
        let event_id = self.event_id.clone();
        let txn_id = self.txn_id.clone();
        RUNTIME
            .spawn(async move {
                if let Some(event_id) = event_id {
                    if let Some(request) = client
                        .encryption()
                        .get_verification_request(&sender, event_id)
                        .await
                    {
                        request
                            .accept()
                            .await
                            .expect("Can't accept verification request");
                        return Ok(true);
                    }
                } else if let Some(txn_id) = txn_id {
                    if let Some(request) = client
                        .encryption()
                        .get_verification_request(&sender, txn_id)
                        .await
                    {
                        request
                            .accept()
                            .await
                            .expect("Can't accept verification request");
                        return Ok(true);
                    }
                }
                // request may be timed out
                info!("Could not get verification request");
                Ok(false)
            })
            .await?
    }

    pub async fn cancel_verification_request(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = self.sender.clone();
        let event_id = self.event_id.clone();
        let txn_id = self.txn_id.clone();
        RUNTIME
            .spawn(async move {
                if let Some(event_id) = event_id {
                    if let Some(request) = client
                        .encryption()
                        .get_verification_request(&sender, event_id)
                        .await
                    {
                        request
                            .cancel()
                            .await
                            .expect("Can't cancel verification request");
                        return Ok(true);
                    }
                } else if let Some(txn_id) = txn_id {
                    if let Some(request) = client
                        .encryption()
                        .get_verification_request(&sender, txn_id)
                        .await
                    {
                        request
                            .cancel()
                            .await
                            .expect("Can't cancel verification request");
                        return Ok(true);
                    }
                }
                // request may be timed out
                info!("Could not get verification request");
                Ok(false)
            })
            .await?
    }

    pub async fn accept_verification_request_with_methods(
        &self,
        methods: &mut Vec<String>,
    ) -> Result<bool> {
        let client = self.client.clone();
        let sender = self.sender.clone();
        let event_id = self.event_id.clone();
        let txn_id = self.txn_id.clone();
        let values: Vec<VerificationMethod> =
            (*methods).iter().map(|e| e.as_str().into()).collect();
        RUNTIME
            .spawn(async move {
                if let Some(event_id) = event_id {
                    if let Some(request) = client
                        .encryption()
                        .get_verification_request(&sender, event_id)
                        .await
                    {
                        request
                            .accept_with_methods(values)
                            .await
                            .expect("Can't accept verification request");
                        return Ok(true);
                    }
                } else if let Some(txn_id) = txn_id {
                    if let Some(request) = client
                        .encryption()
                        .get_verification_request(&sender, txn_id)
                        .await
                    {
                        request
                            .accept_with_methods(values)
                            .await
                            .expect("Can't accept verification request");
                        return Ok(true);
                    }
                }
                // request may be timed out
                info!("Could not get verification request");
                Ok(false)
            })
            .await?
    }

    pub async fn start_sas_verification(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = self.sender.clone();
        let event_id = self.event_id.clone();
        let txn_id = self.txn_id.clone();
        RUNTIME
            .spawn(async move {
                if let Some(event_id) = event_id {
                    if let Some(request) = client
                        .encryption()
                        .get_verification_request(&sender, event_id)
                        .await
                    {
                        let sas = request
                            .start_sas()
                            .await
                            .expect("Can't accept verification request");
                        return Ok(sas.is_some());
                    }
                } else if let Some(txn_id) = txn_id {
                    if let Some(request) = client
                        .encryption()
                        .get_verification_request(&sender, txn_id)
                        .await
                    {
                        let sas = request
                            .start_sas()
                            .await
                            .expect("Can't accept verification request");
                        return Ok(sas.is_some());
                    }
                }
                // request may be timed out
                info!("Could not get verification request");
                Ok(false)
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
        let sender = self.sender.clone();
        let event_id = self.event_id.clone();
        let txn_id = self.txn_id.clone();
        RUNTIME
            .spawn(async move {
                if let Some(event_id) = event_id {
                    if let Some(Verification::SasV1(sas)) = client
                        .encryption()
                        .get_verification(&sender, event_id.as_str())
                        .await
                    {
                        sas.accept().await?;
                        return Ok(true);
                    }
                } else if let Some(txn_id) = txn_id {
                    if let Some(Verification::SasV1(sas)) = client
                        .encryption()
                        .get_verification(&sender, txn_id.as_str())
                        .await
                    {
                        sas.accept().await?;
                        return Ok(true);
                    }
                }
                // request may be timed out
                info!("Could not get verification object");
                Ok(false)
            })
            .await?
    }

    pub async fn cancel_sas_verification(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = self.sender.clone();
        let event_id = self.event_id.clone();
        let txn_id = self.txn_id.clone();
        RUNTIME
            .spawn(async move {
                if let Some(event_id) = event_id {
                    if let Some(Verification::SasV1(sas)) = client
                        .encryption()
                        .get_verification(&sender, event_id.as_str())
                        .await
                    {
                        sas.cancel().await?;
                        return Ok(true);
                    }
                } else if let Some(txn_id) = txn_id {
                    if let Some(Verification::SasV1(sas)) = client
                        .encryption()
                        .get_verification(&sender, txn_id.as_str())
                        .await
                    {
                        sas.cancel().await?;
                        return Ok(true);
                    }
                }
                // request may be timed out
                info!("Could not get verification object");
                Ok(false)
            })
            .await?
    }

    pub async fn send_verification_key(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = self.sender.clone();
        RUNTIME
            .spawn(async move {
                client.sync_once(SyncSettings::default()).await?; // send_outgoing_requests is called there
                Ok(true)
            })
            .await?
    }

    pub async fn cancel_verification_key(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = self.sender.clone();
        let event_id = self.event_id.clone();
        let txn_id = self.txn_id.clone();
        RUNTIME
            .spawn(async move {
                if let Some(event_id) = event_id {
                    if let Some(Verification::SasV1(sas)) = client
                        .encryption()
                        .get_verification(&sender, event_id.as_str())
                        .await
                    {
                        sas.cancel().await?;
                        return Ok(true);
                    }
                } else if let Some(txn_id) = txn_id {
                    if let Some(Verification::SasV1(sas)) = client
                        .encryption()
                        .get_verification(&sender, txn_id.as_str())
                        .await
                    {
                        sas.cancel().await?;
                        return Ok(true);
                    }
                }
                // request may be timed out
                info!("Could not get verification object");
                Ok(false)
            })
            .await?
    }

    pub async fn get_verification_emoji(&self) -> Result<Vec<VerificationEmoji>> {
        let client = self.client.clone();
        let sender = self.sender.clone();
        let event_id = self.event_id.clone();
        let txn_id = self.txn_id.clone();
        RUNTIME
            .spawn(async move {
                if let Some(event_id) = event_id {
                    if let Some(Verification::SasV1(sas)) = client
                        .encryption()
                        .get_verification(&sender, event_id.as_str())
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
                        } else {
                            return Ok(vec![]);
                        }
                    }
                } else if let Some(txn_id) = txn_id {
                    if let Some(Verification::SasV1(sas)) = client
                        .encryption()
                        .get_verification(&sender, txn_id.as_str())
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
                        } else {
                            return Ok(vec![]);
                        }
                    }
                }
                // request may be timed out
                info!("Could not get verification object");
                Ok(vec![])
            })
            .await?
    }

    pub async fn confirm_sas_verification(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = self.sender.clone();
        let event_id = self.event_id.clone();
        let txn_id = self.txn_id.clone();
        RUNTIME
            .spawn(async move {
                if let Some(event_id) = event_id {
                    if let Some(Verification::SasV1(sas)) = client
                        .encryption()
                        .get_verification(&sender, event_id.as_str())
                        .await
                    {
                        sas.confirm().await?;
                        return Ok(sas.is_done());
                    }
                } else if let Some(txn_id) = txn_id {
                    if let Some(Verification::SasV1(sas)) = client
                        .encryption()
                        .get_verification(&sender, txn_id.as_str())
                        .await
                    {
                        sas.confirm().await?;
                        return Ok(sas.is_done());
                    }
                }
                // request may be timed out
                info!("Could not get verification object");
                Ok(false)
            })
            .await?
    }

    pub async fn mismatch_sas_verification(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = self.sender.clone();
        let event_id = self.event_id.clone();
        let txn_id = self.txn_id.clone();
        RUNTIME
            .spawn(async move {
                if let Some(event_id) = event_id {
                    if let Some(Verification::SasV1(sas)) = client
                        .encryption()
                        .get_verification(&sender, event_id.as_str())
                        .await
                    {
                        sas.mismatch().await?;
                        return Ok(true);
                    }
                } else if let Some(txn_id) = txn_id {
                    if let Some(Verification::SasV1(sas)) = client
                        .encryption()
                        .get_verification(&sender, txn_id.as_str())
                        .await
                    {
                        sas.mismatch().await?;
                        return Ok(true);
                    }
                }
                // request may be timed out
                info!("Could not get verification object");
                Ok(false)
            })
            .await?
    }

    pub async fn review_verification_mac(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = self.sender.clone();
        let event_id = self.event_id.clone();
        let txn_id = self.txn_id.clone();
        RUNTIME
            .spawn(async move {
                if let Some(event_id) = event_id {
                    if let Some(Verification::SasV1(sas)) = client
                        .encryption()
                        .get_verification(&sender, event_id.as_str())
                        .await
                    {
                        return Ok(sas.is_done());
                    }
                } else if let Some(txn_id) = txn_id {
                    if let Some(Verification::SasV1(sas)) = client
                        .encryption()
                        .get_verification(&sender, txn_id.as_str())
                        .await
                    {
                        return Ok(sas.is_done());
                    }
                }
                // request may be timed out
                info!("Could not get verification object");
                Ok(false)
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
    sync_key_verification_request_handle: Option<EventHandlerHandle>,
    sync_key_verification_ready_handle: Option<EventHandlerHandle>,
    sync_key_verification_start_handle: Option<EventHandlerHandle>,
    sync_key_verification_cancel_handle: Option<EventHandlerHandle>,
    sync_key_verification_accept_handle: Option<EventHandlerHandle>,
    sync_key_verification_key_handle: Option<EventHandlerHandle>,
    sync_key_verification_mac_handle: Option<EventHandlerHandle>,
    sync_key_verification_done_handle: Option<EventHandlerHandle>,
    sync_room_encrypted_handle: Option<EventHandlerHandle>,
    to_device_key_verification_request_handle: Option<EventHandlerHandle>,
    to_device_key_verification_ready_handle: Option<EventHandlerHandle>,
    to_device_key_verification_start_handle: Option<EventHandlerHandle>,
    to_device_key_verification_cancel_handle: Option<EventHandlerHandle>,
    to_device_key_verification_accept_handle: Option<EventHandlerHandle>,
    to_device_key_verification_key_handle: Option<EventHandlerHandle>,
    to_device_key_verification_mac_handle: Option<EventHandlerHandle>,
    to_device_key_verification_done_handle: Option<EventHandlerHandle>,
    to_device_room_encrypted_handle: Option<EventHandlerHandle>,
    to_device_room_key_handle: Option<EventHandlerHandle>,
    to_device_room_key_request_handle: Option<EventHandlerHandle>,
    to_device_forwarded_room_key_handle: Option<EventHandlerHandle>,
    to_device_secret_send_handle: Option<EventHandlerHandle>,
    to_device_secret_request_handle: Option<EventHandlerHandle>,
}

impl VerificationController {
    pub fn new() -> Self {
        let (tx, rx) = channel::<VerificationEvent>(10); // dropping after more than 10 items queued
        VerificationController {
            event_tx: tx,
            event_rx: Arc::new(Mutex::new(Some(rx))),
            sync_key_verification_request_handle: None,
            sync_key_verification_ready_handle: None,
            sync_key_verification_start_handle: None,
            sync_key_verification_cancel_handle: None,
            sync_key_verification_accept_handle: None,
            sync_key_verification_key_handle: None,
            sync_key_verification_mac_handle: None,
            sync_key_verification_done_handle: None,
            sync_room_encrypted_handle: None,
            to_device_key_verification_request_handle: None,
            to_device_key_verification_ready_handle: None,
            to_device_key_verification_start_handle: None,
            to_device_key_verification_cancel_handle: None,
            to_device_key_verification_accept_handle: None,
            to_device_key_verification_key_handle: None,
            to_device_key_verification_mac_handle: None,
            to_device_key_verification_done_handle: None,
            to_device_room_encrypted_handle: None,
            to_device_room_key_handle: None,
            to_device_room_key_request_handle: None,
            to_device_forwarded_room_key_handle: None,
            to_device_secret_send_handle: None,
            to_device_secret_request_handle: None,
        }
    }

    pub fn add_sync_event_handler(&mut self, client: &MatrixClient) {
        let me = self.clone();

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: OriginalSyncRoomMessageEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                if let MessageType::VerificationRequest(content) = &ev.content.msgtype {
                    let dev_id = c.device_id().expect("guest user cannot get device id");
                    let event_type = ev.content.event_type();
                    info!("{} got {}", dev_id, event_type);
                    let event_id = ev.event_id;
                    let methods = content.methods.clone();
                    let msg = VerificationEvent::new(
                        &c,
                        event_type.to_string(),
                        Some(event_id.clone()),
                        None,
                        ev.sender.clone(),
                        None,
                        None,
                        None,
                    );
                    if let Err(e) = me.event_tx.try_send(msg) {
                        warn!("Dropping event for {}: {}", event_id, e);
                    }
                }
            },
        );
        self.sync_key_verification_request_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: OriginalSyncKeyVerificationReadyEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", dev_id, event_type);
                let event_id = ev.content.relates_to.event_id;
                let msg = VerificationEvent::new(
                    &c,
                    event_type.to_string(),
                    Some(event_id.clone()),
                    None,
                    ev.sender.clone(),
                    Some(ev.content.from_device.clone()),
                    None,
                    None,
                );
                if let Err(e) = me.event_tx.try_send(msg) {
                    warn!("Dropping event for {}: {}", event_id, e);
                }
            },
        );
        self.sync_key_verification_ready_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: OriginalSyncKeyVerificationStartEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", dev_id, event_type);
                let event_id = ev.content.relates_to.event_id;
                let method = ev.content.method;
                let msg = VerificationEvent::new(
                    &c,
                    event_type.to_string(),
                    Some(event_id.clone()),
                    None,
                    ev.sender.clone(),
                    Some(ev.content.from_device.clone()),
                    None,
                    None,
                );
                if let Err(e) = me.event_tx.try_send(msg) {
                    warn!("Dropping event for {}: {}", event_id, e);
                }
            },
        );
        self.sync_key_verification_start_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: OriginalSyncKeyVerificationCancelEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", dev_id, event_type);
                let event_id = ev.content.relates_to.event_id;
                let msg = VerificationEvent::new(
                    &c,
                    event_type.to_string(),
                    Some(event_id.clone()),
                    None,
                    ev.sender.clone(),
                    None,
                    Some(ev.content.code.clone()),
                    Some(ev.content.reason.clone()),
                );
                if let Err(e) = me.event_tx.try_send(msg) {
                    warn!("Dropping event for {}: {}", event_id, e);
                }
            },
        );
        self.sync_key_verification_cancel_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: OriginalSyncKeyVerificationAcceptEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", dev_id, event_type);
                let event_id = ev.content.relates_to.event_id;
                let method = ev.content.method;
                let msg = VerificationEvent::new(
                    &c,
                    event_type.to_string(),
                    Some(event_id.clone()),
                    None,
                    ev.sender.clone(),
                    None,
                    None,
                    None,
                );
                if let Err(e) = me.event_tx.try_send(msg) {
                    warn!("Dropping event for {}: {}", event_id, e);
                }
            },
        );
        self.sync_key_verification_accept_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: OriginalSyncKeyVerificationKeyEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", dev_id, event_type);
                let event_id = ev.content.relates_to.event_id;
                let key = ev.content.key;
                let msg = VerificationEvent::new(
                    &c,
                    event_type.to_string(),
                    Some(event_id.clone()),
                    None,
                    ev.sender.clone(),
                    None,
                    None,
                    None,
                );
                if let Err(e) = me.event_tx.try_send(msg) {
                    warn!("Dropping event for {}: {}", event_id, e);
                }
            },
        );
        self.sync_key_verification_key_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: OriginalSyncKeyVerificationMacEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", dev_id, event_type);
                let event_id = ev.content.relates_to.event_id;
                let mac = ev.content.mac;
                let keys = ev.content.keys;
                let msg = VerificationEvent::new(
                    &c,
                    event_type.to_string(),
                    Some(event_id.clone()),
                    None,
                    ev.sender.clone(),
                    None,
                    None,
                    None,
                );
                if let Err(e) = me.event_tx.try_send(msg) {
                    warn!("Dropping event for {}: {}", event_id, e);
                }
            },
        );
        self.sync_key_verification_mac_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: OriginalSyncKeyVerificationDoneEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", dev_id, event_type);
                let event_id = ev.content.relates_to.event_id;
                let msg = VerificationEvent::new(
                    &c,
                    event_type.to_string(),
                    Some(event_id.clone()),
                    None,
                    ev.sender.clone(),
                    None,
                    None,
                    None,
                );
                if let Err(e) = me.event_tx.try_send(msg) {
                    warn!("Dropping event for {}: {}", event_id, e);
                }
            },
        );
        self.sync_key_verification_done_handle = Some(handle);

        client.add_event_handler_context(me);
        let handle = client.add_event_handler(
            |ev: OriginalSyncRoomEncryptedEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", dev_id, event_type);
            },
        );
        self.sync_room_encrypted_handle = Some(handle);
    }

    pub fn remove_sync_event_handler(&mut self, client: &MatrixClient) {
        if let Some(handle) = self.sync_key_verification_request_handle.clone() {
            client.remove_event_handler(handle);
            self.sync_key_verification_request_handle = None;
        }
        if let Some(handle) = self.sync_key_verification_ready_handle.clone() {
            client.remove_event_handler(handle);
            self.sync_key_verification_ready_handle = None;
        }
        if let Some(handle) = self.sync_key_verification_start_handle.clone() {
            client.remove_event_handler(handle);
            self.sync_key_verification_start_handle = None;
        }
        if let Some(handle) = self.sync_key_verification_cancel_handle.clone() {
            client.remove_event_handler(handle);
            self.sync_key_verification_cancel_handle = None;
        }
        if let Some(handle) = self.sync_key_verification_accept_handle.clone() {
            client.remove_event_handler(handle);
            self.sync_key_verification_accept_handle = None;
        }
        if let Some(handle) = self.sync_key_verification_key_handle.clone() {
            client.remove_event_handler(handle);
            self.sync_key_verification_key_handle = None;
        }
        if let Some(handle) = self.sync_key_verification_mac_handle.clone() {
            client.remove_event_handler(handle);
            self.sync_key_verification_mac_handle = None;
        }
        if let Some(handle) = self.sync_key_verification_done_handle.clone() {
            client.remove_event_handler(handle);
            self.sync_key_verification_done_handle = None;
        }
        if let Some(handle) = self.sync_room_encrypted_handle.clone() {
            client.remove_event_handler(handle);
            self.sync_room_encrypted_handle = None;
        }
    }

    pub fn add_to_device_event_handler(&mut self, client: &MatrixClient) {
        let me = self.clone();

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceKeyVerificationRequestEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", dev_id, event_type);
                let txn_id = ev.content.transaction_id;
                let methods = ev.content.methods.clone();
                let msg = VerificationEvent::new(
                    &c,
                    event_type.to_string(),
                    None,
                    Some(txn_id.clone()),
                    ev.sender.clone(),
                    Some(ev.content.from_device.clone()),
                    None,
                    None,
                );
                if let Err(e) = me.event_tx.try_send(msg) {
                    warn!("Dropping transaction for {}: {}", txn_id, e);
                }
            },
        );
        self.to_device_key_verification_request_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceKeyVerificationReadyEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", dev_id, event_type);
                let txn_id = ev.content.transaction_id;
                let methods = ev.content.methods;
                let msg = VerificationEvent::new(
                    &c,
                    event_type.to_string(),
                    None,
                    Some(txn_id.clone()),
                    ev.sender.clone(),
                    Some(ev.content.from_device.clone()),
                    None,
                    None,
                );
                if let Err(e) = me.event_tx.try_send(msg) {
                    warn!("Dropping transaction for {}: {}", txn_id, e);
                }
            },
        );
        self.to_device_key_verification_ready_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceKeyVerificationStartEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", dev_id, event_type);
                let txn_id = ev.content.transaction_id;
                let method = ev.content.method;
                let msg = VerificationEvent::new(
                    &c,
                    event_type.to_string(),
                    None,
                    Some(txn_id.clone()),
                    ev.sender.clone(),
                    Some(ev.content.from_device.clone()),
                    None,
                    None,
                );
                if let Err(e) = me.event_tx.try_send(msg) {
                    warn!("Dropping transaction for {}: {}", txn_id, e);
                }
            },
        );
        self.to_device_key_verification_start_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceKeyVerificationCancelEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", dev_id, event_type);
                let txn_id = ev.content.transaction_id;
                let msg = VerificationEvent::new(
                    &c,
                    event_type.to_string(),
                    None,
                    Some(txn_id.clone()),
                    ev.sender.clone(),
                    None,
                    Some(ev.content.code.clone()),
                    Some(ev.content.reason.clone()),
                );
                if let Err(e) = me.event_tx.try_send(msg) {
                    warn!("Dropping transaction for {}: {}", txn_id, e);
                }
            },
        );
        self.to_device_key_verification_cancel_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceKeyVerificationAcceptEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", dev_id, event_type);
                let txn_id = ev.content.transaction_id;
                let method = ev.content.method;
                let msg = VerificationEvent::new(
                    &c,
                    event_type.to_string(),
                    None,
                    Some(txn_id.clone()),
                    ev.sender.clone(),
                    None,
                    None,
                    None,
                );
                if let Err(e) = me.event_tx.try_send(msg) {
                    warn!("Dropping transaction for {}: {}", txn_id, e);
                }
            },
        );
        self.to_device_key_verification_accept_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceKeyVerificationKeyEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", dev_id, event_type);
                let txn_id = ev.content.transaction_id;
                let key = ev.content.key;
                let msg = VerificationEvent::new(
                    &c,
                    event_type.to_string(),
                    None,
                    Some(txn_id.clone()),
                    ev.sender.clone(),
                    None,
                    None,
                    None,
                );
                if let Err(e) = me.event_tx.try_send(msg) {
                    warn!("Dropping transaction for {}: {}", txn_id, e);
                }
            },
        );
        self.to_device_key_verification_key_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceKeyVerificationMacEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", dev_id, event_type);
                let txn_id = ev.content.transaction_id;
                let mac = ev.content.mac;
                let keys = ev.content.keys;
                let msg = VerificationEvent::new(
                    &c,
                    event_type.to_string(),
                    None,
                    Some(txn_id.clone()),
                    ev.sender.clone(),
                    None,
                    None,
                    None,
                );
                if let Err(e) = me.event_tx.try_send(msg) {
                    warn!("Dropping transaction for {}: {}", txn_id, e);
                }
            },
        );
        self.to_device_key_verification_mac_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceKeyVerificationDoneEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", dev_id, event_type);
                let txn_id = ev.content.transaction_id;
                let msg = VerificationEvent::new(
                    &c,
                    event_type.to_string(),
                    None,
                    Some(txn_id.clone()),
                    ev.sender.clone(),
                    None,
                    None,
                    None,
                );
                if let Err(e) = me.event_tx.try_send(msg) {
                    warn!("Dropping transaction for {}: {}", txn_id, e);
                }
            },
        );
        self.to_device_key_verification_done_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceRoomEncryptedEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", dev_id, event_type);
            },
        );
        self.to_device_room_encrypted_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceRoomKeyEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", dev_id, event_type);
            },
        );
        self.to_device_room_key_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceRoomKeyRequestEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", dev_id, event_type);
            },
        );
        self.to_device_room_key_request_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceForwardedRoomKeyEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", dev_id, event_type);
            },
        );
        self.to_device_forwarded_room_key_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceSecretSendEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", dev_id, event_type);
            },
        );
        self.to_device_secret_send_handle = Some(handle);

        client.add_event_handler_context(me);
        let handle = client.add_event_handler(
            |ev: ToDeviceSecretRequestEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", dev_id, event_type);
                info!("ToDeviceSecretRequestEvent: {:?}", ev);
                let secret_name = match &ev.content.action {
                    RequestAction::Request(s) => s,
                    // We ignore cancellations here since there's nothing to serve.
                    RequestAction::RequestCancellation => return,
                    action => {
                        warn!("Unknown secret request action");
                        return;
                    }
                };
                if let Ok(Some(device)) = c
                    .encryption()
                    .get_device(&ev.sender, &ev.content.requesting_device_id)
                    .await
                {
                    let user_id = c.user_id().expect("guest user cannot get user id");
                    if device.user_id() == user_id && device.is_verified() {}
                }
            },
        );
        self.to_device_secret_request_handle = Some(handle);
    }

    pub fn remove_to_device_event_handler(&mut self, client: &MatrixClient) {
        if let Some(handle) = self.to_device_key_verification_request_handle.clone() {
            client.remove_event_handler(handle);
            self.to_device_key_verification_request_handle = None;
        }
        if let Some(handle) = self.to_device_key_verification_ready_handle.clone() {
            client.remove_event_handler(handle);
            self.to_device_key_verification_ready_handle = None;
        }
        if let Some(handle) = self.to_device_key_verification_start_handle.clone() {
            client.remove_event_handler(handle);
            self.to_device_key_verification_start_handle = None;
        }
        if let Some(handle) = self.to_device_key_verification_cancel_handle.clone() {
            client.remove_event_handler(handle);
            self.to_device_key_verification_cancel_handle = None;
        }
        if let Some(handle) = self.to_device_key_verification_accept_handle.clone() {
            client.remove_event_handler(handle);
            self.to_device_key_verification_accept_handle = None;
        }
        if let Some(handle) = self.to_device_key_verification_key_handle.clone() {
            client.remove_event_handler(handle);
            self.to_device_key_verification_key_handle = None;
        }
        if let Some(handle) = self.to_device_key_verification_mac_handle.clone() {
            client.remove_event_handler(handle);
            self.to_device_key_verification_mac_handle = None;
        }
        if let Some(handle) = self.to_device_key_verification_done_handle.clone() {
            client.remove_event_handler(handle);
            self.to_device_key_verification_done_handle = None;
        }
        if let Some(handle) = self.to_device_room_encrypted_handle.clone() {
            client.remove_event_handler(handle);
            self.to_device_room_encrypted_handle = None;
        }
        if let Some(handle) = self.to_device_room_key_handle.clone() {
            client.remove_event_handler(handle);
            self.to_device_room_key_handle = None;
        }
        if let Some(handle) = self.to_device_room_key_request_handle.clone() {
            client.remove_event_handler(handle);
            self.to_device_room_key_request_handle = None;
        }
        if let Some(handle) = self.to_device_forwarded_room_key_handle.clone() {
            client.remove_event_handler(handle);
            self.to_device_forwarded_room_key_handle = None;
        }
        if let Some(handle) = self.to_device_secret_send_handle.clone() {
            client.remove_event_handler(handle);
            self.to_device_secret_send_handle = None;
        }
        if let Some(handle) = self.to_device_secret_request_handle.clone() {
            client.remove_event_handler(handle);
            self.to_device_secret_request_handle = None;
        }
    }
}

impl Client {
    pub fn verification_event_rx(&self) -> Option<Receiver<VerificationEvent>> {
        self.verification_controller.event_rx.lock().take()
    }
}
