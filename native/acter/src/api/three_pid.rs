use acter_core::events::three_pid::{ThreePidContent, ThreePidRecord};
use anyhow::{bail, Context, Result};
use matrix_sdk::{
    reqwest::{ClientBuilder, StatusCode},
    Account,
};
use ruma::{thirdparty::Medium, uint, ClientSecret, SessionId};
use ruma_client_api::{
    account::ThirdPartyIdRemovalStatus,
    uiaa::{AuthData, Password, UserIdentifier},
};
use serde::Deserialize;
use std::{collections::BTreeMap, ops::Deref};

use super::{client::Client, RUNTIME};

#[derive(Clone)]
pub struct ThreePidManager {
    account: Account,
    client: Client,
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

    pub async fn request_token_via_email(&self, email_address: String) -> Result<bool> {
        let client = self.client.clone();
        let account = self.account.clone();
        let secret = ClientSecret::new(); // make random string that will be exposed to confirmation email
        RUNTIME
            .spawn(async move {
                let capabilities = client.get_capabilities().await?;
                if !capabilities.thirdparty_id_changes.enabled {
                    bail!("This client cannot change third party identity");
                }
                let response = account
                    .request_3pid_email_token(&secret, &email_address, uint!(0))
                    .await?;

                // add this record to custom data
                let record = ThreePidRecord::new(response.sid.to_string(), secret);
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
                account.set_account_data(content).await?;

                Ok(true)
            })
            .await?
    }

    pub async fn try_confirm_email_status(
        &self,
        email_address: String,
        password: String,
    ) -> Result<bool> {
        let client = self.client.clone();
        let account = self.account.clone();
        let user_id = self.client.user_id()?;

        RUNTIME
            .spawn(async move {
                let capabilities = client.get_capabilities().await?;
                if !capabilities.thirdparty_id_changes.enabled {
                    bail!("This client cannot change third party identity");
                }
                let content = account
                    .account_data::<ThreePidContent>()
                    .await?
                    .context("Not found any email registration content")?
                    .deserialize()?;
                let record = content
                    .via_email
                    .get(&email_address)
                    .context("That email address was not registered")?;
                let session_id = record.session_id();
                let passphrase = record.passphrase();
                let sid = SessionId::parse(session_id.clone())?;
                let secret = ClientSecret::parse(passphrase.clone())?;
                // try again with password
                // FIXME: this shouldn't be hardcoded but use an Actual IUAA-flow
                let auth_data = AuthData::Password(Password::new(
                    UserIdentifier::UserIdOrLocalpart(user_id.to_string()),
                    password,
                ));

                if let Err(e) = account
                    .add_3pid(&secret, &sid, Some(auth_data.clone()))
                    .await
                {
                    if let Some(a) = e.as_uiaa_response() {
                        if let Some(std_err) = &a.auth_error {
                            bail!("{0}: {1}", std_err.kind, std_err.message);
                        }
                    }
                    return Err(e.into());
                }

                Ok(true)
            })
            .await?
    }

    pub async fn submit_token_from_email(
        &self,
        email_address: String,
        token: String,
        password: String,
    ) -> Result<bool> {
        let client = self.client.clone();
        let account = self.account.clone();
        let user_id = self.client.user_id()?;

        RUNTIME
            .spawn(async move {
                let capabilities = client.get_capabilities().await?;
                if !capabilities.thirdparty_id_changes.enabled {
                    bail!("This client cannot change third party identity");
                }
                let content = account
                    .account_data::<ThreePidContent>()
                    .await?
                    .context("Not found any email registration content")?
                    .deserialize()?;
                let record = content
                    .via_email
                    .get(&email_address)
                    .context("That email address was not registered")?;
                let session_id = record.session_id();
                let secret = record.passphrase();
                let sid = SessionId::parse(session_id.clone())?;
                let secret = ClientSecret::parse(secret.clone())?;
                let submit_url = format!(
                    "{}/_matrix/client/unstable/add_threepid/email/submit_token",
                    client.homeserver(),
                );

                // send confirmation
                let http_client = ClientBuilder::new().build()?;
                let submit_response = http_client
                    .get(submit_url)
                    .query(&[
                        ("token", token),
                        ("client_secret", secret.to_string()),
                        ("sid", session_id),
                    ])
                    .send()
                    .await?;
                if submit_response.status() != StatusCode::OK {
                    return Ok(false);
                }
                let text = submit_response.text().await?;
                let ValidateResponse { success } = serde_json::from_str(&text)?;
                if !success {
                    return Ok(false);
                }
                // try again with password
                // FIXME: this shouldn't be hardcoded but use an Actual IUAA-flow
                let auth_data = AuthData::Password(Password::new(
                    UserIdentifier::UserIdOrLocalpart(user_id.to_string()),
                    password,
                ));

                if let Err(e) = account.add_3pid(&secret, &sid, Some(auth_data)).await {
                    if let Some(a) = e.as_uiaa_response() {
                        if let Some(std_err) = &a.auth_error {
                            bail!("{0}: {1}", std_err.kind, std_err.message);
                        }
                    }
                    return Err(e.into());
                }

                Ok(true)
            })
            .await?
    }

    pub async fn remove_email_address(&self, email_address: String) -> Result<bool> {
        let client = self.client.clone();
        let account = self.account.clone();
        RUNTIME
            .spawn(async move {
                let capabilities = client.get_capabilities().await?;
                if !capabilities.thirdparty_id_changes.enabled {
                    bail!("This client cannot change third party identity");
                }
                // find it among the confirmed email addresses
                let response = account.get_3pids().await?;
                if let Some(index) = response
                    .threepids
                    .iter()
                    .position(|x| x.medium == Medium::Email && x.address == email_address)
                {
                    let response = account
                        .delete_3pid(&email_address, Medium::Email, None)
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
                if content.via_email.contains_key(&email_address) {
                    content.via_email.remove(&email_address);
                    account.set_account_data(content).await?;
                    return Ok(true);
                }

                Ok(false)
            })
            .await?
    }
}

impl Client {
    pub fn three_pid_manager(&self) -> Result<ThreePidManager> {
        let account = self.account()?;
        Ok(ThreePidManager {
            account: account.deref().clone(),
            client: self.clone(),
        })
    }
}

#[derive(Deserialize, Debug)]
struct ValidateResponse {
    pub success: bool,
}
