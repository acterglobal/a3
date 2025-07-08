use acter_matrix::events::three_pid::{ThreePidContent, ThreePidRecord};
use anyhow::{bail, Context, Result};
use matrix_sdk::reqwest::{ClientBuilder, StatusCode};
use matrix_sdk_base::ruma::{
    api::client::{
        account::{request_3pid_management_token_via_email, ThirdPartyIdRemovalStatus},
        uiaa::{AuthData, Password, UserIdentifier},
    },
    assign,
    thirdparty::{Medium, ThirdPartyIdentifier},
    uint, ClientSecret, MilliSecondsSinceUnixEpoch, OwnedClientSecret, SessionId,
};
use serde::Deserialize;
use std::{collections::BTreeMap, ops::Deref};

use super::Account;
use crate::{api::common::clearify_error, RUNTIME};

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
pub struct ExternalId {
    address: String,
    medium: Medium,
    added_at: MilliSecondsSinceUnixEpoch,
    validated_at: MilliSecondsSinceUnixEpoch,
}

impl ExternalId {
    fn new(val: ThirdPartyIdentifier) -> Self {
        ExternalId {
            address: val.address,
            medium: val.medium,
            added_at: val.added_at,
            validated_at: val.validated_at,
        }
    }

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

#[derive(Deserialize, Debug)]
struct ValidateResponse {
    pub success: bool,
}

impl Account {
    pub async fn confirmed_email_addresses(&self) -> Result<Vec<String>> {
        let account = self.account.clone();

        RUNTIME
            .spawn(async move {
                let response = account.get_3pids().await.map_err(clearify_error)?;
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

    pub async fn request_3pid_management_token_via_email(
        &self,
        email: String,
    ) -> Result<ThreePidEmailTokenResponse> {
        let client = self.client.deref().clone();
        let account = self.account.clone();
        let client_secret = ClientSecret::new();

        RUNTIME
            .spawn(async move {
                let capabilities = client.get_capabilities().await?;
                if !capabilities.thirdparty_id_changes.enabled {
                    bail!("Server doesn’t support change of third party identity");
                }
                let inner = account
                    .request_3pid_email_token(&client_secret, &email, uint!(0))
                    .await
                    .map_err(clearify_error)?;

                // add this record to custom data
                let record = ThreePidRecord::new(inner.sid.to_string(), client_secret.clone());
                let maybe_content = account.account_data::<ThreePidContent>().await?;
                let content = if let Some(raw_content) = maybe_content {
                    let mut content = raw_content.deserialize()?;
                    content
                        .via_email
                        .entry(email)
                        .and_modify(|x| *x = record.clone())
                        .or_insert(record);
                    content
                } else {
                    let mut via_email = BTreeMap::new();
                    via_email.insert(email, record);
                    let via_phone = BTreeMap::new();
                    ThreePidContent {
                        via_email,
                        via_phone,
                    }
                };
                account.set_account_data(content).await?;

                Ok(ThreePidEmailTokenResponse {
                    inner,
                    client_secret,
                })
            })
            .await?
    }

    // add 3pid on the homeserver for this account
    // this 3pid may be used by the homeserver to authenticate the user during sensitive operations
    #[cfg(feature = "testing")]
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
                    bail!("Server doesn’t support 3pid change");
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

    pub async fn external_ids(&self) -> Result<Vec<ExternalId>> {
        let account = self.account.clone();

        RUNTIME
            .spawn(async move {
                let resp = account.get_3pids().await.map_err(clearify_error)?;
                let records = resp.threepids.into_iter().map(ExternalId::new).collect();
                Ok(records)
            })
            .await?
    }

    pub async fn try_confirm_email_status(
        &self,
        email_address: String,
        password: String,
    ) -> Result<bool> {
        let client = self.client.deref().clone();
        let account = self.account.clone();
        let user_id = self.user_id.clone();

        RUNTIME
            .spawn(async move {
                let capabilities = client.get_capabilities().await?;
                if !capabilities.thirdparty_id_changes.enabled {
                    bail!("Server doesn’t support change of third party identity");
                }
                let mut content = account
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
                // FIXME: this shouldn’t be hardcoded but use an Actual IUAA-flow
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
                            bail!("{:?}: {:?}", std_err.kind, std_err.message);
                        }
                    }
                    return Err(e.into());
                }

                // now email address can be removed from account data
                // because session id & passphrase are wasted
                content.via_email.remove(&email_address);
                account.set_account_data(content).await?;

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
                    bail!("Server doesn’t support change of third party identity");
                }
                let mut content = account
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
                // FIXME: this shouldn’t be hardcoded but use an Actual IUAA-flow
                let auth_data = AuthData::Password(Password::new(
                    UserIdentifier::UserIdOrLocalpart(user_id.to_string()),
                    password,
                ));

                if let Err(e) = account.add_3pid(&secret, &sid, Some(auth_data)).await {
                    if let Some(a) = e.as_uiaa_response() {
                        if let Some(std_err) = &a.auth_error {
                            bail!("{:?}: {:?}", std_err.kind, std_err.message);
                        }
                    }
                    return Err(e.into());
                }

                // now email address can be removed from account data
                // because session id & passphrase are wasted
                content.via_email.remove(&email_address);
                account.set_account_data(content).await?;

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
                    bail!("Server doesn’t support change of third party identity");
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
