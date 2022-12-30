#![warn(clippy::all)]

use anyhow::Result;
use clap::Parser;

use effektio_core::ruma;

mod action;
mod config;

use config::EffektioCliConfig;
use env_logger::Builder;

#[tokio::main]
async fn main() -> Result<()> {
    let cli = EffektioCliConfig::parse();
    Builder::default().parse_filters(&cli.log).try_init()?;
    cli.action.run().await?;
    Ok(())
}
