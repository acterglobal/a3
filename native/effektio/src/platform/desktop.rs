use anyhow::Result;
use matrix_sdk::ClientBuilder;

use super::native;

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

// this excludes macos, because macos and ios is very much alike in logging

pub fn init_logging(log_dir: String, filter: Option<String>) -> Result<()> {
    native::init_logging(log_dir, filter, None)
}
