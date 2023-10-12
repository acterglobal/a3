use acter_core::events::three_pid::{ThreePidContent, ThreePidRecord};
use anyhow::{bail, Context, Result};
use matrix_sdk::{
    reqwest::{ClientBuilder, StatusCode},
    ruma::{
        api::client::account::ThirdPartyIdRemovalStatus, thirdparty::Medium, uint, ClientSecret,
        OwnedSessionId, SessionId,
    },
    Account as SdkAccount,
};
use serde::Deserialize;
use std::{
    collections::{BTreeMap, HashMap},
    ops::Deref,
};
use tracing::warn;

use super::{account::Account, RUNTIME};

#[derive(Clone)]
pub struct ThreePidManager {
    account: SdkAccount,
}

impl ThreePidManager {
    pub async fn confirmed_email_addresses(&self) -> Result<Vec<String>> {
        let account = self.account.clone();
        RUNTIME
            .spawn(async move {
                let response = account.get_3pids().await?;
                let addresses = response
                    .threepids
                    .iter()
                    .filter_map(|x| {
                        if x.medium == Medium::Email {
                            Some(x.address.clone())
                        } else {
                            None
                        }
                    })
                    .collect::<Vec<String>>();
                Ok(addresses)
            })
            .await?
    }

    pub async fn requested_email_addresses(&self) -> Result<Vec<String>> {
        let account = self.account.clone();
        RUNTIME
            .spawn(async move {
                let maybe_content = account.account_data::<ThreePidContent>().await?;
                let Some(raw_content) = maybe_content else {
                    return Ok(vec![]);
                };
                let content = raw_content.deserialize()?;
                let addresses = content.via_email.iter().map(|(k, v)| k.clone()).collect();
                Ok(addresses)
            })
            .await?
    }

    pub async fn request_token_via_email(
        &self,
        email_address: String,
        password: String,
    ) -> Result<bool> {
        let account = self.account.clone();
        let secret = ClientSecret::parse(password.clone()).context("Password parsing failed")?;
        RUNTIME
            .spawn(async move {
                let response = account
                    .request_3pid_email_token(&secret, email_address.as_str(), uint!(0))
                    .await?;

                // add this record to custom data
                let record = ThreePidRecord::new(
                    response.submit_url.clone(),
                    response.sid.to_string(),
                    password,
                );
                let maybe_content = account.account_data::<ThreePidContent>().await?;
                let content = if let Some(raw_content) = maybe_content {
                    let mut content = raw_content.deserialize()?;
                    content
                        .via_email
                        .entry(email_address)
                        .and_modify(|x| *x = record.clone())
                        .or_insert(record);
                    content
                } else {
                    let mut via_email = BTreeMap::new();
                    via_email.insert(email_address, record);
                    let via_phone = BTreeMap::new();
                    ThreePidContent {
                        via_email,
                        via_phone,
                    }
                };
                account
                    .set_account_data(content)
                    .await
                    .context("Setting account data failed")?;

                Ok(true)
            })
            .await?
    }

    pub async fn submit_token_from_email(
        &self,
        email_address: String,
        token: String,
    ) -> Result<bool> {
        let account = self.account.clone();
        RUNTIME
            .spawn(async move {
                let maybe_content = account.account_data::<ThreePidContent>().await?;
                let Some(raw_content) = maybe_content else {
                    warn!("Not found any email registration content");
                    return Ok(false);
                };
                let content = raw_content.deserialize()?;
                let Some(record) = content.via_email.get(email_address.as_str()) else {
                    warn!("That email address was not registered");
                    return Ok(false);
                };
                let Some(submit_url) = record.submit_url() else {
                    warn!("The submit url for email confirmation was not given");
                    return Ok(false);
                };
                let session_id = record.session_id();
                let password = record.passphrase();
                let sid =
                    SessionId::parse(session_id.clone()).context("Session id parsing failed")?;
                let secret = ClientSecret::parse(password).context("Password parsing failed")?;

                // send confirmation
                let http_client = ClientBuilder::new().build()?;
                let mut params: HashMap<String, String> = HashMap::new();
                params.insert("sid".to_string(), session_id.clone());
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

    pub async fn remove_email_address(&self, email_address: String) -> Result<bool> {
        let account = self.account.clone();
        RUNTIME
            .spawn(async move {
                // find it among the confirmed email addresses
                let response = account.get_3pids().await?;
                if let Some(index) = response
                    .threepids
                    .iter()
                    .position(|x| x.medium == Medium::Email && x.address == email_address)
                {
                    let response = account
                        .delete_3pid(email_address.as_str(), Medium::Email, None)
                        .await?;
                    match response.id_server_unbind_result {
                        ThirdPartyIdRemovalStatus::Success => {
                            return Ok(true);
                        }
                        _ => {
                            return Ok(false);
                        }
                    }
                }

                // find it among the unconfirmed email addresses
                let maybe_content = account.account_data::<ThreePidContent>().await?;
                let Some(raw_content) = maybe_content else {
                    return Ok(false);
                };
                let mut content = raw_content.deserialize()?;
                if content.via_email.contains_key(email_address.as_str()) {
                    content.via_email.remove(email_address.as_str());
                    account
                        .set_account_data(content)
                        .await
                        .context("Setting account data failed")?;
                    return Ok(true);
                }

                Ok(false)
            })
            .await?
    }
}

impl Account {
    pub fn three_pid_manager(&self) -> ThreePidManager {
        let account = self.deref().clone();
        ThreePidManager { account }
    }
}

#[derive(Deserialize, Debug)]
struct ValidateResponse {
    pub success: bool,
}
