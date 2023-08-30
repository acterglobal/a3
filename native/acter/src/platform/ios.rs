use anyhow::Result;
use log::{Level, Log, Metadata, Record};
use matrix_sdk::ClientBuilder;
use oslog::OsLog;
use std::sync::{Arc, Mutex};

use super::native;

pub async fn destroy_local_data(base_path: String, home_dir: String) -> Result<bool> {
    native::destroy_local_data(base_path, home_dir).await
}
// this includes macos, because macos and ios is very much alike in logging

#[cfg(target_os = "ios")]
pub async fn new_client_config(
    base_path: String,
    home_dir: String,
    reset_if_existing: bool,
) -> Result<ClientBuilder> {
    let builder = native::new_client_config(base_path, home_dir, reset_if_existing)
        .await?
        .user_agent(format!("acter-ios/{:}", env!("CARGO_PKG_VERSION")));
    Ok(builder)
}

#[cfg(target_os = "macos")]
pub async fn new_client_config(
    base_path: String,
    home_dir: String,
    reset_if_existing: bool,
) -> Result<ClientBuilder> {
    let builder = native::new_client_config(base_path, home_dir, reset_if_existing)
        .await?
        .user_agent(format!(
            "{:}/acter@{:}",
            option_env!("CARGO_BIN_NAME").unwrap_or("acter-desktop"),
            env!("CARGO_PKG_VERSION")
        ));
    Ok(builder)
}

const APP_TAG: &str = "global.acter.app"; // product bundle id in project config

pub fn init_logging(log_dir: String, filter: String) -> Result<()> {
    let console_logger = LoggerWrapper::new(APP_TAG, "viewcycle").cloned_boxed_logger();
    native::init_logging(log_dir, filter, Some(console_logger))
}

/// Wrapper for our console which acts as the actual logger.
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
