use acter_core::events::settings::{ActerUserAppSettingsContent, APP_USER_SETTINGS};
use anyhow::{bail, Context, Result};
use futures::StreamExt;
use matrix_sdk::{media::MediaRequest, Account as SdkAccount};
use ruma::{assign, uint};
use ruma_client_api::{
    account::request_3pid_management_token_via_email,
    uiaa::{AuthData, EmailIdentity, Password, ThirdpartyIdCredentials},
};
use ruma_common::{
    thirdparty::Medium, ClientSecret, MilliSecondsSinceUnixEpoch, OwnedClientSecret, OwnedMxcUri,
    OwnedUserId, SessionId, UserId,
};
use ruma_events::{ignored_user_list::IgnoredUserListEventContent, room::MediaSource};
use std::{ops::Deref, path::PathBuf};
use tokio::sync::broadcast::Receiver;
use tokio_stream::{wrappers::BroadcastStream, Stream};
use tracing::info;

use super::{
    common::{clearify_error, OptionBuffer, OptionString, ThumbnailSize},
    RUNTIME,
};
use crate::{ActerUserAppSettings, Client};

#[derive(Clone, Debug)]
pub struct Account {
    account: SdkAccount,
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
                    bail!("This client cannot change display name");
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
        let client = self.client.deref().clone();
        let account = self.account.clone();
        let path = PathBuf::from(uri);
        RUNTIME
            .spawn(async move {
                let capabilities = client.get_capabilities().await?;
                if !capabilities.set_avatar_url.enabled {
                    bail!("This client cannot change avatar url");
                }
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

    pub async fn request_3pid_email_token(
        &self,
        email: String,
    ) -> Result<ThreePidEmailTokenResponse> {
        let account = self.account.clone();
        let client_secret = ClientSecret::new();

        RUNTIME
            .spawn(async move {
                let inner = account
                    .request_3pid_email_token(&client_secret, &email, uint!(0))
                    .await
                    .map_err(clearify_error)?;
                Ok(ThreePidEmailTokenResponse {
                    inner,
                    client_secret,
                })
            })
            .await?
    }

    // this fn will use client secret & session id that were returned from previous stage of UIAA process
    pub async fn add_3pid(
        &self,
        client_secret: String,
        sid: String,
        password: String,
    ) -> Result<bool> {
        let client = self.client.deref().clone();
        let account = self.account.clone();
        let user_id = self.user_id.clone();
        let client_secret = ClientSecret::parse(&client_secret)?;
        let sid = SessionId::parse(&sid)?; // it was already related with email or msisdn

        RUNTIME
            .spawn(async move {
                let capabilities = client.get_capabilities().await?;
                if !capabilities.thirdparty_id_changes.enabled {
                    bail!("Server doesn't support 3pid change");
                }
                if let Err(e) = account.add_3pid(&client_secret, &sid, None).await {
                    let Some(inf) = e.as_uiaa_response() else {
                        return Err(clearify_error(e));
                    };
                    let pswd = assign!(Password::new(user_id.into(), password), {
                        session: inf.session.clone(),
                    });
                    let auth_data = AuthData::Password(pswd);
                    account
                        .add_3pid(&client_secret, &sid, Some(auth_data))
                        .await
                        .map_err(clearify_error)?;
                }
                Ok(true)
            })
            .await?
    }

    pub async fn delete_3pid_email(&self, address: String) -> Result<bool> {
        let client = self.client.deref().clone();
        let account = self.account.clone();

        RUNTIME
            .spawn(async move {
                let capabilities = client.get_capabilities().await?;
                if !capabilities.thirdparty_id_changes.enabled {
                    bail!("Server doesn't support 3pid change");
                }
                account
                    .delete_3pid(&address, Medium::Email, None)
                    .await
                    .map_err(clearify_error)?;
                Ok(true)
            })
            .await?
    }

    pub async fn get_3pids(&self, address: String) -> Result<Vec<ThreePid>> {
        let account = self.account.clone();

        RUNTIME
            .spawn(async move {
                let resp = account.get_3pids().await.map_err(clearify_error)?;
                let records = resp
                    .threepids
                    .iter()
                    .map(|x| ThreePid {
                        address: x.address.clone(),
                        medium: x.medium.clone(),
                        added_at: x.added_at,
                        validated_at: x.validated_at,
                    })
                    .collect();
                Ok(records)
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
                    bail!("Server doesn't support password change");
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
                if let Err(e) = account.deactivate(None, None).await {
                    let Some(inf) = e.as_uiaa_response() else {
                        return Err(clearify_error(e));
                    };
                    let pswd = assign!(Password::new(user_id.into(), password), {
                        session: inf.session.clone(),
                    });
                    let auth_data = AuthData::Password(pswd);
                    account.deactivate(None, Some(auth_data)).await?;
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
        self.client.subscribe(APP_USER_SETTINGS.to_string())
    }
}

#[derive(Clone)]
pub struct ThreePidEmailTokenResponse {
    inner: request_3pid_management_token_via_email::v3::Response,
    client_secret: OwnedClientSecret,
}

impl ThreePidEmailTokenResponse {
    pub fn sid(&self) -> String {
        self.inner.sid.to_string()
    }

    pub fn submit_url(&self) -> Option<String> {
        self.inner.submit_url.clone()
    }

    pub fn client_secret(&self) -> String {
        self.client_secret.to_string()
    }
}

#[derive(Clone)]
pub struct ThreePid {
    address: String,
    medium: Medium,
    added_at: MilliSecondsSinceUnixEpoch,
    validated_at: MilliSecondsSinceUnixEpoch,
}

impl ThreePid {
    pub fn address(&self) -> String {
        self.address.clone()
    }

    pub fn medium(&self) -> String {
        self.medium.to_string()
    }

    pub fn added_at(&self) -> u64 {
        self.added_at.get().into()
    }

    pub fn validated_at(&self) -> u64 {
        self.validated_at.get().into()
    }
}
