use anyhow::{bail, Context, Result};
use matrix_sdk::{media::MediaFormat, Account as SdkAccount};
use ruma_common::{OwnedMxcUri, OwnedUserId};
use ruma_events::ignored_user_list::IgnoredUserListEventContent;
use std::{ops::Deref, path::PathBuf, str::FromStr};

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

    pub async fn ignore_user(&self, user_id: String) -> Result<bool> {
        let user_id = OwnedUserId::from_str(&user_id)?;
        let account = self.account.clone();

        RUNTIME
            .spawn(async move {
                account.ignore_user(&user_id).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn unignore_user(&self, user_id: String) -> Result<bool> {
        let user_id = OwnedUserId::from_str(&user_id)?;
        let account = self.account.clone();

        RUNTIME
            .spawn(async move {
                account.unignore_user(&user_id).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn ignored_users(&self) -> Result<Vec<OwnedUserId>> {
        let account = self.account.clone();

        RUNTIME
            .spawn(async move {
                let maybe_content = account
                    .account_data::<IgnoredUserListEventContent>()
                    .await?;
                let Some(raw_content) = maybe_content  else {
                bail!("No ignored Users found");
            };
                let content = raw_content.deserialize()?;
                Ok(content.ignored_users.keys().map(Clone::clone).collect())
            })
            .await?
    }
}
