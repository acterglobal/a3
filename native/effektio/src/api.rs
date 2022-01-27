use futures::Stream;
use anyhow::Result;
use matrix_sdk::{
    Client as MatrixClient,
    Session,
    media::{MediaRequest, MediaFormat, MediaType},
};
pub use matrix_sdk::{
    ruma::{UserId, MxcUri, DeviceId, ServerName}
};
use lazy_static::lazy_static;
use tokio::runtime;
use url::Url;
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

impl std::ops::Deref for Client {
    type Target = MatrixClient;
    fn deref(&self) -> &MatrixClient {
        &self.0
    }
}

impl Client {
    pub async fn restore_token(&self) -> Result<String> {
        let session = self.0.session().await.expect("Missing session");
        let homeurl = self.0.homeserver().await.into();
        Ok(serde_json::to_string(&RestoreToken {
            session, homeurl
        })?)
    }

    // pub async fn get_mxcuri_media(&self, uri: String) -> Result<Vec<u8>> {
    //     let l = self.0.clone();
    //     RUNTIME.spawn(async move {
    //         let user_id = l.user_id().await.expect("No User ID found");
    //         Ok(user_id.as_str().to_string())
    //     }).await?
    // }

    pub async fn user_id(&self) -> Result<String> {
        let l = self.0.clone();
        RUNTIME.spawn(async move {
            let user_id = l.user_id().await.expect("No User ID found");
            Ok(user_id.as_str().to_string())
        }).await?
    }

    pub async fn display_name(&self) -> Result<String> {
        let l = self.0.clone();
        RUNTIME.spawn(async move {
            let display_name = l.display_name().await?.expect("No User ID found");
            Ok(display_name.as_str().to_string())
        }).await?
    }

    pub async fn device_id(&self) -> Result<String> {
        let l = self.0.clone();
        RUNTIME.spawn(async move {
            let device_id = l.device_id().await.expect("No Device ID found");
            Ok(device_id.as_str().to_string())
        }).await?
    }

    pub async fn avatar(&self) -> Result<Vec<u8>> {
        let l = self.0.clone();
        RUNTIME.spawn(async move {
            let uri = l.avatar_url().await?.expect("No avatar Url given");
            Ok(l.get_media_content(&MediaRequest{
                media_type: MediaType::Uri(uri),
                format: MediaFormat::File
            }, true).await?)
        }).await?
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
