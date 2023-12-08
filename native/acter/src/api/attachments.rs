use acter_core::{
    events::attachments::{AttachmentBuilder, AttachmentContent},
    models::{self, ActerModel, AnyActerModel},
};
use anyhow::{bail, Context, Result};
use core::time::Duration;
use futures::stream::StreamExt;
use matrix_sdk::{
    room::Room,
    ruma::{assign, UInt},
    RoomState,
};
use ruma_common::{MxcUri, OwnedEventId, OwnedUserId};
use ruma_events::{
    room::{
        message::{
            AudioInfo, AudioMessageEventContent, FileInfo, FileMessageEventContent,
            ImageMessageEventContent, LocationInfo, LocationMessageEventContent, VideoInfo,
            VideoMessageEventContent,
        },
        ImageInfo,
    },
    MessageLikeEventType,
};
use std::{ops::Deref, path::PathBuf};
use tokio::sync::broadcast::Receiver;
use tokio_stream::Stream;

use super::{api::FfiBuffer, client::Client, stream::MsgContentDraft, RUNTIME};
use crate::MsgContent;

impl Client {
    pub async fn wait_for_attachment(
        &self,
        key: String,
        timeout: Option<Box<Duration>>,
    ) -> Result<Attachment> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let AnyActerModel::Attachment(attachment) = me.wait_for(key.clone(), timeout).await? else {
                    bail!("{key} is not a attachment");
                };
                let room = me
                    .core
                    .client()
                    .get_room(&attachment.meta.room_id)
                    .context("Room not found")?;
                Ok(Attachment {
                    client: me.clone(),
                    room,
                    inner: attachment,
                })
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct Attachment {
    client: Client,
    room: Room,
    inner: models::Attachment,
}

impl Deref for Attachment {
    type Target = models::Attachment;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl Attachment {
    pub fn type_str(&self) -> String {
        self.inner.content().type_str()
    }

    pub fn sender(&self) -> OwnedUserId {
        self.inner.meta.sender.clone()
    }

    pub fn origin_server_ts(&self) -> u64 {
        self.inner.meta.origin_server_ts.get().into()
    }

    pub fn msg_content(&self) -> MsgContent {
        MsgContent::from(&self.inner.content)
    }

    pub async fn source_binary(&self) -> Result<FfiBuffer<u8>> {
        // any variable in self can't be called directly in spawn
        match &self.inner.content {
            AttachmentContent::Image(content) => {
                self.client.source_binary(content.source.clone()).await
            }
            AttachmentContent::Audio(content) => {
                self.client.source_binary(content.source.clone()).await
            }
            AttachmentContent::Video(content) => {
                self.client.source_binary(content.source.clone()).await
            }
            AttachmentContent::File(content) => {
                self.client.source_binary(content.source.clone()).await
            }
            AttachmentContent::Location(content) => {
                let buf = Vec::<u8>::new();
                Ok(FfiBuffer::new(buf))
            }
        }
    }
}

#[derive(Clone, Debug)]
pub struct AttachmentsManager {
    client: Client,
    room: Room,
    inner: models::AttachmentsManager,
}

impl Deref for AttachmentsManager {
    type Target = models::AttachmentsManager;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

pub struct AttachmentDraft {
    client: Client,
    room: Room,
    inner: AttachmentBuilder,
}

impl AttachmentDraft {
    fn is_joined(&self) -> bool {
        matches!(self.room.state(), RoomState::Joined)
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Can only attachment in joined rooms");
        }
        let room = self.room.clone();
        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();
        let inner = self.inner.build()?;
        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }
                let response = room.send(inner).await?;
                Ok(response.event_id)
            })
            .await?
    }
}

impl AttachmentsManager {
    pub(crate) fn new(
        client: Client,
        room: Room,
        inner: models::AttachmentsManager,
    ) -> AttachmentsManager {
        AttachmentsManager {
            client,
            room,
            inner,
        }
    }

    pub fn stats(&self) -> models::AttachmentsStats {
        self.inner.stats().clone()
    }

    pub fn has_attachments(&self) -> bool {
        *self.stats().has_attachments()
    }

    pub fn attachments_count(&self) -> u32 {
        *self.stats().total_attachments_count()
    }

    pub async fn attachments(&self) -> Result<Vec<Attachment>> {
        let manager = self.inner.clone();
        let client = self.client.clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let res = manager
                    .attachments()
                    .await?
                    .into_iter()
                    .map(|inner| Attachment {
                        client: client.clone(),
                        room: room.clone(),
                        inner,
                    })
                    .collect();
                Ok(res)
            })
            .await?
    }

    pub async fn content_draft(&self, base_draft: Box<MsgContentDraft>) -> Result<AttachmentDraft> {
        let room = self.room.clone();
        let client = self.room.client();

        let content = RUNTIME
            .spawn(async move {
                match *base_draft {
                    MsgContentDraft::TextPlain { .. } => {
                        bail!("non-media content not allowed")
                    }
                    MsgContentDraft::TextMarkdown { .. } => {
                        bail!("non-media content not allowed")
                    }
                    MsgContentDraft::Image { body, source, info } => {
                        let info = info.expect("image info needed");
                        let mimetype = info.mimetype.clone().expect("mimetype needed");
                        let content_type = mimetype.parse::<mime::Mime>()?;
                        let mut image_content = if room.is_encrypted().await? {
                            let mut reader = std::fs::File::open(source)?;
                            let encrypted_file = client
                                .prepare_encrypted_file(&content_type, &mut reader)
                                .await?;
                            ImageMessageEventContent::encrypted(body, encrypted_file)
                        } else {
                            let path = PathBuf::from(source);
                            let mut image_buf = std::fs::read(path)?;
                            let response = client.media().upload(&content_type, image_buf).await?;
                            ImageMessageEventContent::plain(body, response.content_uri)
                        };
                        image_content.info = Some(Box::new(info));
                        anyhow::Ok(AttachmentContent::Image(image_content))
                    }
                    MsgContentDraft::Audio { body, source, info } => {
                        let info = info.expect("audio info needed");
                        let mimetype = info.mimetype.clone().expect("mimetype needed");
                        let content_type = mimetype.parse::<mime::Mime>()?;
                        let mut audio_content = if room.is_encrypted().await? {
                            let mut reader = std::fs::File::open(source)?;
                            let encrypted_file = client
                                .prepare_encrypted_file(&content_type, &mut reader)
                                .await?;
                            AudioMessageEventContent::encrypted(body, encrypted_file)
                        } else {
                            let path = PathBuf::from(source);
                            let mut audio_buf = std::fs::read(path)?;
                            let response = client.media().upload(&content_type, audio_buf).await?;
                            AudioMessageEventContent::plain(body, response.content_uri)
                        };
                        audio_content.info = Some(Box::new(info));
                        anyhow::Ok(AttachmentContent::Audio(audio_content))
                    }
                    MsgContentDraft::Video { body, source, info } => {
                        let info = info.expect("video info needed");
                        let mimetype = info.mimetype.clone().expect("mimetype needed");
                        let content_type = mimetype.parse::<mime::Mime>()?;
                        let mut video_content = if room.is_encrypted().await? {
                            let mut reader = std::fs::File::open(source)?;
                            let encrypted_file = client
                                .prepare_encrypted_file(&content_type, &mut reader)
                                .await?;
                            VideoMessageEventContent::encrypted(body, encrypted_file)
                        } else {
                            let path = PathBuf::from(source);
                            let mut video_buf = std::fs::read(path)?;
                            let response = client.media().upload(&content_type, video_buf).await?;
                            VideoMessageEventContent::plain(body, response.content_uri)
                        };
                        video_content.info = Some(Box::new(info));
                        anyhow::Ok(AttachmentContent::Video(video_content))
                    }
                    MsgContentDraft::File {
                        body,
                        source,
                        info,
                        filename,
                    } => {
                        let info = info.expect("file info needed");
                        let mimetype = info.mimetype.clone().expect("mimetype needed");
                        let content_type = mimetype.parse::<mime::Mime>()?;
                        let mut file_content = if room.is_encrypted().await? {
                            let mut reader = std::fs::File::open(source)?;
                            let encrypted_file = client
                                .prepare_encrypted_file(&content_type, &mut reader)
                                .await?;
                            FileMessageEventContent::encrypted(body, encrypted_file)
                        } else {
                            let path = PathBuf::from(source);
                            let mut file_buf = std::fs::read(path)?;
                            let response = client.media().upload(&content_type, file_buf).await?;
                            FileMessageEventContent::plain(body, response.content_uri)
                        };
                        file_content.info = Some(Box::new(info));
                        file_content.filename = filename.clone();
                        anyhow::Ok(AttachmentContent::File(file_content))
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
                        anyhow::Ok(AttachmentContent::Location(location_content))
                    }
                }
            })
            .await??;

        let mut builder = self.inner.draft_builder();
        builder.content(content);
        Ok(AttachmentDraft {
            client: self.client.clone(),
            room: self.room.clone(),
            inner: builder,
        })
    }

    pub fn subscribe_stream(&self) -> impl Stream<Item = bool> {
        self.client.subscribe_stream(self.inner.update_key())
    }

    pub fn subscribe(&self) -> Receiver<()> {
        self.client.subscribe(self.inner.update_key())
    }
}
