use anyhow::Result;
use env_logger::filter::Builder as FilterBuilder;
use log::LevelFilter;
use matrix_sdk::ClientBuilder;
use std::path::PathBuf;

use super::native;

pub use super::native::sanitize;

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

pub fn init_logging(log_dir: String, filter: Option<String>) -> Result<String> {
    std::env::set_var("RUST_BACKTRACE", "1");
    log_panics::init();

    let log_level = match filter {
        Some(filter) => FilterBuilder::new().parse(&filter).build(),
        None => FilterBuilder::new().build(),
    };

    let file_name = chrono::Local::now()
        .format("app_%Y-%m-%d_%H-%M-%S.log")
        .to_string();
    let mut path = PathBuf::from(log_dir.as_str());
    path.push(file_name);
    let log_path = path.to_string_lossy().to_string();

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
        .chain(std::io::stdout())
        .chain(fern::log_file(log_path.clone())?)
        .apply()?;

    log::info!("log file path: {}", log_path);
    Ok(log_path)
}
