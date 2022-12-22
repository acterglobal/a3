use anyhow::{bail, Context, Result};
use clap::Parser;
use effektio_core::{
    events::{NewsContentType, NewsEventDevContent},
    ruma::{
        api::client::filter::RoomEventFilter,
        events::{room::MediaSource, MessageLikeEvent},
        RoomId,
    },
};
use log::{info, warn};

use crate::config::{LoginConfig, ENV_ROOM};

/// Posting a news item to a given room
#[derive(Parser, Debug)]
pub struct FetchNews {
    /// The room you want to post the news to
    #[clap(short, long, parse(try_from_str), env = ENV_ROOM)]
    pub room: Box<RoomId>,
    #[clap(flatten)]
    pub login: LoginConfig,
}

impl FetchNews {
    pub async fn run(&self) -> Result<()> {
        let types = vec!["org.effektio.dev.news".to_owned()];
        let client = self.login.client().await?;
        // FIXME: is there a more efficient way? First sync can take very long...
        let sync_resp = client.sync_once(Default::default()).await?;
        let room = client
            .get_joined_room(&self.room)
            .context("Room not found or not joined")?;
        info!("Found room {:?}", room.name());
        let mut query =
            matrix_sdk::room::MessagesOptions::backward().from(Some(sync_resp.next_batch.as_str()));
        let mut filter = RoomEventFilter::default();
        filter.types = Some(types.as_slice().to_vec());
        query.filter = filter;
        let messages = room.messages(query).await?;
        if messages.chunk.is_empty() {
            bail!("no messages found");
        }
        for entry in messages.chunk {
            let event = match entry
                .event
                .deserialize_as::<MessageLikeEvent<NewsEventDevContent>>()
            {
                Ok(MessageLikeEvent::Original(o)) => o,
                Ok(MessageLikeEvent::Redacted(_)) => {
                    // FIXME: what do we do with redactions
                    continue;
                }
                Err(e) => {
                    warn!("Non Compliant News Entry found: {}", e);
                    continue;
                }
            };
            let news = event.content;
            let mut table = term_table::Table::new();
            table.add_row(term_table::row::Row::new(vec![
                term_table::table_cell::TableCell::new_with_alignment(
                    event.event_id,
                    2,
                    term_table::table_cell::Alignment::Center,
                ),
            ]));
            table.add_row(term_table::row::Row::new(vec![
                term_table::table_cell::TableCell::new_with_alignment(
                    event.room_id,
                    1,
                    term_table::table_cell::Alignment::Center,
                ),
                term_table::table_cell::TableCell::new_with_alignment(
                    event.sender,
                    1,
                    term_table::table_cell::Alignment::Center,
                ),
            ]));
            for content in news.contents {
                let (key, content) = match content {
                    NewsContentType::Image(image) => match image.source {
                        MediaSource::Plain(url) => ("image", url.to_string()),
                        MediaSource::Encrypted(_) => ("image", "<encrypted>".to_owned()),
                    },
                    NewsContentType::Video(video) => match video.source {
                        MediaSource::Plain(url) => ("video", url.to_string()),
                        MediaSource::Encrypted(_) => ("video", "<encrypted>".to_owned()),
                    },
                    NewsContentType::Text(text) => ("text", text.body),
                    _ => ("unknown", "n/a".to_owned()),
                };
                table.add_row(term_table::row::Row::new(vec![
                    term_table::table_cell::TableCell::new_with_alignment(
                        key,
                        1,
                        term_table::table_cell::Alignment::Left,
                    ),
                    term_table::table_cell::TableCell::new_with_alignment(
                        content,
                        1,
                        term_table::table_cell::Alignment::Left,
                    ),
                ]));
            }
            println!("{}", table.render());
        }
        Ok(())
    }
}
