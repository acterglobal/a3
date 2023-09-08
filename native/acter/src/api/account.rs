use anyhow::{Context, Result};
use matrix_sdk::{
    media::MediaFormat,
    ruma::{thirdparty::Medium, uint, ClientSecret, OwnedMxcUri, OwnedUserId},
    Account as SdkAccount,
};
use std::{ops::Deref, path::PathBuf};

use super::{
    api::FfiBuffer,
    common::{OptionBuffer, OptionString},
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

    pub async fn display_name(&self) -> Result<OptionString> {
        let account = self.account.clone();
        RUNTIME
            .spawn(async move {
                let name = account.get_display_name().await?;
                Ok(OptionString::new(name))
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
        RUNTIME
            .spawn(async move {
                let guess = mime_guess::from_path(path.clone());
                let content_type = guess.first().context("MIME type should be given")?;
                let data = std::fs::read(path).context("File should be read")?;
                let new_url = account.upload_avatar(&content_type, data).await?;
                Ok(new_url)
            })
            .await?
    }

    pub async fn email_address(&self) -> Result<OptionString> {
        let account = self.account.clone();
        RUNTIME
            .spawn(async move {
                let response = account.get_3pids().await?;
                for threepid in response.threepids.iter() {
                    if threepid.medium == Medium::Email {
                        return Ok(OptionString::new(Some(threepid.address.clone())));
                    }
                }
                Ok(OptionString::new(None))
            })
            .await?
    }

    pub async fn request_token_via_email(
        &self,
        email_address: String,
        password: String,
    ) -> Result<bool> {
        let account = self.account.clone();
        let secret = ClientSecret::parse(password).context("Password parsing failed")?;
        RUNTIME
            .spawn(async move {
                let token_response = account
                    .request_3pid_email_token(&secret, email_address.as_str(), uint!(0))
                    .await?;

                // Wait for the user to confirm that the token was submitted or prompt
                // the user for the token and send it to submit_url.

                let uiaa_response = account.add_3pid(&secret, &token_response.sid, None).await?;
                Ok(true)
            })
            .await?
    }
}
