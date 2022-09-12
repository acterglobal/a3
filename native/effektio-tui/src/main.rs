#![warn(clippy::all)]

use anyhow::Result;
use clap::Parser;

mod config;

use config::EffektioTuiConfig;
use flexi_logger::Logger;

use app_dirs2::{app_root, AppDataType, AppInfo};

const APP_INFO: AppInfo = AppInfo {
    name: "Effektio TUI",
    author: "Effektio Team",
};

#[tokio::main]
async fn main() -> Result<()> {
    let cli = EffektioTuiConfig::parse();
    Logger::try_with_str(cli.log)?.start()?;
    let app_dir = app_root(AppDataType::UserData, &APP_INFO)?;

    let client = cli.login.client(app_dir).await?;

    Ok(())
}
