use acter_core::util::Local;
use anyhow::{bail, Result};
use lazy_static::lazy_static;
use log::{LevelFilter, Log, Metadata, Record};
use matrix_sdk::{Client, ClientBuilder};
use matrix_sdk_sled::make_store_config;
use parse_env_filter::eager::{filters, Filter};
use std::{
    path::PathBuf,
    sync::{Arc, Mutex},
};

pub async fn new_client_config(base_path: String, home: String) -> Result<ClientBuilder> {
    let data_path = sanitize(base_path, home);

    std::fs::create_dir_all(&data_path)?;

    let builder = Client::builder()
        .store_config(make_store_config(&data_path, None).await?)
        .user_agent(format!("acter-testing/{:}", env!("CARGO_PKG_VERSION")));
    Ok(builder)
}

lazy_static! {
    static ref FILE_LOGGER: Mutex<Option<Arc<fern::ImplDispatch>>> = Mutex::new(None);
}

pub fn init_logging(
    log_dir: String,
    filter: String,
    console_logger: Option<Box<dyn Log>>,
) -> Result<()> {
    std::env::set_var("RUST_BACKTRACE", "1");
    log_panics::init();

    let mut builder = fern::Dispatch::new().format(|out, message, record| {
        out.finish(format_args!(
            "{}[{}][{}] {}",
            Local::now().format("[%Y-%m-%d][%H:%M:%S]"),
            record.target(),
            record.level(),
            message
        ))
    });

    let Ok(items) = filters(&filter) else {
        bail!("Parsing log filters failed");
    };
    for Filter {
        target,
        span,
        level,
    } in items
    {
        match level {
            Some(level) => {
                if let Some(level) = get_log_filter(level) {
                    // Add level filter per module
                    builder = builder.level_for(target.to_owned(), level);
                }
            }
            None => {
                if let Some(level) = get_log_filter(target) {
                    // Add blanket level filter
                    builder = builder.level(level);
                }
            }
        }
    }

    // Output to console
    if let Some(console_logger) = console_logger {
        builder = builder.chain(console_logger);
    } else {
        builder = builder.chain(std::io::stdout());
    }

    let mut path = PathBuf::from(log_dir.as_str());
    path.push("app_");

    let (level, dispatch) = builder
        // Output to file
        .chain(fern::Manual::new(path, "%Y-%m-%d_%H-%M-%S%.f.log"))
        .into_dispatch_with_arc();

    if level == log::LevelFilter::Off {
        log::set_boxed_logger(Box::new(NopLogger))?;
    } else {
        log::set_boxed_logger(Box::new(dispatch.clone()))?;
    }
    log::set_max_level(level);

    *FILE_LOGGER.lock().unwrap() = Some(dispatch);

    Ok(())
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

struct NopLogger;

impl Log for NopLogger {
    fn enabled(&self, metadata: &Metadata) -> bool {
        false
    }

    fn log(&self, record: &Record) {}

    fn flush(&self) {}
}

fn get_log_filter(level: &str) -> Option<LevelFilter> {
    match level {
        "debug" => Some(LevelFilter::Debug),
        "error" => Some(LevelFilter::Error),
        "info" => Some(LevelFilter::Info),
        "warn" => Some(LevelFilter::Warn),
        "trace" => Some(LevelFilter::Trace),
        _ => None,
    }
}
