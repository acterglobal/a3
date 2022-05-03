use crate::platform;
use anyhow::{bail, Context, Result};
use effektio_core::ruma::api::client::{
    account::register, uiaa,
};
use effektio_core::RestoreToken;
use futures::Stream;
use lazy_static::lazy_static;
use matrix_sdk::Session;
use tokio::runtime;
use url::Url;
pub use ruma;

lazy_static! {
    static ref RUNTIME: runtime::Runtime =
        runtime::Runtime::new().expect("Can't start Tokio runtime");
}

mod auth;
mod client;
mod conversation;
mod group;
mod messages;
mod room;
mod stream;


pub use client::{Client, ClientStateBuilder};
pub use auth::{guest_client, login_with_token, login_new_client, register_with_registration_token};
pub use conversation::Conversation;
pub use group::Group;
pub use messages::AnyMessage;
pub use room::{Member, Room};
pub use stream::TimelineStream;

pub type UserId = ruma::OwnedUserId;

ffi_gen_macro::ffi_gen!("native/effektio/api.rsh");

fn init_logging(filter: Option<String>) -> Result<()> {
    platform::init_logging(filter)?;
    Ok(())
}
