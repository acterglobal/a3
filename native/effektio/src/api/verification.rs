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
            room::message::{MessageType, OriginalSyncRoomMessageEvent},
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
        } else if let Some(txn_id) = &self.txn_id {
            Some(txn_id.to_string())
        } else {
            None
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
                        sas.accept().await.unwrap();
                        return Ok(true);
                    }
                } else if let Some(txn_id) = txn_id {
                    if let Some(Verification::SasV1(sas)) = client
                        .encryption()
                        .get_verification(&sender, txn_id.as_str())
                        .await
                    {
                        sas.accept().await.unwrap();
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
                        sas.cancel().await.unwrap();
                        return Ok(true);
                    }
                } else if let Some(txn_id) = txn_id {
                    if let Some(Verification::SasV1(sas)) = client
                        .encryption()
                        .get_verification(&sender, txn_id.as_str())
                        .await
                    {
                        sas.cancel().await.unwrap();
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
                        sas.cancel().await.unwrap();
                        return Ok(true);
                    }
                } else if let Some(txn_id) = txn_id {
                    if let Some(Verification::SasV1(sas)) = client
                        .encryption()
                        .get_verification(&sender, txn_id.as_str())
                        .await
                    {
                        sas.cancel().await.unwrap();
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
                        sas.confirm().await.unwrap();
                        return Ok(sas.is_done());
                    }
                } else if let Some(txn_id) = txn_id {
                    if let Some(Verification::SasV1(sas)) = client
                        .encryption()
                        .get_verification(&sender, txn_id.as_str())
                        .await
                    {
                        sas.confirm().await.unwrap();
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
                        sas.mismatch().await.unwrap();
                        return Ok(true);
                    }
                } else if let Some(txn_id) = txn_id {
                    if let Some(Verification::SasV1(sas)) = client
                        .encryption()
                        .get_verification(&sender, txn_id.as_str())
                        .await
                    {
                        sas.mismatch().await.unwrap();
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
    request_sync_event_handle: Option<EventHandlerHandle>,
    request_to_device_event_handle: Option<EventHandlerHandle>,
    ready_sync_event_handle: Option<EventHandlerHandle>,
    ready_to_device_event_handle: Option<EventHandlerHandle>,
    start_sync_event_handle: Option<EventHandlerHandle>,
    start_to_device_event_handle: Option<EventHandlerHandle>,
    cancel_sync_event_handle: Option<EventHandlerHandle>,
    cancel_to_device_event_handle: Option<EventHandlerHandle>,
    accept_sync_event_handle: Option<EventHandlerHandle>,
    accept_to_device_event_handle: Option<EventHandlerHandle>,
    key_sync_event_handle: Option<EventHandlerHandle>,
    key_to_device_event_handle: Option<EventHandlerHandle>,
    mac_sync_event_handle: Option<EventHandlerHandle>,
    mac_to_device_event_handle: Option<EventHandlerHandle>,
    done_sync_event_handle: Option<EventHandlerHandle>,
    done_to_device_event_handle: Option<EventHandlerHandle>,
}

impl VerificationController {
    pub fn new() -> Self {
        let (tx, rx) = channel::<VerificationEvent>(10); // dropping after more than 10 items queued
        VerificationController {
            event_tx: tx,
            event_rx: Arc::new(Mutex::new(Some(rx))),
            request_sync_event_handle: None,
            request_to_device_event_handle: None,
            ready_sync_event_handle: None,
            ready_to_device_event_handle: None,
            start_sync_event_handle: None,
            start_to_device_event_handle: None,
            cancel_sync_event_handle: None,
            cancel_to_device_event_handle: None,
            accept_sync_event_handle: None,
            accept_to_device_event_handle: None,
            key_sync_event_handle: None,
            key_to_device_event_handle: None,
            mac_sync_event_handle: None,
            mac_to_device_event_handle: None,
            done_sync_event_handle: None,
            done_to_device_event_handle: None,
        }
    }

    pub fn add_sync_event_handler(&mut self, client: &MatrixClient) {
        let me = self.clone();

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: OriginalSyncRoomMessageEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                if let MessageType::VerificationRequest(_) = &ev.content.msgtype {
                    let dev_id = c
                        .device_id()
                        .expect("guest user cannot get device id")
                        .to_string();
                    info!("{} got m.key.verification.request", dev_id);
                    let event_id = ev.event_id;
                    let msg = VerificationEvent::new(
                        &c,
                        "m.key.verification.request".to_string(),
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
        self.request_sync_event_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: OriginalSyncKeyVerificationReadyEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                info!("{} got m.key.verification.ready", dev_id.to_string());
                let event_id = ev.content.relates_to.event_id;
                let msg = VerificationEvent::new(
                    &c,
                    "m.key.verification.ready".to_string(),
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
        self.ready_sync_event_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: OriginalSyncKeyVerificationStartEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                info!("{} got m.key.verification.start", dev_id.to_string());
                let event_id = ev.content.relates_to.event_id;
                let msg = VerificationEvent::new(
                    &c,
                    "m.key.verification.start".to_string(),
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
        self.start_sync_event_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: OriginalSyncKeyVerificationCancelEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                info!("{} got m.key.verification.cancel", dev_id.to_string());
                let event_id = ev.content.relates_to.event_id;
                let msg = VerificationEvent::new(
                    &c,
                    "m.key.verification.cancel".to_string(),
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
        self.cancel_sync_event_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: OriginalSyncKeyVerificationAcceptEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                info!("{} got m.key.verification.accept", dev_id.to_string());
                let event_id = ev.content.relates_to.event_id;
                let msg = VerificationEvent::new(
                    &c,
                    "m.key.verification.accept".to_string(),
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
        self.accept_sync_event_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: OriginalSyncKeyVerificationKeyEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                info!("{} got m.key.verification.key", dev_id.to_string());
                let event_id = ev.content.relates_to.event_id;
                let msg = VerificationEvent::new(
                    &c,
                    "m.key.verification.key".to_string(),
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
        self.key_sync_event_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: OriginalSyncKeyVerificationMacEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                info!("{} got m.key.verification.mac", dev_id.to_string());
                let event_id = ev.content.relates_to.event_id;
                let msg = VerificationEvent::new(
                    &c,
                    "m.key.verification.mac".to_string(),
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
        self.mac_sync_event_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: OriginalSyncKeyVerificationDoneEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                info!("{} got m.key.verification.done", dev_id.to_string());
                let event_id = ev.content.relates_to.event_id;
                let msg = VerificationEvent::new(
                    &c,
                    "m.key.verification.done".to_string(),
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
        self.done_sync_event_handle = Some(handle);
    }

    pub fn remove_sync_event_handler(&mut self, client: &MatrixClient) {
        if let Some(handle) = self.request_sync_event_handle.clone() {
            client.remove_event_handler(handle);
            self.request_sync_event_handle = None;
        }
        if let Some(handle) = self.ready_sync_event_handle.clone() {
            client.remove_event_handler(handle);
            self.ready_sync_event_handle = None;
        }
        if let Some(handle) = self.start_sync_event_handle.clone() {
            client.remove_event_handler(handle);
            self.start_sync_event_handle = None;
        }
        if let Some(handle) = self.cancel_sync_event_handle.clone() {
            client.remove_event_handler(handle);
            self.cancel_sync_event_handle = None;
        }
        if let Some(handle) = self.accept_sync_event_handle.clone() {
            client.remove_event_handler(handle);
            self.accept_sync_event_handle = None;
        }
        if let Some(handle) = self.key_sync_event_handle.clone() {
            client.remove_event_handler(handle);
            self.key_sync_event_handle = None;
        }
        if let Some(handle) = self.mac_sync_event_handle.clone() {
            client.remove_event_handler(handle);
            self.mac_sync_event_handle = None;
        }
        if let Some(handle) = self.done_sync_event_handle.clone() {
            client.remove_event_handler(handle);
            self.done_sync_event_handle = None;
        }
    }

    pub fn add_to_device_event_handler(&mut self, client: &MatrixClient) {
        let me = self.clone();

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceKeyVerificationRequestEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c
                    .device_id()
                    .expect("guest user cannot get device id")
                    .to_string();
                info!("{} got m.key.verification.request", dev_id);
                let txn_id = ev.content.transaction_id;
                let msg = VerificationEvent::new(
                    &c,
                    "m.key.verification.request".to_string(),
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
        self.request_to_device_event_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceKeyVerificationReadyEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                info!("{} got m.key.verification.ready", dev_id.to_string());
                let txn_id = ev.content.transaction_id;
                let msg = VerificationEvent::new(
                    &c,
                    "m.key.verification.ready".to_string(),
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
        self.ready_to_device_event_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceKeyVerificationStartEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                info!("{} got m.key.verification.start", dev_id.to_string());
                let txn_id = ev.content.transaction_id;
                let msg = VerificationEvent::new(
                    &c,
                    "m.key.verification.start".to_string(),
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
        self.start_to_device_event_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceKeyVerificationCancelEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                info!("{} got m.key.verification.cancel", dev_id.to_string());
                let txn_id = ev.content.transaction_id;
                let msg = VerificationEvent::new(
                    &c,
                    "m.key.verification.cancel".to_string(),
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
        self.cancel_to_device_event_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceKeyVerificationAcceptEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                info!("{} got m.key.verification.accept", dev_id.to_string());
                let txn_id = ev.content.transaction_id;
                let msg = VerificationEvent::new(
                    &c,
                    "m.key.verification.accept".to_string(),
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
        self.accept_to_device_event_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceKeyVerificationKeyEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                info!("{} got m.key.verification.key", dev_id.to_string());
                let txn_id = ev.content.transaction_id;
                let msg = VerificationEvent::new(
                    &c,
                    "m.key.verification.key".to_string(),
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
        self.key_to_device_event_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceKeyVerificationMacEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                info!("{} got m.key.verification.mac", dev_id.to_string());
                let txn_id = ev.content.transaction_id;
                let msg = VerificationEvent::new(
                    &c,
                    "m.key.verification.mac".to_string(),
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
        self.mac_to_device_event_handle = Some(handle);

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceKeyVerificationDoneEvent,
             c: MatrixClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let dev_id = c.device_id().expect("guest user cannot get device id");
                info!("{} got m.key.verification.done", dev_id.to_string());
                let txn_id = ev.content.transaction_id;
                let msg = VerificationEvent::new(
                    &c,
                    "m.key.verification.done".to_string(),
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
        self.done_to_device_event_handle = Some(handle);
    }

    pub fn remove_to_device_event_handler(&mut self, client: &MatrixClient) {
        if let Some(handle) = self.request_to_device_event_handle.clone() {
            client.remove_event_handler(handle);
            self.request_to_device_event_handle = None;
        }
        if let Some(handle) = self.ready_to_device_event_handle.clone() {
            client.remove_event_handler(handle);
            self.ready_to_device_event_handle = None;
        }
        if let Some(handle) = self.start_to_device_event_handle.clone() {
            client.remove_event_handler(handle);
            self.start_to_device_event_handle = None;
        }
        if let Some(handle) = self.cancel_to_device_event_handle.clone() {
            client.remove_event_handler(handle);
            self.cancel_to_device_event_handle = None;
        }
        if let Some(handle) = self.accept_to_device_event_handle.clone() {
            client.remove_event_handler(handle);
            self.accept_to_device_event_handle = None;
        }
        if let Some(handle) = self.key_to_device_event_handle.clone() {
            client.remove_event_handler(handle);
            self.key_to_device_event_handle = None;
        }
        if let Some(handle) = self.mac_to_device_event_handle.clone() {
            client.remove_event_handler(handle);
            self.mac_to_device_event_handle = None;
        }
        if let Some(handle) = self.done_to_device_event_handle.clone() {
            client.remove_event_handler(handle);
            self.done_to_device_event_handle = None;
        }
    }
}

impl Client {
    pub fn verification_event_rx(&self) -> Option<Receiver<VerificationEvent>> {
        self.verification_controller.event_rx.lock().take()
    }
}
