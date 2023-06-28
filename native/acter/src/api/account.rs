use anyhow::{bail, Context, Result};
use matrix_sdk::{
    media::MediaFormat,
    ruma::{OwnedMxcUri, OwnedUserId},
    Account as SdkAccount,
};
use std::{ops::Deref, path::PathBuf};

use super::{
    api::FfiBuffer,
    common::{OptionBuffer, OptionText},
    RUNTIME,
};

#[derive(Clone, Debug)]
pub struct Account {
    account: SdkAccount,
    user_id: OwnedUserId,
}

impl Deref for Account {
    type Target = SdkAccount;
    fn deref(&self) -> &SdkAccount {
        &self.account
    }
}

impl Account {
    pub fn new(account: SdkAccount, user_id: OwnedUserId) -> Self {
        Account { account, user_id }
    }

    pub fn user_id(&self) -> OwnedUserId {
        self.user_id.clone()
    }

    pub async fn display_name(&self) -> Result<OptionText> {
        let account = self.account.clone();
        RUNTIME
            .spawn(async move {
                let name = account.get_display_name().await?;
                Ok(OptionText::new(name))
            })
            .await?
    }

    pub async fn set_display_name(&self, new_name: String) -> Result<bool> {
        let account = self.account.clone();
        RUNTIME
            .spawn(async move {
                let name = if new_name.is_empty() {
                    None
                } else {
                    Some(new_name.as_str())
                };
                account.set_display_name(name).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn avatar(&self) -> Result<OptionBuffer> {
        let account = self.account.clone();
        RUNTIME
            .spawn(async move {
                let buf = account.get_avatar(MediaFormat::File).await?;
                Ok(OptionBuffer::new(buf))
            })
            .await?
    }

    pub async fn upload_avatar(&self, uri: String) -> Result<OwnedMxcUri> {
        let account = self.account.clone();
        let path = PathBuf::from(uri);
        let guess = mime_guess::from_path(path.clone());
        let content_type = guess.first().context("No MIME type")?;
        if !content_type.to_string().starts_with("image/") {
            bail!("Account avatar accepts only image file");
        }
        RUNTIME
            .spawn(async move {
                let buf = std::fs::read(path)?;
                let new_url = account.upload_avatar(&content_type, buf).await?;
                Ok(new_url)
            })
            .await?
    }
}
