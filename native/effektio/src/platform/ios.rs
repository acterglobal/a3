use anyhow::Result;
use env_logger::filter::Builder as FilterBuilder;
use log::{Level, LevelFilter, Log, Metadata, Record};
use matrix_sdk::ClientBuilder;
use oslog::OsLog;
use std::{
    fs::OpenOptions,
    path::PathBuf,
    sync::{Arc, Mutex},
};

use super::native;

pub async fn new_client_config(base_path: String, home: String) -> Result<ClientBuilder> {
    let builder = native::new_client_config(base_path, home)
        .await?
        .user_agent(format!("effektio-ios/{:}", env!("CARGO_PKG_VERSION")));
    Ok(builder)
}

// this includes macos, because macos and ios is very much alike in logging

pub fn init_logging(app_name: String, log_dir: String, filter: Option<String>) -> Result<String> {
    std::env::set_var("RUST_BACKTRACE", "1");
    log_panics::init();

    let log_level = match filter {
        Some(filter) => FilterBuilder::new().parse(&filter).build(),
        None => FilterBuilder::new().build(),
    };

    let console_logger = LoggerWrapper::new(app_name.as_str(), "viewcycle").cloned_boxed_logger();

    let file_name = chrono::Local::now()
        .format("app_%Y-%m-%d_%H-%M-%S.log")
        .to_string();
    let mut path = PathBuf::from(log_dir.as_str());
    path.push(file_name);
    let log_path = path.to_string_lossy().to_string();

    let file_logger = OpenOptions::new()
        .write(true)
        .create(true)
        .truncate(true)
        .create(true)
        .open(log_path.as_str())?;

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
        .chain(console_logger)
        .chain(file_logger)
        .apply()?;

    log::info!("log file path: {}", log_path.clone());
    Ok(log_path)
}

/// Wrapper for our verification which acts as the actual logger.
#[derive(Clone)]
struct LoggerWrapper(Arc<Mutex<OsLog>>);

impl LoggerWrapper {
    fn new(subsystem: &str, category: &str) -> Self {
        let logger = OsLog::new(subsystem, category);
        LoggerWrapper(Arc::new(Mutex::new(logger)))
    }

    fn cloned_boxed_logger(&self) -> Box<dyn Log> {
        Box::new(self.clone())
    }
}

impl Log for LoggerWrapper {
    fn enabled(&self, metadata: &Metadata) -> bool {
        metadata.level() <= Level::Info
    }

    fn log(&self, record: &Record) {
        let metadata = record.metadata();
        if self.enabled(metadata) {
            let logger = self.0.lock().unwrap();
            match metadata.level() {
                Level::Error => logger.fault(record.args().to_string().as_str()),
                Level::Warn => logger.error(record.args().to_string().as_str()),
                Level::Info => logger.default(record.args().to_string().as_str()),
                Level::Debug => logger.info(record.args().to_string().as_str()),
                Level::Trace => logger.debug(record.args().to_string().as_str()),
            }
        }
    }

    fn flush(&self) {}
}

pub fn rotate_logging() -> Result<()> {
    Ok(())
}
