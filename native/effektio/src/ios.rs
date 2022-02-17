use anyhow::Result;
use log::Level;
use matrix_sdk::config::ClientConfig;
use sanitize_filename_reader_friendly::sanitize;
use std::{fs, path};
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::{fmt::format::FmtSpan, EnvFilter};

pub(crate) fn new_client_config(base_path: String, home: String) -> Result<ClientConfig> {
    let data_path = path::PathBuf::from(base_path).join(sanitize(&home));

    fs::create_dir_all(&data_path)?;

    let config = ClientConfig::new()
        .user_agent("effektio-ios")?
        .store_path(&data_path);
    Ok(config)
}

pub(crate) fn init_logging(filter: Option<String>) -> Result<()> {
    // FIXME: not yet supported

    Ok(())
}
