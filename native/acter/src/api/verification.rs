use anyhow::{bail, Context, Result};
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
        api::client::uiaa::{AuthData, Password, UserIdentifier},
        assign,
    },
    Client as SdkClient,
};
use ruma_common::{device_id, OwnedDeviceId, OwnedEventId, OwnedTransactionId, OwnedUserId};
use ruma_events::{
    key::verification::{accept::AcceptMethod, start::StartMethod, VerificationMethod},
    room::{
        encrypted::OriginalSyncRoomEncryptedEvent,
        message::{MessageType, OriginalSyncRoomMessageEvent},
    },
    AnyToDeviceEvent, EventContent,
};
use std::{
    collections::HashMap,
    sync::Arc,
    time::{Duration, SystemTime, UNIX_EPOCH},
};
use tokio::sync::Mutex;
use tracing::{error, info};

use super::{client::Client, common::DeviceRecord, device::DeviceNewEvent, RUNTIME};

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
    /// event content
    content: HashMap<String, String>,
    /// emoji array
    emojis: Vec<VerificationEmoji>,
}

impl VerificationEvent {
    pub(crate) fn new(
        client: SdkClient,
        controller: VerificationController,
        event_type: String,
        event_id: Option<OwnedEventId>,
        txn_id: Option<OwnedTransactionId>,
        sender: OwnedUserId,
    ) -> Self {
        VerificationEvent {
            client,
            controller,
            event_type,
            event_id,
            txn_id,
            sender,
            content: Default::default(),
            emojis: Default::default(),
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

    pub(crate) fn set_content(&mut self, key: String, value: String) {
        self.content.insert(key, value);
    }

    pub fn get_content(&self, key: String) -> Option<String> {
        self.content.get(&key).cloned()
    }

    pub(crate) fn set_emojis(&mut self, emojis: Vec<VerificationEmoji>) {
        self.emojis.clone_from(&emojis);
    }

    // when this device triggered verification of other device, it can get emojis from SAS state
    pub fn emojis(&self) -> Vec<VerificationEmoji> {
        self.emojis.clone()
    }

    // when other device triggered verification of this device, it can get emojis from remote server
    pub async fn get_emojis(&self) -> Result<Vec<VerificationEmoji>> {
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
                        let Some(items) = sas.emoji() else {
                            bail!("No emojis found. Aborted.");
                        };
                        let sequence = items
                            .iter()
                            .map(|e| VerificationEmoji {
                                symbol: e.symbol.chars().next().unwrap() as u32, // first char in string
                                description: e.description.to_string(),
                            })
                            .collect::<Vec<VerificationEmoji>>();
                        return Ok(sequence);
                    }
                } else if let Some(txn_id) = txn_id {
                    if let Some(Verification::SasV1(sas)) = client
                        .encryption()
                        .get_verification(&sender, txn_id.as_str())
                        .await
                    {
                        let Some(items) = sas.emoji() else {
                            bail!("No emojis found. Aborted.");
                        };
                        let sequence = items
                            .iter()
                            .map(|e| VerificationEmoji {
                                symbol: e.symbol.chars().next().unwrap() as u32, // first char in string
                                description: e.description.to_string(),
                            })
                            .collect::<Vec<VerificationEmoji>>();
                        return Ok(sequence);
                    }
                }
                // request may be timed out
                bail!("Could not get verification object");
            })
            .await?
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
                bail!("Could not get verification request");
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
                bail!("Could not get verification request");
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
                bail!("Could not get verification request");
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
                bail!("Could not get verification request");
            })
            .await?
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
                bail!("Could not get verification object");
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
                bail!("Could not get verification object");
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
                bail!("Could not get verification object");
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
                bail!("Could not get verification object");
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
                bail!("Could not get verification object");
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
                let mut msg = VerificationEvent::new(
                    client.clone(),
                    controller.clone(),
                    event_type,
                    event_id.clone(),
                    txn_id.clone(),
                    sender.clone(),
                );
                let methods = our_methods
                    .iter()
                    .map(|x| x.to_string())
                    .collect::<Vec<String>>()
                    .join(",");
                msg.set_content("our_methods".to_string(), methods);
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
                let mut msg = VerificationEvent::new(
                    client.clone(),
                    controller.clone(),
                    event_type,
                    event_id.clone(),
                    txn_id.clone(),
                    sender.clone(),
                );
                let methods = their_methods
                    .iter()
                    .map(|x| x.to_string())
                    .collect::<Vec<String>>()
                    .join(",");
                msg.set_content("their_methods".to_string(), methods);
                msg.set_content("other_device_id".to_string(), other_device_id.to_string());
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
                let mut msg = VerificationEvent::new(
                    client.clone(),
                    controller.clone(),
                    event_type,
                    event_id.clone(),
                    txn_id.clone(),
                    sender.clone(),
                );
                let methods = their_methods
                    .iter()
                    .map(|x| x.to_string())
                    .collect::<Vec<String>>()
                    .join(",");
                msg.set_content("their_methods".to_string(), methods);
                let methods = our_methods
                    .iter()
                    .map(|x| x.to_string())
                    .collect::<Vec<String>>()
                    .join(",");
                msg.set_content("our_methods".to_string(), methods);
                msg.set_content("other_device_id".to_string(), other_device_id.to_string());
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
                let mut msg = VerificationEvent::new(
                    client.clone(),
                    controller.clone(),
                    event_type,
                    event_id.clone(),
                    txn_id.clone(),
                    sender.clone(),
                );
                msg.set_content(
                    "cancel_code".to_string(),
                    cancel_info.cancel_code().to_string(),
                );
                msg.set_content("reason".to_string(), cancel_info.reason().to_string());
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
                let mut msg = VerificationEvent::new(
                    client.clone(),
                    controller.clone(),
                    event_type,
                    event_id.clone(),
                    txn_id.clone(),
                    sender.clone(),
                );
                if let Some(auth_string) = emojis {
                    let sequence = auth_string
                        .emojis
                        .iter()
                        .map(|e| VerificationEmoji {
                            symbol: e.symbol.chars().next().unwrap() as u32, // first char in string
                            description: e.description.to_string(),
                        })
                        .collect::<Vec<VerificationEmoji>>();
                    msg.set_emojis(sequence);
                }
                msg.set_content(
                    "decimals".to_string(),
                    serde_json::to_string(&decimals).unwrap(),
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
                let mut msg = VerificationEvent::new(
                    client.clone(),
                    controller.clone(),
                    event_type,
                    event_id.clone(),
                    txn_id.clone(),
                    sender.clone(),
                );
                let devices = verified_devices
                    .iter()
                    .map(|x| x.device_id().to_string())
                    .collect::<Vec<String>>();
                msg.set_content("verified_devices".to_string(), devices.join(","));
                let identifiers = verified_identities
                    .iter()
                    .map(|x| x.user_id().to_string())
                    .collect::<Vec<String>>();
                msg.set_content("verified_identities".to_string(), identifiers.join(","));
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
                let mut msg = VerificationEvent::new(
                    client.clone(),
                    controller.clone(),
                    event_type,
                    event_id.clone(),
                    txn_id.clone(),
                    sender.clone(),
                );
                msg.set_content(
                    "cancel_code".to_string(),
                    cancel_info.cancel_code().to_string(),
                );
                msg.set_content("reason".to_string(), cancel_info.reason().to_string());
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
                let mut msg = VerificationEvent::new(
                    client.clone(),
                    controller.clone(),
                    event_type,
                    event_id.clone(),
                    txn_id.clone(),
                    sender.clone(),
                );
                let key_agreement_protocols = protocols
                    .key_agreement_protocols
                    .iter()
                    .map(|x| x.to_string())
                    .collect::<Vec<String>>();
                msg.set_content(
                    "key_agreement_protocols".to_string(),
                    key_agreement_protocols.join(","),
                );
                let hashes = protocols
                    .hashes
                    .iter()
                    .map(|x| x.to_string())
                    .collect::<Vec<String>>();
                msg.set_content("hashes".to_string(), hashes.join(","));
                let message_authentication_codes = protocols
                    .message_authentication_codes
                    .iter()
                    .map(|x| x.to_string())
                    .collect::<Vec<String>>();
                msg.set_content(
                    "message_authentication_codes".to_string(),
                    message_authentication_codes.join(","),
                );
                let short_authentication_string = protocols
                    .short_authentication_string
                    .iter()
                    .map(|x| x.to_string())
                    .collect::<Vec<String>>();
                msg.set_content(
                    "short_authentication_string".to_string(),
                    short_authentication_string.join(","),
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
                let mut msg = VerificationEvent::new(
                    client.clone(),
                    controller.clone(),
                    event_type,
                    event_id.clone(),
                    txn_id.clone(),
                    sender.clone(),
                );
                msg.set_content(
                    "key_agreement_protocol".to_string(),
                    accepted_protocols.key_agreement_protocol.to_string(),
                );
                msg.set_content("hash".to_string(), accepted_protocols.hash.to_string());
                let short_auth_string = accepted_protocols
                    .short_auth_string
                    .iter()
                    .map(|x| x.to_string())
                    .collect::<Vec<String>>();
                msg.set_content("short_auth_string".to_string(), short_auth_string.join(","));
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
    any_to_device_handle: Option<EventHandlerHandle>,
}

impl VerificationController {
    pub fn new() -> Self {
        let (tx, rx) = channel::<VerificationEvent>(10); // dropping after more than 10 items queued
        VerificationController {
            event_tx: tx,
            event_rx: Arc::new(Mutex::new(Some(rx))),
            sync_key_verification_request_handle: None,
            any_to_device_handle: None,
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
                        ev.sender,
                    );
                    if let Err(e) = me.event_tx.try_send(msg) {
                        error!("Dropping event for {}: {}", ev.event_id, e);
                    }
                    // from then on, accept_verification_request takes over
                }
            },
        );
        self.sync_key_verification_request_handle = Some(handle);
    }

    pub fn remove_sync_event_handler(&mut self, client: &SdkClient) {
        if let Some(handle) = self.sync_key_verification_request_handle.clone() {
            client.remove_event_handler(handle);
            self.sync_key_verification_request_handle = None;
        }
    }

    pub fn add_to_device_event_handler(&mut self, client: &SdkClient) {
        client.add_event_handler_context(self.clone());
        let handle = client.add_event_handler(
            |ev: AnyToDeviceEvent,
             c: SdkClient,
             Ctx(mut me): Ctx<VerificationController>| async move {
                let device_id = c.device_id().expect("guest user cannot get device id");
                match ev {
                    AnyToDeviceEvent::KeyVerificationRequest(evt) => {
                        let event_type = evt.content.event_type();
                        info!("{} got {}", device_id, event_type);
                        let mut msg = VerificationEvent::new(
                            c,
                            me.clone(),
                            event_type.to_string(),
                            None,
                            Some(evt.content.transaction_id.clone()),
                            evt.sender,
                        );
                        msg.set_content("from_device".to_string(), evt.content.from_device.to_string());
                        let methods = evt.content.methods.iter().map(|x| x.to_string()).collect::<Vec<String>>();
                        msg.set_content("methods".to_string(), methods.join(","));
                        msg.set_content("timestamp".to_string(), evt.content.timestamp.get().to_string());
                        if let Err(e) = me.event_tx.try_send(msg) {
                            error!("Dropping transaction for {}: {}", evt.content.transaction_id, e);
                        }
                    }
                    AnyToDeviceEvent::KeyVerificationReady(evt) => {
                        let event_type = evt.content.event_type();
                        info!("{} got {}", device_id, event_type);
                        let mut msg = VerificationEvent::new(
                            c,
                            me.clone(),
                            event_type.to_string(),
                            None,
                            Some(evt.content.transaction_id.clone()),
                            evt.sender,
                        );
                        msg.set_content("from_device".to_string(), evt.content.from_device.to_string());
                        let methods = evt.content.methods.iter().map(|x| x.to_string()).collect::<Vec<String>>();
                        msg.set_content("methods".to_string(), methods.join(","));
                        if let Err(e) = me.event_tx.try_send(msg) {
                            error!("Dropping transaction for {}: {}", evt.content.transaction_id, e);
                        }
                    }
                    AnyToDeviceEvent::KeyVerificationStart(evt) => {
                        let event_type = evt.content.event_type();
                        info!("{} got {}", device_id, event_type);
                        let mut msg = VerificationEvent::new(
                            c,
                            me.clone(),
                            event_type.to_string(),
                            None,
                            Some(evt.content.transaction_id.clone()),
                            evt.sender,
                        );
                        msg.set_content("from_device".to_string(), evt.content.from_device.to_string());
                        match evt.content.method {
                            StartMethod::SasV1(content) => {
                                let key_agreement_protocols = content
                                    .key_agreement_protocols
                                    .iter()
                                    .map(|x| x.to_string())
                                    .collect::<Vec<String>>();
                                msg.set_content("key_agreement_protocols".to_string(), key_agreement_protocols.join(","));
                                let hashes = content
                                    .hashes
                                    .iter()
                                    .map(|x| x.to_string())
                                    .collect::<Vec<String>>();
                                msg.set_content("hashes".to_string(), hashes.join(","));
                                let message_authentication_codes = content
                                    .message_authentication_codes
                                    .iter()
                                    .map(|x| x.to_string())
                                    .collect::<Vec<String>>();
                                msg.set_content("message_authentication_codes".to_string(), message_authentication_codes.join(","));
                                let short_authentication_string = content
                                    .short_authentication_string
                                    .iter()
                                    .map(|x| x.to_string())
                                    .collect::<Vec<String>>();
                                msg.set_content("short_authentication_string".to_string(), short_authentication_string.join(","));
                            }
                            StartMethod::ReciprocateV1(content) => {
                                let secret = serde_json::to_string(&content.secret).unwrap();
                                msg.set_content("secret".to_string(), secret);
                            }
                            _ => {}
                        }
                        if let Err(e) = me.event_tx.try_send(msg) {
                            error!("Dropping transaction for {}: {}", evt.content.transaction_id, e);
                        }
                    }
                    AnyToDeviceEvent::KeyVerificationKey(evt) => {
                        let event_type = evt.content.event_type();
                        info!("{} got {}", device_id, event_type);
                        let mut msg = VerificationEvent::new(
                            c,
                            me.clone(),
                            event_type.to_string(),
                            None,
                            Some(evt.content.transaction_id.clone()),
                            evt.sender,
                        );
                        msg.set_content("key".to_string(), evt.content.key.to_string());
                        if let Err(e) = me.event_tx.try_send(msg) {
                            error!("Dropping transaction for {}: {}", evt.content.transaction_id, e);
                        }
                    }
                    AnyToDeviceEvent::KeyVerificationAccept(evt) => {
                        let event_type = evt.content.event_type();
                        info!("{} got {}", device_id, event_type);
                        let mut msg = VerificationEvent::new(
                            c,
                            me.clone(),
                            event_type.to_string(),
                            None,
                            Some(evt.content.transaction_id.clone()),
                            evt.sender,
                        );
                        if let AcceptMethod::SasV1(content) = evt.content.method {
                            msg.set_content("hash".to_string(), content.hash.to_string());
                            msg.set_content("key_agreement_protocol".to_string(), content.key_agreement_protocol.to_string());
                            msg.set_content("message_authentication_code".to_string(), content.message_authentication_code.to_string());
                            let short_authentication_string = content
                                .short_authentication_string
                                .iter()
                                .map(|x| x.as_str().into())
                                .collect::<Vec<String>>();
                            msg.set_content("short_authentication_string".to_string(), short_authentication_string.join(","));
                            msg.set_content("commitment".to_string(), content.commitment.to_string());
                        }
                        if let Err(e) = me.event_tx.try_send(msg) {
                            error!("Dropping transaction for {}: {}", evt.content.transaction_id, e);
                        }
                    }
                    AnyToDeviceEvent::KeyVerificationCancel(evt) => {
                        let event_type = evt.content.event_type();
                        info!("{} got {}", device_id, event_type);
                        let mut msg = VerificationEvent::new(
                            c,
                            me.clone(),
                            event_type.to_string(),
                            None,
                            Some(evt.content.transaction_id.clone()),
                            evt.sender,
                        );
                        msg.set_content("code".to_string(), evt.content.code.to_string());
                        msg.set_content("reason".to_string(), evt.content.reason);
                        if let Err(e) = me.event_tx.try_send(msg) {
                            error!("Dropping transaction for {}: {}", evt.content.transaction_id, e);
                        }
                    }
                    AnyToDeviceEvent::KeyVerificationMac(evt) => {
                        let event_type = evt.content.event_type();
                        info!("{} got {}", device_id, event_type);
                        let mut msg = VerificationEvent::new(
                            c,
                            me.clone(),
                            event_type.to_string(),
                            None,
                            Some(evt.content.transaction_id.clone()),
                            evt.sender,
                        );
                        msg.set_content("keys".to_string(), evt.content.keys.to_string());
                        let mac = serde_json::to_string(&evt.content.mac).unwrap();
                        msg.set_content("mac".to_string(), mac);
                        if let Err(e) = me.event_tx.try_send(msg) {
                            error!("Dropping transaction for {}: {}", evt.content.transaction_id, e);
                        }
                    }
                    AnyToDeviceEvent::KeyVerificationDone(evt) => {
                        let event_type = evt.content.event_type();
                        info!("{} got {}", device_id, event_type);
                        let msg = VerificationEvent::new(
                            c,
                            me.clone(),
                            event_type.to_string(),
                            None,
                            Some(evt.content.transaction_id.clone()),
                            evt.sender,
                        );
                        if let Err(e) = me.event_tx.try_send(msg) {
                            error!("Dropping transaction for {}: {}", evt.content.transaction_id, e);
                        }
                    }
                    _ => {}
                }
            },
        );
        self.any_to_device_handle = Some(handle);
    }

    pub fn remove_to_device_event_handler(&mut self, client: &SdkClient) {
        if let Some(handle) = self.any_to_device_handle.clone() {
            client.remove_event_handler(handle);
            self.any_to_device_handle = None;
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
                    let is_verified = crypto_devices.get(&device.device_id).is_some_and(|d| {
                        d.is_cross_signed_by_owner() || d.is_verified_with_cross_signing()
                    });
                    let mut is_active = false;
                    if let Some(last_seen_ts) = device.last_seen_ts {
                        let limit = SystemTime::now()
                            .checked_sub(Duration::from_secs(90 * 24 * 60 * 60))
                            .context("Couldn't get time of 90 days ago")?
                            .duration_since(UNIX_EPOCH)
                            .context("Couldn't calculate duration from Unix epoch")?;
                        let secs: u64 = last_seen_ts.as_secs().into();
                        if secs < limit.as_secs() {
                            is_active = true;
                        }
                    }
                    sessions.push(DeviceRecord::new(
                        device.device_id.clone(),
                        device.display_name.clone(),
                        device.last_seen_ts,
                        device.last_seen_ip.clone(),
                        is_verified,
                        is_active,
                    ));
                }
                info!("all sessions: {:?}", sessions);
                Ok(sessions)
            })
            .await?
    }

    pub async fn delete_devices(
        &self,
        dev_ids: &mut Vec<String>,
        username: String,
        password: String,
    ) -> Result<bool> {
        let client = self.client.clone();
        let devices = (*dev_ids)
            .iter()
            .map(|x| x.as_str().into())
            .collect::<Vec<OwnedDeviceId>>();
        RUNTIME
            .spawn(async move {
                if let Err(e) = client.delete_devices(&devices, None).await {
                    if let Some(info) = e.as_uiaa_response() {
                        let pass_data = assign!(Password::new(
                            UserIdentifier::UserIdOrLocalpart(username),
                            password,
                        ), {
                            session: info.session.clone(),
                        });
                        let auth_data = AuthData::Password(pass_data);
                        client.delete_devices(&devices, Some(auth_data)).await?;
                    } else {
                        return Ok(false);
                    }
                }
                Ok(true)
            })
            .await?
    }

    pub async fn request_verification(&self, dev_id: String) -> Result<bool> {
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let user_id = client.user_id().context("User not found")?;
                if let Some(device) = client
                    .encryption()
                    .get_device(user_id, device_id!(dev_id.as_str()))
                    .await
                    .context("Couldn't get crypto device")?
                {
                    let is_verified = device.is_cross_signed_by_owner()
                        || device.is_verified_with_cross_signing();
                    if !is_verified {
                        let request = device
                            .request_verification()
                            .await
                            .context("Failed to request verification")?;
                    }
                }
                Ok(true)
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

impl DeviceNewEvent {
    pub async fn request_verification_to_user(&self) -> Result<bool> {
        let client = self.client();
        RUNTIME
            .spawn(async move {
                let user_id = client
                    .user_id()
                    .context("guest user cannot request verification")?;
                let user = client
                    .encryption()
                    .get_user_identity(user_id)
                    .await?
                    .context("alice should get user identity")?;
                user.request_verification().await?;
                Ok(true)
            })
            .await?
    }

    pub async fn request_verification_to_device(&self, dev_id: String) -> Result<bool> {
        let client = self.client();
        RUNTIME
            .spawn(async move {
                let user_id = client
                    .user_id()
                    .context("guest user cannot request verification")?;
                let dev = client
                    .encryption()
                    .get_device(user_id, device_id!(dev_id.as_str()))
                    .await?
                    .context("alice should get device")?;
                dev.request_verification_with_methods(vec![VerificationMethod::SasV1])
                    .await?;
                Ok(true)
            })
            .await?
    }

    pub async fn request_verification_to_user_with_methods(
        &self,
        methods: &mut Vec<String>,
    ) -> Result<bool> {
        let client = self.client();
        let values = (*methods).iter().map(|e| e.as_str().into()).collect();
        RUNTIME
            .spawn(async move {
                let user_id = client
                    .user_id()
                    .context("guest user cannot request verification")?;
                let user = client
                    .encryption()
                    .get_user_identity(user_id)
                    .await?
                    .context("alice should get user identity")?;
                user.request_verification_with_methods(values).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn request_verification_to_device_with_methods(
        &self,
        dev_id: String,
        methods: &mut Vec<String>,
    ) -> Result<bool> {
        let client = self.client();
        let values = (*methods).iter().map(|e| e.as_str().into()).collect();
        RUNTIME
            .spawn(async move {
                let user_id = client
                    .user_id()
                    .context("guest user cannot request verification")?;
                let dev = client
                    .encryption()
                    .get_device(user_id, device_id!(dev_id.as_str()))
                    .await?
                    .context("alice should get device")?;
                dev.request_verification_with_methods(values).await?;
                Ok(true)
            })
            .await?
    }
}
