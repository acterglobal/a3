use anyhow::Result;
use log::{Log, Metadata, Record};
use matrix_sdk::{Client, ClientBuilder};
use matrix_sdk_sled::make_store_config;
use std::path::PathBuf;

pub async fn new_client_config(base_path: String, home: String) -> Result<ClientBuilder> {
    let data_path = sanitize(base_path, home);

    std::fs::create_dir_all(&data_path)?;

    let builder = Client::builder()
        .store_config(make_store_config(&data_path, None).await?)
        .user_agent(format!("effektio-testing/{:}", env!("CARGO_PKG_VERSION")));
    Ok(builder)
}

pub fn init_logging(log_dir: String, filter: Option<String>) -> Result<()> {
    Ok(())
}

pub async fn report_bug(
    url: String,
    username: String,
    password: Option<String>,
    app_name: String,
    version: String,
    text: String,
    label: String,
    with_log: bool,
) -> Result<bool> {
    Ok(true)
}

pub fn sanitize(base_path: String, home: String) -> PathBuf {
    PathBuf::from(base_path).join(sanitize_filename_reader_friendly::sanitize(&home))
}

pub struct NopLogger;

impl Log for NopLogger {
    fn enabled(&self, metadata: &Metadata) -> bool {
        false
    }

    fn log(&self, record: &Record) {}

    fn flush(&self) {}
}
