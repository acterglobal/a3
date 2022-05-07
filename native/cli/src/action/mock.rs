use anyhow::Result;
use clap::{crate_version, Parser};

use effektio_core::ruma;
use effektio_core::matrix_sdk::{Client, ClientBuilder};

use ruma::{
    api::client::{
        account::register::{v3::Request as RegistrationRequest},
        uiaa,
    },
    assign,
};

fn default_client_config(homeserver: &str) -> Result<ClientBuilder> {
    Ok(
        Client::builder()
        .user_agent(&format!("effektio-cli/{}", crate_version!()))
        .homeserver_url(homeserver)
    )
}

async fn register(homeserver: &str, username: &str, password: &str) -> Result<Client>{
    let client = default_client_config(homeserver)?.build().await?;

    let request = assign!(RegistrationRequest::new(), {
        username: Some(username),
        password: Some(password),
        
        auth: Some(uiaa::AuthData::FallbackAcknowledgement(
            uiaa::FallbackAcknowledgement::new("foobar"),
        )),
    });
    client.register(request).await?;
    Ok(client)

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

        let sisko = register(&homeserver, "sisko", "sisko").await?;
        let kyra = register(&homeserver, "kyra", "kyra").await?;
        let worf = register(&homeserver, "worf", "worf").await?;
        let bashir = register(&homeserver, "bashir", "bashir").await?;
        let miles = register(&homeserver, "miles", "miles").await?;
        let dax = register(&homeserver, "dax", "dax").await?;

        Ok(())
    }
}