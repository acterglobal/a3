use acter_core::events::password_reset::{
    PasswordResetContent, PasswordResetViaEmail, PasswordResetViaPhone,
};
use anyhow::{Context, Result};
use matrix_sdk::{
    reqwest::{ClientBuilder, StatusCode},
    ruma::{thirdparty::Medium, uint, ClientSecret, OwnedSessionId, SessionId},
};
use serde::Deserialize;
use std::{collections::HashMap, ops::Deref};

use super::{account::Account, common::OptionString, RUNTIME};

#[derive(Clone)]
pub struct PasswordReset {
    inner: PasswordResetContent,
}

impl Deref for PasswordReset {
    type Target = PasswordResetContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl PasswordReset {
    fn via_email(&self) -> Option<PasswordResetViaEmail> {
        self.inner.via_email()
    }

    fn via_phone(&self) -> Option<PasswordResetViaPhone> {
        self.inner.via_phone()
    }
}

impl Account {
    pub async fn email_address(&self) -> Result<OptionString> {
        let account = self.deref().clone();
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
        let account = self.deref().clone();
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
        let account = self.deref().clone();
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

    pub async fn set_password_reset_via_email(
        &self,
        submit_url: Option<String>,
        session_id: String,
        passphrase: String,
    ) -> Result<bool> {
        let account = self.deref().clone();
        RUNTIME
            .spawn(async move {
                let data = PasswordResetViaEmail::new(
                    submit_url.clone(),
                    session_id.clone(),
                    passphrase.clone(),
                );
                let content = PasswordResetContent::new(Some(data), None);
                account
                    .set_account_data(content)
                    .await
                    .context("Setting account data failed")?;
                Ok(true)
            })
            .await?
    }

    pub async fn set_password_reset_via_phone(
        &self,
        submit_url: Option<String>,
        session_id: String,
        passphrase: String,
    ) -> Result<bool> {
        let account = self.deref().clone();
        RUNTIME
            .spawn(async move {
                let data = PasswordResetViaPhone::new(
                    submit_url.clone(),
                    session_id.clone(),
                    passphrase.clone(),
                );
                let content = PasswordResetContent::new(None, Some(data));
                account
                    .set_account_data(content)
                    .await
                    .context("Setting account data failed")?;
                Ok(true)
            })
            .await?
    }

    pub async fn get_password_reset(&self) -> Result<PasswordReset> {
        let account = self.deref().clone();
        RUNTIME
            .spawn(async move {
                if let Some(raw_content) = account
                    .account_data::<PasswordResetContent>()
                    .await
                    .context("getting of PasswordResetContent from account data was failed")?
                {
                    let inner = raw_content
                        .deserialize()
                        .context("deserialization of PasswordResetContent was failed")?;
                    return Ok(PasswordReset { inner });
                }
                Ok(PasswordReset {
                    inner: PasswordResetContent::new(None, None),
                })
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
