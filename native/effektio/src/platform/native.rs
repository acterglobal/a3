use anyhow::{bail, Result};
use lazy_static::lazy_static;
use log::{Log, Metadata, Record};
use matrix_sdk::{Client, ClientBuilder};
use matrix_sdk_sled::make_store_config;
use std::{
    path::PathBuf,
    sync::{Arc, Mutex},
};

use super::super::api::RUNTIME;

pub async fn new_client_config(base_path: String, home: String) -> Result<ClientBuilder> {
    let data_path = sanitize(base_path, home);

    std::fs::create_dir_all(&data_path)?;

    let builder = Client::builder()
        .store_config(make_store_config(&data_path, None).await?)
        .user_agent(format!("effektio-testing/{:}", env!("CARGO_PKG_VERSION")));
    Ok(builder)
}

lazy_static! {
    pub static ref FILE_LOGGER: Mutex<Option<Arc<fern::ImplDispatch>>> = Mutex::new(None);
}

pub fn rotate_log_file() -> Result<String> {
    match &*FILE_LOGGER.lock().unwrap() {
        Some(dispatch) => {
            for output in dispatch.rotate().iter() {
                match output {
                    Some((old_path, new_path)) => {
                        return Ok(old_path.to_string_lossy().to_string());
                    }
                    None => {}
                }
            }
        }
        None => {
            bail!("You didn't set up file logger.");
        }
    }
    Ok("".to_string())
}

pub fn write_log(text: String, level: String) -> Result<()> {
    match level.as_str() {
        "debug" => log::debug!("{}", text),
        "error" => log::error!("{}", text),
        "info" => log::info!("{}", text),
        "warn" => log::warn!("{}", text),
        "trace" => log::trace!("{}", text),
        _ => {}
    }
    Ok(())
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
