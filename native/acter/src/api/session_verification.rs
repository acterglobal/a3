use anyhow::{bail, Result};
use futures::stream::StreamExt;
use matrix_sdk::encryption::{
    identities::UserIdentity,
    verification::{SasState, SasVerification, VerificationRequest, VerificationRequestState},
    Encryption,
};
use matrix_sdk_base::ruma::{
    events::{key::verification::VerificationMethod, AnyToDeviceEvent},
    UserId,
};
use std::sync::Arc;
use tokio::sync::{
    broadcast::{channel, Receiver, Sender},
    RwLock,
};
use tokio_stream::wrappers::BroadcastStream;
use tracing::{error, info};

use super::RUNTIME;

#[derive(Clone, Debug)]
pub struct SessionVerificationEmoji {
    symbol: String,
    description: String,
}

impl SessionVerificationEmoji {
    pub fn symbol(&self) -> String {
        self.symbol.clone()
    }

    pub fn description(&self) -> String {
        self.description.clone()
    }
}

#[derive(Clone, Debug)]
pub struct SessionVerificationData {
    emojis: Option<Vec<SessionVerificationEmoji>>,
    decimals: Option<Vec<u16>>,
}

impl SessionVerificationData {
    pub fn emojis(&self) -> Option<Vec<SessionVerificationEmoji>> {
        self.emojis.clone()
    }

    pub fn decimals(&self) -> Option<Vec<u16>> {
        self.decimals.clone()
    }
}

#[derive(Clone, Debug)]
pub struct VerificationRequestEvent {
    sender_id: String,
    flow_id: String,
    device_id: String,
    display_name: Option<String>,
    /// First time this device was seen in milliseconds since epoch.
    first_seen_timestamp: u64,
    controller: SessionVerificationController,
}

impl VerificationRequestEvent {
    pub async fn accept(&self) -> Result<VerificationReadyStage> {
        let sender_id = self.sender_id.clone();
        let flow_id = self.flow_id.clone();
        let controller = self.controller.clone();
        let verification_request = self.controller.verification_request.clone();
        RUNTIME
            .spawn(async move {
                let verification_request = verification_request.write().await;
                if let Some(verification_request) = verification_request.clone() {
                    let methods = vec![VerificationMethod::SasV1];
                    verification_request.accept_with_methods(methods).await?;
                }
                Ok(VerificationReadyStage {
                    sender_id,
                    flow_id,
                    controller,
                })
            })
            .await?
    }

    pub async fn cancel(&self) -> Result<bool> {
        let verification_request = self.controller.verification_request.clone();
        RUNTIME
            .spawn(async move {
                let verification_request = verification_request.write().await;
                if let Some(verification_request) = verification_request.clone() {
                    verification_request.cancel().await?;
                    return Ok(true);
                }
                Ok(false)
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct VerificationReadyStage {
    sender_id: String,
    flow_id: String,
    controller: SessionVerificationController,
}

impl VerificationReadyStage {
    pub async fn start_sas(&self) -> Result<SasPromptStage> {
        let sender_id = self.sender_id.clone();
        let flow_id = self.flow_id.clone();
        let controller = self.controller.clone();
        let verification_request = self.controller.verification_request.clone();
        let sas_verification = self.controller.sas_verification.clone();
        RUNTIME
            .spawn(async move {
                let verification_request = verification_request.write().await;
                if let Some(verification_request) = verification_request.clone() {
                    if let Some(verification) = verification_request.start_sas().await? {
                        let mut sas_verification = sas_verification.write().await;
                        *sas_verification = Some(verification.clone());
                    }
                }
                Ok(SasPromptStage {
                    sender_id,
                    flow_id,
                    controller,
                })
            })
            .await?
    }

    pub async fn cancel(&self) -> Result<bool> {
        let verification_request = self.controller.verification_request.clone();
        RUNTIME
            .spawn(async move {
                let verification_request = verification_request.write().await;
                if let Some(verification_request) = verification_request.clone() {
                    verification_request.cancel().await?;
                    return Ok(true);
                }
                Ok(false)
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct SasPromptStage {
    sender_id: String,
    flow_id: String,
    controller: SessionVerificationController,
}

impl SasPromptStage {
    pub async fn get_emojis(&self) -> Result<SessionVerificationData> {
        let sas_verification = self.controller.sas_verification.clone();
        RUNTIME
            .spawn(async move {
                let sas_verification = sas_verification.write().await;
                let Some(sas_verification) = sas_verification.clone() else {
                    bail!("sas verification was not started")
                };
                let emojis = sas_verification.emoji().map(|f| {
                    f.into_iter()
                        .map(|emoji| SessionVerificationEmoji {
                            symbol: emoji.symbol.to_owned(),
                            description: emoji.description.to_owned(),
                        })
                        .collect()
                });
                let decimals = sas_verification.decimals().map(|f| vec![f.0, f.1, f.2]);
                Ok(SessionVerificationData { emojis, decimals })
            })
            .await?
    }

    pub async fn approve(&self) -> Result<bool> {
        let sas_verification = self.controller.sas_verification.clone();
        RUNTIME
            .spawn(async move {
                let sas_verification = sas_verification.write().await;
                if let Some(sas_verification) = sas_verification.clone() {
                    sas_verification.confirm().await?;
                    return Ok(true);
                }
                Ok(false)
            })
            .await?
    }

    pub async fn decline(&self) -> Result<bool> {
        let sas_verification = self.controller.sas_verification.clone();
        RUNTIME
            .spawn(async move {
                let sas_verification = sas_verification.write().await;
                if let Some(sas_verification) = sas_verification.clone() {
                    sas_verification.mismatch().await?;
                    return Ok(true);
                }
                Ok(false)
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct SessionVerificationController {
    encryption: Encryption,
    user_identity: UserIdentity,
    event_tx: Sender<VerificationRequestEvent>,
    event_rx: Arc<Receiver<VerificationRequestEvent>>,
    verification_request: Arc<RwLock<Option<VerificationRequest>>>,
    sas_verification: Arc<RwLock<Option<SasVerification>>>,
}

impl SessionVerificationController {
    pub(crate) fn new(encryption: Encryption, user_identity: UserIdentity) -> Self {
        let (tx, rx) = channel::<VerificationRequestEvent>(10); // dropping after more than 10 items queued
        SessionVerificationController {
            encryption,
            user_identity,
            event_tx: tx,
            event_rx: Arc::new(rx),
            verification_request: Arc::new(RwLock::new(None)),
            sas_verification: Arc::new(RwLock::new(None)),
        }
    }

    pub(crate) async fn process_to_device_message(&self, event: AnyToDeviceEvent) {
        if let AnyToDeviceEvent::KeyVerificationRequest(event) = event {
            info!("Received verification request: {:}", event.sender);

            let Some(request) = self
                .encryption
                .get_verification_request(&event.sender, &event.content.transaction_id)
                .await
            else {
                error!("Failed retrieving verification request");
                return;
            };

            if !request.is_self_verification() {
                info!("Received non-self verification request. Ignoring.");
                return;
            }

            let VerificationRequestState::Requested {
                other_device_data, ..
            } = request.state()
            else {
                error!("Received key verification event but the request is in the wrong state.");
                return;
            };

            let msg = VerificationRequestEvent {
                sender_id: request.other_user_id().into(),
                flow_id: request.flow_id().into(),
                device_id: other_device_data.device_id().into(),
                display_name: other_device_data.display_name().map(str::to_string),
                first_seen_timestamp: other_device_data.first_time_seen_ts().get().into(),
                controller: self.clone(),
            };
            if let Err(e) = self.event_tx.send(msg) {
                error!("Dropping flow for {}: {}", event.content.transaction_id, e);
            }
        }
    }

    async fn listen_to_verification_request_changes(
        verification_request: VerificationRequest,
        sas_verification: Arc<RwLock<Option<SasVerification>>>,
        // delegate: Delegate,
    ) {
        let mut stream = verification_request.changes();

        while let Some(state) = stream.next().await {
            match state {
                VerificationRequestState::Transitioned { verification } => {
                    let Some(verification) = verification.sas() else {
                        error!("Invalid, non-sas verification flow. Returning.");
                        return;
                    };

                    let mut sas_verification = sas_verification.write().await;
                    *sas_verification = Some(verification.clone());

                    if verification.accept().await.is_ok() {
                        // if let Some(delegate) = &*delegate.read().unwrap() {
                        //     delegate.did_start_sas_verification()
                        // }

                        // let delegate = delegate.clone();
                        // tokio::spawn(Self::listen_to_sas_verification_changes(
                        //     verification,
                        //     delegate,
                        // ));
                    } else {
                        // if let Some(delegate) = &*delegate.read().unwrap() {
                        //     delegate.did_fail()
                        // }
                    }
                }
                VerificationRequestState::Ready { .. } => {
                    // if let Some(delegate) = &*delegate.read().unwrap() {
                    //     delegate.did_accept_verification_request()
                    // }
                }
                VerificationRequestState::Cancelled(..) => {
                    // if let Some(delegate) = &*delegate.read().unwrap() {
                    //     delegate.did_cancel();
                    // }
                }
                _ => {}
            }
        }
    }
}
