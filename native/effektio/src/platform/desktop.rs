use anyhow::Result;
use flexi_logger::{AdaptiveFormat, Logger};
use matrix_sdk::{Client, ClientBuilder};
use std::{fs, path};

use super::native;

pub use super::native::sanitize;

pub async fn new_client_config(base_path: String, home: String) -> Result<ClientBuilder> {
    let builder = native::new_client_config(base_path, home)
        .await?
        .user_agent(format!(
            "{:}/effektio@{:}",
            option_env!("CARGO_BIN_NAME").unwrap_or("effektio-desktop"),
            env!("CARGO_PKG_VERSION")
        ));
    Ok(builder)
}

pub fn init_logging(filter: Option<String>) -> Result<()> {
    std::env::set_var("RUST_BACKTRACE", "1");
    log_panics::init();

    let logger = if let Some(log_str) = filter {
        Logger::try_with_env_or_str(log_str)?
    } else {
        Logger::try_with_env()?
    };
    logger
        .adaptive_format_for_stderr(AdaptiveFormat::Detailed)
        .start()?;
    Ok(())
}
