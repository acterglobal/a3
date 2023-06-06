//! Testing modules, don't use in production!

use acter_core::{
    matrix_sdk::{Client, ClientBuilder},
    ruma::{
        api::client::{
            account::register::v3::Request as RegistrationRequest, room::Visibility, uiaa,
        },
        assign, OwnedUserId,
    },
};
use anyhow::{bail, Result};
use core::{future::Future, time::Duration};
use matrix_sdk_base::store::{MemoryStore, StoreConfig};
use tokio::time::sleep;

use crate::{
    api::register_with_token_under_config, register_under_config, sanatize_user,
    Client as EfkClient,
};

/// testing helper to give a task time to finish
///
/// alias for `wait_for_secs(3, 1, fun).await` - running up to 3 times with 1 second sleep
/// in between
pub async fn wait_for<F, T, O>(fun: F) -> Result<Option<T>>
where
    F: Fn() -> O,
    O: Future<Output = Result<Option<T>>>,
{
    wait_for_secs(3, 1, fun).await
}

/// testing helper to give a task time to finish
///
/// Will call `fun().await` up to `count` times, checking wether that returned `Ok(Some(T))` and
/// return `Ok(Some(T))` if it does. Sleep up to `secs` seconds in between each call. Return `Ok(None)`
/// if even after all that time, it didn't succeed. Passes on any internally raised error
pub async fn wait_for_secs<F, T, O>(count: u32, secs: u8, fun: F) -> Result<Option<T>>
where
    F: Fn() -> O,
    O: Future<Output = Result<Option<T>>>,
{
    let duration = Duration::from_secs(secs as u64);
    let mut remaining = count;
    loop {
        if let Some(t) = fun().await? {
            return Ok(Some(t));
        }
        let Some(new) = remaining.checked_sub(1)  else {
            break
        };
        remaining = new;
        sleep(duration).await;
    }
    Ok(None)
}

pub async fn default_client_config(
    homeserver: &str,
    username: &str,
    user_agent: String,
    store_cfg: StoreConfig,
) -> Result<ClientBuilder> {
    Ok(Client::builder()
        .user_agent(user_agent)
        .store_config(store_cfg)
        .homeserver_url(homeserver))
}

pub async fn ensure_user(
    homeserver_url: String,
    homeserver_name: String,
    username: String,
    reg_token: Option<String>,
    user_agent: String,
    store_config: StoreConfig,
) -> Result<EfkClient> {
    let (user_id, config) = {
        let (user_id, fallback_to_default_homeserver) =
            sanatize_user(&username, &homeserver_name).await?;
        let mut config = default_client_config(
            &homeserver_url,
            &username,
            user_agent.clone(),
            store_config.clone(),
        )
        .await?;

        if fallback_to_default_homeserver {
            (user_id, config.homeserver_url(homeserver_url.clone()))
        } else {
            (user_id.clone(), config.server_name(user_id.server_name()))
        }
    };

    let with_token = reg_token.is_some();
    let password = match &reg_token {
        Some(token) => format!("{token}:{username}"),
        None => username.clone(),
    };

    let cl = config.clone().build().await?;
    let login_res = cl.login_username(username.clone(), &password).send().await;

    if let Err(e) = login_res {
        log::warn!("Login for {username} failed: {e}. Trying to register instead.");
        let client = if let Some(token) = reg_token {
            register_with_token_under_config(
                config.clone(),
                username.clone(),
                password.clone(),
                user_agent.clone(),
                token,
            )
            .await?
        } else {
            register_under_config(
                config.clone(),
                username.clone(),
                username.clone(),
                user_agent.clone(),
            )
            .await?
        };
        client
            .login_username(username.clone(), &username)
            .send()
            .await?;
        Ok(client)
    } else {
        // login went fine
        EfkClient::new(cl, Default::default()).await
    }
}
