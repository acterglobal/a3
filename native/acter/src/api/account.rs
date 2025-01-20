use acter_core::events::settings::{ActerUserAppSettingsContent, APP_USER_SETTINGS};
use anyhow::{bail, Context, Result};
use futures::stream::StreamExt;
use matrix_sdk::Account as SdkAccount;
use matrix_sdk_base::{
    media::MediaRequestParameters,
    ruma::{
        api::client::uiaa::{AuthData, Password},
        assign,
        events::{ignored_user_list::IgnoredUserListEventContent, room::MediaSource},
        OwnedMxcUri, OwnedUserId, UserId,
    },
    StateStoreDataKey, StateStoreDataValue,
};
use std::{ops::Deref, path::PathBuf};
use tokio::sync::broadcast::Receiver;
use tokio_stream::{wrappers::BroadcastStream, Stream};

use super::{
    common::{clearify_error, OptionBuffer, OptionString, ThumbnailSize},
    RUNTIME,
};
use crate::{ActerUserAppSettings, Client};

mod three_pid;

pub use three_pid::{ExternalId, ThreePidEmailTokenResponse};

#[derive(Clone, Debug)]
pub struct Account {
    pub(crate) account: SdkAccount,
    client: Client,
    user_id: OwnedUserId,
}

impl Deref for Account {
    type Target = SdkAccount;
    fn deref(&self) -> &SdkAccount {
        &self.account
    }
}

impl Account {
    pub fn new(account: SdkAccount, user_id: OwnedUserId, client: Client) -> Self {
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
        let client = self.client.deref().clone();
        let account = self.account.clone();
        RUNTIME
            .spawn(async move {
                let capabilities = client.get_capabilities().await?;
                if !capabilities.set_displayname.enabled {
                    bail!("Server doesn’t support change of display name");
                }
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
        let client = self.client.deref().clone();
        RUNTIME
            .spawn(async move {
                let source = match account.get_cached_avatar_url().await? {
                    Some(url) => MediaSource::Plain(url),
                    None => match account.get_avatar_url().await? {
                        Some(e) => MediaSource::Plain(e),
                        None => return Ok(OptionBuffer::new(None)),
                    },
                };
                let format = ThumbnailSize::parse_into_media_format(thumb_size);
                let request = MediaRequestParameters { source, format };
                Ok(OptionBuffer::new(Some(
                    client.media().get_media_content(&request, true).await?,
                )))
            })
            .await?
    }

    pub async fn upload_avatar(&self, uri: String) -> Result<OwnedMxcUri> {
        let client = self.client.deref().clone();
        let account = self.account.clone();
        let path = PathBuf::from(uri);
        let user_id = self.user_id();
        RUNTIME
            .spawn(async move {
                let capabilities = client.get_capabilities().await?;
                if !capabilities.set_avatar_url.enabled {
                    bail!("Server doesn’t support change of avatar url");
                }
                let guess = mime_guess::from_path(path.clone());
                let content_type = guess.first().context("don’t know mime type")?;
                let data = std::fs::read(path)?;
                let new_url = account.upload_avatar(&content_type, data).await?;

                // set the internal cached key so the next fetch properly updates this
                client
                    .store()
                    .set_kv_data(
                        StateStoreDataKey::UserAvatarUrl(&user_id),
                        StateStoreDataValue::UserAvatarUrl(new_url.clone()),
                    )
                    .await;
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

    pub async fn change_password(&self, old_val: String, new_val: String) -> Result<bool> {
        let client = self.client.deref().clone();
        let account = self.account.clone();
        let user_id = self.user_id.clone();

        RUNTIME
            .spawn(async move {
                let capabilities = client.get_capabilities().await?;
                if !capabilities.change_password.enabled {
                    bail!("Server doesn’t support password change");
                }
                if let Err(e) = account.change_password(&new_val, None).await {
                    let Some(inf) = e.as_uiaa_response() else {
                        return Err(clearify_error(e));
                    };
                    let pswd = assign!(Password::new(user_id.into(), old_val), {
                        session: inf.session.clone(),
                    });
                    let auth_data = AuthData::Password(pswd);
                    account
                        .change_password(&new_val, Some(auth_data))
                        .await
                        .map_err(clearify_error)?;
                }
                Ok(true)
            })
            .await?
    }

    pub async fn deactivate(&self, password: String) -> Result<bool> {
        let account = self.account.clone();
        let user_id = self.user_id.clone();

        RUNTIME
            .spawn(async move {
                if let Err(e) = account.deactivate(None, None, false).await {
                    let Some(inf) = e.as_uiaa_response() else {
                        return Err(clearify_error(e));
                    };
                    let pswd = assign!(Password::new(user_id.into(), password), {
                        session: inf.session.clone(),
                    });
                    let auth_data = AuthData::Password(pswd);
                    account.deactivate(None, Some(auth_data), false).await?;
                    // FIXME: remove local data, too!
                }
                Ok(true)
            })
            .await?
    }

    pub async fn acter_app_settings(&self) -> Result<ActerUserAppSettings> {
        let account = self.account.clone();

        RUNTIME
            .spawn(async move {
                let inner = if let Some(raw) = account
                    .account_data::<ActerUserAppSettingsContent>()
                    .await?
                {
                    raw.deserialize()?
                } else {
                    ActerUserAppSettingsContent::default()
                };

                Ok(ActerUserAppSettings::new(account, inner))
            })
            .await?
    }

    pub fn subscribe_app_settings_stream(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.subscribe()).map(|_| true)
    }

    pub fn subscribe(&self) -> Receiver<()> {
        self.client.subscribe(APP_USER_SETTINGS.clone())
    }
}
