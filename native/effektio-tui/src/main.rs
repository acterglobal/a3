#![warn(clippy::all)]

use anyhow::Result;
use clap::Parser;

mod config;
mod ui;

use config::EffektioTuiConfig;
use flexi_logger::Logger;
use futures::pin_mut;
use futures::StreamExt;
use std::sync::mpsc::channel;
use ui::AppUpdate;

use app_dirs2::{app_root, AppDataType, AppInfo};

const APP_INFO: AppInfo = AppInfo {
    name: "Effektio TUI",
    author: "Effektio Team",
};

#[tokio::main]
async fn main() -> Result<()> {
    let cli = EffektioTuiConfig::parse();
    Logger::try_with_str(cli.log)?.start()?;
    let (sender, rx) = channel::<AppUpdate>();
    let app_dir = app_root(AppDataType::UserData, &APP_INFO)?;

    let client = cli.login.client(app_dir).await?;
    let sync_state = client.start_sync();

    tokio::spawn(async move {
        let username = client.user_id().await.unwrap();
        sender
            .send(AppUpdate::SetUsername(username.to_string()))
            .unwrap();

        let dp = client.display_name().await.unwrap();
        sender
            .send(AppUpdate::SetUsername(format!(
                "{:} ({:})",
                dp,
                username.to_string()
            )))
            .unwrap();

        let sync_stream = sync_state.get_first_synced_rx().unwrap();
        pin_mut!(sync_stream);

        loop {
            if let Some(_x) = sync_stream.next().await {}
        }
    });
    ui::run_ui(rx)?;

    Ok(())
}
