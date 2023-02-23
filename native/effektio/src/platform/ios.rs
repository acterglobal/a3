use anyhow::Result;
use env_logger::filter::Builder as FilterBuilder;
use log::{Level, LevelFilter, Log, Metadata, Record};
use matrix_sdk::ClientBuilder;
use oslog::OsLog;
use std::{
    fs::canonicalize,
    path::PathBuf,
    sync::{Arc, Mutex},
};

use super::native;

// this includes macos, because macos and ios is very much alike in logging

#[cfg(target_os = "macos")]
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

#[cfg(not(target_os = "macos"))]
pub async fn new_client_config(base_path: String, home: String) -> Result<ClientBuilder> {
    let builder = native::new_client_config(base_path, home)
        .await?
        .user_agent(format!("effektio-ios/{:}", env!("CARGO_PKG_VERSION")));
    Ok(builder)
}

static mut FILE_LOGGER: Option<Arc<fern::ImplDispatch>> = None;

pub fn init_logging(app_name: String, log_dir: String, filter: Option<String>) -> Result<()> {
    std::env::set_var("RUST_BACKTRACE", "1");
    log_panics::init();

    let log_level = match filter {
        Some(filter) => FilterBuilder::new().parse(&filter).build(),
        None => FilterBuilder::new().build(),
    };

    let console_logger = LoggerWrapper::new(app_name.as_str(), "viewcycle").cloned_boxed_logger();

    let mut path = PathBuf::from(log_dir.as_str());
    path.push("app_");

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
        .chain(fern::Manual::new(path, "%Y-%m-%d_%H-%M-%S%.f.log"))
        .into_dispatch_with_arc();

    if level == log::LevelFilter::Off {
        log::set_boxed_logger(Box::new(native::NopLogger)).unwrap();
    } else {
        log::set_boxed_logger(Box::new(dispatch.clone())).unwrap();
    }
    log::set_max_level(level);

    unsafe {
        FILE_LOGGER = Some(dispatch);
    }

    Ok(())
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

pub fn rotate_logging() -> Result<String> {
    unsafe {
        if let Some(dispatch) = &FILE_LOGGER {
            let res = dispatch.rotate();
            for output in res.iter() {
                match output {
                    Some((old_path, new_path)) => {
                        return Ok(canonicalize(old_path)?.to_string_lossy().to_string());
                    }
                    None => {}
                }
            }
        }
    }
    Ok("".to_string())
}
