use anyhow::Result;
use clap::{crate_version, Parser};

use effektio_core::matrix_sdk::{Client, ClientBuilder};
use effektio_core::ruma;

use ruma::{
    api::client::{account::register::v3::Request as RegistrationRequest, uiaa},
    assign,
};

use std::time::Duration;
use tokio::time::sleep;

fn default_client_config(homeserver: &str) -> Result<ClientBuilder> {
    Ok(Client::builder()
        .user_agent(&format!("effektio-cli/{}", crate_version!()))
        .homeserver_url(homeserver))
}

async fn register(homeserver: &str, username: &str, password: &str) -> Result<Client> {
    let client = default_client_config(homeserver)?.build().await?;
    if let Err(resp) = client.register(RegistrationRequest::new()).await {
        if let Some(response) = resp.uiaa_response() {
            let request = assign!(RegistrationRequest::new(), {
                username: Some(username),
                password: Some(password),

                auth: Some(uiaa::AuthData::Dummy(uiaa::Dummy::new())),
            });
            client.register(request).await?;
        }
    }

    Ok(client)
}

async fn ensure_user(homeserver: &str, username: &str, password: &str) -> Result<Client> {
    match register(homeserver, username, password).await {
        Ok(cl) => Ok(cl),
        Err(e) => {
            log::warn!("Could not register {:}, {:}", username, e);
            let c = default_client_config(homeserver)?.build().await?;
            c.login(username, password, None, None).await?;
            Ok(c)
        }
    }
}

/// Posting a news item to a given room
#[derive(Parser, Debug)]
pub struct Mock {
    #[clap()]
    pub homeserver: String,
}

impl Mock {
    pub async fn run(&self) -> Result<()> {
        let homeserver = self.homeserver.as_str();

        // FIXME: would be better if we used the effektio API for this...

        let _sisko = ensure_user(homeserver, "sisko", "sisko").await?;
        sleep(Duration::from_millis(300)).await;
        let _kyra = ensure_user(homeserver, "kyra", "kyra").await?;
        sleep(Duration::from_millis(300)).await;
        let _worf = ensure_user(homeserver, "worf", "worf").await?;
        sleep(Duration::from_millis(300)).await;
        let _bashir = ensure_user(homeserver, "bashir", "bashir").await?;
        sleep(Duration::from_millis(300)).await;
        // let _miles = ensure_user(homeserver, "miles", "miles").await?;
        // sleep(Duration::from_millis(300)).await;
        // let _dax = ensure_user(homeserver, "dax", "dax").await?;
        // sleep(Duration::from_millis(300)).await;

        Ok(())
    }
}
