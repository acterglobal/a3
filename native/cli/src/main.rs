#![warn(clippy::all)]

use anyhow::Result;
use clap::Parser;

mod action;
mod config;

use config::EffektioCliConfig;
use flexi_logger::Logger;

#[tokio::main]
async fn main() -> Result<()> {
    let cli = EffektioCliConfig::parse();
    Logger::try_with_str(cli.log)?.start()?;
    cli.action.run().await?;
    Ok(())
}
