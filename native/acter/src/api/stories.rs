use acter_matrix::{
    events::{
        stories::{self, StoryBuilder, StoryContent, StorySlideBuilder},
        Colorize, ColorizeBuilder, ObjRef as CoreObjRef, ObjRefBuilder,
        RefDetails as CoreRefDetails, RefPreview,
    },
    models::{self, can_redact, ActerModel, AnyActerModel, ReactionManager},
    referencing::{IndexKey, SectionIndex},
};
use anyhow::{bail, Context, Result};
use futures::stream::StreamExt;
use matrix_sdk::room::Room;
use matrix_sdk_base::{
    ruma::{
        events::{room::message::MessageType, MessageLikeEventType},
        OwnedEventId, OwnedRoomId, OwnedUserId,
    },
    RoomState,
};
use std::{
    collections::{hash_map::Entry, HashMap},
    ops::Deref,
};
use tokio::sync::broadcast::Receiver;
use tokio_stream::{wrappers::BroadcastStream, Stream};
use tracing::{trace, warn};

use crate::MsgDraft;

use super::{
    api::FfiBuffer,
    client::Client,
    common::ThumbnailSize,
    deep_linking::{ObjRef, RefDetails},
    spaces::Space,
    timeline::MsgContent,
    RUNTIME,
};

impl Client {
    pub async fn wait_for_story(&self, key: String, timeout: Option<u8>) -> Result<Story> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let AnyActerModel::Story(content) = me.wait_for(key.clone(), timeout).await? else {
                    bail!("{key} is not a news");
                };
                let room = me.room_by_id_typed(content.room_id())?;
                Ok(Story::new(me, room, content))
            })
            .await?
    }
    pub async fn latest_stories(&self, mut count: u32) -> Result<Vec<Story>> {
        Ok(self
            .models_of_list_with_room(IndexKey::Section(SectionIndex::Stories))
            .await?
            .take_while(|_| {
                if count > 0 {
                    count -= 1;
                    true
                } else {
                    false
                }
            })
            .map(|(inner, room)| Story::new(self.clone(), room, inner))
            .collect())
    }
}

impl Space {
    pub async fn latest_stories(&self, mut count: u32) -> Result<Vec<Story>> {
        let room = self.room.clone();
        let room_id = room.room_id().to_owned();
        Ok(self
            .client
            .models_of_list_with_room_under_check(
                IndexKey::RoomSection(room_id, SectionIndex::Stories),
                move |_r| Ok(room.clone()),
            )
            .await?
            .take_while(|_| {
                if count > 0 {
                    count -= 1;
                    true
                } else {
                    false
                }
            })
            .map(|(inner, room)| Story::new(self.client.clone(), room, inner))
            .collect())
    }
}

#[derive(Clone, Debug)]
pub struct StorySlide {
    client: Client,
    room: Room,
    unique_id: String,
    inner: stories::StorySlide,
}

impl Deref for StorySlide {
    type Target = stories::StorySlide;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl StorySlide {
    pub fn type_str(&self) -> String {
        self.inner.content().type_str()
    }

    pub fn unique_id(&self) -> String {
        self.unique_id.clone()
    }

    pub fn colors(&self) -> Option<Colorize> {
        self.inner.colors.clone()
    }

    pub fn msg_content(&self) -> MsgContent {
        match &self.inner.content {
            StoryContent::Image(content) => MsgContent::from(content),
            StoryContent::File(content) => MsgContent::from(content),
            StoryContent::Location(content) => MsgContent::from(content),
            StoryContent::Audio(content) => MsgContent::from(content),
            StoryContent::Video(content) => MsgContent::from(content),
            StoryContent::Text(content) => MsgContent::from(content),
        }
    }

    pub async fn source_binary(
        &self,
        thumb_size: Option<Box<ThumbnailSize>>,
    ) -> Result<FfiBuffer<u8>> {
        // any variable in self can’t be called directly in spawn
        match &self.inner.content {
            StoryContent::Text(content) => {
                let buf = Vec::<u8>::new();
                Ok(FfiBuffer::new(buf))
            }

            StoryContent::Image(content) => match thumb_size {
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

            StoryContent::Audio(content) => {
                if thumb_size.is_some() {
                    warn!("DeveloperError: audio has not thumbnail");
                }
                self.client
                    .source_binary(content.source.clone(), None)
                    .await
            }

            StoryContent::Video(content) => match thumb_size {
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

            StoryContent::File(content) => match thumb_size {
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
            StoryContent::Location(content) => {
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
        self.inner
            .references()
            .iter()
            .map(|inner| ObjRef::new(self.client.deref().clone(), inner.clone()))
            .collect()
    }
}

#[derive(Clone)]
pub struct StorySlideDraft {
    content: MsgDraft,
    references: Vec<CoreObjRef>,
    colorize_builder: ColorizeBuilder,
}

impl StorySlideDraft {
    fn new(content: MsgDraft) -> Self {
        StorySlideDraft {
            content,
            references: vec![],
            colorize_builder: ColorizeBuilder::default(),
        }
    }

    pub fn color(&mut self, colors: Box<ColorizeBuilder>) {
        self.colorize_builder = *colors;
    }

    async fn build(self, client: &Client, room: &Room) -> Result<stories::StorySlide> {
        let msg = self.content.into_room_msg(room).await?;
        let content = match msg.msgtype {
            MessageType::Text(msg) => StoryContent::Text(msg),
            MessageType::Image(content) => StoryContent::Image(content),
            MessageType::Audio(content) => StoryContent::Audio(content),
            MessageType::Video(content) => StoryContent::Video(content),
            MessageType::File(content) => StoryContent::File(content),
            MessageType::Location(content) => StoryContent::Location(content),
            _ => bail!(
                "Message type {0} not supported for news entry",
                msg.msgtype.msgtype()
            ),
        };

        Ok(StorySlideBuilder::default()
            .content(content)
            .references(self.references)
            .colors(self.colorize_builder.build())
            .build()?)
    }

    pub fn add_reference(&mut self, reference: Box<ObjRefBuilder>) -> &Self {
        self.references.push((*reference).build());
        self
    }

    pub fn unset_references(&mut self) -> &Self {
        self.references.clear();
        self
    }
}

#[derive(Clone, Debug)]
pub struct Story {
    client: Client,
    room: Room,
    content: models::Story,
}

impl Deref for Story {
    type Target = models::Story;
    fn deref(&self) -> &Self::Target {
        &self.content
    }
}

/// Custom functions
impl Story {
    pub fn new(client: Client, room: Room, content: models::Story) -> Self {
        Story {
            client,
            room,
            content,
        }
    }

    pub fn slides_count(&self) -> u8 {
        self.content.slides().len() as u8
    }

    pub fn get_slide(&self, pos: u8) -> Option<StorySlide> {
        let unique_id = format!("{}-${pos}", self.content.event_id());
        self.content
            .slides()
            .get(pos as usize)
            .map(|inner| StorySlide {
                inner: inner.clone(),
                client: self.client.clone(),
                room: self.room.clone(),
                unique_id,
            })
    }

    pub fn slides(&self) -> Vec<StorySlide> {
        let event_id = self.content.event_id();
        self.content
            .slides()
            .iter()
            .enumerate()
            .map(|(pos, slide)| {
                (StorySlide {
                    inner: slide.clone(),
                    client: self.client.clone(),
                    room: self.room.clone(),
                    unique_id: format!("${event_id}-${pos}"),
                })
            })
            .collect()
    }

    pub async fn refresh(&self) -> Result<Story> {
        let key = self.content.event_id().to_owned();
        let client = self.client.clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let AnyActerModel::Story(content) = client.store().get(&key).await? else {
                    bail!("Refreshing failed. {key} not a news")
                };
                Ok(Story::new(client, room, content))
            })
            .await?
    }

    pub async fn can_redact(&self) -> Result<bool> {
        let sender = self.content.sender().to_owned();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move { Ok(can_redact(&room, &sender).await?) })
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

    pub async fn read_receipts(&self) -> Result<crate::ReadReceiptsManager> {
        crate::ReadReceiptsManager::new(
            self.client.clone(),
            self.room.clone(),
            self.content.event_id().to_owned(),
        )
        .await
    }

    fn is_joined(&self) -> bool {
        matches!(self.room.state(), RoomState::Joined)
    }

    pub fn update_builder(&self) -> Result<StoryUpdateBuilder> {
        if !self.is_joined() {
            bail!("Can only update news in joined rooms");
        }
        Ok(StoryUpdateBuilder {
            client: self.client.clone(),
            room: self.room.clone(),
            content: self.content.updater(),
            slides: None,
        })
    }

    pub fn subscribe_stream(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.subscribe()).map(|_| true)
    }

    pub fn subscribe(&self) -> Receiver<()> {
        let key = self.content.event_id().to_owned();
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

    pub fn origin_server_ts(&self) -> u64 {
        self.content.meta.timestamp.get().into()
    }

    pub async fn ref_details(&self) -> Result<RefDetails> {
        let room = self.room.clone();
        let client = self.client.deref().clone();
        let target_id = self.content.event_id().to_owned();
        let room_id = self.room.room_id().to_owned();

        RUNTIME
            .spawn(async move {
                let via = room.route().await?;
                let room_display_name = room.cached_display_name();
                Ok(RefDetails::new(
                    client,
                    CoreRefDetails::TaskList {
                        target_id,
                        room_id: Some(room_id),
                        via,
                        preview: RefPreview::new(None, room_display_name),
                        action: Default::default(),
                    },
                ))
            })
            .await?
    }

    pub fn internal_link(&self) -> String {
        let target_id = &self.content.event_id().to_string()[1..];
        let room_id = &self.room.room_id().to_string()[1..];
        format!("acter:o/{room_id}/boost/{target_id}")
    }
}

#[derive(Clone)]
pub struct StoryDraft {
    client: Client,
    room: Room,
    content: StoryBuilder,
    slides: Vec<StorySlideDraft>,
}

impl StoryDraft {
    pub fn add_slide(&mut self, draft: Box<StorySlideDraft>) -> &mut Self {
        self.slides.push(*draft);
        self
    }

    pub fn slides(&self) -> Vec<StorySlideDraft> {
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
                    let saved_slide = slide.clone().build(&client, &room).await?;
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
pub struct StoryUpdateBuilder {
    client: Client,
    room: Room,
    content: stories::StoryUpdateBuilder,
    slides: Option<Vec<StorySlideDraft>>,
}

impl StoryUpdateBuilder {
    pub fn add_slide(&mut self, draft: Box<StorySlideDraft>) -> &mut Self {
        if let Some(slides) = self.slides.as_mut() {
            slides.push(*draft);
            self.slides = Some(slides.to_vec());
        } else {
            self.slides = Some(vec![*draft]);
        }
        self
    }

    pub fn swap_slides(&mut self, from: u8, to: u8) -> Result<&mut Self> {
        let Some(slides) = self.slides.as_mut() else {
            bail!("No slides to swap");
        };
        if to > slides.len() as u8 {
            bail!("upper bound is exceeded")
        }
        slides.swap(from as usize, to as usize);
        self.slides = Some(slides.to_vec());
        Ok(self)
    }

    pub fn unset_slides(&mut self) -> &mut Self {
        self.slides = Some(vec![]);
        self
    }

    pub fn unset_slides_update(&mut self) -> &mut Self {
        self.slides = None;
        self
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let client = self.client.clone();
        let room = self.room.clone();
        let my_id = self.client.user_id()?;
        let mut inner = self.content.clone();
        let drafts = self.slides.clone().context("No slides to send")?;

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::RoomMessage)
                    .await?;
                if !permitted {
                    bail!("No permissions to send message in this room");
                }
                let mut slides = vec![];
                for draft in drafts {
                    let slide = draft.build(&client, &room).await?;
                    slides.push(slide);
                }
                inner.slides(Some(slides));
                let content = inner.build()?;
                let response = room.send(content).await?;
                Ok(response.event_id)
            })
            .await?
    }
}

impl Space {
    pub fn story_draft(&self) -> Result<StoryDraft> {
        if !self.is_joined() {
            bail!("Unable to create news for spaces we are not part on");
        }
        Ok(StoryDraft {
            client: self.client.clone(),
            room: self.inner.room.clone(),
            content: Default::default(),
            slides: vec![],
        })
    }
}

impl From<MsgDraft> for StorySlideDraft {
    fn from(value: MsgDraft) -> Self {
        StorySlideDraft::new(value)
    }
}
impl MsgDraft {
    pub fn into_story_slide_draft(&self) -> StorySlideDraft {
        self.clone().into()
    }
}
