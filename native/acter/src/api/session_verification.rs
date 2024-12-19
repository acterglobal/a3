use anyhow::{bail, Result};
use futures::stream::{Stream, StreamExt};
use matrix_sdk::{
    encryption::{
        verification::{
            Emoji, SasState, SasVerification, Verification, VerificationRequest,
            VerificationRequestState,
        },
        Encryption,
    },
    event_handler::{Ctx, EventHandlerHandle},
    ruma::{
        events::{
            key::verification::{request::ToDeviceKeyVerificationRequestEvent, VerificationMethod},
            room::message::{MessageType, OriginalSyncRoomMessageEvent},
        },
        OwnedUserId,
    },
    Client as SdkClient,
};
use std::{
    marker::Unpin,
    sync::{Arc, RwLock},
};
use tokio::sync::broadcast::{channel, Receiver, Sender};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};
use tokio_stream::wrappers::BroadcastStream;
use tracing::{error, info};

use super::{Client, RUNTIME};

#[derive(Clone, Debug)]
pub(crate) struct SessionVerificationController {
    to_device_verification_request_handle: Option<EventHandlerHandle>,
    room_msg_verification_request_handle: Option<EventHandlerHandle>,
    request_event_tx: Sender<VerificationRequestEvent>,
    request_event_rx: Arc<Receiver<VerificationRequestEvent>>,
    verification_request: Arc<RwLock<Option<VerificationRequest>>>,
    sas_verification: Arc<RwLock<Option<SasVerification>>>,
}

impl SessionVerificationController {
    pub fn new() -> Self {
        let (tx, rx) = channel::<VerificationRequestEvent>(10); // dropping after more than 10 items queued
        SessionVerificationController {
            to_device_verification_request_handle: None,
            room_msg_verification_request_handle: None,
            request_event_tx: tx,
            request_event_rx: Arc::new(rx),
            verification_request: Arc::new(RwLock::new(None)),
            sas_verification: Arc::new(RwLock::new(None)),
        }
    }

    pub fn add_event_handlers(&mut self, client: &SdkClient) {
        client.add_event_handler_context(self.clone());

        // to_device event is intended to verify other device
        let handle = client.add_event_handler(
            |ev: ToDeviceKeyVerificationRequestEvent,
             c: SdkClient,
             Ctx(me): Ctx<SessionVerificationController>| async move {
                let req_evt = VerificationRequestEvent::new(
                    c.clone(),
                    ev.content.transaction_id.to_string(),
                    ev.sender.clone(),
                );
                if let Err(e) = me.request_event_tx.send(req_evt) {
                    error!("Dropping flow for {}: {}", ev.content.transaction_id, e);
                } else {
                    let Some(request) = c
                        .encryption()
                        .get_verification_request(&ev.sender, &ev.content.transaction_id)
                        .await
                    else {
                        error!("Request object wasn't created");
                        return;
                    };
                    // tokio::spawn(request_verification_handler(c, request));
                }
            },
        );
        self.to_device_verification_request_handle = Some(handle);

        // sync event is intended to verify other user
        let handle = client.add_event_handler(
            |ev: OriginalSyncRoomMessageEvent,
             c: SdkClient,
             Ctx(me): Ctx<SessionVerificationController>| async move {
                if let MessageType::VerificationRequest(content) = &ev.content.msgtype {
                    let req_evt = VerificationRequestEvent::new(
                        c.clone(),
                        ev.event_id.to_string(),
                        ev.sender.clone(),
                    );
                    if let Err(e) = me.request_event_tx.send(req_evt) {
                        error!("Dropping flow for {}: {}", ev.event_id, e);
                    } else {
                        let Some(request) = c
                            .encryption()
                            .get_verification_request(&ev.sender, &ev.event_id)
                            .await
                        else {
                            error!("Request object wasn't created");
                            return;
                        };
                        // tokio::spawn(request_verification_handler(c, request));
                    }
                }
            },
        );
        self.room_msg_verification_request_handle = Some(handle);
    }

    pub fn remove_event_handlers(&mut self, client: &SdkClient) {
        if let Some(handle) = self.to_device_verification_request_handle.clone() {
            client.remove_event_handler(handle);
            self.to_device_verification_request_handle = None;
        }
        if let Some(handle) = self.room_msg_verification_request_handle.clone() {
            client.remove_event_handler(handle);
            self.room_msg_verification_request_handle = None;
        }
    }
}

#[derive(Clone, Debug)]
pub struct VerificationRequestEvent {
    client: SdkClient,
    flow_id: String,
    sender: OwnedUserId,
}

impl VerificationRequestEvent {
    pub(crate) fn new(client: SdkClient, flow_id: String, sender: OwnedUserId) -> Self {
        VerificationRequestEvent {
            client,
            flow_id,
            sender,
        }
    }

    pub async fn accept(&self) -> Result<VerificationRequestResult> {
        let client = self.client.clone();
        let flow_id = self.flow_id.clone();
        let sender = self.sender.clone();
        RUNTIME
            .spawn(async move {
                let Some(request) = client
                    .encryption()
                    .get_verification_request(&sender, &flow_id)
                    .await
                else {
                    bail!("Unknown session verification request")
                };
                info!(
                    "Accepting verification request from {}",
                    request.other_user_id()
                );
                let methods = vec![VerificationMethod::SasV1];
                if let Err(e) = request.accept_with_methods(methods).await {
                    bail!("Can't accept verification request");
                }
                Ok(VerificationRequestResult::new(client, flow_id, sender))
            })
            .await?
    }

    pub async fn cancel(&self) -> Result<bool> {
        let client = self.client.clone();
        let flow_id = self.flow_id.clone();
        let sender = self.sender.clone();
        RUNTIME
            .spawn(async move {
                let Some(request) = client
                    .encryption()
                    .get_verification_request(&sender, &flow_id)
                    .await
                else {
                    bail!("Unknown session verification request")
                };
                info!(
                    "Cancelling verification request from {}",
                    request.other_user_id()
                );
                if let Err(e) = request.cancel().await {
                    bail!("Can't cancel verification request");
                }
                Ok(true)
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct VerificationRequestResult {
    client: SdkClient,
    flow_id: String,
    sender: OwnedUserId,
}

impl VerificationRequestResult {
    pub(crate) fn new(client: SdkClient, flow_id: String, sender: OwnedUserId) -> Self {
        VerificationRequestResult {
            client,
            flow_id,
            sender,
        }
    }

    pub async fn start_sas(&self, timeout_in_secs: u64) -> Result<StartSasResult> {
        let client = self.client.clone();
        let flow_id = self.flow_id.clone();
        let sender = self.sender.clone();
        RUNTIME
            .spawn(async move {
                let Some(request) = client
                    .encryption()
                    .get_verification_request(&sender, &flow_id)
                    .await
                else {
                    bail!("Unknown session verification request")
                };
                info!("Starting SAS verification from {}", request.other_user_id());

                // confirm that verification request state is ready
                let timeout_in_secs = timeout_in_secs.try_into()?;
                let retry_strategy = FibonacciBackoff::from_millis(1000)
                    .map(jitter)
                    .take(timeout_in_secs);
                let cloned_request = request.clone();
                Retry::spawn(retry_strategy, move || {
                    let request = cloned_request.clone();
                    async move {
                        if let VerificationRequestState::Ready { .. } = request.state() {
                            Ok(())
                        } else {
                            bail!("verification request state not ready")
                        }
                    }
                })
                .await?;

                let Some(verification) = request.start_sas().await? else {
                    bail!("failed to start sas verification")
                };
                Ok(StartSasResult::new(client, flow_id, sender))
            })
            .await?
    }

    pub async fn cancel(&self) -> Result<bool> {
        let client = self.client.clone();
        let flow_id = self.flow_id.clone();
        let sender = self.sender.clone();
        RUNTIME
            .spawn(async move {
                let Some(request) = client
                    .encryption()
                    .get_verification_request(&sender, &flow_id)
                    .await
                else {
                    bail!("Unknown session verification request")
                };
                info!(
                    "Cancelling verification request from {}",
                    request.other_user_id()
                );
                if let Err(e) = request.cancel().await {
                    bail!("Can't cancel verification request");
                }
                Ok(true)
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct StartSasResult {
    client: SdkClient,
    flow_id: String,
    sender: OwnedUserId,
}

impl StartSasResult {
    pub(crate) fn new(client: SdkClient, flow_id: String, sender: OwnedUserId) -> Self {
        StartSasResult {
            client,
            flow_id,
            sender,
        }
    }

    pub async fn accept(&self, timeout_in_secs: u64) -> Result<AcceptSasResult> {
        let client = self.client.clone();
        let flow_id = self.flow_id.clone();
        let sender = self.sender.clone();
        RUNTIME
            .spawn(async move {
                let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, &flow_id)
                    .await
                else {
                    bail!("Could not get SAS verification object")
                };
                info!(
                    "Accepting SAS verification with {} {}",
                    &sas.other_device().user_id(),
                    &sas.other_device().device_id()
                );

                // confirm that SAS verification was started
                let timeout_in_secs = timeout_in_secs.try_into()?;
                let retry_strategy = FibonacciBackoff::from_millis(1000)
                    .map(jitter)
                    .take(timeout_in_secs);
                let cloned_sas = sas.clone();
                Retry::spawn(retry_strategy, move || {
                    let sas = cloned_sas.clone();
                    async move {
                        if let SasState::Started { .. } = sas.state() {
                            Ok(())
                        } else {
                            bail!("SAS verification not started")
                        }
                    }
                })
                .await?;

                if let Err(e) = sas.accept().await {
                    bail!("Can't accept SAS verification");
                }
                Ok(AcceptSasResult::new(client, flow_id, sender))
            })
            .await?
    }

    pub async fn cancel(&self) -> Result<bool> {
        let client = self.client.clone();
        let flow_id = self.flow_id.clone();
        let sender = self.sender.clone();
        RUNTIME
            .spawn(async move {
                let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, &flow_id)
                    .await
                else {
                    bail!("Could not get SAS verification object")
                };
                info!(
                    "Cancelling SAS verification with {} {}",
                    &sas.other_device().user_id(),
                    &sas.other_device().device_id()
                );
                if let Err(e) = sas.cancel().await {
                    bail!("Can't cancel SAS verification");
                }
                Ok(true)
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct AcceptSasResult {
    client: SdkClient,
    flow_id: String,
    sender: OwnedUserId,
}

impl AcceptSasResult {
    pub(crate) fn new(client: SdkClient, flow_id: String, sender: OwnedUserId) -> Self {
        AcceptSasResult {
            client,
            flow_id,
            sender,
        }
    }

    pub async fn get_emojis(&self, timeout_in_secs: u64) -> Result<[Emoji; 7]> {
        let client = self.client.clone();
        let flow_id = self.flow_id.clone();
        let sender = self.sender.clone();
        RUNTIME
            .spawn(async move {
                let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, &flow_id)
                    .await
                else {
                    bail!("Could not get SAS verification object")
                };
                info!(
                    "Getting the emojis with {} {}",
                    &sas.other_device().user_id(),
                    &sas.other_device().device_id()
                );

                // confirm that keys were exchanged for SAS verification
                let timeout_in_secs = timeout_in_secs.try_into()?;
                let retry_strategy = FibonacciBackoff::from_millis(1000)
                    .map(jitter)
                    .take(timeout_in_secs);
                let cloned_sas = sas.clone();
                Retry::spawn(retry_strategy, move || {
                    let sas = cloned_sas.clone();
                    async move {
                        if let SasState::KeysExchanged { .. } = sas.state() {
                            Ok(())
                        } else {
                            bail!("keys not exchanged")
                        }
                    }
                })
                .await?;

                let Some(emojis) = sas.emoji() else {
                    bail!("Can't get the emojis")
                };
                Ok(emojis)
            })
            .await?
    }

    pub async fn approve(&self, timeout_in_secs: u64) -> Result<bool> {
        let client = self.client.clone();
        let flow_id = self.flow_id.clone();
        let sender = self.sender.clone();
        RUNTIME
            .spawn(async move {
                let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, &flow_id)
                    .await
                else {
                    bail!("Could not get SAS verification object")
                };
                info!(
                    "Confirming SAS verification with {} {}",
                    &sas.other_device().user_id(),
                    &sas.other_device().device_id()
                );

                // confirm that keys were exchanged for SAS verification
                let timeout_in_secs = timeout_in_secs.try_into()?;
                let retry_strategy = FibonacciBackoff::from_millis(1000)
                    .map(jitter)
                    .take(timeout_in_secs);
                let cloned_sas = sas.clone();
                Retry::spawn(retry_strategy, move || {
                    let sas = cloned_sas.clone();
                    async move {
                        if let SasState::KeysExchanged { .. } = sas.state() {
                            Ok(())
                        } else {
                            bail!("keys not exchanged")
                        }
                    }
                })
                .await?;

                if let Err(e) = sas.confirm().await {
                    bail!("Can't confirm SAS verification");
                }
                Ok(true)
            })
            .await?
    }

    pub async fn decline(&self, timeout_in_secs: u64) -> Result<bool> {
        let client = self.client.clone();
        let flow_id = self.flow_id.clone();
        let sender = self.sender.clone();
        RUNTIME
            .spawn(async move {
                let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, &flow_id)
                    .await
                else {
                    bail!("Could not get SAS verification object")
                };
                info!(
                    "Mismatching SAS verification with {} {}",
                    &sas.other_device().user_id(),
                    &sas.other_device().device_id()
                );

                // confirm that keys were exchanged for SAS verification
                let timeout_in_secs = timeout_in_secs.try_into()?;
                let retry_strategy = FibonacciBackoff::from_millis(1000)
                    .map(jitter)
                    .take(timeout_in_secs);
                let cloned_sas = sas.clone();
                Retry::spawn(retry_strategy, move || {
                    let sas = cloned_sas.clone();
                    async move {
                        if let SasState::KeysExchanged { .. } = sas.state() {
                            Ok(())
                        } else {
                            bail!("keys not exchanged")
                        }
                    }
                })
                .await?;

                if let Err(e) = sas.mismatch().await {
                    bail!("Can't mismatch SAS verification");
                }
                Ok(true)
            })
            .await?
    }

    pub async fn cancel(&self) -> Result<bool> {
        let client = self.client.clone();
        let flow_id = self.flow_id.clone();
        let sender = self.sender.clone();
        RUNTIME
            .spawn(async move {
                let Some(Verification::SasV1(sas)) = client
                    .encryption()
                    .get_verification(&sender, &flow_id)
                    .await
                else {
                    bail!("Could not get SAS verification object")
                };
                info!(
                    "Cancelling SAS verification with {} {}",
                    &sas.other_device().user_id(),
                    &sas.other_device().device_id()
                );
                if let Err(e) = sas.cancel().await {
                    bail!("Can't cancel SAS verification");
                }
                Ok(true)
            })
            .await?
    }
}

async fn request_verification_handler(client: SdkClient, request: VerificationRequest) {
    let mut stream = request.changes();

    while let Some(state) = stream.next().await {
        match state {
            VerificationRequestState::Created { .. }
            | VerificationRequestState::Requested { .. }
            | VerificationRequestState::Ready { .. } => (),
            VerificationRequestState::Transitioned { verification } => {
                // We only support SAS verification.
                if let Verification::SasV1(s) = verification {
                    // tokio::spawn(sas_verification_handler(client, s));
                    break;
                }
            }
            VerificationRequestState::Done | VerificationRequestState::Cancelled(_) => break,
        }
    }
}
