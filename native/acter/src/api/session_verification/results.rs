use anyhow::{bail, Result};
use matrix_sdk::{
    encryption::verification::{Emoji, SasState, Verification, VerificationRequestState},
    ruma::OwnedUserId,
    Client as SdkClient,
};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};
use tracing::{error, info};

use super::super::RUNTIME;

#[derive(Clone, Debug)]
pub struct AcceptRequestResult {
    client: SdkClient,
    flow_id: String,
    sender: OwnedUserId,
}

impl AcceptRequestResult {
    pub(crate) fn new(client: SdkClient, flow_id: String, sender: OwnedUserId) -> Self {
        AcceptRequestResult {
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
