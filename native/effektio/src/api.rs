use futures::Stream;
use anyhow::Result;
pub use matrix_sdk::Client;
use matrix_sdk::{
    Session,
    ruma::{UserId},
};
use lazy_static::lazy_static;
use tokio::runtime;
use url::Url;
use log::warn;
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


pub async fn login_new_client(username: String, password: String, base_path: String) -> Result<Client> {
    let config = platform::new_client_config(base_path, username.clone())?;
    let user = Box::<UserId>::try_from(username)?;
    // First we need to log in.
    RUNTIME.spawn(async move {
        let client = Client::new_from_user_id_with_config(&user, config).await?;
        client.login(user, &password, None, None).await?;
        Ok(client)
    }).await?
}

pub fn echo(inp: String) -> Result<String> {
    Ok(String::from(inp))
}

fn init_logging(filter: Option<String>) -> Result<()> {
    platform::init_logging(filter)?;
    Ok(())
}
