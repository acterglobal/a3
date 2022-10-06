use matrix_sdk::{store::make_store_config, Client, ClientBuilder};
use sanitize_filename_reader_friendly::sanitize;
use std::{fs::create_dir_all, path::PathBuf};

pub fn new_client_config(base_path: String, home: String) -> anyhow::Result<ClientBuilder> {
    let data_path = PathBuf::from(base_path).join(sanitize(&home));

    create_dir_all(&data_path)?;

    Ok(Client::builder()
        .store_config(make_store_config(&data_path, None)?)
        .user_agent("effektio-test-platform"))
}

pub fn init_logging(filter: Option<String>) -> anyhow::Result<()> {
    Ok(())
}
