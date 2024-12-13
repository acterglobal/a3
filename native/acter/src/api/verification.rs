use anyhow::{bail, Context, Result};
use futures::stream::{Stream, StreamExt};
use matrix_sdk::{
    config::SyncSettings,
    encryption::verification::{
        Emoji, SasState, SasVerification, Verification, VerificationRequest,
        VerificationRequestState,
    },
    event_handler::{Ctx, EventHandlerHandle},
    Client as SdkClient,
};
use matrix_sdk_base::ruma::{
    api::client::{
        device::delete_device,
        uiaa::{AuthData, Password, UserIdentifier},
    },
    assign, device_id,
    events::{
        key::verification::{accept::AcceptMethod, start::StartMethod, VerificationMethod},
        room::message::{MessageType, OriginalSyncRoomMessageEvent},
        AnyToDeviceEvent, EventContent,
    },
    OwnedDeviceId, OwnedUserId,
};
use std::{
    collections::HashMap,
    marker::Unpin,
    ops::Deref,
    sync::Arc,
    time::{Duration, SystemTime, UNIX_EPOCH},
};
use tokio::sync::broadcast::{channel, Receiver, Sender};
use tokio_stream::wrappers::BroadcastStream;
use tracing::{error, info};

use super::{client::Client, common::DeviceRecord, RUNTIME};

#[derive(Clone, Debug)]
pub struct VerificationEvent {
    client: SdkClient,
    controller: VerificationController,
    event_type: String,
    flow_id: String,
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
        flow_id: String,
        sender: OwnedUserId,
    ) -> Self {
        VerificationEvent {
            client,
            controller,
            event_type,
            flow_id,
            sender,
            content: Default::default(),
            emojis: Default::default(),
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
        let flow_id = self.flow_id.clone();
        RUNTIME
            .spawn(async move {
                let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, &flow_id)
                    .await
                else {
                    // request may be timed out
                    bail!("Could not get verification object")
                };
                let items = sas.emoji().context("No emojis found. Aborted.")?;
                let sequence = items
                    .iter()
                    .filter_map(VerificationEmoji::new)
                    .collect::<Vec<VerificationEmoji>>();
                Ok(sequence)
            })
            .await?
    }

    pub async fn accept_verification_request(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = self.sender.clone();
        let flow_id = self.flow_id.clone();
        RUNTIME
            .spawn(async move {
                let Some(request) = client
                    .encryption()
                    .get_verification_request(&sender, &flow_id)
                    .await
                else {
                    // request may be timed out
                    bail!("Could not get verification request")
                };
                info!(
                    "Accepting verification request from {}",
                    request.other_user_id()
                );
                request.accept().await?;
                Ok(true)
            })
            .await?
    }

    // alternative of terminate_verification
    pub async fn cancel_verification_request(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = self.sender.clone();
        let flow_id = self.flow_id.clone();
        RUNTIME
            .spawn(async move {
                let Some(request) = client
                    .encryption()
                    .get_verification_request(&sender, &flow_id)
                    .await
                else {
                    // request may be timed out
                    bail!("Could not get verification request")
                };
                request.cancel().await?;
                Ok(true)
            })
            .await?
    }

    pub async fn accept_verification_request_with_method(&self, method: String) -> Result<bool> {
        let client = self.client.clone();
        let sender = self.sender.clone();
        let flow_id = self.flow_id.clone();
        let values = vec![VerificationMethod::from(method.as_str())];
        RUNTIME
            .spawn(async move {
                let Some(request) = client
                    .encryption()
                    .get_verification_request(&sender, &flow_id)
                    .await
                else {
                    // request may be timed out
                    bail!("Could not get verification request")
                };
                info!(
                    "Accepting verification request from {}",
                    request.other_user_id()
                );
                request.accept_with_methods(values).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn start_sas_verification(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = self.sender.clone();
        let flow_id = self.flow_id.clone();
        RUNTIME
            .spawn(async move {
                let Some(request) = client
                    .encryption()
                    .get_verification_request(&sender, &flow_id)
                    .await
                else {
                    // request may be timed out
                    bail!("Could not get verification request")
                };
                let sas = request.start_sas().await?;
                Ok(sas.is_some())
            })
            .await?
    }

    pub async fn accept_sas_verification(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = self.sender.clone();
        let flow_id = self.flow_id.clone();
        RUNTIME
            .spawn(async move {
                let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, &flow_id)
                    .await
                else {
                    // request may be timed out
                    bail!("Could not get verification object")
                };
                info!(
                    "Starting verification with {} {}",
                    &sas.other_device().user_id(),
                    &sas.other_device().device_id()
                );
                sas.accept().await?;
                Ok(true)
            })
            .await?
    }

    pub async fn cancel_sas_verification(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = self.sender.clone();
        let flow_id = self.flow_id.clone();
        RUNTIME
            .spawn(async move {
                let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, &flow_id)
                    .await
                else {
                    // request may be timed out
                    bail!("Could not get verification object")
                };
                sas.cancel().await?;
                Ok(true)
            })
            .await?
    }

    #[cfg(feature = "testing")]
    pub async fn send_verification_key(&self) -> Result<bool> {
        let client = self.client.clone();
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
        let flow_id = self.flow_id.clone();
        RUNTIME
            .spawn(async move {
                let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, &flow_id)
                    .await
                else {
                    // request may be timed out
                    bail!("Could not get verification object")
                };
                sas.confirm().await?;
                Ok(true)
            })
            .await?
    }

    pub async fn mismatch_sas_verification(&self) -> Result<bool> {
        let client = self.client.clone();
        let sender = self.sender.clone();
        let flow_id = self.flow_id.clone();
        RUNTIME
            .spawn(async move {
                let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, &flow_id)
                    .await
                else {
                    // request may be timed out
                    bail!("Could not get verification object")
                };
                sas.mismatch().await?;
                Ok(true)
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
    fn new(val: &Emoji) -> Option<Self> {
        // first char would be symbol
        val.symbol.chars().next().map(|chr| VerificationEmoji {
            symbol: chr as u32,
            description: val.description.to_owned(),
        })
    }

    pub fn symbol(&self) -> u32 {
        self.symbol
    }

    pub fn description(&self) -> String {
        self.description.clone()
    }
}

async fn request_verification_handler(
    client: Client,
    request: VerificationRequest,
    flow_id: String,
    sender: OwnedUserId,
) -> Result<()> {
    let controller = client.verification_controller.clone();
    let mut stream = request.changes();
    while let Some(state) = stream.next().await {
        match state {
            VerificationRequestState::Created { our_methods } => {
                let device_id = client.device_id()?;
                let event_type = "VerificationRequestState::Created".to_string();
                info!("{} got {}", device_id, event_type);
                let mut msg = VerificationEvent::new(
                    client.core.client().clone(),
                    controller.clone(),
                    event_type,
                    flow_id.clone(),
                    sender.clone(),
                );
                let methods = our_methods
                    .iter()
                    .map(|x| x.to_string())
                    .collect::<Vec<String>>()
                    .join(",");
                msg.set_content("our_methods".to_string(), methods);
                if let Err(e) = controller.event_tx.send(msg) {
                    error!("Dropping flow for {}: {}", flow_id, e);
                }
            }
            VerificationRequestState::Requested {
                their_methods,
                other_device_data,
            } => {
                let device_id = client.device_id()?;
                let event_type = "VerificationRequestState::Requested".to_string();
                info!("{} got {}", device_id, event_type);
                let mut msg = VerificationEvent::new(
                    client.core.client().clone(),
                    controller.clone(),
                    event_type,
                    flow_id.clone(),
                    sender.clone(),
                );
                let methods = their_methods
                    .iter()
                    .map(|x| x.to_string())
                    .collect::<Vec<String>>()
                    .join(",");
                msg.set_content("their_methods".to_string(), methods);
                msg.set_content(
                    "other_device_id".to_string(),
                    other_device_data.device_id().to_string(),
                );
                if let Err(e) = controller.event_tx.send(msg) {
                    error!("Dropping flow for {}: {}", flow_id, e);
                }
            }
            VerificationRequestState::Ready {
                their_methods,
                our_methods,
                other_device_data,
            } => {
                let device_id = client.device_id()?;
                let event_type = "VerificationRequestState::Ready".to_string();
                info!("{} got {}", device_id, event_type);
                let mut msg = VerificationEvent::new(
                    client.core.client().clone(),
                    controller.clone(),
                    event_type,
                    flow_id.clone(),
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
                msg.set_content(
                    "other_device_id".to_string(),
                    other_device_data.device_id().to_string(),
                );
                if let Err(e) = controller.event_tx.send(msg) {
                    error!("Dropping flow for {}: {}", flow_id, e);
                }
            }
            VerificationRequestState::Transitioned { verification } => {
                if let Verification::SasV1(s) = verification {
                    let device_id = client.device_id()?;
                    let event_type = "VerificationRequestState::Transitioned".to_string();
                    info!("{} got {}", device_id, event_type);
                    let msg = VerificationEvent::new(
                        client.core.client().clone(),
                        controller.clone(),
                        event_type,
                        flow_id.clone(),
                        sender.clone(),
                    );
                    if let Err(e) = controller.event_tx.send(msg) {
                        error!("Dropping flow for {}: {}", flow_id, e);
                    }
                }
            }
            VerificationRequestState::Done => {
                let device_id = client.device_id()?;
                let event_type = "VerificationRequestState::Done".to_string();
                info!("{} got {}", device_id, event_type);
                let msg = VerificationEvent::new(
                    client.core.client().clone(),
                    controller.clone(),
                    event_type,
                    flow_id.clone(),
                    sender.clone(),
                );
                if let Err(e) = controller.event_tx.send(msg) {
                    error!("Dropping flow for {}: {}", flow_id, e);
                }
                break; // finish
            }
            VerificationRequestState::Cancelled(cancel_info) => {
                let device_id = client.device_id()?;
                let event_type = "VerificationRequestState::Cancelled".to_string();
                info!("{} got {}", device_id, event_type);
                let mut msg = VerificationEvent::new(
                    client.core.client().clone(),
                    controller.clone(),
                    event_type,
                    flow_id.clone(),
                    sender.clone(),
                );
                msg.set_content(
                    "cancel_code".to_string(),
                    cancel_info.cancel_code().to_string(),
                );
                msg.set_content("reason".to_string(), cancel_info.reason().to_string());
                if let Err(e) = controller.event_tx.send(msg) {
                    error!("Dropping flow for {}: {}", flow_id, e);
                }
                break; // finish
            }
        }
    }
    Ok(())
}

async fn sas_verification_handler(
    client: Client,
    sas: SasVerification,
    flow_id: String,
    sender: OwnedUserId,
) -> Result<()> {
    let controller = client.verification_controller.clone();
    let mut stream = sas.changes();
    while let Some(state) = stream.next().await {
        match state {
            SasState::KeysExchanged { emojis, decimals } => {
                let device_id = client.device_id()?;
                let event_type = "SasState::KeysExchanged".to_string();
                info!("{} got {}", device_id, event_type);
                let mut msg = VerificationEvent::new(
                    client.core.client().clone(),
                    controller.clone(),
                    event_type,
                    flow_id.clone(),
                    sender.clone(),
                );
                if let Some(auth_string) = emojis {
                    let sequence = auth_string
                        .emojis
                        .iter()
                        .filter_map(VerificationEmoji::new)
                        .collect::<Vec<VerificationEmoji>>();
                    msg.set_emojis(sequence);
                }
                let value = match serde_json::to_string(&decimals) {
                    Ok(e) => e,
                    Err(e) => {
                        error!("KeysExchanged: couldn’t convert decimals to string");
                        return Err(e.into());
                    }
                };
                msg.set_content("decimals".to_string(), value);
                if let Err(e) = controller.event_tx.send(msg) {
                    error!("Dropping flow for {}: {}", flow_id, e);
                }
            }
            SasState::Done {
                verified_devices,
                verified_identities,
            } => {
                let device_id = client.device_id()?;
                let event_type = "SasState::Done".to_string();
                info!("{} got {}", device_id, event_type);
                let mut msg = VerificationEvent::new(
                    client.core.client().clone(),
                    controller.clone(),
                    event_type,
                    flow_id.clone(),
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
                if let Err(e) = controller.event_tx.send(msg) {
                    error!("Dropping flow for {}: {}", flow_id, e);
                }
                break; // finish
            }
            SasState::Cancelled(cancel_info) => {
                let device_id = client.device_id()?;
                let event_type = "SasState::Cancelled".to_string();
                info!("{} got {}", device_id, event_type);
                let mut msg = VerificationEvent::new(
                    client.core.client().clone(),
                    controller.clone(),
                    event_type,
                    flow_id.clone(),
                    sender.clone(),
                );
                msg.set_content(
                    "cancel_code".to_string(),
                    cancel_info.cancel_code().to_string(),
                );
                msg.set_content("reason".to_string(), cancel_info.reason().to_string());
                if let Err(e) = controller.event_tx.send(msg) {
                    error!("Dropping flow for {}: {}", flow_id, e);
                }
                break; // finish
            }
            SasState::Started { protocols } => {
                let device_id = client.device_id()?;
                let event_type = "SasState::Started".to_string();
                info!("{} got {}", device_id, event_type);
                let mut msg = VerificationEvent::new(
                    client.core.client().clone(),
                    controller.clone(),
                    event_type,
                    flow_id.clone(),
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
                if let Err(e) = controller.event_tx.send(msg) {
                    error!("Dropping flow for {}: {}", flow_id, e);
                }
            }
            SasState::Accepted { accepted_protocols } => {
                let device_id = client.device_id()?;
                let event_type = "SasState::Accepted".to_string();
                info!("{} got {}", device_id, event_type);
                let mut msg = VerificationEvent::new(
                    client.core.client().clone(),
                    controller.clone(),
                    event_type,
                    flow_id.clone(),
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
                if let Err(e) = controller.event_tx.send(msg) {
                    error!("Dropping flow for {}: {}", flow_id, e);
                }
            }
            SasState::Confirmed => {
                let device_id = client.device_id()?;
                let event_type = "SasState::Confirmed".to_string();
                info!("{} got {}", device_id, event_type);
                let msg = VerificationEvent::new(
                    client.core.client().clone(),
                    controller.clone(),
                    event_type,
                    flow_id.clone(),
                    sender.clone(),
                );
                if let Err(e) = controller.event_tx.send(msg) {
                    error!("Dropping flow for {}: {}", flow_id, e);
                }
            }
            SasState::Created { protocols } => {} // FIXME: Is there anything for us to do here?
        }
    }
    Ok(())
}

#[derive(Clone, Debug)]
pub(crate) struct VerificationController {
    event_tx: Sender<VerificationEvent>,
    event_rx: Arc<Receiver<VerificationEvent>>,
    sync_key_verification_request_handle: Option<EventHandlerHandle>,
    any_to_device_handle: Option<EventHandlerHandle>,
}

impl VerificationController {
    pub fn new() -> Self {
        let (tx, rx) = channel::<VerificationEvent>(10); // dropping after more than 10 items queued
        VerificationController {
            event_tx: tx,
            event_rx: Arc::new(rx),
            sync_key_verification_request_handle: None,
            any_to_device_handle: None,
        }
    }

    // sync event is intended to verify other user
    pub fn add_sync_event_handler(&mut self, client: &SdkClient) {
        client.add_event_handler_context(self.clone());
        let handle = client.add_event_handler(
            |ev: OriginalSyncRoomMessageEvent,
             c: SdkClient,
             Ctx(me): Ctx<VerificationController>| async move {
                if let MessageType::VerificationRequest(content) = &ev.content.msgtype {
                    info!("MessageType::VerificationRequest");
                    let device_id = c.device_id().expect("DeviceId needed");
                    let event_type = ev.content.event_type();
                    info!("{} got {}", device_id, event_type);
                    let mut msg = VerificationEvent::new(
                        c,
                        me.clone(),
                        event_type.to_string(),
                        ev.event_id.to_string(),
                        ev.sender,
                    );
                    msg.set_content("body".to_string(), content.body.clone());
                    msg.set_content("from_device".to_string(), content.from_device.to_string());
                    let methods = content
                        .methods
                        .iter()
                        .map(|x| x.to_string())
                        .collect::<Vec<String>>();
                    msg.set_content("methods".to_string(), methods.join(","));
                    msg.set_content("to".to_string(), content.to.to_string());
                    // this may be the past event occurred when device was off
                    // so this event has no timestamp field unlike AnyToDeviceEvent::KeyVerificationRequest
                    if let Err(e) = me.event_tx.send(msg) {
                        error!("Dropping flow for {}: {}", ev.event_id, e);
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

    // to_device event is intended to verify other device
    pub fn add_to_device_event_handler(&mut self, client: &SdkClient) {
        client.add_event_handler_context(self.clone());
        let handle = client.add_event_handler(
            |ev: AnyToDeviceEvent, c: SdkClient, Ctx(me): Ctx<VerificationController>| async move {
                let device_id = c.device_id().expect("DeviceId needed");
                match ev {
                    AnyToDeviceEvent::KeyVerificationRequest(evt) => {
                        info!("AnyToDeviceEvent::KeyVerificationRequest");
                        let event_type = evt.content.event_type();
                        info!("{} got {}", device_id, event_type);
                        let mut msg = VerificationEvent::new(
                            c,
                            me.clone(),
                            event_type.to_string(),
                            evt.content.transaction_id.to_string(),
                            evt.sender,
                        );
                        msg.set_content(
                            "from_device".to_string(),
                            evt.content.from_device.to_string(),
                        );
                        let methods = evt
                            .content
                            .methods
                            .iter()
                            .map(|x| x.to_string())
                            .collect::<Vec<String>>();
                        msg.set_content("methods".to_string(), methods.join(","));
                        msg.set_content(
                            "timestamp".to_string(),
                            evt.content.timestamp.get().to_string(),
                        );
                        if let Err(e) = me.event_tx.send(msg) {
                            error!("Dropping flow for {}: {}", evt.content.transaction_id, e);
                        }
                    }
                    AnyToDeviceEvent::KeyVerificationReady(evt) => {
                        info!("AnyToDeviceEvent::KeyVerificationReady");
                        let event_type = evt.content.event_type();
                        info!("{} got {}", device_id, event_type);
                        let mut msg = VerificationEvent::new(
                            c,
                            me.clone(),
                            event_type.to_string(),
                            evt.content.transaction_id.to_string(),
                            evt.sender,
                        );
                        msg.set_content(
                            "from_device".to_string(),
                            evt.content.from_device.to_string(),
                        );
                        let methods = evt
                            .content
                            .methods
                            .iter()
                            .map(|x| x.to_string())
                            .collect::<Vec<String>>();
                        msg.set_content("methods".to_string(), methods.join(","));
                        if let Err(e) = me.event_tx.send(msg) {
                            error!("Dropping flow for {}: {}", evt.content.transaction_id, e);
                        }
                    }
                    AnyToDeviceEvent::KeyVerificationStart(evt) => {
                        info!("AnyToDeviceEvent::KeyVerificationStart");
                        let event_type = evt.content.event_type();
                        info!("{} got {}", device_id, event_type);
                        let mut msg = VerificationEvent::new(
                            c,
                            me.clone(),
                            event_type.to_string(),
                            evt.content.transaction_id.to_string(),
                            evt.sender,
                        );
                        msg.set_content(
                            "from_device".to_string(),
                            evt.content.from_device.to_string(),
                        );
                        match evt.content.method {
                            StartMethod::SasV1(content) => {
                                let key_agreement_protocols = content
                                    .key_agreement_protocols
                                    .iter()
                                    .map(|x| x.to_string())
                                    .collect::<Vec<String>>();
                                msg.set_content(
                                    "key_agreement_protocols".to_string(),
                                    key_agreement_protocols.join(","),
                                );
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
                                msg.set_content(
                                    "message_authentication_codes".to_string(),
                                    message_authentication_codes.join(","),
                                );
                                let short_authentication_string = content
                                    .short_authentication_string
                                    .iter()
                                    .map(|x| x.to_string())
                                    .collect::<Vec<String>>();
                                msg.set_content(
                                    "short_authentication_string".to_string(),
                                    short_authentication_string.join(","),
                                );
                            }
                            StartMethod::ReciprocateV1(content) => {
                                let secret = match serde_json::to_string(&content.secret) {
                                    Ok(e) => e,
                                    Err(e) => {
                                        error!("ReciprocateV1: couldn’t convert secret to string");
                                        return;
                                    }
                                };
                                msg.set_content("secret".to_string(), secret);
                            }
                            _ => {}
                        }
                        if let Err(e) = me.event_tx.send(msg) {
                            error!("Dropping flow for {}: {}", evt.content.transaction_id, e);
                        }
                    }
                    AnyToDeviceEvent::KeyVerificationKey(evt) => {
                        info!("AnyToDeviceEvent::KeyVerificationKey");
                        let event_type = evt.content.event_type();
                        info!("{} got {}", device_id, event_type);
                        let mut msg = VerificationEvent::new(
                            c,
                            me.clone(),
                            event_type.to_string(),
                            evt.content.transaction_id.to_string(),
                            evt.sender,
                        );
                        msg.set_content("key".to_string(), evt.content.key.to_string());
                        if let Err(e) = me.event_tx.send(msg) {
                            error!("Dropping flow for {}: {}", evt.content.transaction_id, e);
                        }
                    }
                    AnyToDeviceEvent::KeyVerificationAccept(evt) => {
                        info!("AnyToDeviceEvent::KeyVerificationAccept");
                        let event_type = evt.content.event_type();
                        info!("{} got {}", device_id, event_type);
                        let mut msg = VerificationEvent::new(
                            c,
                            me.clone(),
                            event_type.to_string(),
                            evt.content.transaction_id.to_string(),
                            evt.sender,
                        );
                        if let AcceptMethod::SasV1(content) = evt.content.method {
                            msg.set_content("hash".to_string(), content.hash.to_string());
                            msg.set_content(
                                "key_agreement_protocol".to_string(),
                                content.key_agreement_protocol.to_string(),
                            );
                            msg.set_content(
                                "message_authentication_code".to_string(),
                                content.message_authentication_code.to_string(),
                            );
                            let short_authentication_string = content
                                .short_authentication_string
                                .iter()
                                .map(|x| x.as_str().into())
                                .collect::<Vec<String>>();
                            msg.set_content(
                                "short_authentication_string".to_string(),
                                short_authentication_string.join(","),
                            );
                            msg.set_content(
                                "commitment".to_string(),
                                content.commitment.to_string(),
                            );
                        }
                        if let Err(e) = me.event_tx.send(msg) {
                            error!("Dropping flow for {}: {}", evt.content.transaction_id, e);
                        }
                    }
                    AnyToDeviceEvent::KeyVerificationCancel(evt) => {
                        info!("AnyToDeviceEvent::KeyVerificationCancel");
                        let event_type = evt.content.event_type();
                        info!("{} got {}", device_id, event_type);
                        let mut msg = VerificationEvent::new(
                            c,
                            me.clone(),
                            event_type.to_string(),
                            evt.content.transaction_id.to_string(),
                            evt.sender,
                        );
                        msg.set_content("code".to_string(), evt.content.code.to_string());
                        msg.set_content("reason".to_string(), evt.content.reason);
                        if let Err(e) = me.event_tx.send(msg) {
                            error!("Dropping flow for {}: {}", evt.content.transaction_id, e);
                        }
                    }
                    AnyToDeviceEvent::KeyVerificationMac(evt) => {
                        info!("AnyToDeviceEvent::KeyVerificationMac");
                        let event_type = evt.content.event_type();
                        info!("{} got {}", device_id, event_type);
                        let mut msg = VerificationEvent::new(
                            c,
                            me.clone(),
                            event_type.to_string(),
                            evt.content.transaction_id.to_string(),
                            evt.sender,
                        );
                        msg.set_content("keys".to_string(), evt.content.keys.to_string());
                        let mac = match serde_json::to_string(&evt.content.mac) {
                            Ok(e) => e,
                            Err(e) => {
                                error!("KeyVerificationMac: couldn’t convert mac to string");
                                return;
                            }
                        };
                        msg.set_content("mac".to_string(), mac);
                        if let Err(e) = me.event_tx.send(msg) {
                            error!("Dropping flow for {}: {}", evt.content.transaction_id, e);
                        }
                    }
                    AnyToDeviceEvent::KeyVerificationDone(evt) => {
                        info!("AnyToDeviceEvent::KeyVerificationDone");
                        let event_type = evt.content.event_type();
                        info!("{} got {}", device_id, event_type);
                        let msg = VerificationEvent::new(
                            c,
                            me.clone(),
                            event_type.to_string(),
                            evt.content.transaction_id.to_string(),
                            evt.sender,
                        );
                        if let Err(e) = me.event_tx.send(msg) {
                            error!("Dropping flow for {}: {}", evt.content.transaction_id, e);
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
    client: Client,
}

impl SessionManager {
    pub async fn all_sessions(&self) -> Result<Vec<DeviceRecord>> {
        let client = self.client.clone();
        let user_id = client.user_id()?;
        let device_id = client.device_id()?;

        RUNTIME
            .spawn(async move {
                let response = client.devices().await?;
                let crypto_devices = client.encryption().get_user_devices(&user_id).await?;
                let mut sessions = vec![];
                for device in response.devices {
                    let is_verified = crypto_devices.get(&device.device_id).is_some_and(|d| {
                        d.is_cross_signed_by_owner() || d.is_verified_with_cross_signing()
                    });
                    let mut is_active = false;
                    if let Some(last_seen_ts) = device.last_seen_ts {
                        let limit = SystemTime::now()
                            .checked_sub(Duration::from_secs(90 * 24 * 60 * 60))
                            .context("Unable to get time of 90 days ago")?
                            .duration_since(UNIX_EPOCH)?;
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
                        device.device_id == device_id,
                    ));
                }
                info!("all sessions: {:?}", sessions);
                Ok(sessions)
            })
            .await?
    }

    pub async fn delete_device(
        &self,
        dev_id: String,
        username: String,
        password: String,
    ) -> Result<bool> {
        let client = self.client.deref().clone();
        let dev_id = OwnedDeviceId::from(dev_id);
        RUNTIME
            .spawn(async move {
                let request = delete_device::v3::Request::new(dev_id.clone());
                if let Err(e) = client.send(request, None).await {
                    if let Some(info) = e.as_uiaa_response() {
                        let pass_data = assign!(Password::new(
                            UserIdentifier::UserIdOrLocalpart(username),
                            password,
                        ), {
                            session: info.session.clone(),
                        });
                        let auth_data = AuthData::Password(pass_data);
                        let request = assign!(delete_device::v3::Request::new(dev_id), {
                            auth: Some(auth_data),
                        });
                        client.send(request, None).await?;
                    } else {
                        return Ok(false);
                    }
                }
                Ok(true)
            })
            .await?
    }

    pub async fn request_verification(&self, dev_id: String) -> Result<String> {
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let user_id = client.user_id()?;
                let device = client
                    .encryption()
                    .get_device(&user_id, device_id!(dev_id.as_str()))
                    .await?
                    .context("Could not get device from encryption")?;
                let is_verified =
                    device.is_cross_signed_by_owner() || device.is_verified_with_cross_signing();
                if is_verified {
                    bail!("Device {} was already verified", dev_id);
                }
                let request = device.request_verification().await?;
                info!("requested verification - flow_id: {}", request.flow_id());
                Ok(request.flow_id().to_owned())
            })
            .await?
    }

    // alternative of cancel_verification_request
    pub async fn terminate_verification(&self, flow_id: String) -> Result<bool> {
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let user_id = client.user_id()?;
                let request = client
                    .encryption()
                    .get_verification_request(&user_id, flow_id)
                    .await
                    .context("Could not get verification request")?; // request may be timed out
                request.cancel().await?;
                Ok(true)
            })
            .await?
    }
}

impl Client {
    // this return value should be Unpin, because next() of this stream is called in wait_for_verification_event
    // this return value should be wrapped in Box::pin, to make unpin possible
    pub fn verification_event_rx(&self) -> impl Stream<Item = VerificationEvent> + Unpin {
        let mut stream = BroadcastStream::new(self.verification_controller.event_rx.resubscribe());
        Box::pin(stream.filter_map(|o| async move { o.ok() }))
    }

    pub fn session_manager(&self) -> SessionManager {
        SessionManager {
            client: self.clone(),
        }
    }

    pub async fn request_verification(&self, dev_id: String) -> Result<VerificationEvent> {
        let client = self.core.client().clone();
        let controller = self.verification_controller.clone();
        let user_id = self.user_id()?;

        RUNTIME
            .spawn(async move {
                let device = client
                    .clone()
                    .encryption()
                    .get_device(&user_id, device_id!(dev_id.as_str()))
                    .await?
                    .context("Could not get device from encryption")?;
                let is_verified =
                    device.is_cross_signed_by_owner() || device.is_verified_with_cross_signing();
                if is_verified {
                    bail!("Device {} was already verified", dev_id);
                }
                let request = device.request_verification().await?;
                let flow_id = request.flow_id().to_owned();
                info!("requested verification - flow_id: {}", flow_id.clone());
                let msg = VerificationEvent::new(
                    client,
                    controller,
                    "VerificationRequestState::Created".to_owned(),
                    flow_id,
                    user_id,
                );
                Ok(msg)
            })
            .await?
    }

    #[cfg(feature = "testing")]
    pub async fn request_verification_with_method(
        &self,
        dev_id: String,
        method: String,
    ) -> Result<String> {
        let client = self.core.client().clone();
        let user_id = self.user_id()?;
        let values = vec![VerificationMethod::from(method.as_str())];

        RUNTIME
            .spawn(async move {
                let device = client
                    .encryption()
                    .get_device(&user_id, device_id!(dev_id.as_str()))
                    .await?
                    .context("Could not get device from encryption")?;
                let request = device.request_verification_with_methods(values).await?;
                Ok(request.flow_id().to_owned())
            })
            .await?
    }

    pub async fn install_request_event_handler(&self, flow_id: String) -> Result<bool> {
        let me = self.clone();
        let sender = self.user_id()?;

        RUNTIME
            .spawn(async move {
                let request = me
                    .core
                    .client()
                    .encryption()
                    .get_verification_request(&sender, &flow_id)
                    .await
                    .context("Could not get verification request")?; // request may be timed out
                tokio::spawn(request_verification_handler(me, request, flow_id, sender));
                Ok(true)
            })
            .await?
    }

    pub async fn install_sas_event_handler(&self, flow_id: String) -> Result<bool> {
        let me = self.clone();
        let sender = self.user_id()?;

        RUNTIME
            .spawn(async move {
                let Some(Verification::SasV1(sas)) = me
                    .core
                    .client()
                    .encryption()
                    .get_verification(&sender, &flow_id)
                    .await
                else {
                    // request may be timed out
                    bail!("Could not get verification object")
                };
                tokio::spawn(sas_verification_handler(me, sas, flow_id, sender));
                Ok(true)
            })
            .await?
    }
}
