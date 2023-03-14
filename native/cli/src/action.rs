use acter_core::ruma;
use anyhow::Result;
use clap::Parser;

// mod execute;
mod fetch_news;
mod mock;
mod post_news;

use crate::config::{LoginConfig, ENV_ROOM};

// pub use execute::ExecuteOpts;
pub use fetch_news::FetchNews;
pub use mock::MockOpts;
pub use post_news::PostNews;

#[derive(clap::Subcommand, Debug)]
pub enum Action {
    /// Post News to a room
    PostNews(PostNews),
    /// Fetch News of the use
    FetchNews(FetchNews),
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
            Action::PostNews(news) => news.run().await?,
            Action::FetchNews(config) => config.run().await?,
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
