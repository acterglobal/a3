use anyhow::{bail, Context, Result};
use futures::stream::{Stream, StreamExt};
use matrix_sdk::{
    encryption::{
        verification::{SasState, SasVerification, VerificationRequest, VerificationRequestState},
        Encryption,
    },
    event_handler::{Ctx, EventHandlerHandle},
    Client as SdkClient,
};
use matrix_sdk_base::ruma::{
    device_id,
    events::{key::verification::VerificationMethod, AnyToDeviceEvent},
    OwnedUserId, UserId,
};
use std::{marker::Unpin, sync::Arc};
use tokio::sync::{
    broadcast::{channel, Receiver, Sender},
    RwLock,
};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};
use tokio_stream::wrappers::BroadcastStream;
use tracing::{error, info};

use super::{Client, RUNTIME};

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
    controller: Arc<SessionVerificationController>,
}

impl VerificationRequestEvent {
    pub async fn acknowledge(&self) -> Result<bool> {
        let sender_id = UserId::parse(&self.sender_id)?;
        let flow_id = self.flow_id.clone();
        let controller = self.controller.clone();
        RUNTIME
            .spawn(async move {
                let request = controller
                    .encryption
                    .get_verification_request(&sender_id, flow_id)
                    .await
                    .context("Failed to get verification request")?;
                *controller.verification_request.write().await = Some(request);
                let verification_request = controller
                    .verification_request
                    .read()
                    .await
                    .clone()
                    .unwrap(); // it was already initialized in above statement
                tokio::spawn(
                    SessionVerificationController::listen_to_verification_request_changes(
                        verification_request,
                        controller.sas_verification.clone(),
                    ),
                );
                Ok(true)
            })
            .await?
    }

    pub async fn accept(&self) -> Result<VerificationReadyStage> {
        let sender_id = self.sender_id.clone();
        let flow_id = self.flow_id.clone();
        let controller = self.controller.clone();
        RUNTIME
            .spawn(async move {
                let verification_request = controller.verification_request.read().await;
                let Some(verification_request) = verification_request.clone() else {
                    bail!("verification request was not initialized")
                };
                let methods = vec![VerificationMethod::SasV1];
                verification_request.accept_with_methods(methods).await?;
                Ok(VerificationReadyStage {
                    sender_id,
                    flow_id,
                    controller: controller.clone(),
                })
            })
            .await?
    }

    pub async fn cancel(&self) -> Result<bool> {
        let controller = self.controller.clone();
        RUNTIME
            .spawn(async move {
                let verification_request = controller.verification_request.read().await;
                let Some(verification_request) = verification_request.clone() else {
                    bail!("verification request was not initialized")
                };
                verification_request.cancel().await?;
                Ok(true)
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct VerificationReadyStage {
    sender_id: String,
    flow_id: String,
    controller: Arc<SessionVerificationController>,
}

impl VerificationReadyStage {
    pub async fn start_sas(&self) -> Result<SasPromptStage> {
        // wait for the state of verification request to reach Ready or Transitioned, so that start_sas can be succeeded
        let svc = self.controller.clone();
        let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
        let is_ready = Retry::spawn(retry_strategy, move || {
            let controller = svc.clone();
            async move {
                let verification_request = controller.verification_request.read().await;
                let Some(verification_request) = verification_request.clone() else {
                    bail!("verification request was not initialized")
                };
                match verification_request.state() {
                    VerificationRequestState::Ready { .. }
                    | VerificationRequestState::Transitioned { .. } => Ok(true),
                    _ => bail!(
                        "the state of verification request didn't reach Ready or Transitioned yet"
                    ),
                }
            }
        })
        .await?;
        if !is_ready {
            bail!("the state of verification request didn't reach Ready or Transitioned yet");
        }

        let sender_id = self.sender_id.clone();
        let flow_id = self.flow_id.clone();
        let controller = self.controller.clone();
        RUNTIME
            .spawn(async move {
                let verification_request = controller.verification_request.read().await;
                let Some(verification_request) = verification_request.clone() else {
                    bail!("verification request was not initialized")
                };
                let Some(verification) = verification_request.start_sas().await? else {
                    bail!("Failed to start sas")
                };
                let mut sas_verification = controller.sas_verification.write().await;
                *sas_verification = Some(verification.clone());
                Ok(SasPromptStage {
                    sender_id,
                    flow_id,
                    controller: controller.clone(),
                })
            })
            .await?
    }

    pub async fn cancel(&self) -> Result<bool> {
        let controller = self.controller.clone();
        RUNTIME
            .spawn(async move {
                let verification_request = controller.verification_request.read().await;
                let Some(verification_request) = verification_request.clone() else {
                    bail!("verification request was not initialized")
                };
                verification_request.cancel().await?;
                Ok(true)
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct SasPromptStage {
    sender_id: String,
    flow_id: String,
    controller: Arc<SessionVerificationController>,
}

impl SasPromptStage {
    pub async fn get_emojis(&self) -> Result<SessionVerificationData> {
        // wait for the state of sas verification to reach KeysExchanged, so that get_emoji can be succeeded
        let svc = self.controller.clone();
        let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
        let is_ready = Retry::spawn(retry_strategy, move || {
            let controller = svc.clone();
            async move {
                let sas_verification = controller.sas_verification.read().await;
                let Some(sas_verification) = sas_verification.clone() else {
                    bail!("sas verification was not initialized")
                };
                match sas_verification.state() {
                    SasState::KeysExchanged { .. } => Ok(true),
                    _ => bail!("the state of sas verification didn't reach KeysExchanged yet"),
                }
            }
        })
        .await?;
        if !is_ready {
            bail!("the state of sas verification didn't reach KeysExchanged yet");
        }

        let controller = self.controller.clone();
        RUNTIME
            .spawn(async move {
                let sas_verification = controller.sas_verification.read().await;
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
        let controller = self.controller.clone();
        RUNTIME
            .spawn(async move {
                let sas_verification = controller.sas_verification.read().await;
                let Some(sas_verification) = sas_verification.clone() else {
                    bail!("sas verification was not started")
                };
                sas_verification.confirm().await?;
                Ok(true)
            })
            .await?
    }

    pub async fn decline(&self) -> Result<bool> {
        let controller = self.controller.clone();
        RUNTIME
            .spawn(async move {
                let sas_verification = controller.sas_verification.read().await;
                let Some(sas_verification) = sas_verification.clone() else {
                    bail!("sas verification was not started")
                };
                sas_verification.mismatch().await?;
                Ok(true)
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct SessionVerificationController {
    encryption: Encryption,
    user_id: OwnedUserId,
    event_tx: Sender<VerificationRequestEvent>,
    event_rx: Arc<Receiver<VerificationRequestEvent>>,
    verification_request: Arc<RwLock<Option<VerificationRequest>>>,
    sas_verification: Arc<RwLock<Option<SasVerification>>>,
    any_to_device_handle: Option<EventHandlerHandle>,
}

impl SessionVerificationController {
    pub(crate) fn new(encryption: Encryption, user_id: OwnedUserId) -> Self {
        let (tx, rx) = channel::<VerificationRequestEvent>(10); // dropping after more than 10 items queued
        SessionVerificationController {
            encryption,
            user_id,
            event_tx: tx,
            event_rx: Arc::new(rx),
            verification_request: Arc::new(RwLock::new(None)),
            sas_verification: Arc::new(RwLock::new(None)),
            any_to_device_handle: None,
        }
    }

    // to_device event is intended to verify other device
    pub(crate) fn add_to_device_event_handler(&mut self, client: &SdkClient) {
        client.add_event_handler_context(self.clone());
        let handle = client.add_event_handler(
            move |ev: AnyToDeviceEvent, Ctx(me): Ctx<SessionVerificationController>| async move {
                if let AnyToDeviceEvent::KeyVerificationRequest(ev) = ev {
                    info!("Received verification request: {:}", ev.sender);

                    let Some(request) = me
                        .encryption
                        .get_verification_request(&ev.sender, &ev.content.transaction_id)
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
                        controller: Arc::new(me.clone()),
                    };
                    if let Err(e) = me.event_tx.send(msg) {
                        error!("Dropping flow for {}: {}", ev.content.transaction_id, e);
                    }
                }
            },
        );
        self.any_to_device_handle = Some(handle);
    }

    pub(crate) fn remove_to_device_event_handler(&mut self, client: &SdkClient) {
        if let Some(handle) = self.any_to_device_handle.clone() {
            client.remove_event_handler(handle);
            self.any_to_device_handle = None;
        }
    }

    pub(crate) async fn request_verification(
        &self,
        dev_id: String,
    ) -> Result<VerificationRequestEvent> {
        let device = self
            .encryption
            .get_device(&self.user_id, device_id!(dev_id.as_str()))
            .await?
            .context("Could not get device from encryption")?;
        let is_verified =
            device.is_cross_signed_by_owner() || device.is_verified_with_cross_signing();
        if is_verified {
            bail!("Device {} was already verified", dev_id);
        }
        let methods = vec![VerificationMethod::SasV1];
        let request = device.request_verification_with_methods(methods).await?;
        let flow_id = request.flow_id().to_owned();
        info!("requested verification - flow_id: {}", flow_id);
        let msg = VerificationRequestEvent {
            sender_id: self.user_id.to_string(),
            flow_id,
            device_id: dev_id,
            display_name: device.display_name().map(str::to_string),
            first_seen_timestamp: device.first_time_seen_ts().get().into(),
            controller: Arc::new(self.clone()),
        };
        Ok(msg)
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

                    info!("=============================================================");
                    let mut sas_verification = sas_verification.write().await;
                    *sas_verification = Some(verification.clone());
                    info!("=============================================================");

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

impl Client {
    // this return value should be Unpin, because next() of this stream is called in wait_for_verification_request_event
    // this return value should be wrapped in Box::pin, to make unpin possible
    pub async fn verification_request_event_rx(
        &self,
    ) -> Result<impl Stream<Item = VerificationRequestEvent> + Unpin> {
        let session_verification_controller = self.session_verification_controller.clone();
        RUNTIME
            .spawn(async move {
                let svc = session_verification_controller.read().await.clone();
                let mut stream = BroadcastStream::new(svc.event_rx.resubscribe());
                let result = stream.filter_map(|o| async move { o.ok() });
                Ok(Box::pin(result))
            })
            .await?
    }

    pub async fn request_session_verification(
        &self,
        dev_id: String,
    ) -> Result<VerificationRequestEvent> {
        let session_verification_controller = self.session_verification_controller.clone();
        RUNTIME
            .spawn(async move {
                let svc = session_verification_controller.read().await.clone();
                svc.request_verification(dev_id).await
            })
            .await?
    }
}
