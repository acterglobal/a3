use anyhow::Result;
use crate::config::{ENV_ROOM, LoginConfig};
use clap::Parser;
use effektio_core::ruma;


mod post_news;
mod fetch_news;
mod mock;

pub use mock::Mock;
pub use post_news::PostNews;
pub use fetch_news::FetchNews;



#[derive(clap::Subcommand, Debug)]
pub enum Action {
    /// Post News to a room
    PostNews(PostNews),
    /// Fetch News of the use
    FetchNews(FetchNews),
    /// Room Management
    Mock(Mock),
    /// Room Management
    Manage(Manage),
}

impl Action {
    pub async fn run(&self) -> Result<()> {
        Ok(match &*self{
            Action::PostNews(news) => news.run().await?,
            Action::FetchNews(config) => config.run().await?,
            Action::Mock(config) => config.run().await?,
            _ => unimplemented!(),
        })
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
