use acter_core::{
    events::{
        news::{self, FallbackNewsContent, NewsContent, NewsEntryBuilder, NewsSlideBuilder},
        Colorize, ColorizeBuilder, ObjRef,
    },
    models::{self, ActerModel, AnyActerModel, ReactionManager},
    statics::KEYS,
};
use anyhow::{bail, Context, Result};
use futures::stream::StreamExt;
use matrix_sdk::{room::Room, RoomState};
use ruma_common::{OwnedEventId, OwnedRoomId, OwnedUserId};
use ruma_events::{
    room::message::{
        AudioMessageEventContent, FileMessageEventContent, ImageMessageEventContent,
        LocationMessageEventContent, TextMessageEventContent, VideoMessageEventContent,
    },
    MessageLikeEventType,
};
use std::{
    collections::{hash_map::Entry, HashMap},
    ops::Deref,
    path::PathBuf,
};
use tokio::sync::broadcast::Receiver;
use tokio_stream::{wrappers::BroadcastStream, Stream};
use tracing::{trace, warn};

use crate::MsgDraft;

use super::{
    api::FfiBuffer,
    client::Client,
    common::{MsgContent, ThumbnailSize},
    spaces::Space,
    stream::msg_draft::MsgContentDraft,
    RUNTIME,
};

impl Client {
    pub async fn wait_for_news(&self, key: String, timeout: Option<u8>) -> Result<NewsEntry> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let AnyActerModel::NewsEntry(content) = me.wait_for(key.clone(), timeout).await?
                else {
                    bail!("{key} is not a news");
                };
                let room = me.room_by_id_typed(content.room_id())?;
                NewsEntry::new(me.clone(), room, content).await
            })
            .await?
    }

    pub async fn latest_news_entries(&self, mut count: u32) -> Result<Vec<NewsEntry>> {
        let mut news = Vec::new();
        let mut rooms_map: HashMap<OwnedRoomId, Room> = HashMap::new();
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let mut all_news = me
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

                let client = me.core.client();
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
                    let news_entry = NewsEntry::new(me.clone(), room, content).await?;
                    news.push(news_entry);
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
                    news.push(NewsEntry::new(client.clone(), room.clone(), content).await?);
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
    unique_id: String,
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

    pub fn unique_id(&self) -> String {
        self.unique_id.clone()
    }

    pub fn colors(&self) -> Option<Colorize> {
        self.inner.colors.to_owned()
    }

    pub fn msg_content(&self) -> MsgContent {
        match &self.inner.content {
            NewsContent::Image(content)
            | NewsContent::Fallback(FallbackNewsContent::Image(content)) => {
                MsgContent::from(content)
            }
            NewsContent::File(content)
            | NewsContent::Fallback(FallbackNewsContent::File(content)) => {
                MsgContent::from(content)
            }
            NewsContent::Location(content)
            | NewsContent::Fallback(FallbackNewsContent::Location(content)) => {
                MsgContent::from(content)
            }
            NewsContent::Audio(content)
            | NewsContent::Fallback(FallbackNewsContent::Audio(content)) => {
                MsgContent::from(content)
            }
            NewsContent::Video(content)
            | NewsContent::Fallback(FallbackNewsContent::Video(content)) => {
                MsgContent::from(content)
            }
            NewsContent::Text(content)
            | NewsContent::Fallback(FallbackNewsContent::Text(content)) => {
                MsgContent::from(content)
            }
        }
    }

    pub async fn source_binary(
        &self,
        thumb_size: Option<Box<ThumbnailSize>>,
    ) -> Result<FfiBuffer<u8>> {
        // any variable in self can't be called directly in spawn
        match &self.inner.content {
            NewsContent::Text(content)
            | NewsContent::Fallback(FallbackNewsContent::Text(content)) => {
                let buf = Vec::<u8>::new();
                Ok(FfiBuffer::new(buf))
            }

            NewsContent::Image(content)
            | NewsContent::Fallback(FallbackNewsContent::Image(content)) => match thumb_size {
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

            NewsContent::Audio(content)
            | NewsContent::Fallback(FallbackNewsContent::Audio(content)) => {
                if thumb_size.is_some() {
                    warn!("DeveloperError: audio has not thumbnail");
                }
                self.client
                    .source_binary(content.source.clone(), None)
                    .await
            }

            NewsContent::Video(content)
            | NewsContent::Fallback(FallbackNewsContent::Video(content)) => match thumb_size {
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

            NewsContent::File(content)
            | NewsContent::Fallback(FallbackNewsContent::File(content)) => match thumb_size {
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
            NewsContent::Location(content)
            | NewsContent::Fallback(FallbackNewsContent::Location(content)) => {
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

    pub fn references(&mut self) -> Vec<ObjRef> {
        self.inner.references().clone()
    }
}

#[derive(Clone)]
pub struct NewsSlideDraft {
    content: MsgContentDraft,
    references: Vec<ObjRef>,
    colorize_builder: ColorizeBuilder,
}

impl NewsSlideDraft {
    fn new(content: MsgContentDraft) -> Self {
        NewsSlideDraft {
            content,
            references: vec![],
            colorize_builder: ColorizeBuilder::default(),
        }
    }

    #[allow(clippy::boxed_local)]
    pub fn color(&mut self, colors: Box<ColorizeBuilder>) {
        self.colorize_builder = *colors;
    }

    async fn build(self, client: &Client, room: &Room) -> Result<news::NewsSlide> {
        let content = match self.content {
            MsgContentDraft::TextPlain { body } => {
                let text_content = TextMessageEventContent::plain(body);
                NewsContent::Text(text_content)
            }
            MsgContentDraft::TextMarkdown { body } => {
                let text_content = TextMessageEventContent::markdown(body);
                NewsContent::Text(text_content)
            }
            MsgContentDraft::TextHtml { html, plain } => {
                let text_content = TextMessageEventContent::html(plain, html);
                NewsContent::Text(text_content)
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

                NewsContent::Image(image_content)
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

                NewsContent::Audio(audio_content)
            }
            MsgContentDraft::Video { source, info } => {
                let info = info.expect("video info needed");
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

                NewsContent::Video(video_content)
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
                file_content.filename = filename;

                NewsContent::File(file_content)
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
                NewsContent::Location(location_content)
            }
        };
        Ok(NewsSlideBuilder::default()
            .content(content)
            .references(self.references)
            .colors(self.colorize_builder.build())
            .build()?)
    }

    #[allow(clippy::boxed_local)]
    pub fn add_reference(&mut self, reference: Box<ObjRef>) -> &Self {
        self.references.push(*reference);
        self
    }

    pub fn unset_references(&mut self) -> &Self {
        self.references.clear();
        self
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
    pub async fn new(client: Client, room: Room, content: models::NewsEntry) -> Result<Self> {
        Ok(NewsEntry {
            client,
            room,
            content,
        })
    }

    pub fn slides_count(&self) -> u8 {
        self.content.slides().len() as u8
    }

    pub fn get_slide(&self, pos: u8) -> Option<NewsSlide> {
        let unique_id = format!("{}-${pos}", self.content.event_id());
        self.content
            .slides()
            .get(pos as usize)
            .map(|inner| NewsSlide {
                inner: inner.clone(),
                client: self.client.clone(),
                room: self.room.clone(),
                unique_id,
            })
    }

    pub fn slides(&self) -> Vec<NewsSlide> {
        let event_id = self.content.event_id();
        self.content
            .slides()
            .iter()
            .enumerate()
            .map(|(pos, slide)| {
                (NewsSlide {
                    inner: slide.clone(),
                    client: self.client.clone(),
                    room: self.room.clone(),
                    unique_id: format!("${event_id}-${pos}"),
                })
            })
            .collect()
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
                NewsEntry::new(client, room, content).await
            })
            .await?
    }

    pub async fn reactions(&self) -> Result<crate::ReactionManager> {
        crate::ReactionManager::new(
            self.client.clone(),
            self.room.clone(),
            self.content.event_id().to_owned(),
        )
        .await
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
        crate::CommentsManager::new(client, room, event_id).await
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
    slides: Vec<NewsSlideDraft>,
}

impl NewsEntryDraft {
    pub async fn add_slide(&mut self, draft: Box<NewsSlideDraft>) -> Result<bool> {
        self.slides.push(*draft);
        Ok(true)
    }

    pub fn slides(&self) -> Vec<NewsSlideDraft> {
        self.slides.clone()
    }

    pub fn swap_slides(&mut self, from: u8, to: u8) -> Result<&mut Self> {
        if to > self.slides.len() as u8 {
            bail!("upper bound is exceeded")
        }
        self.slides.swap(from as usize, to as usize);
        Ok(self)
    }

    pub fn unset_slides(&mut self) -> &mut Self {
        self.slides.clear();
        self
    }

    pub async fn send(&mut self) -> Result<OwnedEventId> {
        trace!("starting send");
        let client = self.client.clone();
        let room = self.room.clone();
        let my_id = self.client.user_id()?;
        let slides_drafts = self.slides.clone();
        let mut builder = self.content.clone();

        RUNTIME
            .spawn(async move {
                let mut slides = vec![];
                for slide in &slides_drafts {
                    let saved_slide = slide.to_owned().build(&client, &room).await?;
                    slides.push(saved_slide);
                }
                builder.slides(slides);

                trace!("send buildin");
                let content = builder.build()?;
                trace!("off we go");
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::RoomMessage)
                    .await?;
                if !permitted {
                    bail!("No permissions to send message in this room");
                }
                let response = room.send(content).await?;
                Ok(response.event_id)
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
    pub async fn add_slide(&mut self, draft: Box<NewsSlideDraft>) -> Result<bool> {
        let client = self.client.clone();
        let room = self.room.clone();
        let mut slides = vec![];

        let slide = RUNTIME
            .spawn(async move {
                let draft = draft.build(&client, &room).await?;
                anyhow::Ok(draft)
            })
            .await??;

        slides.push(slide);

        self.content.slides(Some(slides));
        Ok(true)
    }

    pub fn swap_slides(&mut self, from: u8, to: u8) -> Result<&mut Self> {
        let content = self.content.build()?;
        let mut slides = content.slides.expect("content slides");
        if to > slides.len() as u8 {
            bail!("upper bound is exceeded")
        }
        slides.swap(from as usize, to as usize);
        self.content.slides(Some(slides));
        Ok(self)
    }

    pub fn unset_slides(&mut self) -> &mut Self {
        self.content.slides(Some(vec![]));
        self
    }

    pub fn unset_slides_update(&mut self) -> &mut Self {
        self.content.slides(None);
        self
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let my_id = self.client.user_id()?;
        let content = self.content.build()?;

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::RoomMessage)
                    .await?;
                if !permitted {
                    bail!("No permissions to send message in this room");
                }
                let response = room.send(content).await?;
                Ok(response.event_id)
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
}

impl From<MsgDraft> for NewsSlideDraft {
    fn from(value: MsgDraft) -> Self {
        NewsSlideDraft::new(value.inner)
    }
}
impl MsgDraft {
    pub fn into_news_slide_draft(&self) -> NewsSlideDraft {
        self.clone().into()
    }
}
