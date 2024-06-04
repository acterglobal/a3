use acter_core::RestoreToken;
use anyhow::{bail, Context, Result};
use lazy_static::lazy_static;
use matrix_sdk::{
    matrix_auth::{MatrixSession, MatrixSessionTokens},
    reqwest::{ClientBuilder as ReqClientBuilder, StatusCode},
    Client as SdkClient, ClientBuilder as SdkClientBuilder, SessionMeta,
};
use ruma::{assign, uint};
use ruma_client_api::{
    account::{
        add_3pid, register, request_password_change_token_via_email,
        request_registration_token_via_email,
    },
    uiaa::{AuthData, Dummy, EmailIdentity, Password, RegistrationToken, ThirdpartyIdCredentials},
};
use ruma_common::{ClientSecret, OwnedClientSecret, OwnedUserId, SessionId, UserId};
use serde::Deserialize;
use std::{ops::Deref, sync::RwLock};
use tracing::{error, info};
use url::Url;
use uuid::Uuid;

use super::{
    client::{Client, ClientStateBuilder},
    common::clearify_error,
    RUNTIME,
};
use crate::{platform, OptionString};

lazy_static! {
    static ref PROXY_URL: RwLock<Option<String>> = RwLock::new(None);
}

pub fn set_proxy(new_proxy: Option<String>) {
    *PROXY_URL.write().expect("Proxy URL couldn't be unlocked") = new_proxy;
}

pub async fn sanitize_user(
    username: &str,
    default_homeserver_name: &str,
) -> Result<(OwnedUserId, bool)> {
    let formatted_username = if !username.starts_with('@') {
        format!("@{username}")
    } else {
        username.to_owned()
    };

    // fully qualified username, good to go
    if let Ok(user_id) = UserId::parse(formatted_username.clone()) {
        return Ok((user_id, false));
    }

    // we need to fallback to the testing/default scenario
    let user_id = UserId::parse(format!("{formatted_username}:{default_homeserver_name}"))?;

    Ok((user_id, true))
}

pub async fn destroy_local_data(
    base_path: String,
    media_cache_base_path: Option<String>,
    username: String,
    default_homeserver_name: String,
) -> Result<bool> {
    let (user_id, fallback) = sanitize_user(&username, &default_homeserver_name).await?;
    platform::destroy_local_data(base_path, user_id.to_string(), media_cache_base_path).await
}

pub async fn make_client_config(
    base_path: String,
    username: &str,
    media_cache_base_path: String,
    db_passphrase: Option<String>,
    default_homeserver_name: &str,
    default_homeserver_url: &str,
    reset_if_existing: bool,
) -> Result<(SdkClientBuilder, OwnedUserId)> {
    let (user_id, fallback) = sanitize_user(username, default_homeserver_name).await?;
    let mut builder = platform::new_client_config(
        base_path,
        user_id.to_string(),
        media_cache_base_path,
        db_passphrase,
        reset_if_existing,
    )
    .await?;

    if let Some(proxy) = PROXY_URL.read().expect("Reading PROXY_URL failed").clone() {
        builder = builder.proxy(proxy);
    }

    if fallback {
        Ok((builder.homeserver_url(default_homeserver_url), user_id))
    } else {
        // we need to fallback to the testing/default scenario
        return Ok((builder.server_name(user_id.server_name()), user_id));
    }
}

pub async fn guest_client(
    base_path: String,
    media_cache_base_path: String,
    default_homeserver_name: String,
    default_homeserver_url: String,
    device_name: Option<String>,
) -> Result<Client> {
    let db_passphrase = Uuid::new_v4().to_string();
    let config = platform::new_client_config(
        base_path.clone(),
        default_homeserver_name,
        media_cache_base_path,
        Some(db_passphrase.clone()),
        true,
    )
    .await?
    .homeserver_url(default_homeserver_url);
    RUNTIME
        .spawn(async move {
            let client = config.build().await?;
            let request = assign!(register::v3::Request::new(), {
                kind: register::RegistrationKind::Guest,
                initial_device_display_name: device_name,
            });
            let response = client.matrix_auth().register(request).await?;
            let device_id = response
                .device_id
                .clone()
                .context("device id not given by server")?;
            let auth_session = MatrixSession {
                meta: SessionMeta {
                    user_id: response.user_id.clone(),
                    device_id,
                },
                tokens: MatrixSessionTokens {
                    access_token: response.access_token.context("no access token given")?,
                    refresh_token: response.refresh_token.clone(),
                },
            };
            client.restore_session(auth_session).await?;
            let state = ClientStateBuilder::default()
                .is_guest(true)
                .db_passphrase(Some(db_passphrase))
                .build()?;
            let c = Client::new(client, state).await?;
            info!("Successfully created guest login: {:?}", response.user_id);
            Ok(c)
        })
        .await?
}

pub async fn login_with_token_under_config(
    restore_token: RestoreToken,
    config: SdkClientBuilder,
) -> Result<Client> {
    let RestoreToken {
        session,
        homeurl,
        is_guest,
        db_passphrase,
        ..
    } = restore_token;
    let user_id = session.user_id.to_string();
    RUNTIME
        .spawn(async move {
            let client = config.homeserver_url(homeurl).build().await?;
            let auth_session = MatrixSession {
                meta: SessionMeta {
                    user_id: session.user_id.clone(),
                    device_id: session.device_id.clone(),
                },
                tokens: MatrixSessionTokens {
                    access_token: session.access_token.clone(),
                    refresh_token: None,
                },
            };
            client.restore_session(auth_session).await?;
            let state = ClientStateBuilder::default()
                .is_guest(is_guest)
                .db_passphrase(db_passphrase)
                .build()?;
            let c = Client::new(client.clone(), state).await?;
            info!(
                "Successfully logged in user {user_id}, device {:?} with token.",
                client.device_id(),
            );
            Ok(c)
        })
        .await?
}

pub async fn login_with_token(
    base_path: String,
    media_cache_base_path: String,
    restore_token: String,
) -> Result<Client> {
    let token: RestoreToken = serde_json::from_str(&restore_token)?;
    let (config, user_id) = make_client_config(
        base_path,
        token.session.user_id.as_str(),
        media_cache_base_path,
        token.db_passphrase.clone(),
        "",
        "",
        false,
    )
    .await?;
    login_with_token_under_config(token, config).await
}

async fn login_client(
    client: SdkClient,
    user_id: OwnedUserId,
    password: String,
    db_passphrase: Option<String>,
    device_name: Option<String>,
) -> Result<Client> {
    let mut login_builder = client.matrix_auth().login_username(&user_id, &password);
    let name; // to capture the inner string for login-builder lifetime
    if let Some(s) = device_name {
        name = s;
        login_builder = login_builder.initial_device_display_name(&name)
    };
    login_builder.send().await?;
    let state = ClientStateBuilder::default()
        .is_guest(false)
        .db_passphrase(db_passphrase)
        .build()?;
    info!(
        "Successfully logged in user {user_id}, device {:?}",
        client.device_id(),
    );
    Client::new(client.clone(), state).await
}

pub async fn login_new_client_under_config(
    config: SdkClientBuilder,
    user_id: OwnedUserId,
    password: String,
    db_passphrase: Option<String>,
    device_name: Option<String>,
) -> Result<Client> {
    RUNTIME
        .spawn(async move {
            login_client(
                config.build().await?,
                user_id,
                password,
                db_passphrase,
                device_name,
            )
            .await
        })
        .await?
}

pub async fn login_new_client(
    base_path: String,
    media_cache_base_path: String,
    username: String,
    password: String,
    default_homeserver_name: String,
    default_homeserver_url: String,
    device_name: Option<String>,
) -> Result<Client> {
    let db_passphrase = Uuid::new_v4().to_string();
    let (config, user_id) = make_client_config(
        base_path,
        &username,
        media_cache_base_path,
        Some(db_passphrase.clone()),
        &default_homeserver_name,
        &default_homeserver_url,
        true,
    )
    .await?;
    login_new_client_under_config(config, user_id, password, Some(db_passphrase), device_name).await
}

#[allow(clippy::too_many_arguments)]
pub async fn register(
    base_path: String,
    media_cache_base_path: String,
    username: String,
    password: String,
    user_agent: String,
    registration_token: String,
    default_homeserver_name: String,
    default_homeserver_url: String,
) -> Result<Client> {
    let db_passphrase = Uuid::new_v4().to_string();
    let (config, user_id) = make_client_config(
        base_path,
        &username,
        media_cache_base_path,
        Some(db_passphrase.clone()),
        &default_homeserver_name,
        &default_homeserver_url,
        true,
    )
    .await?;
    register_under_config(config, user_id, password, Some(db_passphrase), user_agent).await
}

pub async fn register_under_config(
    config: SdkClientBuilder,
    user_id: OwnedUserId,
    password: String,
    db_passphrase: Option<String>,
    user_agent: String,
) -> Result<Client> {
    RUNTIME
        .spawn(async move {
            let client = config.build().await?;
            if let Err(e) = client
                .matrix_auth()
                .register(register::v3::Request::new())
                .await
            {
                // FIXME: do actually check the registration types...
                if e.as_uiaa_response().is_none() {
                    return Err(clearify_error(e));
                }
                let request = assign!(register::v3::Request::new(), {
                    username: Some(user_id.localpart().to_owned()),
                    password: Some(password.clone()),
                    initial_device_display_name: Some(user_agent.clone()),
                    auth: Some(AuthData::Dummy(Dummy::new())),
                });
                client
                    .matrix_auth()
                    .register(request)
                    .await
                    .map_err(clearify_error)?;
            }

            info!(
                "Successfully registered user {user_id}, device {:?}",
                client.device_id(),
            );
            if (client.logged_in()) {
                let state = ClientStateBuilder::default()
                    .is_guest(false)
                    .db_passphrase(db_passphrase)
                    .build()?;
                Client::new(client, state).await
            } else {
                // we didn't receive the login details yet, do a full login attempt
                login_client(client, user_id, password, db_passphrase, Some(user_agent)).await
            }
        })
        .await?
}

#[allow(clippy::too_many_arguments)]
pub async fn register_with_token(
    base_path: String,
    media_cache_base_path: String,
    username: String,
    password: String,
    registration_token: String,
    default_homeserver_name: String,
    default_homeserver_url: String,
    user_agent: String,
) -> Result<Client> {
    let db_passphrase = Uuid::new_v4().to_string();
    let (config, user_id) = make_client_config(
        base_path,
        &username,
        media_cache_base_path.clone(),
        Some(db_passphrase.clone()),
        &default_homeserver_name,
        &default_homeserver_url,
        true,
    )
    .await?;
    register_with_token_under_config(
        config,
        user_id,
        password,
        Some(db_passphrase),
        user_agent,
        registration_token,
    )
    .await
}

pub async fn register_with_token_under_config(
    config: SdkClientBuilder,
    user_id: OwnedUserId,
    password: String,
    db_passphrase: Option<String>,
    user_agent: String,
    registration_token: String,
) -> Result<Client> {
    // First we need to log in.
    RUNTIME
        .spawn(async move {
            let client = config.build().await?;
            let request = assign!(register::v3::Request::new(), {
                username: Some(user_id.localpart().to_owned()),
                password: Some(password.clone()),
                initial_device_display_name: Some(user_agent.clone()),
                auth: Some(AuthData::Dummy(Dummy::new())),
            });

            if let Err(e) = client.matrix_auth().register(request).await {
                // FIXME: do actually check the registration types...
                let Some(inf) = e.as_uiaa_response() else {
                    return Err(clearify_error(e));
                };

                info!("Acceptable auth flows: {inf:?}");

                // FIXME: do actually check the registration types...
                let request = assign!(register::v3::Request::new(), {
                    auth: Some(AuthData::RegistrationToken(
                        assign!(RegistrationToken::new(registration_token), {
                            session: inf.session.clone(),
                        }),
                    )),
                });
                client
                    .matrix_auth()
                    .register(request)
                    .await
                    .map_err(clearify_error)?;
            } // else all went well.

            info!(
                "Successfully registered user {user_id}, device {:?}",
                client.device_id(),
            );
            if (client.logged_in()) {
                let state = ClientStateBuilder::default()
                    .is_guest(false)
                    .db_passphrase(db_passphrase)
                    .build()?;
                Client::new(client, state).await
            } else {
                // we didn't receive the login details yet, do a full login attempt
                login_client(client, user_id, password, db_passphrase, Some(user_agent)).await
            }
        })
        .await?
}

pub async fn request_registration_token_via_email(
    base_path: String,
    media_cache_base_path: String,
    username: String,
    default_homeserver_name: String,
    default_homeserver_url: String,
    email: String,
) -> Result<RegistrationTokenViaEmailResponse> {
    let homeserver_url = Url::parse(&default_homeserver_url)?;
    let db_passphrase = Uuid::new_v4().to_string();
    let (config, user_id) = make_client_config(
        base_path,
        &username,
        media_cache_base_path,
        Some(db_passphrase.clone()),
        &default_homeserver_name,
        &default_homeserver_url,
        true,
    )
    .await?;

    RUNTIME
        .spawn(async move {
            let client = SdkClient::new(homeserver_url).await?;
            let client_secret = ClientSecret::new();
            let request = request_registration_token_via_email::v3::Request::new(
                client_secret,
                email,
                uint!(0),
            );
            let inner = client.send(request, None).await?;
            Ok(RegistrationTokenViaEmailResponse { inner })
        })
        .await?
}

#[derive(Clone)]
pub struct RegistrationTokenViaEmailResponse {
    inner: request_registration_token_via_email::v3::Response,
}

impl RegistrationTokenViaEmailResponse {
    pub fn sid(&self) -> String {
        self.inner.sid.to_string()
    }

    pub fn submit_url(&self) -> OptionString {
        OptionString::new(self.inner.submit_url.clone())
    }
}

pub async fn request_password_change_email_token(
    default_homeserver_url: String,
    email: String,
) -> Result<PasswordChangeEmailTokenResponse> {
    let homeserver_url = Url::parse(&default_homeserver_url)?;

    RUNTIME
        .spawn(async move {
            let client = SdkClient::new(homeserver_url).await?;
            let client_secret = ClientSecret::new();
            let request = request_password_change_token_via_email::v3::Request::new(
                client_secret,
                email,
                uint!(0),
            );
            let inner = client.send(request, None).await?;
            Ok(PasswordChangeEmailTokenResponse { inner })
        })
        .await?
}

#[derive(Clone)]
pub struct PasswordChangeEmailTokenResponse {
    inner: request_password_change_token_via_email::v3::Response,
}

impl PasswordChangeEmailTokenResponse {
    pub fn sid(&self) -> String {
        self.inner.sid.to_string()
    }

    pub fn submit_url(&self) -> OptionString {
        OptionString::new(self.inner.submit_url.clone())
    }
}

async fn request_password_change_token_via_email_without_login(
    default_homeserver_url: &str,
    email: &str,
) -> Result<()> {
    let http_client = ReqClientBuilder::new().build()?;
    let homeserver_url = Url::parse(default_homeserver_url)?;
    let submit_url =
        homeserver_url.join("/_matrix/client/v3/account/password/email/requestToken")?;

    let body = serde_json::json!({
        "client_secret": ClientSecret::new().to_string(),
        "email": email.to_owned(),
        "send_attempt": 0,
    });

    let resp = http_client
        .post(submit_url.to_string())
        .body(body.to_string())
        .send()
        .await?;

    info!(
        "request_password_change_token_via_email_without_login: {:?}",
        resp
    );

    if resp.status() != StatusCode::OK {
        let text = resp.text().await?;
        bail!(
            "request_password_change_token_via_email_without_login failed: {}",
            text
        );
    }

    Ok(())
}

pub async fn fetch_session_for_password_change(
    default_homeserver_url: &str,
) -> Result<FetchSessionForPasswordChangeResponse> {
    let http_client = ReqClientBuilder::new().build()?;
    let homeserver_url = Url::parse(default_homeserver_url)?;
    let submit_url = homeserver_url.join("/_matrix/client/v3/account/password")?;

    let body = serde_json::json!({});

    let resp = http_client
        .post(submit_url.to_string())
        .body(body.to_string())
        .send()
        .await?;

    info!("fetch_session_for_password_change: {:?}", resp);

    if resp.status() == StatusCode::UNAUTHORIZED {
        // it is expected because of not logged in
        let text = resp.text().await?;
        let res = serde_json::from_str::<FetchSessionForPasswordChangeResponse>(&text)?;
        return Ok(res);
    }

    let text = resp.text().await?;
    bail!("fetch_session_for_password_change failed: {}", text)
}

#[derive(Clone, Deserialize)]
struct PasswordChangeFlow {
    stages: Vec<String>,
}

#[derive(Clone, Deserialize)]
pub struct FetchSessionForPasswordChangeResponse {
    session: String,
    flows: Vec<PasswordChangeFlow>,
}

impl FetchSessionForPasswordChangeResponse {
    pub fn session(&self) -> String {
        self.session.clone()
    }

    pub fn has_flow(&self, stage: String) -> bool {
        self.flows.iter().any(|x| x.stages.contains(&stage))
    }
}

pub async fn change_password_without_login(
    default_homeserver_url: &str,
    new_val: &str,
    sid: String,
    client_secret: String,
    id_server: String,
    id_access_token: String,
    session: String,
) -> Result<()> {
    let http_client = ReqClientBuilder::new().build()?;
    let homeserver_url = Url::parse(default_homeserver_url)?;
    let submit_url = homeserver_url.join("/_matrix/client/v3/account/password")?;

    info!("change_password_without_login session: {}", &session);

    let body = serde_json::json!({
        "new_password": new_val.to_owned(),
        "logout_devices": false,
        "auth": {
            "threepid_creds": {
                "sid": sid,
                "client_secret": client_secret,
                "id_server": id_server,
                "id_access_token": id_access_token
            },
            "session": session,
            "type": "m.login.email.identity".to_owned()
        }
    });

    let resp = http_client
        .post(submit_url.to_string())
        .body(body.to_string())
        .send()
        .await?;

    info!("change_password_without_login: {:?}", resp);

    if resp.status() != StatusCode::OK {
        let text = resp.text().await?;
        bail!("change_password_without_login failed: {}", text);
    }

    Ok(())
}

pub async fn reset_password_1st_stage(
    default_homeserver_url: String,
    email: String,
    new_val: String,
) -> Result<PasswordResetFirstResponse> {
    let homeserver_url = Url::parse(&default_homeserver_url)?;

    RUNTIME
        .spawn(async move {
            let resp = request_password_change_token_via_email_without_login(
                &default_homeserver_url,
                &email,
            )
            .await?;

            let client = SdkClient::new(homeserver_url).await?; // not-logged-in
            let account = client.account();

            // first calling of password change api
            info!("change_password before");
            if let Err(e) = client.account().change_password(&new_val, None).await {
                info!("change_password after");
                let Some(inf) = e.as_uiaa_response() else {
                    info!("change_password uiaa response failed: {:?}", e);
                    return Err(clearify_error(e));
                };

                // request 3pid token
                let client_secret = ClientSecret::new();
                let req = request_password_change_token_via_email::v3::Request::new(
                    client_secret.clone(),
                    email,
                    uint!(0),
                );
                let inner = client.send(req, None).await?;

                return Ok(PasswordResetFirstResponse {
                    client_secret,
                    session: inf.session.clone(),
                    inner,
                });
            }

            bail!("couldn't get a set of flows from change_password");
        })
        .await?
}

#[derive(Clone)]
pub struct PasswordResetFirstResponse {
    client_secret: OwnedClientSecret,
    session: Option<String>,
    inner: request_password_change_token_via_email::v3::Response,
}

impl PasswordResetFirstResponse {
    pub fn client_secret(&self) -> String {
        self.client_secret.to_string()
    }

    pub fn session(&self) -> Option<String> {
        self.session.clone()
    }

    pub fn sid(&self) -> String {
        self.inner.sid.to_string()
    }

    pub fn submit_url(&self) -> OptionString {
        OptionString::new(self.inner.submit_url.clone())
    }
}

pub async fn reset_password_2nd_stage(
    default_homeserver_url: String,
    sid: String,
    client_secret: String,
    id_server: String,
    id_access_token: String,
    session: Option<String>,
    new_val: String,
) -> Result<()> {
    let homeserver_url = Url::parse(&default_homeserver_url)?;
    let sid = SessionId::parse(&sid)?;
    let client_secret = ClientSecret::parse_box(client_secret.as_str())?;

    RUNTIME
        .spawn(async move {
            let client = SdkClient::new(homeserver_url).await?;
            let account = client.account();

            // second calling of password change api
            let thirdparty_id_creds =
                ThirdpartyIdCredentials::new(sid, client_secret, id_server, id_access_token);
            let email_ident = assign!(EmailIdentity::new(thirdparty_id_creds), {
                session,
            });
            let auth_data = AuthData::EmailIdentity(email_ident);
            account
                .change_password(&new_val, Some(auth_data))
                .await
                .map_err(clearify_error)?;

            Ok(())
        })
        .await?
}

impl Client {
    pub async fn deactivate(&self, password: String) -> Result<bool> {
        let account = self.account()?;
        RUNTIME
            .spawn(async move {
                if let Err(e) = account.deref().deactivate(None, None).await {
                    if let Some(resp) = e.as_uiaa_response() {
                        let pswd = assign!(Password::new(account.user_id().into(), password), {
                            session: resp.session.clone(),
                        });
                        let auth_data = AuthData::Password(pswd);
                        account.deref().deactivate(None, Some(auth_data)).await?;
                        // FIXME: remove local data, too!
                    } else {
                        error!(?e, "Not a UIAA response");
                        bail!("No a uiaa response");
                    }
                }
                Ok(true)
            })
            .await?
    }

    pub async fn change_password(&self, old_val: String, new_val: String) -> Result<bool> {
        let client = self.core.client().clone();
        let account = self.account()?;
        RUNTIME
            .spawn(async move {
                let capabilities = client.get_capabilities().await?;
                if !capabilities.change_password.enabled {
                    bail!("Server doesn't support password change");
                }
                if let Err(e) = account.deref().change_password(&new_val, None).await {
                    let Some(inf) = e.as_uiaa_response() else {
                        return Err(clearify_error(e));
                    };
                    let pswd = assign!(Password::new(account.user_id().into(), old_val), {
                        session: inf.session.clone(),
                    });
                    let auth_data = AuthData::Password(pswd);
                    account
                        .deref()
                        .change_password(&new_val, Some(auth_data))
                        .await
                        .map_err(clearify_error)?;
                }
                Ok(true)
            })
            .await?
    }
}
