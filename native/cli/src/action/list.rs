use acter_core::spaces::SpaceRelation;
use anyhow::{Context, Result};
use clap::Parser;
use futures::StreamExt;

use crate::config::LoginConfig;

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

    #[clap(long)]
    pub await_history_sync: bool,
}

impl List {
    pub async fn run(&self) -> Result<()> {
        let mut client = self.login.client().await?;
        tracing::info!(" - Syncing -");
        let sync_state = client.start_sync();

        let mut is_synced = sync_state.first_synced_rx().context("not yet read")?;
        while is_synced.next().await != Some(true) {} // let's wait for it to have synced
        tracing::info!(" - First Sync finished - ");

        if self.await_history_sync {
            tracing::info!(" - Waiting for history to have synced - ");
            sync_state.await_has_synced_history().await?;
            tracing::info!(" - History synced - ");
        }

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
                println!(" - Topic: {topic}");

                if let Some(avatar_url) = sp.avatar_url() {
                    println!(" - Avatar: {avatar_url}");
                }

                let relations = &sp.space_relations().await?;

                if let Some(p) = relations.main_parent() {
                    println!(" - Canonical parent: {} ({})", p.room_id(), p.target_type());
                }

                if relations.other_parents().is_empty() {
                    if relations.main_parent().is_some() {
                        println!(" - No other space parents");
                    } else {
                        println!(" - No space parents");
                    }
                } else {
                    println!(
                        " - Other Space parents: {}",
                        relations
                            .other_parents()
                            .iter()
                            .map(|r| format!("{} ({})", r.room_id(), r.target_type()))
                            .collect::<Vec<_>>()
                            .join(", ")
                    )
                }
                let children = relations.children();
                if children.is_empty() {
                    println!(" - No space children");
                } else {
                    let (suggested, other): (Vec<&SpaceRelation>, Vec<&SpaceRelation>) =
                        children.iter().partition(|p| p.suggested());
                    if !suggested.is_empty() {
                        println!(
                            " - Suggested space children: {}",
                            suggested
                                .iter()
                                .map(|r| format!("{} ({})", r.room_id(), r.target_type()))
                                .collect::<Vec<_>>()
                                .join(", ")
                        );
                        if !other.is_empty() {
                            println!(
                                " - Other space children: {}",
                                other
                                    .iter()
                                    .map(|r| format!("{} ({})", r.room_id(), r.target_type()))
                                    .collect::<Vec<_>>()
                                    .join(", ")
                            );
                        }
                    } else if !other.is_empty() {
                        println!(
                            " - Space children: {}",
                            other
                                .iter()
                                .map(|r| format!("{} ({})", r.room_id(), r.target_type()))
                                .collect::<Vec<_>>()
                                .join(", ")
                        )
                    };
                }

                if is_acter_space {
                    let news_count = sp.latest_news_entries(100).await?.len();
                    let task_lists = sp.task_lists().await?.len();
                    let pins = sp.pins().await?.len();
                    let pinned_links = sp.pinned_links().await?.len();
                    let events_count = sp.calendar_events().await?.len();
                    println!(" - Objects: ");
                    println!("   * {news_count} NewsItems ");
                    println!("   * {task_lists} TaskList ");
                    println!("   * {events_count} Calendar Events ");
                    println!("   * {pins} Pins of which {pinned_links} are links");
                }

                println!(); // give it space to breath
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
