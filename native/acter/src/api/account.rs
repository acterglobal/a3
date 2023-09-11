use anyhow::{bail, Context, Result};
use matrix_sdk::{
    media::MediaFormat,
    reqwest::{ClientBuilder, StatusCode},
    ruma::{
        events::ignored_user_list::IgnoredUserListEventContent, thirdparty::Medium, uint,
        ClientSecret, OwnedMxcUri, OwnedSessionId, OwnedUserId, SessionId,
    },
    Account as SdkAccount,
};
use serde::Deserialize;
use std::{collections::HashMap, ops::Deref, path::PathBuf, str::FromStr};

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

    pub async fn email_address(&self) -> Result<OptionString> {
        let account = self.account.clone();
        RUNTIME
            .spawn(async move {
                let response = account.get_3pids().await?;
                for threepid in response.threepids.iter() {
                    if threepid.medium == Medium::Email {
                        let address = threepid.address.clone();
                        return Ok(OptionString::new(Some(address)));
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
    ) -> Result<EmailTokenResponse> {
        let account = self.account.clone();
        let secret = ClientSecret::parse(password).context("Password parsing failed")?;
        RUNTIME
            .spawn(async move {
                let response = account
                    .request_3pid_email_token(&secret, email_address.as_str(), uint!(0))
                    .await?;
                Ok(EmailTokenResponse {
                    session_id: response.sid,
                    submit_url: response.submit_url,
                })
            })
            .await?
    }

    pub async fn submit_token_from_email(
        &self,
        submit_url: String,
        session_id: String,
        password: String,
        token: String,
    ) -> Result<bool> {
        let account = self.account.clone();
        let sid = SessionId::parse(session_id.clone()).context("Session id parsing failed")?;
        let secret = ClientSecret::parse(password).context("Password parsing failed")?;
        RUNTIME
            .spawn(async move {
                let http_client = ClientBuilder::new().build()?;
                let mut params: HashMap<String, String> = HashMap::new();
                params.insert("sid".to_string(), session_id);
                params.insert("client_secret".to_string(), secret.to_string());
                params.insert("token".to_string(), token);
                let submit_response = http_client.post(submit_url).form(&params).send().await?;
                if submit_response.status() != StatusCode::OK {
                    return Ok(false);
                }
                let text = submit_response
                    .text()
                    .await
                    .context("Validating email failed")?;
                let ValidateResponse { success } = serde_json::from_str(text.as_str())?;
                if !success {
                    return Ok(false);
                }
                let uiaa_response = account.add_3pid(&secret, &sid, None).await?;
                Ok(true)
            })
            .await?
    }
}

#[derive(Deserialize, Debug)]
struct ValidateResponse {
    pub success: bool,
}

#[derive(Clone, Debug)]
pub struct EmailTokenResponse {
    session_id: OwnedSessionId,
    submit_url: Option<String>,
}

impl EmailTokenResponse {
    pub fn session_id(&self) -> String {
        self.session_id.to_string()
    }

    pub fn submit_url(&self) -> Option<String> {
        self.submit_url.clone()
    }
}
