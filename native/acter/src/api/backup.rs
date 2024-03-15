use futures::{Stream, StreamExt, TryStreamExt};
use matrix_sdk::encryption::{
    backups::{BackupState, Backups},
    Encryption,
};
use tokio_stream::wrappers::errors::BroadcastStreamRecvError;
use tokio_stream::wrappers::BroadcastStream;

use crate::{Client, RUNTIME};
use anyhow::Result;
use tracing::warn;

fn state_to_string(state: &BackupState) -> String {
    match state {
        BackupState::Unknown => "unknown".to_owned(),
        BackupState::Enabling => "enabling".to_owned(),
        BackupState::Resuming => "resuming".to_owned(),
        BackupState::Enabled => "enabled".to_owned(),
        BackupState::Downloading => "downloading".to_owned(),
        BackupState::Disabling => "disabling".to_owned(),
        BackupState::Creating => "creating".to_owned(),
    }
}

#[derive(Debug, Clone)]
pub struct BackupManager {
    inner: Backups,
    encryption: Encryption,
}

impl BackupManager {
    pub async fn create(&self) -> Result<bool> {
        let backups = self.inner.clone();
        RUNTIME
            .spawn(async move {
                backups.create().await?;
                Ok(true)
            })
            .await?
    }
    pub async fn disable(&self) -> Result<bool> {
        let backups = self.inner.clone();
        RUNTIME
            .spawn(async move {
                backups.disable().await?;
                Ok(true)
            })
            .await?
    }
    pub fn state_str(&self) -> String {
        state_to_string(&self.inner.state())
    }
    pub async fn are_enabled(&self) -> Result<bool> {
        let backups = self.inner.clone();
        Ok(RUNTIME
            .spawn(async move { backups.are_enabled().await })
            .await?)
    }
    pub async fn exists_on_server(&self) -> Result<bool> {
        let backups = self.inner.clone();
        Ok(RUNTIME
            .spawn(async move { backups.exists_on_server().await })
            .await??)
    }

    pub fn state_stream(&self) -> impl Stream<Item = String> {
        let stream = self.inner.state_stream();
        async_stream::stream! {
            let mut remap = stream.into_stream();

            while let Some(d) = remap.next().await {
                match d {
                    Ok(inner) => { yield state_to_string(&inner); },
                    Err(e) =>  {
                        warn!("Error in state stream processing: {e:?}");
                        break;
                    }
                }
            }
        }
    }

    pub async fn open_secret_store_and_import(&self, secret: String) -> Result<bool> {
        let encryption = self.encryption.clone();
        RUNTIME
            .spawn(async move {
                let create_secret_store = encryption
                    .secret_storage()
                    .open_secret_store(&secret)
                    .await?;
                create_secret_store.import_secrets().await?;
                Ok(true)
            })
            .await?
    }

    pub async fn create_new_secret_store(&self) -> Result<String> {
        let encryption = self.encryption.clone();
        RUNTIME
            .spawn(async move {
                let create_secret_store = encryption.secret_storage().create_secret_store().await?;
                Ok(create_secret_store.secret_storage_key())
            })
            .await?
    }
}

impl Client {
    pub fn backup_manager(&self) -> BackupManager {
        BackupManager {
            inner: self.core.client().encryption().backups(),
            encryption: self.core.client().encryption().clone(),
        }
    }
}
