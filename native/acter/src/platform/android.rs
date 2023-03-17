use android_logger::{AndroidLogger, Config};
use anyhow::Result;
use env_logger::filter::Builder as FilterBuilder;
use log::{Level, LevelFilter, Log, Metadata, Record};
use matrix_sdk::ClientBuilder;
use std::sync::{Arc, Mutex};

use super::native;

pub async fn new_client_config(base_path: String, home: String) -> Result<ClientBuilder> {
    let builder = native::new_client_config(base_path, home)
        .await?
        .user_agent(format!("acter-android/{:}", env!("CARGO_PKG_VERSION")));
    Ok(builder)
}

const APP_TAG: &str = "global.acter.app"; // package name in manifest, application id in build.gradle

pub fn init_logging(log_dir: String, filter: String) -> Result<()> {
    let mut log_config = Config::default()
        .with_max_level(LevelFilter::Trace)
        .with_tag(APP_TAG)
        .with_filter(FilterBuilder::new().parse(filter.as_str()).build());
    let console_logger = LoggerWrapper::new(log_config).cloned_boxed_logger();
    native::init_logging(log_dir, filter, Some(console_logger))
}

/// Wrapper for our console which acts as the actual logger.
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
