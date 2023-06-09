use anyhow::{Context, Result};
use matrix_sdk::{
    media::MediaFormat,
    ruma::{OwnedMxcUri, OwnedUserId},
    Account as SdkAccount,
};

use super::{api::FfiBuffer, RUNTIME};

#[derive(Clone, Debug)]
pub struct Account {
    account: SdkAccount,
    user_id: OwnedUserId,
}

impl std::ops::Deref for Account {
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

    pub async fn display_name(&self) -> Result<String> {
        let account = self.account.clone();
        RUNTIME
            .spawn(async move {
                let display_name = account
                    .get_display_name()
                    .await?
                    .context("No User ID found")?;
                Ok(display_name)
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
                account
                    .set_display_name(name)
                    .await
                    .context("Couldn't set display name")?;
                Ok(true)
            })
            .await?
    }

    pub async fn avatar(&self) -> Result<FfiBuffer<u8>> {
        let account = self.account.clone();
        RUNTIME
            .spawn(async move {
                let buf = account
                    .get_avatar(MediaFormat::File)
                    .await?
                    .context("No avatar URL given")?;
                Ok(FfiBuffer::new(buf))
            })
            .await?
    }

    pub async fn set_avatar(&self, content_type: String, data: Vec<u8>) -> Result<OwnedMxcUri> {
        let account = self.account.clone();
        let content_type = content_type.parse::<mime::Mime>()?;
        RUNTIME
            .spawn(async move {
                let new_url = account
                    .upload_avatar(&content_type, data)
                    .await
                    .context("Couldn't upload avatar")?;
                Ok(new_url)
            })
            .await?
    }
}
