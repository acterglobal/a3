use acter_core::{
    events::{
        news::{self, NewsContent, NewsEntryBuilder},
        Colorize,
    },
    models::{self, ActerModel, AnyActerModel},
    statics::KEYS,
};
use anyhow::{bail, Context, Result};
use core::time::Duration;
use futures::stream::StreamExt;
use matrix_sdk::{
    room::Room,
    ruma::{assign, UInt},
    Client as SdkClient, RoomState,
};
use ruma_common::{MxcUri, OwnedEventId, OwnedRoomId, OwnedUserId};
use ruma_events::room::{
    message::{
        AudioMessageEventContent, FileMessageEventContent, ImageMessageEventContent,
        LocationMessageEventContent, TextMessageEventContent, VideoMessageEventContent,
    },
    ImageInfo,
};
use std::{
    collections::{hash_map::Entry, HashMap},
    ops::Deref,
    path::PathBuf,
};
use tokio::sync::broadcast::Receiver;
use tokio_stream::{wrappers::BroadcastStream, Stream};
use tracing::{trace, warn};

use super::{
    api::FfiBuffer,
    client::Client,
    common::{MsgContent, ThumbnailSize},
    spaces::Space,
    stream::MsgContentDraft,
    RUNTIME,
};

impl Client {
    pub async fn wait_for_news(
        &self,
        key: String,
        timeout: Option<Box<Duration>>,
    ) -> Result<NewsEntry> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let AnyActerModel::NewsEntry(content) = me.wait_for(key.clone(), timeout).await?
                else {
                    bail!("{key} is not a news");
                };
                let room = me
                    .core
                    .client()
                    .get_room(content.room_id())
                    .context("Room not found")?;
                Ok(NewsEntry {
                    client: me.clone(),
                    room,
                    content,
                })
            })
            .await?
    }

    pub async fn latest_news_entries(&self, mut count: u32) -> Result<Vec<NewsEntry>> {
        let mut news = Vec::new();
        let mut rooms_map: HashMap<OwnedRoomId, Room> = HashMap::new();
        let client = self.clone();
        RUNTIME
            .spawn(async move {
                let mut all_news = client
                    .store()
                    .get_list(KEYS::NEWS)
                    .await?
                    .filter_map(|any| {
                        if let AnyActerModel::NewsEntry(t) = any {
                            Some(t)
                        } else {
                            None
                        }
                    })
                    .collect::<Vec<models::NewsEntry>>();
                all_news.sort_by(|a, b| b.meta.origin_server_ts.cmp(&a.meta.origin_server_ts));

                for content in all_news {
                    if count == 0 {
                        break; // we filled what we wanted
                    }
                    let room_id = content.room_id().to_owned();
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
                        content,
                    });
                    count -= 1;
                }
                Ok(news)
            })
            .await?
    }
}

impl Space {
    pub async fn latest_news_entries(&self, mut count: u32) -> Result<Vec<NewsEntry>> {
        let mut news = Vec::new();
        let room_id = self.room_id().to_owned();
        let client = self.client.clone();
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                let mut all_news = client
                    .store()
                    .get_list(&format!("{room_id}::{}", KEYS::NEWS))
                    .await?
                    .filter_map(|any| {
                        if let AnyActerModel::NewsEntry(t) = any {
                            Some(t)
                        } else {
                            None
                        }
                    })
                    .collect::<Vec<models::NewsEntry>>();
                all_news.reverse();

                for content in all_news {
                    if count == 0 {
                        break; // we filled what we wanted
                    }
                    news.push(NewsEntry {
                        client: client.clone(),
                        room: room.clone(),
                        content,
                    });
                    count -= 1;
                }
                Ok(news)
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct NewsSlide {
    client: Client,
    room: Room,
    inner: news::NewsSlide,
}

impl Deref for NewsSlide {
    type Target = news::NewsSlide;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl NewsSlide {
    pub fn type_str(&self) -> String {
        self.inner.content().type_str()
    }

    pub fn has_formatted_text(&self) -> bool {
        matches!(
            self.inner.content(),
            NewsContent::Text(TextMessageEventContent {
                formatted: Some(_),
                ..
            })
        )
    }

    pub fn text(&self) -> String {
        match self.inner.content() {
            NewsContent::Image(ImageMessageEventContent { body, .. }) => body.clone(),
            NewsContent::Audio(AudioMessageEventContent { body, .. }) => body.clone(),
            NewsContent::Video(VideoMessageEventContent { body, .. }) => body.clone(),
            NewsContent::File(FileMessageEventContent { body, .. }) => body.clone(),
            NewsContent::Location(LocationMessageEventContent { body, .. }) => body.clone(),
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

    pub fn msg_content(&self) -> MsgContent {
        match &self.inner.content {
            NewsContent::Text(content) => MsgContent::from(content),
            NewsContent::Image(content) => MsgContent::from(content),
            NewsContent::Audio(content) => MsgContent::from(content),
            NewsContent::Video(content) => MsgContent::from(content),
            NewsContent::File(content) => MsgContent::from(content),
            NewsContent::Location(content) => MsgContent::from(content),
        }
    }

    pub async fn source_binary(
        &self,
        thumb_size: Option<Box<ThumbnailSize>>,
    ) -> Result<FfiBuffer<u8>> {
        // any variable in self can't be called directly in spawn
        match &self.inner.content {
            NewsContent::Text(content) => {
                let buf = Vec::<u8>::new();
                Ok(FfiBuffer::new(buf))
            }
            NewsContent::Image(content) => match thumb_size {
                Some(thumb_size) => {
                    let source = content
                        .info
                        .as_ref()
                        .and_then(|info| info.thumbnail_source.clone())
                        .context("thumbnail source not found")?;
                    self.client.source_binary(source, Some(thumb_size)).await
                }
                None => {
                    self.client
                        .source_binary(content.source.clone(), None)
                        .await
                }
            },
            NewsContent::Audio(content) => {
                if thumb_size.is_some() {
                    warn!("DeveloperError: audio has not thumbnail");
                }
                self.client
                    .source_binary(content.source.clone(), None)
                    .await
            }
            NewsContent::Video(content) => match thumb_size {
                Some(thumb_size) => {
                    let source = content
                        .info
                        .as_ref()
                        .and_then(|info| info.thumbnail_source.clone())
                        .context("thumbnail source not found")?;
                    self.client.source_binary(source, Some(thumb_size)).await
                }
                None => {
                    self.client
                        .source_binary(content.source.clone(), None)
                        .await
                }
            },
            NewsContent::File(content) => match thumb_size {
                Some(thumb_size) => {
                    let source = content
                        .info
                        .as_ref()
                        .and_then(|info| info.thumbnail_source.clone())
                        .context("thumbnail source not found")?;
                    self.client.source_binary(source, Some(thumb_size)).await
                }
                None => {
                    self.client
                        .source_binary(content.source.clone(), None)
                        .await
                }
            },
            NewsContent::Location(content) => {
                if thumb_size.is_none() {
                    warn!("DeveloperError: location has not file");
                }
                let source = content
                    .info
                    .as_ref()
                    .and_then(|info| info.thumbnail_source.clone())
                    .context("thumbnail source not found")?;
                self.client.source_binary(source, thumb_size).await
            }
        }
    }
}

#[derive(Clone, Debug)]
pub struct NewsEntry {
    client: Client,
    room: Room,
    content: models::NewsEntry,
}

impl Deref for NewsEntry {
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
                let AnyActerModel::NewsEntry(content) = client.store().get(&key).await? else {
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

    fn is_joined(&self) -> bool {
        matches!(self.room.state(), RoomState::Joined)
    }

    pub fn update_builder(&self) -> Result<NewsEntryUpdateBuilder> {
        if !self.is_joined() {
            bail!("Can only update news in joined rooms");
        }
        Ok(NewsEntryUpdateBuilder {
            client: self.client.clone(),
            room: self.room.clone(),
            content: self.content.updater(),
        })
    }

    pub fn subscribe_stream(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.subscribe()).map(|_| true)
    }

    pub fn subscribe(&self) -> Receiver<()> {
        let key = self.content.event_id().to_string();
        self.client.subscribe(key)
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

    pub fn room_id(&self) -> OwnedRoomId {
        self.room.room_id().to_owned()
    }

    pub fn sender(&self) -> OwnedUserId {
        self.content.sender().to_owned()
    }

    pub fn event_id(&self) -> OwnedEventId {
        self.content.event_id().to_owned()
    }
}

#[derive(Clone)]
pub struct NewsEntryDraft {
    client: Client,
    room: Room,
    content: NewsEntryBuilder,
    slides: Vec<NewsSlide>,
}

impl NewsEntryDraft {
    pub async fn add_slide(&mut self, base_draft: Box<MsgContentDraft>) -> Result<bool> {
        let room = self.room.clone();
        let client = self.room.client();

        let inner = RUNTIME
            .spawn(async move {
                let slide = base_draft.into_news_slide(client, room).await?;
                anyhow::Ok(slide)
            })
            .await??;
        let slide = NewsSlide {
            client: self.client.clone(),
            room: self.room.clone(),
            inner,
        };
        self.slides.push(slide);
        Ok(true)
    }

    pub fn unset_slides(&mut self) -> &mut Self {
        self.slides.clear();
        self
    }

    pub fn colors(&mut self, colors: Box<Colorize>) -> &mut Self {
        self.content.colors(Some(Box::into_inner(colors)));
        self
    }

    pub fn unset_colors(&mut self) -> &mut Self {
        self.content.colors(None);
        self
    }

    pub async fn send(&mut self) -> Result<OwnedEventId> {
        trace!("starting send");
        let slides = self
            .slides
            .iter()
            .map(|x| (*x.to_owned()).clone())
            .collect();
        self.content.slides(slides);

        let room = self.room.clone();
        trace!("send buildin");
        let content = self.content.build()?;

        trace!("off we go");
        RUNTIME
            .spawn(async move {
                let resp = room.send(content).await?;
                Ok(resp.event_id)
            })
            .await?
    }
}

#[derive(Clone)]
pub struct NewsEntryUpdateBuilder {
    client: Client,
    room: Room,
    content: news::NewsEntryUpdateBuilder,
}

impl NewsEntryUpdateBuilder {
    #[allow(clippy::ptr_arg)]
    pub fn slides(&mut self, slides: &mut Vec<NewsSlide>) -> &mut Self {
        let items = slides.iter().map(|x| (*x.to_owned()).clone()).collect();
        self.content.slides(Some(items));
        self
    }

    pub fn unset_slides(&mut self) -> &mut Self {
        self.content.slides(Some(vec![]));
        self
    }

    pub fn unset_slides_update(&mut self) -> &mut Self {
        self.content.slides(None);
        self
    }

    pub fn colors(&mut self, colors: Box<Colorize>) -> &mut Self {
        self.content.colors(Some(Some(Box::into_inner(colors))));
        self
    }

    pub fn unset_colors(&mut self) -> &mut Self {
        self.content.colors(Some(None));
        self
    }

    pub fn unset_colors_update(&mut self) -> &mut Self {
        self.content.colors(None::<Option<Colorize>>);
        self
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let content = self.content.build()?;
        RUNTIME
            .spawn(async move {
                let resp = room.send(content).await?;
                Ok(resp.event_id)
            })
            .await?
    }
}

impl Space {
    pub fn news_draft(&self) -> Result<NewsEntryDraft> {
        if !self.is_joined() {
            bail!("Unable to create news for spaces we are not part on");
        }
        Ok(NewsEntryDraft {
            client: self.client.clone(),
            room: self.inner.room.clone(),
            content: Default::default(),
            slides: vec![],
        })
    }

    pub fn news_draft_with_builder(&self, content: NewsEntryBuilder) -> Result<NewsEntryDraft> {
        if !self.is_joined() {
            bail!("Unable to create news for spaces we are not part on");
        }
        Ok(NewsEntryDraft {
            client: self.client.clone(),
            room: self.inner.room.clone(),
            content,
            slides: vec![],
        })
    }
}

impl MsgContentDraft {
    async fn into_news_slide(
        self, // into_* fn takes self by value not reference
        client: SdkClient,
        room: Room,
    ) -> Result<news::NewsSlide> {
        match self {
            MsgContentDraft::TextPlain { body } => {
                let text_content = TextMessageEventContent::plain(body);
                Ok(news::NewsSlide {
                    content: NewsContent::Text(text_content),
                    references: Default::default(),
                })
            }
            MsgContentDraft::TextMarkdown { body } => {
                let text_content = TextMessageEventContent::markdown(body);
                Ok(news::NewsSlide {
                    content: NewsContent::Text(text_content),
                    references: Default::default(),
                })
            }
            MsgContentDraft::Image { source, info } => {
                let info = info.expect("image info needed");
                let mimetype = info.mimetype.clone().expect("mimetype needed");
                let content_type = mimetype.parse::<mime::Mime>()?;
                let path = PathBuf::from(source);
                let mut image_content = if room.is_encrypted().await? {
                    let mut reader = std::fs::File::open(path.clone())?;
                    let encrypted_file = client
                        .prepare_encrypted_file(&content_type, &mut reader)
                        .await?;
                    let body = path
                        .file_name()
                        .expect("it is not file")
                        .to_string_lossy()
                        .to_string();
                    ImageMessageEventContent::encrypted(body, encrypted_file)
                } else {
                    let mut image_buf = std::fs::read(path.clone())?;
                    let response = client.media().upload(&content_type, image_buf).await?;
                    let body = path
                        .file_name()
                        .expect("it is not file")
                        .to_string_lossy()
                        .to_string();
                    ImageMessageEventContent::plain(body, response.content_uri)
                };
                image_content.info = Some(Box::new(info));
                Ok(news::NewsSlide {
                    content: NewsContent::Image(image_content),
                    references: Default::default(),
                })
            }
            MsgContentDraft::Audio { source, info } => {
                let info = info.expect("audio info needed");
                let mimetype = info.mimetype.clone().expect("mimetype needed");
                let content_type = mimetype.parse::<mime::Mime>()?;
                let path = PathBuf::from(source);
                let mut audio_content = if room.is_encrypted().await? {
                    let mut reader = std::fs::File::open(path.clone())?;
                    let encrypted_file = client
                        .prepare_encrypted_file(&content_type, &mut reader)
                        .await?;
                    let body = path
                        .file_name()
                        .expect("it is not file")
                        .to_string_lossy()
                        .to_string();
                    AudioMessageEventContent::encrypted(body, encrypted_file)
                } else {
                    let mut audio_buf = std::fs::read(path.clone())?;
                    let response = client.media().upload(&content_type, audio_buf).await?;
                    let body = path
                        .file_name()
                        .expect("it is not file")
                        .to_string_lossy()
                        .to_string();
                    AudioMessageEventContent::plain(body, response.content_uri)
                };
                audio_content.info = Some(Box::new(info));
                Ok(news::NewsSlide {
                    content: NewsContent::Audio(audio_content),
                    references: Default::default(),
                })
            }
            MsgContentDraft::Video { source, info } => {
                let info = info.expect("image info needed");
                let mimetype = info.mimetype.clone().expect("mimetype needed");
                let content_type = mimetype.parse::<mime::Mime>()?;
                let path = PathBuf::from(source);
                let mut video_content = if room.is_encrypted().await? {
                    let mut reader = std::fs::File::open(path.clone())?;
                    let encrypted_file = client
                        .prepare_encrypted_file(&content_type, &mut reader)
                        .await?;
                    let body = path
                        .file_name()
                        .expect("it is not file")
                        .to_string_lossy()
                        .to_string();
                    VideoMessageEventContent::encrypted(body, encrypted_file)
                } else {
                    let mut video_buf = std::fs::read(path.clone())?;
                    let response = client.media().upload(&content_type, video_buf).await?;
                    let body = path
                        .file_name()
                        .expect("it is not file")
                        .to_string_lossy()
                        .to_string();
                    VideoMessageEventContent::plain(body, response.content_uri)
                };
                video_content.info = Some(Box::new(info));
                Ok(news::NewsSlide {
                    content: NewsContent::Video(video_content),
                    references: Default::default(),
                })
            }
            MsgContentDraft::File {
                source,
                info,
                filename,
            } => {
                let info = info.expect("file info needed");
                let mimetype = info.mimetype.clone().expect("mimetype needed");
                let content_type = mimetype.parse::<mime::Mime>()?;
                let path = PathBuf::from(source);
                let mut file_content = if room.is_encrypted().await? {
                    let mut reader = std::fs::File::open(path.clone())?;
                    let encrypted_file = client
                        .prepare_encrypted_file(&content_type, &mut reader)
                        .await?;
                    let body = path
                        .file_name()
                        .expect("it is not file")
                        .to_string_lossy()
                        .to_string();
                    FileMessageEventContent::encrypted(body, encrypted_file)
                } else {
                    let mut file_buf = std::fs::read(path.clone())?;
                    let response = client.media().upload(&content_type, file_buf).await?;
                    let body = path
                        .file_name()
                        .expect("it is not file")
                        .to_string_lossy()
                        .to_string();
                    FileMessageEventContent::plain(body, response.content_uri)
                };
                file_content.info = Some(Box::new(info));
                file_content.filename = filename.clone();
                Ok(news::NewsSlide {
                    content: NewsContent::File(file_content),
                    references: Default::default(),
                })
            }
            MsgContentDraft::Location {
                body,
                geo_uri,
                info,
            } => {
                let mut location_content = LocationMessageEventContent::new(body, geo_uri);
                if let Some(info) = info {
                    location_content.info = Some(Box::new(info));
                }
                Ok(news::NewsSlide {
                    content: NewsContent::Location(location_content),
                    references: Default::default(),
                })
            }
        }
    }
}
