use futures::Stream;
use anyhow::{bail, Result};
use matrix_sdk::{
    Client as MatrixClient,
    Session,
    media::{MediaRequest, MediaFormat, MediaType},
};
pub use matrix_sdk::{
    room::Room,
    ruma::{
        api::client::r0::account::register,
        UserId, RoomId, MxcUri, DeviceId, ServerName
    }
};
use lazy_static::lazy_static;
use tokio::runtime;
use url::Url;
use serde_json;
use parking_lot::RwLock;
use derive_builder::Builder;

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

#[derive(Default, Builder, Debug)]
pub struct ClientState {
    is_guest: bool,
}

pub struct Client {
    client: MatrixClient,
    state: RwLock<ClientState>,
}

#[derive(Serialize, Deserialize)]
struct RestoreToken {
    is_guest: bool,
    homeurl: String,
    session: Session,
}

impl std::ops::Deref for Client {
    type Target = MatrixClient;
    fn deref(&self) -> &MatrixClient {
        &self.client
    }
}

impl Client {

    fn new(client: MatrixClient, state: ClientState) -> Self {
        Client {
            client,
            state: RwLock::new(state),
        }
    }
    pub fn is_guest(&self) -> bool {
        self.state.read().is_guest
    }

    pub async fn restore_token(&self) -> Result<String> {
        let session = self.client.session().await.expect("Missing session");
        let homeurl = self.client.homeserver().await.into();
        Ok(serde_json::to_string(&RestoreToken {
            session, homeurl, is_guest: self.state.read().is_guest,
        })?)
    }

    // pub async fn get_mxcuri_media(&self, uri: String) -> Result<Vec<u8>> {
    //     let l = self.client.clone();
    //     RUNTIME.spawn(async move {
    //         let user_id = l.user_id().await.expect("No User ID found");
    //         Ok(user_id.as_str().to_string())
    //     }).await?
    // }

    pub async fn user_id(&self) -> Result<String> {
        let l = self.client.clone();
        RUNTIME.spawn(async move {
            let user_id = l.user_id().await.expect("No User ID found");
            Ok(user_id.as_str().to_string())
        }).await?
    }

    pub async fn room(&self, room_name: String) -> Result<Room> {
        let room_id = RoomId::parse(room_name)?;
        let l = self.client.clone();
        RUNTIME.spawn(async move {
            if let Some(room) = l.get_room(&room_id) {
                return Ok(room)
            }
            bail!("Room not found")
        }).await?
    }

    pub async fn display_name(&self) -> Result<String> {
        let l = self.client.clone();
        RUNTIME.spawn(async move {
            let display_name = l.display_name().await?.expect("No User ID found");
            Ok(display_name.as_str().to_string())
        }).await?
    }

    pub async fn device_id(&self) -> Result<String> {
        let l = self.client.clone();
        RUNTIME.spawn(async move {
            let device_id = l.device_id().await.expect("No Device ID found");
            Ok(device_id.as_str().to_string())
        }).await?
    }

    pub async fn avatar(&self) -> Result<Vec<u8>> {
        let l = self.client.clone();
        RUNTIME.spawn(async move {
            let uri = l.avatar_url().await?.expect("No avatar Url given");
            Ok(l.get_media_content(&MediaRequest{
                media_type: MediaType::Uri(uri),
                format: MediaFormat::File
            }, true).await?)
        }).await?
    }
}

pub async fn guest_client(base_path: String, homeurl: String) -> Result<Client> {
    let homeserver = Url::parse(&homeurl)?;
    let config = platform::new_client_config(base_path, homeurl)?;
    let mut guest_registration = register::Request::new();
    guest_registration.kind = register::RegistrationKind::Guest;
    RUNTIME.spawn(async move {
        let client = MatrixClient::new_with_config(homeserver, config)?;
        let register = client.register(guest_registration).await?;
        let session = Session {
            access_token: register.access_token.expect("no access token given"),
            user_id: register.user_id,
            device_id: register.device_id.clone().expect("device id is given by server"),
        };
        client.restore_login(session).await?;
        Ok(Client::new(client, ClientStateBuilder::default().is_guest(true).build()?))
    }).await?

}

pub async fn login_with_token(base_path: String, restore_token: String) -> Result<Client> {
    let RestoreToken { session, homeurl, is_guest } = serde_json::from_str(&restore_token)?;
    let homeserver = Url::parse(&homeurl)?;
    let config = platform::new_client_config(base_path, session.user_id.to_string())?;
    // First we need to log in.
    RUNTIME.spawn(async move {
        let client = MatrixClient::new_with_config(homeserver, config)?;
        client.restore_login(session).await?;
        Ok(Client::new(client, ClientStateBuilder::default().is_guest(is_guest).build()?))
    }).await?
}


pub async fn login_new_client(base_path: String, username: String, password: String) -> Result<Client> {
    let config = platform::new_client_config(base_path, username.clone())?;
    let user = Box::<UserId>::try_from(username)?;
    // First we need to log in.
    RUNTIME.spawn(async move {
        let client = MatrixClient::new_from_user_id_with_config(&user, config).await?;
        client.login(user, &password, None, None).await?;
        Ok(Client::new(client, ClientStateBuilder::default().is_guest(false).build()?))
    }).await?
}

pub fn echo(inp: String) -> Result<String> {
    Ok(String::from(inp))
}

fn init_logging(filter: Option<String>) -> Result<()> {
    platform::init_logging(filter)?;
    Ok(())
}
