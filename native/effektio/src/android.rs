use android_logger::{Config, FilterBuilder};
use anyhow::Result;
use log::Level;
use matrix_sdk::config::ClientConfig;
use sanitize_filename_reader_friendly::sanitize;
use std::{fs, path};
use tracing_subscriber::layer::SubscriberExt;
use tracing_subscriber::{fmt::format::FmtSpan, EnvFilter};

pub(crate) fn new_client_config(base_path: String, home: String) -> Result<ClientConfig> {
    let data_path = path::PathBuf::from(base_path).join(sanitize(&home));

    fs::create_dir_all(&data_path)?;

    let config = ClientConfig::new()
        .user_agent("effektio-android")?
        .store_path(&data_path);
    Ok(config)
}

pub(crate) fn init_logging(filter: Option<String>) -> Result<()> {
    // FIXME: replace by tracing feature
    tracing_log::LogTracer::init().ok();
    let env = std::env::var(EnvFilter::DEFAULT_ENV).unwrap_or_else(|_| "warn".to_owned());
    let subscriber = {
        let b = tracing_subscriber::FmtSubscriber::builder()
            .with_span_events(FmtSpan::ACTIVE | FmtSpan::CLOSE)
            .with_env_filter(EnvFilter::new(env))
            .with_writer(std::io::stderr);
        b.finish()
    };

    let subscriber = subscriber.with(tracing_android::layer("org.effektio")?);
    tracing::subscriber::set_global_default(subscriber).ok();
    std::env::set_var("RUST_BACKTRACE", "1");

    log_panics::init();

    let mut log_config = Config::default()
        .with_min_level(Level::Trace)
        .with_tag("effektio-sdk");
    if let Some(filter) = filter {
        log_config = log_config.with_filter(FilterBuilder::new().parse(&filter).build())
    }

    android_logger::init_once(log_config);

    Ok(())
}
