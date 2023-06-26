//! Testing modules, don't use in production!

use anyhow::{bail, Result};
use core::{future::Future, time::Duration};
use matrix_sdk::{
    ruma::{
        api::client::{
            account::register::v3::Request as RegistrationRequest, room::Visibility, uiaa,
        },
        assign, OwnedUserId,
    },
    Client as SdkClient, ClientBuilder,
};
use matrix_sdk_base::store::{MemoryStore, StoreConfig};
use tokio::time::sleep;
use tracing::info;

use crate::{api::register_with_token_under_config, register_under_config, sanitize_user, Client};

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
    let builder = SdkClient::builder()
        .user_agent(user_agent)
        .store_config(store_cfg)
        .homeserver_url(homeserver);
    Ok(builder)
}

pub async fn ensure_user(
    homeserver_url: String,
    homeserver_name: String,
    username: String,
    reg_token: Option<String>,
    user_agent: String,
    store_config: StoreConfig,
) -> Result<Client> {
    let (user_id, config) = {
        let (user_id, fallback_to_default_homeserver) =
            sanitize_user(&username, &homeserver_name).await?;
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

    let Err(e) = login_res else {
        return Client::new(cl, Default::default()).await
    };

    if let Some(token) = reg_token {
        info!("Login for {username} failed: {e}. Trying to register with token instead.");
        register_with_token_under_config(
            config.clone(),
            user_id,
            password.clone(),
            user_agent.clone(),
            token,
        )
        .await
    } else {
        info!("Login for {username} failed: {e}. Trying to register instead.");
        register_under_config(
            config.clone(),
            user_id,
            password.clone(),
            user_agent.clone(),
        )
        .await
    }
}
