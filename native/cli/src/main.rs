#![warn(clippy::all)]
#![recursion_limit = "256"]

mod action;
mod config;

use anyhow::Result;
use clap::Parser;
use config::ActerCliConfig;
use env_logger::Builder;

#[tokio::main]
async fn main() -> Result<()> {
    let cli = ActerCliConfig::parse();
    Builder::default().parse_filters(&cli.log).try_init()?;
    cli.action.run().await?;
    Ok(())
}
