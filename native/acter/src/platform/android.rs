use android_logger::{AndroidLogger, Config};
use anyhow::Result;
use log::LevelFilter;
use matrix_sdk::ClientBuilder;

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
    .user_agent(format!("acter-android/{:}", env!("CARGO_PKG_VERSION")));
    Ok(builder)
}

const APP_TAG: &str = "global.acter.app"; // package name in manifest, application id in build.gradle

pub fn init_logging(log_dir: String, filter: String) -> Result<()> {
    let mut log_config = Config::default()
        .with_max_level(LevelFilter::Trace)
        .with_tag(APP_TAG);
    let console_logger = Box::new(AndroidLogger::new(log_config));
    native::init_logging(log_dir, filter, Some(console_logger))
}
