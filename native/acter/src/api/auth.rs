use acter_core::RestoreToken;
use anyhow::{bail, Context, Result};
use matrix_sdk::{
    matrix_auth::{MatrixSession, MatrixSessionTokens},
    ruma::{
        api::client::{
            account::register::{v3::Request as RegisterRequest, RegistrationKind},
            uiaa::{AuthData, Dummy, Password, RegistrationToken},
        },
        assign,
    },
    Client as SdkClient, ClientBuilder, SessionMeta, SessionTokens,
};
use ruma_common::OwnedUserId;
use tracing::{error, info};

use super::{
    client::{Client, ClientStateBuilder},
    RUNTIME,
};
use crate::platform;

// public for only integration test, not api.rsh
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
    if let Ok(user_id) = OwnedUserId::try_from(formatted_username.as_str()) {
        return Ok((user_id, false));
    }

    // we need to fallback to the testing/default scenario
    let user_id = OwnedUserId::try_from(format!("{formatted_username}:{default_homeserver_name}"))?;

    Ok((user_id, true))
}

pub async fn destroy_local_data(
    base_path: String,
    username: String,
    default_homeserver_name: String,
) -> Result<bool> {
    let (user_id, fallback) = sanitize_user(&username, &default_homeserver_name).await?;
    platform::destroy_local_data(base_path, user_id.to_string()).await
}

// public for only integration test, not api.rsh
pub async fn make_client_config(
    base_path: String,
    username: &str,
    default_homeserver_name: &str,
    default_homeserver_url: &str,
) -> Result<(ClientBuilder, OwnedUserId)> {
    let (user_id, fallback) = sanitize_user(username, default_homeserver_name).await?;
    let builder = platform::new_client_config(base_path, user_id.to_string(), true).await?;
    if fallback {
        Ok((builder.homeserver_url(default_homeserver_url), user_id))
    } else {
        // we need to fallback to the testing/default scenario
        return Ok((builder.server_name(user_id.server_name()), user_id));
    }
}

pub async fn guest_client(
    base_path: String,
    default_homeserver_name: String,
    default_homeserver_url: String,
    device_name: Option<String>,
) -> Result<Client> {
    let config = platform::new_client_config(base_path, default_homeserver_name, true)
        .await?
        .homeserver_url(default_homeserver_url);
    RUNTIME
        .spawn(async move {
            let client = config.build().await?;
            let request = assign!(RegisterRequest::new(), {
                kind: RegistrationKind::Guest,
                initial_device_display_name: device_name,
            });
            let response = client.matrix_auth().register(request).await?;
            let device_id = response
                .device_id
                .clone()
                .context("device id is given by server")?;
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
            let state = ClientStateBuilder::default().is_guest(true).build()?;
            let c = Client::new(client, state).await?;
            info!("Successfully created guest login: {:?}", response.user_id);
            Ok(c)
        })
        .await?
}

// public for only integration test, not api.rsh
pub async fn login_with_token_under_config(
    restore_token: String,
    config: ClientBuilder,
) -> Result<Client> {
    let RestoreToken {
        session,
        homeurl,
        is_guest,
    } = serde_json::from_str(&restore_token)?;
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
            let state = ClientStateBuilder::default().is_guest(is_guest).build()?;
            let c = Client::new(client.clone(), state).await?;
            info!(
                "Successfully logged in user {user_id}, device {:?} with token.",
                client.device_id(),
            );
            Ok(c)
        })
        .await?
}

pub async fn login_with_token(base_path: String, restore_token: String) -> Result<Client> {
    let RestoreToken {
        session,
        homeurl,
        is_guest,
    } = serde_json::from_str(&restore_token)?;
    let config = platform::new_client_config(base_path, session.user_id.to_string(), false).await?;
    login_with_token_under_config(restore_token, config).await
}

async fn login_client(
    client: SdkClient,
    user_id: OwnedUserId,
    password: String,
    device_name: Option<String>,
) -> Result<Client> {
    let mut login_builder = client.matrix_auth().login_username(&user_id, &password);
    let name; // to capture the inner string for login-builder lifetime
    if let Some(s) = device_name {
        name = s;
        login_builder = login_builder.initial_device_display_name(name.as_str())
    };
    login_builder.send().await?;
    let state = ClientStateBuilder::default().is_guest(false).build()?;
    info!(
        "Successfully logged in user {user_id}, device {:?}",
        client.device_id(),
    );
    Client::new(client.clone(), state).await
}

// public for only integration test, not api.rsh
pub async fn login_new_client_under_config(
    config: ClientBuilder,
    user_id: OwnedUserId,
    password: String,
    device_name: Option<String>,
) -> Result<Client> {
    RUNTIME
        .spawn(async move {
            login_client(config.build().await?, user_id, password, device_name).await
        })
        .await?
}

pub async fn smart_login(
    base_path: String,
    username: String,
    password: String,
    default_homeserver_name: String,
    default_homeserver_url: String,
    device_name: Option<String>,
) -> Result<Client> {
    let (config, user_id) = make_client_config(
        base_path,
        &username,
        &default_homeserver_name,
        &default_homeserver_url,
    )
    .await?;
    login_new_client_under_config(config, user_id, password, device_name).await
}

pub async fn login_new_client(
    base_path: String,
    username: String,
    password: String,
    default_homeserver_name: String,
    default_homeserver_url: String,
    device_name: Option<String>,
) -> Result<Client> {
    let (config, user_id) = make_client_config(
        base_path,
        &username,
        &default_homeserver_name,
        &default_homeserver_url,
    )
    .await?;
    login_new_client_under_config(config, user_id, password, device_name).await
}

pub async fn register(
    base_path: String,
    username: String,
    password: String,
    user_agent: String,
    registration_token: String,
    default_homeserver_name: String,
    default_homeserver_url: String,
) -> Result<Client> {
    let (config, user_id) = make_client_config(
        base_path,
        &username,
        &default_homeserver_name,
        &default_homeserver_url,
    )
    .await?;
    register_under_config(config, user_id, password, user_agent).await
}

pub async fn register_under_config(
    config: ClientBuilder,
    user_id: OwnedUserId,
    password: String,
    user_agent: String,
) -> Result<Client> {
    RUNTIME
        .spawn(async move {
            let client = config.build().await?;
            if let Err(resp) = client.matrix_auth().register(RegisterRequest::new()).await {
                // FIXME: do actually check the registration types...
                if resp.as_uiaa_response().is_some() {
                    let request = assign!(RegisterRequest::new(), {
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

            login_client(client, user_id, password, Some(user_agent)).await
        })
        .await?
}

pub async fn register_with_token(
    base_path: String,
    username: String,
    password: String,
    registration_token: String,
    default_homeserver_name: String,
    default_homeserver_url: String,
    user_agent: String,
) -> Result<Client> {
    let (config, user_id) = make_client_config(
        base_path,
        &username,
        &default_homeserver_name,
        &default_homeserver_url,
    )
    .await?;
    register_with_token_under_config(config, user_id, password, user_agent, registration_token)
        .await
}

pub async fn register_with_token_under_config(
    config: ClientBuilder,
    user_id: OwnedUserId,
    password: String,
    user_agent: String,
    registration_token: String,
) -> Result<Client> {
    // First we need to log in.
    RUNTIME
        .spawn(async move {
            let client = {
                let client = config.build().await?;
                let request = assign!(RegisterRequest::new(), {
                    username: Some(user_id.localpart().to_owned()),
                    password: Some(password.clone()),
                    initial_device_display_name: Some(user_agent.clone()),
                    auth: Some(AuthData::Dummy(Dummy::new())),
                });

                if let Err(err) = client.matrix_auth().register(request).await {
                    let Some(response) = err.as_uiaa_response() else {
                        bail!("Server did not indicate how to allow registration.");
                    };

                    info!("Acceptable auth flows: {response:?}");

                    // FIXME: do actually check the registration types...
                    let token_request = assign!(RegisterRequest::new(), {
                        auth: Some(AuthData::RegistrationToken(
                            assign!(RegistrationToken::new(registration_token), {
                                session: response.session.clone(),
                            }),
                        )),
                    });
                    client.matrix_auth().register(token_request).await?;
                } // else all went well.
                client
            };

            login_client(client, user_id, password, Some(user_agent)).await
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
                Ok(true)
            })
            .await?
    }
}
