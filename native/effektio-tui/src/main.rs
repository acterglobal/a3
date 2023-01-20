#![warn(clippy::all)]

use anyhow::Result;
use clap::Parser;

mod config;
mod ui;

use config::EffektioTuiConfig;
use futures::future::Either;
use futures::pin_mut;
use futures::StreamExt;
use std::sync::mpsc::channel;

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
    let drain = tui_logger::Drain::new();
    // instead of tui_logger::init_logger, we use `env_logger`
    env_logger::Builder::default()
        .parse_filters(&cli.log)
        .format(move |_buf, record|
            // patch the env-logger entry through our drain to the tui-logger
            {
                drain.log(record);
                Ok(())
            })
        .init(); // make this the global logger

    let (sender, rx) = channel::<AppUpdate>();
    let app_dir = if cli.local {
        std::path::PathBuf::new().join(".local")
    } else {
        app_root(AppDataType::UserData, &APP_INFO)?
    };

    if cli.fresh {
        std::fs::remove_dir_all(app_dir.clone())?;
    }

    let mut client = cli.login.client(app_dir).await?;
    let sync_state = client.start_sync();

    tokio::spawn(async move {
        let username = client.user_id().unwrap();
        sender
            .send(AppUpdate::SetUsername(username.to_string()))
            .unwrap();

        let dp = client.account().unwrap().display_name().await.unwrap();
        sender
            .send(AppUpdate::SetUsername(format!("{dp:} ({username:})")))
            .unwrap();

        let sync_stream = sync_state.first_synced_rx().unwrap();
        let history_loaded = sync_state.get_history_loading_rx();

        let main_stream = futures::stream::select(
            history_loaded.map(Either::Right),
            sync_stream.map(Either::Left),
        );

        pin_mut!(main_stream);

        loop {
            match main_stream.next().await {
                Some(Either::Left(synced)) => {
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
                Some(Either::Right(history)) => {
                    tracing::info!("History updated. Done? {:}", history.is_done_loading());
                    if history.is_done_loading() {
                        match client.task_lists().await {
                            Ok(task_lists) => {
                                if task_lists.is_empty() {
                                    tracing::warn!("No task lists found");
                                }
                                sender.send(AppUpdate::SetTasksList(task_lists)).unwrap();
                            }
                            Err(error) => {
                                tracing::error!(?error, "TaskList couldn't be read");
                            }
                        }
                    }
                    sender
                        .send(AppUpdate::SetHistoryLoadState(history))
                        .unwrap();
                }
                None => {}
            }
        }
    });
    ui::run_ui(rx, cli.fullscreen_logs).await?;

    Ok(())
}
