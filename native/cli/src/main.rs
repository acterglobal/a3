#![warn(clippy::all)]

use acter_core::ruma;
use anyhow::Result;
use clap::Parser;

mod action;
mod config;

use config::ActerCliConfig;
use env_logger::Builder;

#[tokio::main]
async fn main() -> Result<()> {
    let cli = ActerCliConfig::parse();
    Builder::default().parse_filters(&cli.log).try_init()?;
    cli.action.run().await?;
    Ok(())
}
