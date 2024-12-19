use anyhow::{bail, Result};
use matrix_sdk::{
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
use std::sync::Arc;
use tokio::sync::broadcast::{channel, Receiver, Sender};
use tracing::{error, info};

use super::{super::RUNTIME, AcceptRequestResult};

#[derive(Clone, Debug)]
pub(crate) struct SessionVerificationController {
    to_device_verification_request_handle: Option<EventHandlerHandle>,
    room_msg_verification_request_handle: Option<EventHandlerHandle>,
    request_event_tx: Sender<VerificationRequestEvent>,
    request_event_rx: Arc<Receiver<VerificationRequestEvent>>,
}

impl SessionVerificationController {
    pub fn new() -> Self {
        let (tx, rx) = channel::<VerificationRequestEvent>(10); // dropping after more than 10 items queued
        SessionVerificationController {
            to_device_verification_request_handle: None,
            room_msg_verification_request_handle: None,
            request_event_tx: tx,
            request_event_rx: Arc::new(rx),
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

    pub async fn accept(&self) -> Result<AcceptRequestResult> {
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
                Ok(AcceptRequestResult::new(client, flow_id, sender))
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
