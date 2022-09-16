#![warn(clippy::all)]

use anyhow::Result;
use clap::Parser;

mod config;
mod ui;

use config::EffektioTuiConfig;
use futures::pin_mut;
use futures::StreamExt;
use std::sync::mpsc::channel;
use tui_logger;
use ui::AppUpdate;

use app_dirs2::{app_root, AppDataType, AppInfo};

const APP_INFO: AppInfo = AppInfo {
    name: "effektio-tui",
    author: "Effektio Team",
};

#[tokio::main]
async fn main() -> Result<()> {
    let cli = EffektioTuiConfig::parse();

    // Set max_log_level to Trace
    tui_logger::init_logger(log::LevelFilter::Trace).unwrap();

    // Set default level for unknown targets to Trace
    tui_logger::set_default_level(log::LevelFilter::Warn);
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
            if let Some(synced) = sync_stream.next().await {
                sender.send(AppUpdate::SetSynced(synced)).unwrap();
                if synced {
                    // let's update the chats;
                    let conversastions = client.conversations().await.unwrap();
                    sender
                        .send(AppUpdate::UpdateConversations(conversastions))
                        .unwrap();

                    // let's update the groups;
                    let groups = client.groups().await.unwrap();
                    sender.send(AppUpdate::UpdateGroups(groups)).unwrap();
                }
            }
        }
    });
    ui::run_ui(rx)?;

    Ok(())
}
