//! Testing modules, don't use in production!

use anyhow::Result;
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

use crate::Client as EfkClient;

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
            anyhow::bail!("No a uiaa response");
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
