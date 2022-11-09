use anyhow::{bail, Context, Result};
use assign::assign;
use effektio_core::{
    ruma::api::client::{account::register, session::login, uiaa},
    RestoreToken,
};
use log::info;
use matrix_sdk::Session;

use crate::platform;

use super::{
    client::{Client, ClientStateBuilder},
    device, RUNTIME,
};

pub async fn guest_client(
    base_path: String,
    homeurl: String,
    device_name: Option<String>,
) -> Result<Client> {
    let config = platform::new_client_config(base_path, homeurl.clone())?.homeserver_url(homeurl);
    RUNTIME
        .spawn(async move {
            let client = config.build().await?;
            let mut request = register::v3::Request::new();
            request.kind = register::RegistrationKind::Guest;
            request.initial_device_display_name = device_name.as_deref();
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
            client.restore_login(session).await?;
            let state = ClientStateBuilder::default()
                .is_guest(true)
                .build()
                .unwrap();
            let c = Client::new(client, state);
            info!("Successfully created guest login: {:?}", response.user_id);
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
    let config = platform::new_client_config(base_path, session.user_id.to_string())?
        .homeserver_url(homeurl);
    // First we need to log in.
    RUNTIME
        .spawn(async move {
            let client = config.build().await?;
            let user_id = session.user_id.to_string();
            client.restore_login(session).await?;
            let state = ClientStateBuilder::default()
                .is_guest(is_guest)
                .build()
                .unwrap();
            let c = Client::new(client.clone(), state);
            info!(
                "Successfully logged in user {:?}, device {:?} with token.",
                user_id,
                client.device_id(),
            );
            Ok(c)
        })
        .await?
}

pub async fn login_new_client(
    base_path: String,
    username: String,
    password: String,
    device_name: Option<String>,
) -> Result<Client> {
    let user_id = effektio_core::ruma::OwnedUserId::try_from(username.clone())?;
    let mut config =
        platform::new_client_config(base_path, username)?.server_name(user_id.server_name());

    match user_id.server_name().as_str() {
        "effektio.org" => {
            // effektio.org has problems with the .well-known-setup at the moment
            config = config.homeserver_url("https://matrix.effektio.org");
        }
        "ds9.effektio.org" => {
            // this is our local CI test environment
            let url = option_env!("HOMESERVER").unwrap_or("http://localhost:8118");
            config = config.homeserver_url(url);
        }
        _ => {}
    };

    // First we need to log in.
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
            let state = ClientStateBuilder::default()
                .is_guest(false)
                .build()
                .unwrap();
            let c = Client::new(client.clone(), state);
            info!(
                "Successfully logged in user {:?}, device {:?}",
                user_id,
                client.device_id(),
            );
            Ok(c)
        })
        .await?
}

pub async fn register_with_registration_token(
    base_path: String,
    username: String,
    password: String,
    registration_token: String,
    device_name: Option<String>,
) -> Result<Client> {
    let user_id = effektio_core::ruma::OwnedUserId::try_from(username.clone())?;
    let config = platform::new_client_config(base_path, username.clone())?
        .server_name(user_id.server_name());
    // First we need to log in.
    RUNTIME
        .spawn(async move {
            let client = config.build().await?;
            if let Err(err) = client.register(register::v3::Request::new()).await {
                if let Some(response) = err.uiaa_response() {
                    // FIXME: do actually check the registration types...
                    let request = assign!(register::v3::Request::new(), {
                        username: Some(&username),
                        password: Some(&password),
                        initial_device_display_name: device_name.as_deref(),
                        auth: Some(uiaa::AuthData::RegistrationToken(
                            uiaa::RegistrationToken::new(&registration_token),
                        )),
                    });
                    client.register(request).await?;
                } else {
                    bail!("Server did not indicate how to  allow registration.");
                }
            } else {
                bail!("Server is not set up to allow registration.");
            }
            let state = ClientStateBuilder::default()
                .is_guest(false)
                .build()
                .unwrap();
            let c = Client::new(client.clone(), state);
            info!(
                "Successfully registered user {:?}, device {:?}",
                username,
                client.device_id(),
            );
            Ok(c)
        })
        .await?
}
