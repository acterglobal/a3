use anyhow::Result;
use matrix_sdk::{Client, ClientBuilder};
use matrix_sdk_sled::make_store_config;
use path::PathBuf;
use std::{fs, path};

pub async fn new_client_config(base_path: String, home: String) -> Result<ClientBuilder> {
    let data_path = sanitize(base_path, home);

    fs::create_dir_all(&data_path)?;

    let builder = Client::builder()
        .store_config(make_store_config(&data_path, None).await?)
        .user_agent(format!("effektio-testing/{:}", env!("CARGO_PKG_VERSION")));
    Ok(builder)
}

pub fn init_logging(log_dir: String, filter: Option<String>) -> Result<String> {
    let file_path = "".to_string();
    Ok(file_path)
}

pub fn sanitize(base_path: String, home: String) -> PathBuf {
    PathBuf::from(base_path).join(sanitize_filename_reader_friendly::sanitize(&home))
}
