use android_logger::{Config, FilterBuilder};
use anyhow::Result;
use log::Level;
use matrix_sdk::ClientBuilder;
use tracing_subscriber::{fmt::format::FmtSpan, layer::SubscriberExt, EnvFilter};

use super::native;

pub fn new_client_config(base_path: String, home: String) -> Result<ClientBuilder> {
    Ok(native::new_client_config(base_path, home)?.user_agent("effektio-android"))
}

pub fn init_logging(filter: Option<String>) -> Result<()> {
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
