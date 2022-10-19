use anyhow::Result;
use flexi_logger;
use matrix_sdk::ClientBuilder;

use super::native;

pub fn new_client_config(base_path: String, home: String) -> Result<ClientBuilder> {
    Ok(native::new_client_config(base_path, home)?.user_agent("effektio-desktop"))
}

pub fn init_logging(filter: Option<String>) -> anyhow::Result<()> {
    std::env::set_var("RUST_BACKTRACE", "1");
    log_panics::init();

    let logger = if let Some(log_str) = filter {
        flexi_logger::Logger::try_with_env_or_str(log_str)?
    } else {
        flexi_logger::Logger::try_with_env()?
    };
    logger
        .adaptive_format_for_stderr(flexi_logger::AdaptiveFormat::Detailed)
        .start()?;
    Ok(())
}
