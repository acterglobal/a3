use anyhow::Result;
use flexi_logger::{Duplicate, FileSpec, Logger};
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

pub fn init_logging(filter: Option<String>) -> Result<String> {
    std::env::set_var("RUST_BACKTRACE", "1");
    log_panics::init();

    let logger = if let Some(log_str) = filter {
        Logger::try_with_env_or_str(log_str)?
    } else {
        Logger::try_with_env()?
    };
    let file_spec = FileSpec::default();
    let file_path = file_spec.as_pathbuf(None).display().to_string();
    logger
        .log_to_file(file_spec)
        .duplicate_to_stderr(Duplicate::All)
        .start()?;
    Ok(file_path)
}
