use crate::platform;
use anyhow::{bail, Context, Result};
use effektio_core::ruma::api::client::account::register;
use effektio_core::RestoreToken;
use futures::Stream;
use lazy_static::lazy_static;
pub use matrix_sdk::ruma;
use matrix_sdk::Session;
use tokio::runtime;
use url::Url;

lazy_static! {
    static ref RUNTIME: runtime::Runtime =
        runtime::Runtime::new().expect("Can't start Tokio runtime");
}

mod client;
mod messages;
mod room;
mod stream;

pub use client::{Client, ClientStateBuilder};
pub use messages::AnyMessage;
pub use room::{Room, RoomMember};
pub use stream::TimelineStream;
pub use effektio_core::models::{ News, Faq, Color, Tag };

#[cfg(feature = "with-mocks")]
pub use effektio_core::mocks::*;

pub type UserId = Box<ruma::UserId>;

ffi_gen_macro::ffi_gen!("native/effektio/api.rsh");

pub async fn guest_client(base_path: String, homeurl: String) -> Result<Client> {
    let config = platform::new_client_config(base_path, homeurl.clone())?.homeserver_url(homeurl);
    let mut guest_registration = register::v3::Request::new();
    guest_registration.kind = register::RegistrationKind::Guest;
    RUNTIME
        .spawn(async move {
            let client = config.build().await?;
            let register = client.register(guest_registration).await?;
            let session = Session {
                access_token: register.access_token.context("no access token given")?,
                user_id: register.user_id,
                device_id: register
                    .device_id
                    .clone()
                    .context("device id is given by server")?,
            };
            client.restore_login(session).await?;
            let c = Client::new(
                client,
                ClientStateBuilder::default().is_guest(true).build()?,
            );
            c.start_sync();
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
            client.restore_login(session).await?;
            let c = Client::new(
                client,
                ClientStateBuilder::default().is_guest(is_guest).build()?,
            );
            c.start_sync();
            Ok(c)
        })
        .await?
}

pub async fn login_new_client(
    base_path: String,
    username: String,
    password: String,
) -> Result<Client> {
    let user = Box::<ruma::UserId>::try_from(username.clone())?;
    let config = platform::new_client_config(base_path, username)?.user_id(&user);
    // First we need to log in.
    RUNTIME
        .spawn(async move {
            let client = config.build().await?;
            client.login(user, &password, None, None).await?;
            let c = Client::new(
                client,
                ClientStateBuilder::default().is_guest(false).build()?,
            );
            c.start_sync();
            Ok(c)
        })
        .await?
}

fn init_logging(filter: Option<String>) -> Result<()> {
    platform::init_logging(filter)?;
    Ok(())
}
