use futures::Stream;
use anyhow::Result;
use matrix_sdk::{
    Client as MatrixClient,
    Session,
    ruma::{UserId},
};
use lazy_static::lazy_static;
use tokio::runtime;
use url::Url;
use log::warn;
use serde_json;

use serde::{Serialize, Deserialize};

#[cfg(target_os = "android")]
use crate::android as platform;

#[cfg(not(target_os = "android"))]
mod platform {
    pub(super) fn new_client_config(base_path: String, home: String) -> anyhow::Result<matrix_sdk::config::ClientConfig> {
        anyhow::bail!("not implemented for current platform")
    }
    pub(super) fn init_logging(filter: Option<String>) -> anyhow::Result<()> {
        anyhow::bail!("not implemented for current platform")
    }
}


lazy_static! {
    static ref RUNTIME: runtime::Runtime =
        runtime::Runtime::new().expect("Can't start Tokio runtime");
}

ffi_gen_macro::ffi_gen!("native/effektio/api.rsh");

pub struct Client(MatrixClient);

#[derive(Serialize, Deserialize)]
struct RestoreToken {
    homeurl: String,
    session: Session,
}

impl Client {

    pub async fn logged_in(&self) -> bool {
        self.0.logged_in().await
    }

    pub async fn restore_token(&self) -> Result<String> {
        let session = self.0.session().await.expect("Missing session");
        let homeurl = self.0.homeserver().await.into();
        Ok(serde_json::to_string(&RestoreToken {
            session, homeurl
        })?)
    }

}

pub async fn login_with_token(base_path: String, restore_token: String) -> Result<Client> {
    let RestoreToken { session, homeurl } = serde_json::from_str(&restore_token)?;
    let homeserver = Url::parse(&homeurl)?;
    let config = platform::new_client_config(base_path, session.user_id.to_string())?;
    // First we need to log in.
    RUNTIME.spawn(async move {
        let client = MatrixClient::new_with_config(homeserver, config)?;
        client.restore_login(session).await?;
        Ok(Client(client))
    }).await?
}


pub async fn login_new_client(base_path: String, username: String, password: String) -> Result<Client> {
    let config = platform::new_client_config(base_path, username.clone())?;
    let user = Box::<UserId>::try_from(username)?;
    // First we need to log in.
    RUNTIME.spawn(async move {
        let client = MatrixClient::new_from_user_id_with_config(&user, config).await?;
        client.login(user, &password, None, None).await?;
        Ok(Client(client))
    }).await?
}

pub fn echo(inp: String) -> Result<String> {
    Ok(String::from(inp))
}

fn init_logging(filter: Option<String>) -> Result<()> {
    platform::init_logging(filter)?;
    Ok(())
}
