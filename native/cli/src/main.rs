#![warn(clippy::all)]

use anyhow::{bail, Context, Result};
use clap::Parser;

use effektio_core::events;
use effektio_core::matrix_sdk;
use effektio_core::ruma;

mod config;
use crate::ruma::api::client::filter::RoomEventFilter;
use config::{Action, EffektioCliConfig};
use flexi_logger::Logger;
use log::{info, warn};
use std::ffi::OsStr;
use std::fs::File;

#[tokio::main]
async fn main() -> Result<()> {
    let cli = EffektioCliConfig::parse();
    Logger::try_with_str(cli.log)?.start()?;
    match cli.action {
        Action::PostNews(news) => {
            let client = news.login.client().await?;
            // FIXME: is there a more efficient way? First sync can take very long...
            client.sync_once(Default::default()).await?;
            let room = client
                .get_joined_room(&news.room)
                .context("Room not found or not joined")?;
            info!("Found room {:?}", room.name());

            let mut contents = Vec::new();

            for p in news.image {
                let mime = match p.extension().and_then(OsStr::to_str) {
                    Some(".jpg") | Some(".jpeg") => mime::IMAGE_JPEG,
                    Some(".png") => mime::IMAGE_PNG,
                    _ => mime::IMAGE_STAR,
                };
                let mut image = File::open(p).context("Couldn't open file for reading")?;

                let res = client.upload(&mime, &mut image).await?;

                contents.push(events::NewsContentType::Image(
                    events::ImageMessageEventContent::plain("".to_owned(), res.content_uri, None),
                ));
            }

            for body in news.text {
                contents.push(events::NewsContentType::Text(
                    events::TextMessageEventContent::plain(body),
                ));
            }

            if contents.is_empty() {
                bail!("No content defined.");
            }

            let colors = if news.color.is_some() || news.background.is_some() {
                let color = if let Some(c) = news.color {
                    Some(c.parse()?)
                } else {
                    None
                };
                let background = if let Some(c) = news.background {
                    Some(c.parse()?)
                } else {
                    None
                };

                Some(events::Colorize { color, background })
            } else {
                None
            };

            let resp = room
                .send(events::NewsEventDevContent { contents, colors }, None)
                .await?;
            info!("Event sent: {}", resp.event_id);
        }
        Action::FetchNews(config) => {
            let types = vec!["org.effektio.dev.news".to_owned()];
            let client = config.login.client().await?;
            // FIXME: is there a more efficient way? First sync can take very long...
            let sync_resp = client.sync_once(Default::default()).await?;
            let room = client
                .get_joined_room(&config.room)
                .context("Room not found or not joined")?;
            info!("Found room {:?}", room.name());
            let mut query = matrix_sdk::room::MessagesOptions::backward(&sync_resp.next_batch);
            let mut filter = RoomEventFilter::default();
            filter.types = Some(types.as_slice());
            query.filter = filter;
            let messages = room.messages(query).await?;
            if messages.chunk.is_empty() {
                bail!("no messages found");
            }
            for entry in messages.chunk {
                let event = match entry
                    .event
                    .deserialize_as::<ruma::events::MessageEvent<events::NewsEventDevContent>>()
                {
                    Ok(e) => e,
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
                        events::NewsContentType::Image(image) => (
                            "image",
                            image.url.map(|a| a.to_string()).unwrap_or(image.body),
                        ),
                        events::NewsContentType::Video(video) => (
                            "video",
                            video.url.map(|a| a.to_string()).unwrap_or(video.body),
                        ),
                        events::NewsContentType::Text(text) => ("text", text.body),
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
        }
        _ => unimplemented!(),
    }
    Ok(())
}
