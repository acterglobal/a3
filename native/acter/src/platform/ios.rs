use anyhow::Result;
use matrix_sdk::ClientBuilder;
use oslog::OsLogger;

use super::native;

pub async fn destroy_local_data(
    base_path: String,
    home_dir: String,
    media_cache_base_path: Option<String>,
) -> Result<bool> {
    native::destroy_local_data(base_path, home_dir, media_cache_base_path).await
}

pub async fn new_client_config(
    base_path: String,
    home_dir: String,
    media_cache_base_path: String,
    db_passphrase: Option<String>,
    reset_if_existing: bool,
) -> Result<ClientBuilder> {
    let builder = native::new_client_config(
        base_path,
        home_dir,
        media_cache_base_path,
        db_passphrase,
        reset_if_existing,
    )
    .await?
    .user_agent(format!("acter-ios/{:}", env!("CARGO_PKG_VERSION")));
    Ok(builder)
}

const APP_TAG: &str = "global.acter.app"; // product bundle id in project config

pub fn init_logging(log_dir: String, filter: String) -> Result<()> {
    let console_logger = Box::new(OsLogger::new(APP_TAG));
    native::init_logging(log_dir, filter, Some(console_logger))
}
