use std::time::{SystemTime, UNIX_EPOCH};

use acter_core::{events::UtcDateTime, store::Store, Error as SdkError};
use anyhow::{bail, Result};
use futures::{Stream, StreamExt};
use matrix_sdk::encryption::{recovery::RecoveryState, CrossSigningResetAuthType, Encryption};
use ruma::api::client::uiaa;
use serde::{Deserialize, Serialize};

use crate::{Client, RUNTIME};

use super::OptionString;

fn state_to_string(state: &RecoveryState) -> String {
    match state {
        RecoveryState::Unknown => "unknown".to_owned(),
        RecoveryState::Enabled => "enabled".to_owned(),
        RecoveryState::Disabled => "disabled".to_owned(),
        RecoveryState::Incomplete => "incomplete".to_owned(),
    }
}

#[derive(Clone, Serialize, Deserialize)]
struct StoredBackupKey {
    timestamp: u64,
    key: String,
}

#[derive(Debug, Clone)]
pub struct BackupManager {
    inner: Encryption,
    store: Store,
}

const BACKUP_STORE_KEY: &str = "backup_encryption_key";

async fn store_backup_key(store: Store, key: String) -> Result<bool> {
    let o = StoredBackupKey {
        timestamp: SystemTime::now().duration_since(UNIX_EPOCH)?.as_secs(),
        key,
    };
    Ok(store.set_raw(BACKUP_STORE_KEY, &o).await.is_ok())
}

async fn read_backup_key(store: Store) -> Result<StoredBackupKey, SdkError> {
    store.get_raw(BACKUP_STORE_KEY).await
}

async fn enable_inner(inner: Encryption, store: Store) -> Result<String> {
    inner.wait_for_e2ee_initialization_tasks().await;
    let recovery = inner.recovery();
    let key = recovery.enable().wait_for_backups_to_upload().await?;
    store_backup_key(store, key.clone()).await?;
    Ok(key)
}

/// Public Api
impl BackupManager {
    pub async fn enable(&self) -> Result<String> {
        let inner = self.inner.clone();
        let store = self.store.clone();
        RUNTIME
            .spawn(async move {
                Ok(enable_inner(inner, store).await?)
            })
            .await?
    }


    pub async fn reset_key(&self) -> Result<String> {
        let inner = self.inner.clone();
        let store = self.store.clone();
        RUNTIME
            .spawn(async move {
                let recovery = inner.recovery();
                let key = recovery.reset_key().await?;

                store_backup_key(store, key.clone()).await?;
                Ok(key)
            })
            .await?
    }


    pub async fn reset_identity(&self, password: String) -> Result<String> {
        let inner = self.inner.clone();
        let store = self.store.clone();
        RUNTIME
            .spawn(async move {
                let recovery = inner.recovery();
                if let Some(handle) = recovery.reset_identity().await? {
                    match handle.auth_type() {
                        CrossSigningResetAuthType::Uiaa(u) => {
                            let user_id = store.user_id().to_string();
                            let mut password = uiaa::Password::new(uiaa::UserIdentifier::UserIdOrLocalpart(user_id), password);
                            password.session = u.session.clone();
                
                            handle.reset(Some(uiaa::AuthData::Password(password))).await?;
                        }
                        CrossSigningResetAuthType::OAuth(o) => {
                            return Err(anyhow::anyhow!("OAuth reset not yet supported"));
                        }
                    }

                }
                Ok(enable_inner(inner, store).await?)
            })
            .await?
    }

    pub async fn disable(&self) -> Result<bool> {
        let encryption = self.inner.clone();
        let store = self.store.clone();
        RUNTIME
            .spawn(async move {
                encryption.recovery().disable().await?;
                store.delete_key(BACKUP_STORE_KEY).await?;
                Ok(true)
            })
            .await?
    }

    async fn stored_key(&self) -> Result<Option<StoredBackupKey>> {
        match self.inner.recovery().state() {
            RecoveryState::Disabled => Ok(None),
            RecoveryState::Unknown | RecoveryState::Enabled | RecoveryState::Incomplete => {
                let store = self.store.clone();
                RUNTIME
                    .spawn(async move {
                        match read_backup_key(store).await {
                            Err(SdkError::ModelNotFound(_)) => Ok(None),
                            Ok(s) => Ok(Some(s)),
                            Err(e) => bail!(e),
                        }
                    })
                    .await?
            }
        }
    }

    pub async fn stored_enc_key(&self) -> Result<OptionString> {
        Ok(self.stored_key().await?.map(|k| k.key).into())
    }

    /// timestamp when this key was stored
    pub async fn stored_enc_key_when(&self) -> Result<u64> {
        Ok(self
            .stored_key()
            .await?
            .map(|k| k.timestamp)
            .unwrap_or_default())
    }

    pub async fn destroy_stored_enc_key(&self) -> Result<bool> {
        let store = self.store.clone();
        RUNTIME
            .spawn(async move {
                store.delete_key(BACKUP_STORE_KEY).await?;
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
            store: self.store().clone(),
        }
    }
}
