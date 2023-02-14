use anyhow::Result;
use env_logger::filter::Builder as FilterBuilder;
use log::{Level, LevelFilter, Log, Metadata, Record};
use matrix_sdk::ClientBuilder;
use oslog::OsLog;
use std::{
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

pub fn init_logging(log_dir: String, filter: Option<String>) -> Result<String> {
    std::env::set_var("RUST_BACKTRACE", "1");
    log_panics::init();

    let log_level = match filter {
        Some(filter) => FilterBuilder::new().parse(&filter).build(),
        None => FilterBuilder::new().build(),
    };

    let wrapper = LoggerWrapper::new("org.effektio.app", "viewcycle");

    let file_name = chrono::Local::now().format("app_%Y-%m-%d_%H-%M-%S.log").to_string();
    let mut path = std::fs::canonicalize(PathBuf::from("."))?;
    path.push(file_name);
    let file_path = path.to_string_lossy().to_string();

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
        .chain(wrapper.cloned_boxed_logger())
        // .chain(fern::log_file(file_path.clone())?)
        .apply()?;

    log::info!("log file path: {}", file_path.clone());

    Ok(file_path)
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
