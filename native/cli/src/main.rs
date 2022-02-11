#![warn(clippy::all)]

use anyhow::{Context, Result};
use clap::Parser;
use tokio;

use effektio_core::events;
use effektio_core::matrix_sdk;
use effektio_core::ruma;

mod config;
use config::{Action, EffektioCliConfig, PostNews};
use flexi_logger::Logger;
use log::info;

#[tokio::main]
async fn main() -> Result<()> {
    let cli = EffektioCliConfig::parse();
    Logger::try_with_str(cli.log)?.start()?;
    match cli.action {
        Action::PostNews(news) => {
            let client = news.login.client().await?;
            // FIXME: is there a more efficient way? First sync can take very long...
            client.sync_once(Default::default()).await?;
            let room = client.get_room(&news.room).context("Room not found")?;
            info!("Found room {:?}", room.name());
        }
        _ => unimplemented!(),
    }
    Ok(())
}
