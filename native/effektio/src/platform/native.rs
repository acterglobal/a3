use anyhow::Result;
use matrix_sdk::{Client, ClientBuilder};
use sanitize_filename_reader_friendly::sanitize;
use std::{fs::create_dir_all, path::PathBuf};

pub fn new_client_config(base_path: String, home: String) -> anyhow::Result<ClientBuilder> {
    Ok(Client::builder().user_agent("effektio-test-platform"))
}

pub fn init_logging(filter: Option<String>) -> Result<()> {
    Ok(())
}
