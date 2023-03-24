use crate::config::LoginConfig;

use anyhow::Result;
use clap::Parser;
use futures::StreamExt;

/// Posting a news item to a given room
#[derive(Parser, Debug)]
pub struct List {
    #[clap(flatten)]
    pub login: LoginConfig,
    /// Whether to list chat, too
    #[clap(long)]
    pub list_chats: bool,
    #[clap(long)]
    pub details: bool,
}

impl List {
    pub async fn run(&self) -> Result<()> {
        let mut client = self.login.client().await?;
        tracing::info!(" - Syncing -");
        let sync_state = client.start_sync();

        let mut is_synced = sync_state.first_synced_rx().expect("note yet read");
        while is_synced.next().await != Some(true) {} // let's wait for it to have synced
        tracing::info!(" - First Sync finished - ");

        println!("## Spaces:");
        for sp in client.spaces().await? {
            let room_id = sp.room_id();
            let is_acter_space = sp.is_acter_space().await;
            let acter_space = if is_acter_space { 'x' } else { ' ' };
            let display_name = sp.display_name().await?;
            println!(" ## [{acter_space}] {room_id}: {display_name}");
            if self.details {
                let aliases = {
                    let aliases = sp.alt_aliases();
                    if aliases.is_empty() {
                        "".to_owned()
                    } else {
                        format!(
                            " ( {} )",
                            aliases
                                .iter()
                                .map(ToString::to_string)
                                .collect::<Vec<_>>()
                                .join(", ")
                        )
                    }
                };
                if !aliases.is_empty() {
                    println!(" - aliases: {aliases}");
                }
                let topic = sp.topic().unwrap_or_default();
                println!(" - topic: {topic}");

                if let Some(avatar_url) = sp.avatar_url() {
                    println!(" - avatar: {avatar_url}");
                }

                if is_acter_space {
                    let news_count = sp.latest_news(100).await?.len();
                    let task_lists = sp.task_lists().await?.len();
                    let pins = sp.pins().await?.len();
                    let pinned_links = sp.pinned_links().await?.len();
                    println!(" - Objects: ");
                    println!("   * {news_count} NewsItems ");
                    println!("   * {task_lists} TaskList ");
                    println!("   * {pins} Pins of which {pinned_links} are links");
                }

                println!(""); // give it space to breath
            }
        }

        if self.list_chats {
            println!("## Chat rooms:");
            for sp in client.conversations().await? {
                println!(" * {} : {}", sp.room_id(), sp.display_name().await?);
            }
        }
        Ok(())
    }
}
