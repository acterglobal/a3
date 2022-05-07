use super::{api, Conversation, Group, Room, RUNTIME};
use anyhow::{bail, Context, Result};
use derive_builder::Builder;
use effektio_core::RestoreToken;
use futures::{stream, Stream, StreamExt};
use lazy_static::lazy_static;
pub use matrix_sdk::ruma::{self, DeviceId, MxcUri, RoomId, ServerName};
use matrix_sdk::{
    media::{MediaFormat, MediaRequest},
    room::Room as MatrixRoom,
    ruma::events::StateEventType,
    Account as MatrixAccount, Client as MatrixClient, LoopCtrl, Session,
};

use parking_lot::RwLock;
use ruma::events::room::MediaSource;
use std::io::Cursor;
use std::sync::Arc;
use url::Url;

#[derive(Clone)]
pub struct Account {
    account: MatrixAccount,
}

impl std::ops::Deref for Account {
    type Target = MatrixAccount;
    fn deref(&self) -> &MatrixAccount {
        &self.account
    }
}

impl Account {
    pub fn new(account: MatrixAccount) -> Self {
        Account { account }
    }

    pub async fn display_name(&self) -> Result<String> {
        let l = self.account.clone();
        RUNTIME
            .spawn(async move {
                let display_name = l.get_display_name().await?.context("No User ID found")?;
                Ok(display_name.as_str().to_string())
            })
            .await?
    }

    pub async fn set_display_name(&self, new_name: String) -> Result<bool> {
        let l = self.account.clone();
        RUNTIME
            .spawn(async move {
                let name = if new_name.len() == 0 {
                    None
                } else {
                    Some(new_name.as_str())
                };
                let display_name = l.set_display_name(name).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn avatar(&self) -> Result<api::FfiBuffer<u8>> {
        let l = self.account.clone();
        RUNTIME
            .spawn(async move {
                let data = l
                    .get_avatar(MediaFormat::File)
                    .await?
                    .context("No avatar Url given")?;
                Ok(api::FfiBuffer::new(data))
            })
            .await?
    }

    pub async fn set_avatar(&self, c_type: String, data: Vec<u8>) -> Result<bool> {
        let l = self.account.clone();
        let mut c = Cursor::new(data);
        RUNTIME
            .spawn(async move {
                let new_url = l.upload_avatar(&c_type.parse()?, &mut c).await?;
                Ok(true)
            })
            .await?
    }
}
