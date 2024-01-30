use anyhow::{Context, Result};
use matrix_sdk::{media::MediaRequest, Account as SdkAccount, Client as SdkClient};
use ruma_common::{OwnedMxcUri, OwnedUserId, UserId};
use ruma_events::{ignored_user_list::IgnoredUserListEventContent, room::MediaSource};
use std::{ops::Deref, path::PathBuf};

use super::{
    common::{OptionBuffer, OptionString, ThumbnailSize},
    RUNTIME,
};

#[derive(Clone, Debug)]
pub struct Account {
    account: SdkAccount,
    client: SdkClient,
    user_id: OwnedUserId,
}

impl Deref for Account {
    type Target = SdkAccount;
    fn deref(&self) -> &SdkAccount {
        &self.account
    }
}

impl Account {
    pub fn new(account: SdkAccount, user_id: OwnedUserId, client: SdkClient) -> Self {
        Account {
            account,
            client,
            user_id,
        }
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

    pub async fn avatar(&self, thumb_size: Option<Box<ThumbnailSize>>) -> Result<OptionBuffer> {
        let account = self.account.clone();
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let source = match account.get_cached_avatar_url().await? {
                    Some(url) => MediaSource::Plain(url.into()),
                    None => match account.get_avatar_url().await? {
                        Some(e) => MediaSource::Plain(e),
                        None => return Ok(OptionBuffer::new(None)),
                    },
                };
                let format = ThumbnailSize::parse_into_media_format(thumb_size);
                let request = MediaRequest { source, format };
                Ok(OptionBuffer::new(Some(
                    client.media().get_media_content(&request, true).await?,
                )))
            })
            .await?
    }

    pub async fn upload_avatar(&self, uri: String) -> Result<OwnedMxcUri> {
        let account = self.account.clone();
        let path = PathBuf::from(uri);
        RUNTIME
            .spawn(async move {
                let guess = mime_guess::from_path(path.clone());
                let content_type = guess.first().context("don't know mime type")?;
                let data = std::fs::read(path)?;
                let new_url = account.upload_avatar(&content_type, data).await?;
                Ok(new_url)
            })
            .await?
    }

    pub async fn ignore_user(&self, user_id: String) -> Result<bool> {
        let user_id = UserId::parse(user_id)?;
        let account = self.account.clone();

        RUNTIME
            .spawn(async move {
                account.ignore_user(&user_id).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn unignore_user(&self, user_id: String) -> Result<bool> {
        let user_id = UserId::parse(user_id)?;
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
                let content = account
                    .account_data::<IgnoredUserListEventContent>()
                    .await?
                    .context("Ignored users not found")?
                    .deserialize()?;
                Ok(content.ignored_users.keys().cloned().collect())
            })
            .await?
    }
}
