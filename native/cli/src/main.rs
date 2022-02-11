#![warn(clippy::all)]

use anyhow::{bail, Context, Result};
use clap::Parser;
use tokio;

use effektio_core::events;
use effektio_core::matrix_sdk;
use effektio_core::ruma;

mod config;
use config::{Action, EffektioCliConfig, PostNews};
use flexi_logger::Logger;
use log::info;
use mime;
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
                Some(events::Colorize {
                    color: news.color.clone(),
                    background: news.background.clone(),
                })
            } else {
                None
            };

            let resp = room
                .send(events::NewsEventDevContent { contents, colors }, None)
                .await?;
            info!("Event sent: {}", resp.event_id);
        }
        _ => unimplemented!(),
    }
    Ok(())
}
