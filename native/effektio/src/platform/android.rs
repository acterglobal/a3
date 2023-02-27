use android_logger::{AndroidLogger, Config, FilterBuilder};
use anyhow::Result;
use lazy_static::lazy_static;
use log::{Level, LevelFilter, Log, Metadata, Record};
use matrix_sdk::ClientBuilder;
use reqwest::{
    multipart::{Form, Part},
    Client, StatusCode,
};
use std::{
    fs,
    path::PathBuf,
    sync::{Arc, Mutex},
};

use super::{native, super::api::RUNTIME};

pub use super::native::sanitize;

pub async fn new_client_config(base_path: String, home: String) -> Result<ClientBuilder> {
    let builder = native::new_client_config(base_path, home)
        .await?
        .user_agent(format!("effektio-android/{:}", env!("CARGO_PKG_VERSION")));
    Ok(builder)
}

lazy_static! {
    static ref FILE_LOGGER: Mutex<Option<Arc<fern::ImplDispatch>>> = Mutex::new(None);
}

pub fn init_logging(log_dir: String, filter: Option<String>) -> Result<()> {
    std::env::set_var("RUST_BACKTRACE", "1");
    log_panics::init();

    let log_level = match filter {
        Some(ref filter) => FilterBuilder::new().parse(&filter).build(),
        None => FilterBuilder::new().build(),
    };

    let mut log_config = Config::default()
        .with_max_level(LevelFilter::Trace)
        .with_tag("com.example.effektio");
    if let Some(filter) = filter {
        log_config = log_config.with_filter(FilterBuilder::new().parse(&filter).build());
    }
    let console_logger = LoggerWrapper::new(log_config).cloned_boxed_logger();

    let mut path = PathBuf::from(log_dir.as_str());
    path.push("app_");

    let (level, dispatch) = fern::Dispatch::new()
        .format(|out, message, record| {
            out.finish(format_args!(
                "{}[{}][{}] {}",
                chrono::Local::now().format("[%Y-%m-%d][%H:%M:%S]"),
                record.target(),
                record.level(),
                message
            ))
        })
        // Add blanket level filter -
        .level(log_level.filter())
        // - and per-module overrides
        .level_for("effektio-sdk", log_level.filter())
        // Output to console
        .chain(console_logger)
        // Output to file
        .chain(fern::Manual::new(path, "%Y-%m-%d_%H-%M-%S%.f.log"))
        .into_dispatch_with_arc();

    if level == log::LevelFilter::Off {
        log::set_boxed_logger(Box::new(native::NopLogger))?;
    } else {
        log::set_boxed_logger(Box::new(dispatch.clone()))?;
    }
    log::set_max_level(level);

    *FILE_LOGGER.lock().unwrap() = Some(dispatch);

    Ok(())
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

pub async fn report_bug(
    url: String,
    username: String,
    password: Option<String>,
    app_name: String,
    version: String,
    text: String,
    label: String,
    with_log: bool,
) -> Result<bool> {
    let mut form = Form::new()
        .text("text", text)
        .text("user_agent", "Mozilla/0.9")
        .text("app", app_name)
        .text("version", version)
        .text("label", label);
    if with_log {
        if let Some(dispatch) = &*FILE_LOGGER.lock().unwrap() {
            let res = dispatch.rotate();
            for output in res.iter() {
                match output {
                    Some((old_path, new_path)) => {
                        let log_path = old_path.canonicalize()?.to_string_lossy().to_string();
                        let file = fs::read(log_path)?;
                        let filename =
                            old_path.file_name().unwrap().to_string_lossy().to_string();
                        let file_part = Part::bytes(file)
                            .file_name(filename)
                            .mime_str("text/plain")?;
                        form = form.part("log", file_part);
                        break;
                    }
                    None => {}
                }
            }
        }
    }
    RUNTIME
        .spawn(async move {
            let resp = Client::new()
                .post(url)
                .basic_auth(username, password)
                .multipart(form)
                .send()
                .await?;
            Ok(resp.status() == StatusCode::OK)
        })
        .await?
}
