#![warn(clippy::all)]

use anyhow::Result;
use clap::Parser;

use acter_core::ruma;

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
