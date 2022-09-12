use android_logger::{Config, FilterBuilder};
use anyhow::Result;
use log::Level;
use matrix_sdk::ClientBuilder;

use super::native;

pub fn new_client_config(base_path: String, home: String) -> Result<ClientBuilder> {
    Ok(native::new_client_config(base_path, home)?
        .user_agent(format!("effektio-android/{:}", env!("CARGO_PKG_VERSION"))))
}

pub fn init_logging(filter: Option<String>) -> Result<()> {
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
