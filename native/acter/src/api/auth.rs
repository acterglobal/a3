use acter_core::RestoreToken;
use anyhow::{bail, Context, Result};
use lazy_static::lazy_static;
use matrix_sdk::{
    matrix_auth::{MatrixSession, MatrixSessionTokens},
    Client as SdkClient, ClientBuilder, SessionMeta,
};
use ruma::assign;
use ruma_client_api::{
    account::register,
    uiaa::{AuthData, Dummy, Password, RegistrationToken},
};
use ruma_common::{OwnedUserId, UserId};
use std::sync::RwLock;
use tracing::{error, info};
use uuid::Uuid;

use super::{
    client::{Client, ClientStateBuilder},
    RUNTIME,
};
use crate::platform;

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
) -> Result<(ClientBuilder, OwnedUserId)> {
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
    config: ClientBuilder,
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
    config: ClientBuilder,
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
    config: ClientBuilder,
    user_id: OwnedUserId,
    password: String,
    db_passphrase: Option<String>,
    user_agent: String,
) -> Result<Client> {
    RUNTIME
        .spawn(async move {
            let client = config.build().await?;
            if let Err(resp) = client
                .matrix_auth()
                .register(register::v3::Request::new())
                .await
            {
                // FIXME: do actually check the registration types...
                if resp.as_uiaa_response().is_some() {
                    let request = assign!(register::v3::Request::new(), {
                        username: Some(user_id.localpart().to_owned()),
                        password: Some(password.clone()),
                        initial_device_display_name: Some(user_agent.clone()),
                        auth: Some(AuthData::Dummy(Dummy::new())),
                    });
                    client.matrix_auth().register(request).await?;
                } else {
                    error!(?resp, "Not a UIAA response");
                    bail!("No a uiaa response");
                }
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
    config: ClientBuilder,
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

            if let Err(err) = client.matrix_auth().register(request).await {
                let response = err
                    .as_uiaa_response()
                    .context("Server did not indicate how to allow registration.")?;

                info!("Acceptable auth flows: {response:?}");

                // FIXME: do actually check the registration types...
                let token_request = assign!(register::v3::Request::new(), {
                    auth: Some(AuthData::RegistrationToken(
                        assign!(RegistrationToken::new(registration_token), {
                            session: response.session.clone(),
                        }),
                    )),
                });
                client.matrix_auth().register(token_request).await?;
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

impl Client {
    pub async fn deactivate(&self, password: String) -> Result<bool> {
        // ToDo: make this a proper User-Interactive Flow rather than hardcoded for
        //       password-only instance.
        let account = self.account()?;
        RUNTIME
            .spawn(async move {
                let auth_data =
                    AuthData::Password(Password::new(account.user_id().into(), password.clone()));
                account.deactivate(None, Some(auth_data)).await?;
                // FIXME: remove local data, too!
                Ok(true)
            })
            .await?
    }
}
