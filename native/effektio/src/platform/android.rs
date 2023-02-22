use android_logger::{AndroidLogger, Config, FilterBuilder};
use anyhow::Result;
use log::{Level, LevelFilter, Log, Metadata, Record};
use matrix_sdk::ClientBuilder;
use std::{
    fs::OpenOptions,
    path::PathBuf,
    sync::{Arc, Mutex},
};

use super::native;

pub async fn new_client_config(base_path: String, home: String) -> Result<ClientBuilder> {
    let builder = native::new_client_config(base_path, home)
        .await?
        .user_agent(format!("effektio-android/{:}", env!("CARGO_PKG_VERSION")));
    Ok(builder)
}

pub fn init_logging(app_name: String, log_dir: String, filter: Option<String>) -> Result<String> {
    std::env::set_var("RUST_BACKTRACE", "1");
    log_panics::init();

    let log_level = match filter {
        Some(ref filter) => FilterBuilder::new().parse(&filter).build(),
        None => FilterBuilder::new().build(),
    };

    let mut log_config = Config::default()
        .with_max_level(LevelFilter::Trace)
        .with_tag(app_name.as_str());
    if let Some(filter) = filter {
        log_config = log_config.with_filter(FilterBuilder::new().parse(&filter).build());
    }
    let console_logger = LoggerWrapper::new(log_config).cloned_boxed_logger();

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

    log::info!("log file path: {}", log_path);
    Ok(log_path)
}

/// Wrapper for our verification which acts as the actual logger.
#[derive(Clone)]
struct LoggerWrapper(Arc<Mutex<AndroidLogger>>);

impl LoggerWrapper {
    fn new(config: Config) -> Self {
        let logger = AndroidLogger::new(config);
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
        if self.enabled(record.metadata()) {
            self.0.lock().unwrap().log(record);
        }
    }

    fn flush(&self) {}
}

pub fn rotate_logging() -> Result<()> {
    Ok(())
}
