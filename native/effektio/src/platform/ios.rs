use super::native;
use anyhow::Result;
use log::Level;
use matrix_sdk::config::ClientConfig;
use sanitize_filename_reader_friendly::sanitize;
use std::{fs, path};
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::{fmt::format::FmtSpan, EnvFilter};

pub fn new_client_config(base_path: String, home: String) -> Result<ClientConfig> {
    Ok(native::new_client_config(base_path, home)?.user_agent("effektio-android")?)
}

pub fn init_logging(filter: Option<String>) -> Result<()> {
    // FIXME: not yet supported

    Ok(())
}
