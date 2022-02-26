use matrix_sdk::config::ClientConfig;
use sanitize_filename_reader_friendly::sanitize;
use std::{fs, path};

pub fn new_client_config(
    base_path: String,
    home: String,
) -> anyhow::Result<matrix_sdk::config::ClientConfig> {
    let data_path = path::PathBuf::from(base_path).join(sanitize(&home));

    fs::create_dir_all(&data_path)?;

    let config = ClientConfig::new()
        .user_agent("effektio-test-platform")?
        .store_path(&data_path);

    Ok(config)
}

pub fn init_logging(filter: Option<String>) -> anyhow::Result<()> {
    Ok(())
}
