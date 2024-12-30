use anyhow::Result;
use futures::{Stream, StreamExt};
use matrix_sdk::encryption::{recovery::RecoveryState, Encryption};

use crate::{Client, RUNTIME};

fn state_to_string(state: &RecoveryState) -> String {
    match state {
        RecoveryState::Unknown => "unknown".to_owned(),
        RecoveryState::Enabled => "enabled".to_owned(),
        RecoveryState::Disabled => "disabled".to_owned(),
        RecoveryState::Incomplete => "incomplete".to_owned(),
    }
}

#[derive(Debug, Clone)]
pub struct BackupManager {
    inner: Encryption,
}

impl BackupManager {
    pub async fn enable(&self) -> Result<String> {
        let inner = self.inner.clone();
        RUNTIME
            .spawn(async move {
                let recovery = inner.recovery();
                Ok(recovery.enable().await?)
            })
            .await?
    }

    pub async fn reset(&self) -> Result<String> {
        let inner = self.inner.clone();
        RUNTIME
            .spawn(async move {
                let recovery = inner.recovery();
                Ok(recovery.reset_key().await?)
            })
            .await?
    }

    pub async fn disable(&self) -> Result<bool> {
        let encryption = self.inner.clone();
        RUNTIME
            .spawn(async move {
                encryption.recovery().disable().await?;
                Ok(true)
            })
            .await?
    }

    pub fn state_str(&self) -> String {
        state_to_string(&self.inner.recovery().state())
    }

    pub fn state_stream(&self) -> impl Stream<Item = String> {
        let mut stream = self.inner.recovery().state_stream();
        async_stream::stream! {
            while let Some(d) = stream.next().await {
                yield state_to_string(&d)
            }
        }
    }

    pub async fn recover(&self, secret: String) -> Result<bool> {
        let inner = self.inner.clone();
        RUNTIME
            .spawn(async move {
                let recovery = inner.recovery();
                recovery.recover(&secret).await?;
                Ok(true)
            })
            .await?
    }
}

impl Client {
    pub fn backup_manager(&self) -> BackupManager {
        BackupManager {
            inner: self.core.client().encryption().clone(),
        }
    }
}
