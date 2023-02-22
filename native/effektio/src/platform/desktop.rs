use anyhow::Result;
use env_logger::filter::Builder as FilterBuilder;
use log::{LevelFilter, Log, Metadata, Record};
use matrix_sdk::ClientBuilder;
use std::{
    fs::{File, OpenOptions},
    io::Write,
    path::PathBuf,
    sync::Arc,
};

use crate::Client;
use super::native;

pub use super::native::sanitize;

pub async fn new_client_config(base_path: String, home: String) -> Result<ClientBuilder> {
    let builder = native::new_client_config(base_path, home)
        .await?
        .user_agent(format!(
            "{:}/effektio@{:}",
            option_env!("CARGO_BIN_NAME").unwrap_or("effektio-desktop"),
            env!("CARGO_PKG_VERSION")
        ));
    Ok(builder)
}

static mut LOGGER: &dyn Log = &NopLogger;

// this excludes macos, because macos and ios is very much alike in logging

pub fn init_logging(app_name: String, log_dir: String, filter: Option<String>) -> Result<String> {
    std::env::set_var("RUST_BACKTRACE", "1");
    log_panics::init();

    let log_level = match filter {
        Some(filter) => FilterBuilder::new().parse(&filter).build(),
        None => FilterBuilder::new().build(),
    };

    let file_name = chrono::Local::now()
        .format("app_%Y-%m-%d_%H-%M-%S.log")
        .to_string();
    let mut path = PathBuf::from(log_dir.as_str());
    path.push(file_name);
    let log_path = path.to_string_lossy().to_string();

    let file = OpenOptions::new()
        .write(true)
        .create(true)
        .truncate(true)
        .create(true)
        .open(log_path.as_str())?;
    // unsafe {
    //     FILE_LOGGER = Some(Arc::new(file.try_clone()?));
    // }

    fern::Dispatch::new()
        .format(|out, message, record| {
            out.finish(format_args!(
                "{}[{}][{}] {}",
                chrono::Local::now().format("[%Y-%m-%d][%H:%M:%S]"),
                record.target(),
                record.level(),
                message
            ))
        })
        .level(log_level.filter())
        .chain(std::io::stdout())
        .chain(file)
        .apply()?;

    log::info!("log file path: {}", log_path);
    Ok(log_path)
}

struct NopLogger;

impl Log for NopLogger {
    fn enabled(&self, metadata: &Metadata) -> bool {
        false
    }

    fn log(&self, record: &Record) {}

    fn flush(&self) {}
}

pub fn rotate_logging() -> Result<()> {
    let logger = log::logger();
    let log_level = log::max_level();
    unsafe {
        log::set_max_level(LevelFilter::Off);
        log::set_boxed_logger(Box::new(&NopLogger));
        // if let Some(file) = &FILE_LOGGER {
        //     file.try_clone()?.flush()?;
        //     FILE_LOGGER = None;
        // }
    }
    Ok(())
}

impl Client {}
