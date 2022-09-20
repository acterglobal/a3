use anyhow::{bail, Context, Result};
use clap::Parser;

use crate::config::{LoginConfig, ENV_ROOM};
use effektio_core::events;

use log::info;
use std::ffi::OsStr;
use std::path::PathBuf;

/// Posting a news item to a given room
#[derive(Parser, Debug)]
pub struct PostNews {
    /// The room you want to post the news to
    #[clap(short, long, parse(try_from_str), env = ENV_ROOM)]
    pub room: Box<effektio_core::ruma::RoomId>,
    #[clap(flatten)]
    pub login: LoginConfig,

    /// Path to images to post
    #[clap(short, long, value_hint = clap::ValueHint::FilePath)]
    pub image: Vec<PathBuf>,

    #[clap(short, long)]
    /// Path to video(s) to post
    pub video: Vec<PathBuf>,

    /// Text to posh
    #[clap(short, long)]
    pub text: Vec<String>,

    /// Font/Text color
    #[clap(short, long)]
    pub color: Option<String>,

    /// Background color
    #[clap(short, long)]
    pub background: Option<String>,
}

impl PostNews {
    pub async fn run(&self) -> Result<()> {
        let client = self.login.client().await?;
        // FIXME: is there a more efficient way? First sync can take very long...
        client.sync_once(Default::default()).await?;
        let room = client
            .get_joined_room(&self.room)
            .context("Room not found or not joined")?;
        info!("Found room {:?}", room.name());

        let mut contents = Vec::new();

        for p in &self.image {
            let mime = match p.extension().and_then(OsStr::to_str) {
                Some(".jpg") | Some(".jpeg") => mime::IMAGE_JPEG,
                Some(".png") => mime::IMAGE_PNG,
                _ => mime::IMAGE_STAR,
            };
            let image = std::fs::read(p).context("Couldn't open file for reading")?;

            let res = client.media().upload(&mime, &image).await?;

            contents.push(events::NewsContentType::Image(
                events::ImageMessageEventContent::plain("".to_owned(), res.content_uri, None),
            ));
        }

        for body in &self.text {
            contents.push(events::NewsContentType::Text(
                events::TextMessageEventContent::plain(body),
            ));
        }

        if contents.is_empty() {
            bail!("No content defined.");
        }

        let colors = if self.color.is_some() || self.background.is_some() {
            let color = if let Some(c) = &self.color {
                Some(c.parse()?)
            } else {
                None
            };
            let background = if let Some(c) = &self.background {
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

        Ok(())
    }
}
