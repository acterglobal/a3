use anyhow::{Context, Result};
use futures::{
    channel::mpsc::{channel, Receiver, Sender},
    stream::StreamExt,
};
use matrix_sdk::{
    config::SyncSettings,
    encryption::verification::{
        SasState, SasVerification, Verification, VerificationRequest, VerificationRequestState,
    },
    event_handler::{Ctx, EventHandlerHandle},
    ruma::{
        events::{
            forwarded_room_key::ToDeviceForwardedRoomKeyEvent,
            key::verification::{
                cancel::CancelCode, request::ToDeviceKeyVerificationRequestEvent,
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
    Client as SdkClient,
};
use std::{
    sync::Arc,
    time::{Duration, SystemTime, UNIX_EPOCH},
};
use tokio::sync::Mutex;
use tracing::{error, info, warn};

use super::{client::Client, common::DeviceRecord, RUNTIME};

#[derive(Clone, Debug)]
pub struct VerificationEvent {
    client: SdkClient,
    controller: VerificationController,
    event_type: String,
    /// for ToDevice event
    event_id: Option<OwnedEventId>,
    /// for sync message
    txn_id: Option<OwnedTransactionId>,
    sender: OwnedUserId,
    /// for request/ready/start events
    other_device_id: Option<OwnedDeviceId>,
    /// for cancel event
    cancel_code: Option<CancelCode>,
    /// for cancel event
    reason: Option<String>,
}

impl VerificationEvent {
    #[allow(clippy::too_many_arguments)]
    pub(crate) fn new(
        client: SdkClient,
        controller: VerificationController,
        event_type: String,
        event_id: Option<OwnedEventId>,
        txn_id: Option<OwnedTransactionId>,
        sender: OwnedUserId,
        other_device_id: Option<OwnedDeviceId>,
        cancel_code: Option<CancelCode>,
        reason: Option<String>,
    ) -> Self {
        VerificationEvent {
            client,
            controller,
            event_type,
            event_id,
            txn_id,
            sender,
            other_device_id,
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
        let controller = self.controller.clone();
        let sender = self.sender.clone();
        let event_id = self.event_id.clone();
        let txn_id = self.txn_id.clone();
        RUNTIME
            .spawn(async move {
                if let Some(eid) = event_id.clone() {
                    if let Some(request) = client
                        .encryption()
                        .get_verification_request(&sender, eid)
                        .await
                    {
                        tokio::spawn(request_verification_handler(
                            client, controller, request, event_id, None, sender, None,
                        ));
                        return Ok(true);
                    }
                } else if let Some(tid) = txn_id.clone() {
                    if let Some(request) = client
                        .encryption()
                        .get_verification_request(&sender, tid)
                        .await
                    {
                        tokio::spawn(request_verification_handler(
                            client, controller, request, None, txn_id, sender, None,
                        ));
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
                        request.cancel().await?;
                        return Ok(true);
                    }
                } else if let Some(txn_id) = txn_id {
                    if let Some(request) = client
                        .encryption()
                        .get_verification_request(&sender, txn_id)
                        .await
                    {
                        request.cancel().await?;
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
        let controller = self.controller.clone();
        let sender = self.sender.clone();
        let event_id = self.event_id.clone();
        let txn_id = self.txn_id.clone();
        let values = (*methods).iter().map(|e| e.as_str().into()).collect();
        RUNTIME
            .spawn(async move {
                if let Some(eid) = event_id.clone() {
                    if let Some(request) = client
                        .encryption()
                        .get_verification_request(&sender, eid)
                        .await
                    {
                        tokio::spawn(request_verification_handler(
                            client,
                            controller,
                            request,
                            event_id,
                            None,
                            sender,
                            Some(values),
                        ));
                        return Ok(true);
                    }
                } else if let Some(tid) = txn_id.clone() {
                    if let Some(request) = client
                        .encryption()
                        .get_verification_request(&sender, tid)
                        .await
                    {
                        tokio::spawn(request_verification_handler(
                            client,
                            controller,
                            request,
                            None,
                            txn_id,
                            sender,
                            Some(values),
                        ));
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
                        let sas = request.start_sas().await?;
                        return Ok(sas.is_some());
                    }
                } else if let Some(txn_id) = txn_id {
                    if let Some(request) = client
                        .encryption()
                        .get_verification_request(&sender, txn_id)
                        .await
                    {
                        let sas = request.start_sas().await?;
                        return Ok(sas.is_some());
                    }
                }
                // request may be timed out
                info!("Could not get verification request");
                Ok(false)
            })
            .await?
    }

    pub fn was_triggered_from_this_device(&self) -> Result<bool> {
        let device_id = self
            .client
            .device_id()
            .context("guest user cannot get device id")?;
        match self.other_device_id.clone() {
            Some(other_device_id) => Ok(other_device_id == *device_id),
            None => Ok(false),
        }
    }

    pub async fn accept_sas_verification(&self) -> Result<bool> {
        let client = self.client.clone();
        let controller = self.controller.clone();
        let sender = self.sender.clone();
        let event_id = self.event_id.clone();
        let txn_id = self.txn_id.clone();
        RUNTIME
            .spawn(async move {
                if let Some(eid) = event_id.clone() {
                    if let Some(Verification::SasV1(sas)) = client
                        .encryption()
                        .get_verification(&sender, eid.as_str())
                        .await
                    {
                        tokio::spawn(sas_verification_handler(
                            client, controller, sas, event_id, None, sender,
                        ));
                        return Ok(true);
                    }
                } else if let Some(tid) = txn_id.clone() {
                    if let Some(Verification::SasV1(sas)) = client
                        .encryption()
                        .get_verification(&sender, tid.as_str())
                        .await
                    {
                        tokio::spawn(sas_verification_handler(
                            client, controller, sas, None, txn_id, sender,
                        ));
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
                                    symbol: e.symbol.chars().next().unwrap() as u32, // first char in string
                                    description: e.description.to_string(),
                                })
                                .collect::<Vec<VerificationEmoji>>();
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
                                    symbol: e.symbol.chars().next().unwrap() as u32, // first char in string
                                    description: e.description.to_string(),
                                })
                                .collect::<Vec<VerificationEmoji>>();
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

async fn request_verification_handler(
    client: SdkClient,
    mut controller: VerificationController,
    request: VerificationRequest,
    event_id: Option<OwnedEventId>,
    txn_id: Option<OwnedTransactionId>,
    sender: OwnedUserId,
    methods: Option<Vec<VerificationMethod>>,
) {
    info!(
        "Accepting verification request from {}",
        request.other_user_id()
    );
    if let Some(methods) = methods {
        request
            .accept_with_methods(methods)
            .await
            .expect("Can't accept verification request");
    } else {
        request
            .accept()
            .await
            .expect("Can't accept verification request");
    }

    let mut stream = request.changes();

    while let Some(state) = stream.next().await {
        match state {
            VerificationRequestState::Created { our_methods } => {
                let device_id = client.device_id().expect("Device not found");
                let event_type = "m.key.verification.create".to_string();
                info!("{} got {}", device_id, event_type);
                let msg = VerificationEvent::new(
                    client.clone(),
                    controller.clone(),
                    event_type,
                    event_id.clone(),
                    txn_id.clone(),
                    sender.clone(),
                    None,
                    None,
                    None,
                );
                if let Err(e) = controller.event_tx.try_send(msg) {
                    if let Some(event_id) = event_id.clone() {
                        error!("Dropping event for {}: {}", event_id, e);
                    }
                    if let Some(txn_id) = txn_id.clone() {
                        error!("Dropping transaction for {}: {}", txn_id, e);
                    }
                }
            }
            VerificationRequestState::Requested {
                their_methods,
                other_device_id,
            } => {
                let device_id = client.device_id().expect("Device not found");
                let event_type = "m.key.verification.request".to_string();
                info!("{} got {}", device_id, event_type);
                let msg = VerificationEvent::new(
                    client.clone(),
                    controller.clone(),
                    event_type,
                    event_id.clone(),
                    txn_id.clone(),
                    sender.clone(),
                    Some(other_device_id.clone()),
                    None,
                    None,
                );
                if let Err(e) = controller.event_tx.try_send(msg) {
                    if let Some(event_id) = event_id.clone() {
                        error!("Dropping event for {}: {}", event_id, e);
                    }
                    if let Some(txn_id) = txn_id.clone() {
                        error!("Dropping transaction for {}: {}", txn_id, e);
                    }
                }
            }
            VerificationRequestState::Ready {
                their_methods,
                our_methods,
                other_device_id,
            } => {
                let device_id = client.device_id().expect("Device not found");
                let event_type = "m.key.verification.ready".to_string();
                info!("{} got {}", device_id, event_type);
                let msg = VerificationEvent::new(
                    client.clone(),
                    controller.clone(),
                    event_type,
                    event_id.clone(),
                    txn_id.clone(),
                    sender.clone(),
                    Some(other_device_id.clone()),
                    None,
                    None,
                );
                if let Err(e) = controller.event_tx.try_send(msg) {
                    if let Some(event_id) = event_id.clone() {
                        error!("Dropping event for {}: {}", event_id, e);
                    }
                    if let Some(txn_id) = txn_id.clone() {
                        error!("Dropping transaction for {}: {}", txn_id, e);
                    }
                }
            }
            VerificationRequestState::Transitioned { verification } => match verification {
                Verification::SasV1(s) => {
                    // from then on, accept_sas_verification takes over
                    break;
                }
            },
            VerificationRequestState::Done => {
                let device_id = client.device_id().expect("Device not found");
                let event_type = "m.key.verification.done".to_string();
                info!("{} got {}", device_id, event_type);
                let msg = VerificationEvent::new(
                    client.clone(),
                    controller.clone(),
                    event_type,
                    event_id.clone(),
                    txn_id.clone(),
                    sender.clone(),
                    None,
                    None,
                    None,
                );
                if let Err(e) = controller.event_tx.try_send(msg) {
                    if let Some(event_id) = event_id.clone() {
                        error!("Dropping event for {}: {}", event_id, e);
                    }
                    if let Some(txn_id) = txn_id.clone() {
                        error!("Dropping transaction for {}: {}", txn_id, e);
                    }
                }
                break;
            }
            VerificationRequestState::Cancelled(cancel_info) => {
                let device_id = client.device_id().expect("Device not found");
                let event_type = "m.key.verification.cancel".to_string();
                info!("{} got {}", device_id, event_type);
                let msg = VerificationEvent::new(
                    client.clone(),
                    controller.clone(),
                    event_type,
                    event_id.clone(),
                    txn_id.clone(),
                    sender.clone(),
                    None,
                    Some(cancel_info.cancel_code().clone()),
                    Some(cancel_info.reason().to_string()),
                );
                if let Err(e) = controller.event_tx.try_send(msg) {
                    if let Some(event_id) = event_id.clone() {
                        error!("Dropping event for {}: {}", event_id, e);
                    }
                    if let Some(txn_id) = txn_id.clone() {
                        error!("Dropping transaction for {}: {}", txn_id, e);
                    }
                }
                break;
            }
        }
    }
}

async fn sas_verification_handler(
    client: SdkClient,
    mut controller: VerificationController,
    sas: SasVerification,
    event_id: Option<OwnedEventId>,
    txn_id: Option<OwnedTransactionId>,
    sender: OwnedUserId,
) {
    info!(
        "Starting verification with {} {}",
        &sas.other_device().user_id(),
        &sas.other_device().device_id()
    );
    sas.accept().await.unwrap();

    let mut stream = sas.changes();

    while let Some(state) = stream.next().await {
        match state {
            SasState::KeysExchanged { emojis, decimals } => {
                let device_id = client.device_id().expect("Device not found");
                let event_type = "m.key.verification.key".to_string();
                info!("{} got {}", device_id, event_type);
                let msg = VerificationEvent::new(
                    client.clone(),
                    controller.clone(),
                    event_type,
                    event_id.clone(),
                    txn_id.clone(),
                    sender.clone(),
                    None,
                    None,
                    None,
                );
                if let Err(e) = controller.event_tx.try_send(msg) {
                    if let Some(event_id) = event_id.clone() {
                        error!("Dropping event for {}: {}", event_id, e);
                    }
                    if let Some(txn_id) = txn_id.clone() {
                        error!("Dropping transaction for {}: {}", txn_id, e);
                    }
                }
            }
            SasState::Done {
                verified_devices,
                verified_identities,
            } => {
                let device_id = client.device_id().expect("Device not found");
                let event_type = "m.key.verification.done".to_string();
                info!("{} got {}", device_id, event_type);
                let msg = VerificationEvent::new(
                    client.clone(),
                    controller.clone(),
                    event_type,
                    event_id.clone(),
                    txn_id.clone(),
                    sender.clone(),
                    None,
                    None,
                    None,
                );
                if let Err(e) = controller.event_tx.try_send(msg) {
                    if let Some(event_id) = event_id.clone() {
                        error!("Dropping event for {}: {}", event_id, e);
                    }
                    if let Some(txn_id) = txn_id.clone() {
                        error!("Dropping transaction for {}: {}", txn_id, e);
                    }
                }
                break;
            }
            SasState::Cancelled(cancel_info) => {
                let device_id = client.device_id().expect("Device not found");
                let event_type = "m.key.verification.cancel".to_string();
                info!("{} got {}", device_id, event_type);
                let msg = VerificationEvent::new(
                    client.clone(),
                    controller.clone(),
                    event_type,
                    event_id.clone(),
                    txn_id.clone(),
                    sender.clone(),
                    None,
                    Some(cancel_info.cancel_code().clone()),
                    Some(cancel_info.reason().to_string()),
                );
                if let Err(e) = controller.event_tx.try_send(msg) {
                    if let Some(event_id) = event_id.clone() {
                        error!("Dropping event for {}: {}", event_id, e);
                    }
                    if let Some(txn_id) = txn_id.clone() {
                        error!("Dropping transaction for {}: {}", txn_id, e);
                    }
                }
                break;
            }
            SasState::Started { protocols } => {
                let device_id = client.device_id().expect("Device not found");
                let event_type = "m.key.verification.start".to_string();
                info!("{} got {}", device_id, event_type);
                let msg = VerificationEvent::new(
                    client.clone(),
                    controller.clone(),
                    event_type,
                    event_id.clone(),
                    txn_id.clone(),
                    sender.clone(),
                    None,
                    None,
                    None,
                );
                if let Err(e) = controller.event_tx.try_send(msg) {
                    if let Some(event_id) = event_id.clone() {
                        error!("Dropping event for {}: {}", event_id, e);
                    }
                    if let Some(txn_id) = txn_id.clone() {
                        error!("Dropping transaction for {}: {}", txn_id, e);
                    }
                }
            }
            SasState::Accepted { accepted_protocols } => {
                let device_id = client.device_id().expect("Device not found");
                let event_type = "m.key.verification.accept".to_string();
                info!("{} got {}", device_id, event_type);
                let msg = VerificationEvent::new(
                    client.clone(),
                    controller.clone(),
                    event_type,
                    event_id.clone(),
                    txn_id.clone(),
                    sender.clone(),
                    None,
                    None,
                    None,
                );
                if let Err(e) = controller.event_tx.try_send(msg) {
                    if let Some(event_id) = event_id.clone() {
                        error!("Dropping event for {}: {}", event_id, e);
                    }
                    if let Some(txn_id) = txn_id.clone() {
                        error!("Dropping transaction for {}: {}", txn_id, e);
                    }
                }
            }
            SasState::Confirmed => {
                let device_id = client.device_id().expect("Device not found");
                let event_type = "m.key.verification.mac".to_string();
                info!("{} got {}", device_id, event_type);
                let msg = VerificationEvent::new(
                    client.clone(),
                    controller.clone(),
                    event_type,
                    event_id.clone(),
                    txn_id.clone(),
                    sender.clone(),
                    None,
                    None,
                    None,
                );
                if let Err(e) = controller.event_tx.try_send(msg) {
                    if let Some(event_id) = event_id.clone() {
                        error!("Dropping event for {}: {}", event_id, e);
                    }
                    if let Some(txn_id) = txn_id.clone() {
                        error!("Dropping transaction for {}: {}", txn_id, e);
                    }
                }
            }
        }
    }
}

#[derive(Clone, Debug)]
pub(crate) struct VerificationController {
    event_tx: Sender<VerificationEvent>,
    event_rx: Arc<Mutex<Option<Receiver<VerificationEvent>>>>,
    sync_key_verification_request_handle: Option<EventHandlerHandle>,
    sync_room_encrypted_handle: Option<EventHandlerHandle>,
    to_device_key_verification_request_handle: Option<EventHandlerHandle>,
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
            sync_room_encrypted_handle: None,
            to_device_key_verification_request_handle: None,
            to_device_room_encrypted_handle: None,
            to_device_room_key_handle: None,
            to_device_room_key_request_handle: None,
            to_device_forwarded_room_key_handle: None,
            to_device_secret_send_handle: None,
            to_device_secret_request_handle: None,
        }
    }

    pub fn add_sync_event_handler(&mut self, client: &SdkClient) {
        client.add_event_handler_context(self.clone());
        let handle = client.add_event_handler(
            |ev: OriginalSyncRoomMessageEvent,
             c: SdkClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                if let MessageType::VerificationRequest(content) = &ev.content.msgtype {
                    let device_id = c.device_id().expect("guest user cannot get device id");
                    let event_type = ev.content.event_type();
                    info!("{} got {}", device_id, event_type);
                    let methods = content.methods.clone();
                    let msg = VerificationEvent::new(
                        c,
                        me.clone(),
                        event_type.to_string(),
                        Some(ev.event_id.clone()),
                        None,
                        ev.sender.clone(),
                        None,
                        None,
                        None,
                    );
                    if let Err(e) = me.event_tx.try_send(msg) {
                        error!("Dropping event for {}: {}", ev.event_id.clone(), e);
                    }
                    // from then on, accept_verification_request takes over
                }
            },
        );
        self.sync_key_verification_request_handle = Some(handle);

        client.add_event_handler_context(self.clone());
        let handle = client.add_event_handler(
            |ev: OriginalSyncRoomEncryptedEvent,
             c: SdkClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let device_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", device_id, event_type);
            },
        );
        self.sync_room_encrypted_handle = Some(handle);
    }

    pub fn remove_sync_event_handler(&mut self, client: &SdkClient) {
        if let Some(handle) = self.sync_key_verification_request_handle.clone() {
            client.remove_event_handler(handle);
            self.sync_key_verification_request_handle = None;
        }
        if let Some(handle) = self.sync_room_encrypted_handle.clone() {
            client.remove_event_handler(handle);
            self.sync_room_encrypted_handle = None;
        }
    }

    pub fn add_to_device_event_handler(&mut self, client: &SdkClient) {
        client.add_event_handler_context(self.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceKeyVerificationRequestEvent,
             c: SdkClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let device_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", device_id, event_type);
                let txn_id = ev.content.transaction_id;
                let methods = ev.content.methods.clone();
                let msg = VerificationEvent::new(
                    c,
                    me.clone(),
                    event_type.to_string(),
                    None,
                    Some(txn_id.clone()),
                    ev.sender.clone(),
                    Some(ev.content.from_device.clone()),
                    None,
                    None,
                );
                if let Err(e) = me.event_tx.try_send(msg) {
                    error!("Dropping transaction for {}: {}", txn_id, e);
                }
            },
        );
        self.to_device_key_verification_request_handle = Some(handle);

        client.add_event_handler_context(self.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceRoomEncryptedEvent,
             c: SdkClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let device_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", device_id, event_type);
            },
        );
        self.to_device_room_encrypted_handle = Some(handle);

        client.add_event_handler_context(self.clone());
        let handle =
            client.add_event_handler(
                |ev: ToDeviceRoomKeyEvent,
                 c: SdkClient,
                 Ctx(mut me): Ctx<VerificationController>| async move {
                    let device_id = c.device_id().expect("guest user cannot get device id");
                    let event_type = ev.content.event_type();
                    info!("{} got {}", device_id, event_type);
                },
            );
        self.to_device_room_key_handle = Some(handle);

        client.add_event_handler_context(self.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceRoomKeyRequestEvent,
             c: SdkClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let device_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", device_id, event_type);
            },
        );
        self.to_device_room_key_request_handle = Some(handle);

        client.add_event_handler_context(self.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceForwardedRoomKeyEvent,
             c: SdkClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let device_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", device_id, event_type);
            },
        );
        self.to_device_forwarded_room_key_handle = Some(handle);

        client.add_event_handler_context(self.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceSecretSendEvent,
             c: SdkClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let device_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", device_id, event_type);
            },
        );
        self.to_device_secret_send_handle = Some(handle);

        client.add_event_handler_context(self.clone());
        let handle = client.add_event_handler(
            |ev: ToDeviceSecretRequestEvent,
             c: SdkClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let device_id = c.device_id().expect("guest user cannot get device id");
                let event_type = ev.content.event_type();
                info!("{} got {}", device_id, event_type);
                info!("ToDeviceSecretRequestEvent: {:?}", ev);
                let secret_name = match &ev.content.action {
                    RequestAction::Request(s) => s,
                    // We ignore cancellations here since there's nothing to serve.
                    RequestAction::RequestCancellation => return,
                    action => {
                        error!("Unknown secret request action");
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

    pub fn remove_to_device_event_handler(&mut self, client: &SdkClient) {
        if let Some(handle) = self.to_device_key_verification_request_handle.clone() {
            client.remove_event_handler(handle);
            self.to_device_key_verification_request_handle = None;
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

pub struct SessionManager {
    client: SdkClient,
}

impl SessionManager {
    pub async fn all_sessions(&self) -> Result<Vec<DeviceRecord>> {
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let user_id = client.user_id().context("User not found")?;
                let response = client.devices().await?;
                let crypto_devices = client
                    .encryption()
                    .get_user_devices(user_id)
                    .await
                    .context("Couldn't get crypto devices")?;
                let mut sessions = vec![];
                for device in response.devices {
                    let is_verified = crypto_devices
                        .get(&device.device_id)
                        .is_some_and(|d| d.is_cross_signed_by_owner() || d.is_verified_with_cross_signing());
                    sessions.push(DeviceRecord::new(
                        device.device_id.clone(),
                        device.display_name.clone(),
                        device.last_seen_ts,
                        device.last_seen_ip.clone(),
                        is_verified,
                    ));
                }
                warn!("all sessions: {:?}", sessions);
                Ok(sessions)
            })
            .await?
    }

    pub async fn verified_sessions(&self) -> Result<Vec<DeviceRecord>> {
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let user_id = client.user_id().context("User not found")?;
                let response = client.devices().await?;
                let crypto_devices = client
                    .encryption()
                    .get_user_devices(user_id)
                    .await
                    .context("Couldn't get crypto devices")?;
                let mut sessions = vec![];
                for device in response.devices {
                    let is_verified = crypto_devices
                        .get(&device.device_id)
                        .is_some_and(|d| d.is_cross_signed_by_owner() || d.is_verified_with_cross_signing());
                    if is_verified {
                        sessions.push(DeviceRecord::new(
                            device.device_id.clone(),
                            device.display_name.clone(),
                            device.last_seen_ts,
                            device.last_seen_ip.clone(),
                            true,
                        ));
                    }
                }
                warn!("verified sessions: {:?}", sessions);
                Ok(sessions)
            })
            .await?
    }

    pub async fn unverified_sessions(&self) -> Result<Vec<DeviceRecord>> {
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let user_id = client.user_id().context("User not found")?;
                let response = client.devices().await?;
                let crypto_devices = client
                    .encryption()
                    .get_user_devices(user_id)
                    .await
                    .context("Couldn't get crypto devices")?;
                let mut sessions = vec![];
                for device in response.devices {
                    let is_verified = crypto_devices
                        .get(&device.device_id)
                        .is_some_and(|d| d.is_cross_signed_by_owner() || d.is_verified_with_cross_signing());
                    if !is_verified {
                        sessions.push(DeviceRecord::new(
                            device.device_id.clone(),
                            device.display_name.clone(),
                            device.last_seen_ts,
                            device.last_seen_ip.clone(),
                            false,
                        ));
                    }
                }
                warn!("unverified sessions: {:?}", sessions);
                Ok(sessions)
            })
            .await?
    }

    pub async fn inactive_sessions(&self) -> Result<Vec<DeviceRecord>> {
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let user_id = client.user_id().context("User not found")?;
                let response = client.devices().await?;
                let crypto_devices = client
                    .encryption()
                    .get_user_devices(user_id)
                    .await
                    .context("Couldn't get crypto devices")?;
                let mut sessions = vec![];
                for device in response.devices {
                    let mut is_inactive = true;
                    if let Some(last_seen_ts) = device.last_seen_ts {
                        let limit = SystemTime::now()
                            .checked_sub(Duration::from_secs(90 * 24 * 60 * 60))
                            .context("Couldn't get time of 90 days ago")?
                            .duration_since(UNIX_EPOCH)
                            .context("Couldn't calculate duration from Unix epoch")?;
                        let secs: u64 = last_seen_ts.as_secs().into();
                        if secs > limit.as_secs() {
                            is_inactive = false;
                        }
                    }
                    if is_inactive {
                        let is_verified = crypto_devices
                            .get(&device.device_id)
                            .is_some_and(|d| d.is_cross_signed_by_owner() || d.is_verified_with_cross_signing());
                        sessions.push(DeviceRecord::new(
                            device.device_id.clone(),
                            device.display_name.clone(),
                            device.last_seen_ts,
                            device.last_seen_ip.clone(),
                            is_verified,
                        ));
                    }
                }
                warn!("inactive sessions: {:?}", sessions);
                Ok(sessions)
            })
            .await?
    }
}

impl Client {
    pub fn verification_event_rx(&self) -> Option<Receiver<VerificationEvent>> {
        match self.verification_controller.event_rx.try_lock() {
            Ok(mut r) => r.take(),
            Err(e) => None,
        }
    }

    pub fn session_manager(&self) -> SessionManager {
        let client = self.core.client().clone();
        SessionManager { client }
    }
}
