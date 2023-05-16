use acter_core::{
    events::{
        news::{self, NewsContent, NewsEntryBuilder},
        AudioMessageEventContent, FileMessageEventContent, Icon, ImageMessageEventContent,
        TextMessageEventContent, VideoMessageEventContent,
    },
    models::{self, ActerModel, AnyActerModel, Color},
    ruma::{OwnedEventId, OwnedRoomId},
    statics::KEYS,
};
use anyhow::{bail, Context, Result};
use async_broadcast::Receiver;
use core::time::Duration;
use matrix_sdk::{
    media::{MediaFormat, MediaRequest},
    room::{Joined, Room},
};
use std::collections::{hash_map::Entry, HashMap};

use super::{
    api::FfiBuffer,
    client::Client,
    common::{AudioDesc, FileDesc, ImageDesc, TextDesc, VideoDesc},
    spaces::Space,
    RUNTIME,
};

impl Client {
    pub async fn wait_for_news(
        &self,
        key: String,
        timeout: Option<Box<Duration>>,
    ) -> Result<NewsEntry> {
        let AnyActerModel::NewsEntry(content) = self.wait_for(key.clone(), timeout).await? else {
            bail!("{key} is not a news");
        };
        let room = self
            .core
            .client()
            .get_room(content.room_id())
            .context("Room not found")?;
        Ok(NewsEntry {
            client: self.clone(),
            room,
            content,
        })
    }

    pub async fn latest_news(&self, mut count: u32) -> Result<Vec<NewsEntry>> {
        let mut news = Vec::new();
        let mut rooms_map: HashMap<OwnedRoomId, Room> = HashMap::new();
        let client = self.clone();
        let mut all_news = self
            .store()
            .get_list(KEYS::NEWS)
            .await
            .context("Couldn't get news list from store")?
            .filter_map(|any| {
                if let AnyActerModel::NewsEntry(t) = any {
                    Some(t)
                } else {
                    None
                }
            })
            .collect::<Vec<models::NewsEntry>>();
        all_news.reverse();

        for t in all_news {
            if count == 0 {
                break; // we filled what we wanted
            }
            let room_id = t.room_id().to_owned();
            let room = match rooms_map.entry(room_id) {
                Entry::Occupied(t) => t.get().clone(),
                Entry::Vacant(e) => {
                    if let Some(room) = client.get_room(e.key()) {
                        e.insert(room.clone());
                        room
                    } else {
                        /// User not part of the room anymore, ignore
                        continue;
                    }
                }
            };
            news.push(NewsEntry {
                client: client.clone(),
                room,
                content: t,
            });
            count -= 1;
        }
        Ok(news)
    }
}

impl Space {
    pub async fn latest_news(&self, mut count: u32) -> Result<Vec<NewsEntry>> {
        let mut news = Vec::new();
        let room_id = self.room_id();
        let mut all_news = self
            .client
            .store()
            .get_list(&format!("{room_id}::{}", KEYS::NEWS))
            .await
            .context("Couldn't get news list from store")?
            .filter_map(|any| {
                if let AnyActerModel::NewsEntry(t) = any {
                    Some(t)
                } else {
                    None
                }
            })
            .collect::<Vec<models::NewsEntry>>();
        all_news.reverse();

        for t in all_news {
            if count == 0 {
                break; // we filled what we wanted
            }
            news.push(NewsEntry {
                client: self.client.clone(),
                room: self.room.clone(),
                content: t,
            });
            count -= 1;
        }
        Ok(news)
    }
}

#[derive(Clone, Debug)]
pub struct NewsSlide {
    client: Client,
    room: Room,
    inner: news::NewsSlide,
}

impl std::ops::Deref for NewsSlide {
    type Target = news::NewsSlide;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl NewsSlide {
    pub fn type_str(&self) -> String {
        self.inner.content().type_str()
    }

    pub fn text(&self) -> String {
        match self.inner.content() {
            NewsContent::Audio(AudioMessageEventContent { body, .. }) => body.clone(),
            NewsContent::File(FileMessageEventContent { body, .. }) => body.clone(),
            NewsContent::Image(ImageMessageEventContent { body, .. }) => body.clone(),
            NewsContent::Video(VideoMessageEventContent { body, .. }) => body.clone(),
            NewsContent::Text(TextMessageEventContent {
                formatted, body, ..
            }) => {
                if let Some(formatted) = formatted {
                    formatted.body.clone()
                } else {
                    body.clone()
                }
            }
        }
    }

    pub fn image_desc(&self) -> Option<ImageDesc> {
        self.inner.content().image().and_then(|content| {
            content
                .info
                .map(|info| ImageDesc::new(content.body, content.source, *info))
        })
    }

    pub async fn image_binary(&self) -> Result<FfiBuffer<u8>> {
        // any variable in self can't be called directly in spawn
        let Some(content) = self.inner.content().image() else {
            bail!("Not an image");
        };
        let client = self.client.clone();
        let request = MediaRequest {
            source: content.source,
            format: MediaFormat::File,
        };
        RUNTIME
            .spawn(async move {
                let buf = client.media().get_media_content(&request, false).await.context("Couldn't get media content")?;
                Ok(FfiBuffer::new(buf))
            })
            .await?
    }

    pub fn audio_desc(&self) -> Option<AudioDesc> {
        self.inner.content().audio().and_then(|content| {
            content
                .info
                .map(|info| AudioDesc::new(content.body, content.source, *info))
        })
    }

    pub async fn audio_binary(&self) -> Result<FfiBuffer<u8>> {
        // any variable in self can't be called directly in spawn
        let Some(content) = self.inner.content().audio() else {
            bail!("Not an audio");
        };
        let client = self.client.clone();
        let request = MediaRequest {
            source: content.source,
            format: MediaFormat::File,
        };
        RUNTIME
            .spawn(async move {
                let buf = client.media().get_media_content(&request, false).await.context("Couldn't get media content")?;
                Ok(FfiBuffer::new(buf))
            })
            .await?
    }

    pub fn video_desc(&self) -> Option<VideoDesc> {
        self.inner.content().video().and_then(|content| {
            content
                .info
                .map(|info| VideoDesc::new(content.body, content.source, *info))
        })
    }

    pub async fn video_binary(&self) -> Result<FfiBuffer<u8>> {
        // any variable in self can't be called directly in spawn
        let Some(content) = self.inner.content().video() else {
            bail!("Not a video");
        };
        let client = self.client.clone();
        let request = MediaRequest {
            source: content.source,
            format: MediaFormat::File,
        };
        RUNTIME
            .spawn(async move {
                let buf = client.media().get_media_content(&request, false).await.context("Couldn't get media content")?;
                Ok(FfiBuffer::new(buf))
            })
            .await?
    }

    pub fn file_desc(&self) -> Option<FileDesc> {
        self.inner.content().file().and_then(|content| {
            content
                .info
                .map(|info| FileDesc::new(content.body, content.source, *info))
        })
    }

    pub async fn file_binary(&self) -> Result<FfiBuffer<u8>> {
        // any variable in self can't be called directly in spawn
        let Some(content) = self.inner.content().file() else {
            bail!("Not a file");
        };
        let client = self.client.clone();
        let request = MediaRequest {
            source: content.source,
            format: MediaFormat::File,
        };
        RUNTIME
            .spawn(async move {
                let buf = client.media().get_media_content(&request, false).await.context("Couldn't get media content")?;
                Ok(FfiBuffer::new(buf))
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct NewsEntry {
    client: Client,
    room: Room,
    content: models::NewsEntry,
}

impl std::ops::Deref for NewsEntry {
    type Target = models::NewsEntry;
    fn deref(&self) -> &Self::Target {
        &self.content
    }
}

/// Custom functions
impl NewsEntry {
    pub fn slides_count(&self) -> u8 {
        self.content.slides().len() as u8
    }

    pub fn get_slide(&self, pos: u8) -> Option<NewsSlide> {
        self.content
            .slides()
            .get(pos as usize)
            .map(|inner| NewsSlide {
                inner: inner.clone(),
                client: self.client.clone(),
                room: self.room.clone(),
            })
    }

    pub async fn refresh(&self) -> Result<NewsEntry> {
        let key = self.content.event_id().to_string();
        let client = self.client.clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let AnyActerModel::NewsEntry(content) = client.store().get(&key).await.context("Couldn't get news entry from store")? else {
                    bail!("Refreshing failed. {key} not a news")
                };
                Ok(NewsEntry {
                    client,
                    room,
                    content,
                })
            })
            .await?
    }

    pub fn update_builder(&self) -> Result<NewsEntryUpdateBuilder> {
        let Room::Joined(joined) = &self.room else {
            bail!("Can only update news in joined rooms");
        };
        Ok(NewsEntryUpdateBuilder {
            client: self.client.clone(),
            room: joined.clone(),
            content: self.content.updater(),
        })
    }

    pub fn subscribe(&self) -> Receiver<()> {
        let key = self.content.event_id().to_string();
        self.client.executor().subscribe(key)
    }

    pub async fn comments(&self) -> Result<crate::CommentsManager> {
        let client = self.client.clone();
        let room = self.room.clone();
        let event_id = self.content.event_id().to_owned();

        RUNTIME
            .spawn(async move {
                let inner =
                    models::CommentsManager::from_store_and_event_id(client.store(), &event_id)
                        .await;
                Ok(crate::CommentsManager::new(client, room, inner))
            })
            .await?
    }

    pub fn comments_count(&self) -> u32 {
        4
    }

    pub fn likes_count(&self) -> u32 {
        19
    }
}

#[derive(Clone)]
pub struct NewsEntryDraft {
    client: Client,
    room: Joined,
    content: NewsEntryBuilder,
}

impl NewsEntryDraft {
    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let content = self.content.build().context("building failed in event content of news entry")?;
        RUNTIME
            .spawn(async move {
                let resp = room.send(content, None).await.context("Couldn't send news entry")?;
                Ok(resp.event_id)
            })
            .await?
    }
}

#[derive(Clone)]
pub struct NewsEntryUpdateBuilder {
    client: Client,
    room: Joined,
    content: news::NewsEntryUpdateBuilder,
}

impl NewsEntryUpdateBuilder {
    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let content = self.content.build().context("building failed in event content of news event update")?;
        RUNTIME
            .spawn(async move {
                let resp = room.send(content, None).await.context("Couldn't send news entry update")?;
                Ok(resp.event_id)
            })
            .await?
    }
}

impl Space {
    pub fn news_draft(&self) -> Result<NewsEntryDraft> {
        let Room::Joined(joined) = &self.inner.room else {
            bail!("You can't create news for spaces we are not part on")
        };
        Ok(NewsEntryDraft {
            client: self.client.clone(),
            room: joined.clone(),
            content: Default::default(),
        })
    }

    pub fn news_draft_with_builder(&self, content: NewsEntryBuilder) -> Result<NewsEntryDraft> {
        let Room::Joined(joined) = &self.inner.room else {
            bail!("You can't create news for spaces we are not part on")
        };
        Ok(NewsEntryDraft {
            client: self.client.clone(),
            room: joined.clone(),
            content,
        })
    }
}
