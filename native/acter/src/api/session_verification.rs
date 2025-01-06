use anyhow::{bail, Result};
use futures::stream::{Stream, StreamExt};
use matrix_sdk::{
    encryption::{
        identities::UserIdentity,
        verification::{SasState, SasVerification, VerificationRequest, VerificationRequestState},
        Encryption,
    },
    event_handler::{Ctx, EventHandlerHandle},
    Client as SdkClient,
};
use matrix_sdk_base::ruma::{
    events::{key::verification::VerificationMethod, AnyToDeviceEvent},
    UserId,
};
use std::{marker::Unpin, sync::Arc};
use tokio::sync::{
    broadcast::{channel, Receiver, Sender},
    RwLock,
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
    controller: SessionVerificationController,
}

impl VerificationRequestEvent {
    pub async fn acknowledge(&self) -> Result<bool> {
        let sender_id = UserId::parse(&self.sender_id)?;
        let flow_id = self.flow_id.clone();
        let controller = self.controller.clone();
        RUNTIME
            .spawn(async move {
                if let Some(verification_request) = controller
                    .encryption
                    .get_verification_request(&sender_id, flow_id)
                    .await
                {
                    *controller.verification_request.write().await =
                        Some(verification_request.clone());
                    tokio::spawn(
                        SessionVerificationController::listen_to_verification_request_changes(
                            verification_request,
                            controller.sas_verification.clone(),
                        ),
                    );
                    Ok(true)
                } else {
                    Ok(false)
                }
            })
            .await?
    }

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
    any_to_device_handle: Option<EventHandlerHandle>,
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
                        controller: me.clone(),
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

impl Client {
    // this return value should be Unpin, because next() of this stream is called in wait_for_verification_request_event
    // this return value should be wrapped in Box::pin, to make unpin possible
    pub fn verification_request_event_rx(
        &self,
    ) -> impl Stream<Item = VerificationRequestEvent> + Unpin {
        let mut stream =
            BroadcastStream::new(self.session_verification_controller.event_rx.resubscribe());
        Box::pin(stream.filter_map(|o| async move { o.ok() }))
    }
}
