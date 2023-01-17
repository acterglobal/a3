use crate::config::{LoginConfig, ENV_ROOM};
use anyhow::Result;
use clap::Parser;
use effektio_core::ruma;

mod fetch_news;
mod mock;
mod post_news;

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
}

impl Action {
    pub async fn run(&self) -> Result<()> {
        match self {
            Action::PostNews(news) => news.run().await?,
            Action::FetchNews(config) => config.run().await?,
            Action::Mock(config) => config.run().await?,
            _ => unimplemented!(),
        };
        Ok(())
    }
}

/// Posting a news item to a given room
#[derive(Parser, Debug)]
pub struct Manage {
    /// The room you want to post the news to
    #[clap(short, long, parse(try_from_str), env = ENV_ROOM)]
    pub room: Box<ruma::RoomId>,
    #[clap(flatten)]
    pub login: LoginConfig,
}
