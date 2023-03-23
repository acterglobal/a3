use crate::config::LoginConfig;

use anyhow::Result;
use clap::Parser;
use futures::StreamExt;

/// Posting a news item to a given room
#[derive(Parser, Debug)]
pub struct List {
    #[clap(flatten)]
    pub login: LoginConfig,
    /// Whether to include chat in the lists
    #[clap(long)]
    pub include_chat: bool,
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
        for sp in client.groups().await? {
            let room_id = sp.room_id();
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
            let acter_space = if sp.is_acter_space().await { 'x' } else { ' ' };
            let display_name = sp.display_name().await?;
            println!(" * [{acter_space}] {room_id}{aliases}: {display_name}");
        }

        if self.include_chat {
            println!("## Chat rooms:");
            for sp in client.conversations().await? {
                println!(" * {} : {}", sp.room_id(), sp.display_name().await?);
            }
        }
        Ok(())
    }
}
