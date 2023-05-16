use acter_core::{
    ruma::{
        api::client::{account::register, session::login, uiaa},
        assign, OwnedUserId,
    },
    RestoreToken,
};
use anyhow::{bail, Context, Result};
use log::info;
use matrix_sdk::{ClientBuilder, Session};

use crate::platform;

use super::{
    client::{Client, ClientStateBuilder},
    RUNTIME,
};

// for only integration test, not api.rsh
pub async fn make_client_config(
    base_path: String,
    username: &str,
    default_homeserver_name: &str,
    default_homeserver_url: &str,
) -> Result<(ClientBuilder, OwnedUserId)> {
    let formatted_username = if !username.starts_with('@') {
        format!("@{username}")
    } else {
        username.to_owned()
    };

    // fully qualified username, good to go
    if let Ok(user_id) = OwnedUserId::try_from(formatted_username.as_str()) {
        let builder = platform::new_client_config(base_path, user_id.to_string(), true)
            .await?
            .server_name(user_id.server_name());
        return Ok((builder, user_id));
    }

    // we need to fallback to the testing/default scenario
    let user_id = OwnedUserId::try_from(format!("{formatted_username}:{default_homeserver_name}"))?;
    let builder = platform::new_client_config(base_path, user_id.to_string(), true)
        .await?
        .homeserver_url(default_homeserver_url);
    Ok((builder, user_id))
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
            let mut request = register::v3::Request::new();
            request.kind = register::RegistrationKind::Guest;
            request.initial_device_display_name = device_name;
            let response = client.register(request).await?;
            let device_id = response
                .device_id
                .clone()
                .context("device id is given by server")?;
            let session = Session {
                access_token: response.access_token.context("no access token given")?,
                user_id: response.user_id.clone(),
                refresh_token: response.refresh_token.clone(),
                device_id,
            };
            client.restore_session(session).await?;
            let state = ClientStateBuilder::default().is_guest(true).build().context("building failed in client state")?;
            let c = Client::new(client, state).await?;
            info!("Successfully created guest login: {:?}", response.user_id);
            Ok(c)
        })
        .await?
}

// for only integration test, not api.rsh
pub async fn login_with_token_under_config(
    restore_token: String,
    config: ClientBuilder,
) -> Result<Client> {
    let RestoreToken {
        session,
        homeurl,
        is_guest,
    } = serde_json::from_str(&restore_token).context("Deserializing Restore Token failed")?;
    let user_id = session.user_id.to_string();
    // First we need to log in.
    RUNTIME
        .spawn(async move {
            let client = config
                .homeserver_url(homeurl)
                .build()
                .await
                .context("building client from config failed")?;
            client
                .restore_session(session)
                .await
                .context("restoring failed")?;
            let state = ClientStateBuilder::default()
                .is_guest(is_guest)
                .build()
                .context("building client state builder failed")?;
            let c = Client::new(client.clone(), state).await?;
            info!(
                "Successfully logged in user {:?}, device {:?} with token.",
                user_id,
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
    } = serde_json::from_str(&restore_token).context("Deserializing Restore Token failed")?;
    let user_id = session.user_id.to_string();
    let config = platform::new_client_config(base_path, user_id.clone(), false)
        .await
        .context("can't build client")?;
    login_with_token_under_config(restore_token, config).await
}

// for only integration test, not api.rsh
pub async fn login_new_client_under_config(
    config: ClientBuilder,
    user_id: OwnedUserId,
    password: String,
    device_name: Option<String>,
) -> Result<Client> {
    RUNTIME
        .spawn(async move {
            let client = config.build().await?;
            let mut login_builder = client.login_username(&user_id, &password);
            let name; // to capture the inner string for login-builder lifetime
            if let Some(s) = device_name {
                name = s;
                login_builder = login_builder.initial_device_display_name(name.as_str())
            };
            login_builder.send().await?;
            let state = ClientStateBuilder::default().is_guest(false).build().context("building failed in client state")?;
            let c = Client::new(client.clone(), state).await?;
            info!(
                "Successfully logged in user {:?}, device {:?}",
                user_id,
                client.device_id(),
            );
            Ok(c)
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

pub async fn register_with_token(
    base_path: String,
    username: String,
    password: String,
    registration_token: String,
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
    // First we need to log in.
    RUNTIME
        .spawn(async move {
            let client = config.build().await?;
            let Err(err) = client.register(register::v3::Request::new()).await else {
                bail!("Server is not set up to allow registration.");
            };
            let Some(response) = err.as_uiaa_response() else {
                bail!("Server did not indicate how to allow registration.");
            };

            // FIXME: do actually check the registration types...
            let request = assign!(register::v3::Request::new(), {
                username: Some(username.clone()),
                password: Some(password),
                initial_device_display_name: device_name,
                auth: Some(uiaa::AuthData::RegistrationToken(
                    uiaa::RegistrationToken::new(registration_token),
                )),
            });
            client.register(request).await?;

            let state = ClientStateBuilder::default().is_guest(false).build().context("building failed in client state")?;
            let c = Client::new(client.clone(), state).await?;
            info!(
                "Successfully registered user {:?}, device {:?}",
                username,
                client.device_id(),
            );
            Ok(c)
        })
        .await?
}
