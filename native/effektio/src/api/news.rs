use anyhow::{bail, Context, Result};
use effektio_core::{events, models::News, ruma::OwnedEventId};

#[cfg(feature = "with-mocks")]
use effektio_core::mocks::gen_mock_news;
use futures_signals::signal::Mutable;
use matrix_sdk::{room::Joined, Client as MatrixClient};
use std::{
    ffi::OsStr,
    fs::File,
    path::PathBuf, // FIXME: make these optional for wasm
};

use super::{client::Client, group::Group, RUNTIME};

impl Client {
    #[cfg(feature = "with-mocks")]
    pub async fn latest_news(&self) -> Result<Vec<News>> {
        Ok(gen_mock_news())
    }
}

#[derive(Clone)]
pub struct NewsDraft {
    client: MatrixClient,
    room: Joined,
    content: Mutable<events::NewsEventDevContent>,
}

impl NewsDraft {
    pub async fn add_image(&self, path: String) -> Result<u32> {
        let p = PathBuf::try_from(path)?;
        let mime = match p.extension().and_then(OsStr::to_str) {
            Some(".jpg") | Some(".jpeg") => mime::IMAGE_JPEG,
            Some(".png") => mime::IMAGE_PNG,
            _ => mime::IMAGE_STAR,
        };

        let me = self.clone();
        // First we need to log in.
        RUNTIME
            .spawn(async move {
                let mut image = std::fs::read(p).context("Couldn't open file for reading")?;

                let response = me.client.media().upload(&mime, &image).await?;

                let mut inner = me.content.lock_mut();
                let counter = inner.contents.len();

                inner.contents.push(events::NewsContentType::Image(
                    events::ImageMessageEventContent::plain(
                        "".to_string(),
                        response.content_uri,
                        None,
                    ),
                ));
                Ok(counter as u32)
            })
            .await?
    }

    pub fn set_colors(&self, foreground: Option<String>, background: Option<String>) -> Result<()> {
        let mut inner = self.content.lock_mut();
        let colors = if foreground.is_none() && background.is_none() {
            None
        } else {
            Some(events::Colorize {
                color: foreground.map(|c| c.parse()).transpose()?,
                background: background.map(|c| c.parse()).transpose()?,
            })
        };
        inner.colors = colors;
        Ok(())
    }

    pub fn add_text(&self, text: String) -> Result<u32> {
        let mut inner = self.content.lock_mut();
        let counter = inner.contents.len();
        inner.contents.push(events::NewsContentType::Text(
            events::TextMessageEventContent::plain(text),
        ));
        Ok(counter as u32)
    }

    pub async fn add_video(&self, path: String) -> Result<u32> {
        let p = PathBuf::try_from(path)?;
        let mime = match p.extension().and_then(OsStr::to_str) {
            Some(".jpg") | Some(".jpeg") => mime::IMAGE_JPEG,
            Some(".png") => mime::IMAGE_PNG,
            _ => mime::IMAGE_STAR,
        };

        let me = self.clone();
        // First we need to log in.
        RUNTIME
            .spawn(async move {
                let mut image = std::fs::read(p).context("Couldn't open file for reading")?;

                let response = me.client.media().upload(&mime, &image).await?;

                let mut inner = me.content.lock_mut();
                let counter = inner.contents.len();

                inner.contents.push(events::NewsContentType::Image(
                    events::ImageMessageEventContent::plain(
                        "".to_string(),
                        response.content_uri,
                        None,
                    ),
                ));
                Ok(counter as u32)
            })
            .await?
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let inner = me.content.lock_ref().clone();
                let resp = me.room.send(inner, None).await?;
                Ok(resp.event_id)
            })
            .await?
    }
}

impl Group {
    pub fn news_draft(&self) -> Result<NewsDraft> {
        if let matrix_sdk::room::Room::Joined(joined) = &self.inner.room {
            Ok(NewsDraft {
                client: self.client.clone(),
                room: joined.clone(),
                content: Default::default(),
            })
        } else {
            bail!("You can't create news for groups we are not part on")
        }
    }
}
