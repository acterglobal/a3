//! Testing modules, don't use in production!

use anyhow::{bail, Result};
use core::{future::Future, time::Duration};
use effektio_core::{
    matrix_sdk::{Client, ClientBuilder},
    ruma::{
        api::client::{
            account::register::v3::Request as RegistrationRequest, room::Visibility, uiaa,
        },
        assign, OwnedUserId,
    },
};
use matrix_sdk_base::store::{MemoryStore, StoreConfig};
use tokio::time::sleep;

use crate::Client as EfkClient;

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

pub async fn register(
    homeserver: &str,
    username: String,
    user_agent: String,
    store_config: StoreConfig,
) -> Result<Client> {
    let client = default_client_config(homeserver, &username, user_agent, store_config)
        .await?
        .build()
        .await?;
    if let Err(resp) = client.register(RegistrationRequest::new()).await {
        // FIXME: do actually check the registration types...
        if let Some(_response) = resp.as_uiaa_response() {
            let request = assign!(RegistrationRequest::new(), {
                username: Some(username.clone()),
                password: Some(username),

                auth: Some(uiaa::AuthData::Dummy(uiaa::Dummy::new())),
            });
            client.register(request).await?;
        } else {
            tracing::error!(?resp, "Not a UIAA response");
            bail!("No a uiaa response");
        }
    }

    Ok(client)
}

pub async fn ensure_user(
    homeserver: &str,
    username: String,
    user_agent: String,
    store_config: StoreConfig,
) -> Result<EfkClient> {
    let cl = match register(
        homeserver,
        username.clone(),
        user_agent.clone(),
        store_config.clone(),
    )
    .await
    {
        Ok(cl) => cl,
        Err(e) => {
            tracing::warn!("Could not register {:}, {:}", username, e);
            default_client_config(homeserver, &username, user_agent, store_config)
                .await?
                .build()
                .await?
        }
    };
    cl.login_username(username.clone(), &username)
        .send()
        .await?;

    EfkClient::new(cl, Default::default()).await
}
