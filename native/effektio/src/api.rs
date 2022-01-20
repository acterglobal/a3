use futures::Stream;
use anyhow::Result;
pub use matrix_sdk::Client;
use url::Url;
use log::warn;
#[cfg(target_os = "android")]
use crate::android as platform;

#[cfg(not(target_os = "android"))]
mod platform {
    pub(super) fn new_client(_url: url::Url, _data_path: String) -> anyhow::Result<matrix_sdk::Client> {
        anyhow::bail!("not implemented for current platform")
    }
    pub(super) fn init_logging(filter: Option<String>) -> anyhow::Result<()> {
        anyhow::bail!("not implemented for current platform")
    }
}

ffi_gen_macro::ffi_gen!("native/effektio/api.rsh");

/// Returns 0 if things went wrong, or the reference number otherwise
pub fn new_client(home_url: String, data_path: String) -> Result<Client> {
    let url = Url::parse(&home_url)?;
    warn!("New client for {}", url);
    platform::new_client(url, data_path)
}

pub fn echo(inp: String) -> Result<String> {
    Ok(String::from(inp))
}

#[allow(clippy::if_same_then_else)]
fn init_logging(filter: Option<String>) -> Result<()> {
    platform::init_logging(filter)?;
    Ok(())
}
