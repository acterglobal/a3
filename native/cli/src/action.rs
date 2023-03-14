use crate::config::{LoginConfig, ENV_ROOM};
use acter_core::ruma;
use anyhow::Result;
use clap::Parser;

// mod execute;
mod mock;

// pub use execute::ExecuteOpts;
pub use mock::MockOpts;

#[derive(clap::Subcommand, Debug)]
pub enum Action {
    /// Mock Data on fresh server
    Mock(MockOpts),
    /// Room Management
    Manage(Manage),
    // /// Template Execution
    // Execute(ExecuteOpts),
}

impl Action {
    pub async fn run(&self) -> Result<()> {
        match self {
            Action::Mock(config) => config.run().await?,
            // Action::Execute(config) => config.run().await?,
            _ => unimplemented!(),
        };
        Ok(())
    }
}

/// Posting a news item to a given room
#[derive(Parser, Debug)]
pub struct Manage {
    /// The room you want to post the news to
    #[clap(short, long, env = ENV_ROOM)]
    pub room: Box<ruma::RoomId>,
    #[clap(flatten)]
    pub login: LoginConfig,
}
