use anyhow::{bail, Result};
use chrono::Local;
use lazy_static::lazy_static;
use log::{log_enabled, Level, LevelFilter, Log, Metadata, Record};
use matrix_sdk::{Client, ClientBuilder, SqliteEventCacheStore};
use matrix_sdk_base::{event_cache::store::EventCacheStoreError, store::StoreConfig};
use matrix_sdk_sqlite::{OpenStoreError, SqliteCryptoStore, SqliteStateStore};
use parse_env_filter::eager::{filters, Filter};
use std::{
    fmt::{Display, Error},
    path::{Path, PathBuf},
    sync::{Arc, Mutex},
};

use crate::RUNTIME;

pub async fn destroy_local_data(
    base_path: String,
    home_dir: String,
    media_cache_base_path: Option<String>,
) -> Result<bool> {
    if let Some(media_base) = media_cache_base_path {
        let data_path = sanitize(&media_base, &home_dir);
        if Path::new(&data_path).try_exists()? {
            std::fs::remove_dir_all(&data_path)?;
        }
    }

    let data_path = sanitize(&base_path, &home_dir);
    if Path::new(&data_path).try_exists()? {
        std::fs::remove_dir_all(&data_path)?;
        return Ok(true);
    }
    Ok(false)
}
fn make_data_path(
    base_path: &str,
    sub_dir: &str,
    should_reset_if_existing: bool,
) -> Result<PathBuf> {
    let data_path = sanitize(base_path, sub_dir);

    if should_reset_if_existing && Path::new(&data_path).try_exists()? {
        let backup_path = sanitize(
            base_path,
            &format!("{sub_dir}_backup_{}", Local::now().to_rfc3339()),
        );
        tracing::warn!("{data_path:?} already existing. Moving to backup at {backup_path:?}.");
        std::fs::rename(&data_path, backup_path)?;
    }
    std::fs::create_dir_all(&data_path)?;
    anyhow::Ok(data_path)
}

pub async fn new_client_config(
    db_base_path: String,
    home_dir: String,
    media_cache_base_path: String,
    db_passphrase: Option<String>,
    reset_if_existing: bool,
) -> Result<ClientBuilder> {
    let media_cached_path = make_data_path(&media_cache_base_path, &home_dir, false)?;
    RUNTIME
        .spawn(async move {
            let data_path = make_data_path(&db_base_path, &home_dir, reset_if_existing)?;

            let config = match make_store_config(
                &data_path,
                media_cached_path.clone(),
                db_passphrase.as_deref(),
            )
            .await
            {
                Err(MakeStoreConfigError::OpenStoreError(OpenStoreError::InitCipher(e))) => {
                    tracing::warn!("Failed to initialize cipher: {e}");
                    let data_path = make_data_path(&db_base_path, &home_dir, true)?; // try resetting the path and do it again.
                    make_store_config(&data_path, media_cached_path, db_passphrase.as_deref())
                        .await?
                }
                Err(e) => {
                    tracing::warn!("Failed to open database: {e}");
                    return Err(e.into());
                }
                Ok(config) => config,
            };
            let builder = Client::builder()
                .store_config(config)
                .user_agent(format!("acter-testing/{:}", env!("CARGO_PKG_VERSION")));
            Ok(builder)
        })
        .await?
}

lazy_static! {
    static ref FILE_LOGGER: Mutex<Option<Arc<fern::ImplDispatch>>> = Mutex::new(None);
}

#[cfg(feature = "tracing")]
pub fn init_logging(
    log_dir: String,
    filter: String,
    console_logger: Option<Box<dyn Log>>,
) -> Result<()> {
    use tracing_subscriber::layer::SubscriberExt;

    let file_appender = tracing_appender::rolling::minutely(log_dir, "acter-tracing.log");
    let (non_blocking, _guard) = tracing_appender::non_blocking(file_appender);

    let subscriber = tracing_subscriber::registry()
        .with(tracing_subscriber::EnvFilter::new(filter))
        .with(tracing_subscriber::fmt::Layer::new().with_writer(non_blocking))
        .with(tracing_subscriber::fmt::Layer::new().with_writer(std::io::stdout));

    tracing_log::LogTracer::init()?;
    #[cfg(feature = "tracing-console")]
    {
        let console_layer = console_subscriber::spawn();
        tracing::subscriber::set_global_default(subscriber.with(console_layer))?;
    }
    #[cfg(not(feature = "tracing-console"))]
    tracing::subscriber::set_global_default(subscriber)?;

    Ok(())
}

#[cfg(not(feature = "tracing"))]
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
            Local::now().format("[%Y-%m-%d][%H:%M:%S%.6f]"),
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

    let mut path = PathBuf::from(&log_dir);
    path.push("app_");

    let (level, dispatch) = builder
        // Output to file
        .chain(fern::Manual::new(path, "%Y-%m-%d_%H-%M-%S%.f.log"))
        .into_dispatch_with_arc();

    if level == LevelFilter::Off {
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
                let Some((old_path, new_path)) = output else {
                    continue;
                };
                return Ok(old_path.to_string_lossy().to_string());
            }
        }
        None => {
            bail!("You didn’t set up file logger.");
        }
    }
    Ok("".to_owned())
}

fn parse_log_level(level: &str) -> Level {
    match level {
        "debug" => Level::Debug,
        "error" => Level::Error,
        "info" => Level::Info,
        "warn" => Level::Warn,
        _ => Level::Trace,
    }
}

pub fn would_log(target: String, level: String) -> bool {
    log_enabled!(target: &target, parse_log_level(&level))
}

pub fn write_log(
    target: String,
    level: String,
    message: String,
    file: Option<String>,
    line: Option<u32>,
    module_path: Option<String>,
) {
    log::logger().log(
        &Record::builder()
            .args(format_args!("{message}"))
            .level(parse_log_level(&level))
            .target(&target)
            .file(file.as_deref())
            .line(line)
            .module_path(module_path.as_deref())
            .build(),
    );
}

pub fn sanitize(base_path: &str, home: &str) -> PathBuf {
    PathBuf::from(base_path).join(sanitize_filename_reader_friendly::sanitize(home))
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

#[derive(Debug)]
enum MakeStoreConfigError {
    OpenStoreError(OpenStoreError),
    EventCacheStoreError(EventCacheStoreError),
}

impl Display for MakeStoreConfigError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            MakeStoreConfigError::OpenStoreError(i) => {
                write!(f, "MakeStoreConfigError::OpenStoreError {}", i)
            }
            MakeStoreConfigError::EventCacheStoreError(i) => {
                write!(f, "MakeStoreConfigError::EventCacheStoreError {}", i)
            }
        }
    }
}

impl std::error::Error for MakeStoreConfigError {}

impl From<OpenStoreError> for MakeStoreConfigError {
    fn from(value: OpenStoreError) -> Self {
        MakeStoreConfigError::OpenStoreError(value)
    }
}

impl From<EventCacheStoreError> for MakeStoreConfigError {
    fn from(value: EventCacheStoreError) -> Self {
        MakeStoreConfigError::EventCacheStoreError(value)
    }
}

async fn make_store_config(
    path: &Path,
    media_cache_path: PathBuf,
    passphrase: Option<&str>,
) -> Result<StoreConfig, MakeStoreConfigError> {
    // FIXME: this stock holder name probably needs to be decided upon
    //        by the outer part to inform us whether this is the main
    //        process or the background job
    let config = StoreConfig::new("acter".to_owned())
        .crypto_store(SqliteCryptoStore::open(path, passphrase).await?);

    let sql_state_store = SqliteStateStore::open(path, passphrase).await?;
    let event_cache_store = SqliteEventCacheStore::open(path, passphrase).await?;
    let Some(passphrase) = passphrase else {
        return Ok(config
            .state_store(sql_state_store)
            .event_cache_store(event_cache_store));
    };

    let event_cache_store = matrix_sdk_store_file_event_cache::wrap_with_file_cache_and_limits(
        &sql_state_store,
        event_cache_store,
        media_cache_path,
        passphrase,
        #[cfg(target_os = "ios")]
        50,
        #[cfg(not(target_os = "ios"))]
        200,
    )
    .await?;
    Ok(config
        .state_store(sql_state_store)
        .event_cache_store(event_cache_store))
}
