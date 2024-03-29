use acter_core::{
    events::attachments::{AttachmentBuilder, AttachmentContent, FallbackAttachmentContent},
    models::{self, ActerModel, AnyActerModel},
};
use anyhow::{bail, Context, Result};
use futures::stream::StreamExt;
use matrix_sdk::{room::Room, Client as SdkClient, RoomState};
use ruma_common::{OwnedEventId, OwnedTransactionId};
use ruma_events::{
    room::message::{
        AudioMessageEventContent, FileMessageEventContent, ImageMessageEventContent,
        LocationMessageEventContent, VideoMessageEventContent,
    },
    MessageLikeEventType,
};
use std::{ops::Deref, path::PathBuf, str::FromStr};
use tokio::sync::broadcast::Receiver;
use tokio_stream::Stream;
use tracing::{trace, warn};

use super::{
    api::FfiBuffer, client::Client, common::ThumbnailSize, stream::MsgContentDraft, RUNTIME,
};
use crate::MsgContent;

impl Client {
    pub async fn wait_for_attachment(
        &self,
        key: String,
        timeout: Option<u8>,
    ) -> Result<Attachment> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let AnyActerModel::Attachment(attachment) =
                    me.wait_for(key.clone(), timeout).await?
                else {
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
    pub fn attachment_id_str(&self) -> String {
        self.inner.meta.event_id.to_string()
    }

    pub fn room_id_str(&self) -> String {
        self.room.room_id().to_string()
    }

    pub fn type_str(&self) -> String {
        self.inner.content().type_str()
    }

    pub fn sender(&self) -> String {
        self.inner.meta.sender.to_string()
    }

    pub fn origin_server_ts(&self) -> u64 {
        self.inner.meta.origin_server_ts.get().into()
    }

    pub fn msg_content(&self) -> MsgContent {
        MsgContent::from(&self.inner.content)
    }

    pub async fn source_binary(
        &self,
        thumb_size: Option<Box<ThumbnailSize>>,
    ) -> Result<FfiBuffer<u8>> {
        // any variable in self can't be called directly in spawn
        match &self.inner.content {
            AttachmentContent::Image(content)
            | AttachmentContent::Fallback(FallbackAttachmentContent::Image(content)) => {
                match thumb_size {
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
                }
            }
            AttachmentContent::Audio(content)
            | AttachmentContent::Fallback(FallbackAttachmentContent::Audio(content)) => {
                if thumb_size.is_some() {
                    warn!("DeveloperError: audio has not thumbnail");
                }
                self.client
                    .source_binary(content.source.clone(), None)
                    .await
            }
            AttachmentContent::Video(content)
            | AttachmentContent::Fallback(FallbackAttachmentContent::Video(content)) => {
                match thumb_size {
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
                }
            }
            AttachmentContent::File(content)
            | AttachmentContent::Fallback(FallbackAttachmentContent::File(content)) => {
                match thumb_size {
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
                }
            }
            AttachmentContent::Location(content)
            | AttachmentContent::Fallback(FallbackAttachmentContent::Location(content)) => {
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
        let my_id = self.client.user_id().context("User not found")?;
        let inner = self.inner.build()?;
        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Unable to find me in room")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permissions to send message in this room");
                }
                let response = room.send(inner).await?;
                Ok(response.event_id)
            })
            .await?
    }
}

impl AttachmentsManager {
    pub(crate) async fn new(
        client: Client,
        room: Room,
        event_id: OwnedEventId,
    ) -> Result<AttachmentsManager> {
        RUNTIME
            .spawn(async move {
                let inner =
                    models::AttachmentsManager::from_store_and_event_id(client.store(), &event_id)
                        .await;
                Ok(AttachmentsManager {
                    client,
                    room,
                    inner,
                })
            })
            .await?
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

    pub async fn reload(&self) -> Result<AttachmentsManager> {
        AttachmentsManager::new(
            self.client.clone(),
            self.room.clone(),
            self.inner.event_id(),
        )
        .await
    }

    pub async fn redact(
        &self,
        attachment_id: String,
        reason: Option<String>,
        txn_id: Option<String>,
    ) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let stats = self.inner.stats();
        let has_entry = self
            .stats()
            .user_attachments
            .into_iter()
            .any(|inner| OwnedEventId::to_string(&inner) == attachment_id);

        if !has_entry {
            bail!("attachment doesn't exist");
        }

        let event_id = OwnedEventId::from_str(&attachment_id).expect("invalid event ID");
        let txn_id = txn_id.map(OwnedTransactionId::from);

        RUNTIME
            .spawn(async move {
                trace!("before redacting attachment");
                let response = room.redact(&event_id, reason.as_deref(), txn_id).await?;
                trace!("after redacting attachment");
                Ok(response.event_id)
            })
            .await?
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
                match base_draft.into_attachment_content(client, room).await? {
                    Some(content) => Ok(content),
                    None => bail!("non-media content not allowed"),
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

impl MsgContentDraft {
    async fn into_attachment_content(
        self, // into_* fn takes self by value not reference
        client: SdkClient,
        room: Room,
    ) -> Result<Option<AttachmentContent>> {
        match self {
            MsgContentDraft::TextPlain { .. }
            | MsgContentDraft::TextMarkdown { .. }
            | MsgContentDraft::TextHtml { .. } => Ok(None),
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
                Ok(Some(AttachmentContent::Image(image_content)))
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
                Ok(Some(AttachmentContent::Audio(audio_content)))
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
                Ok(Some(AttachmentContent::Video(video_content)))
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
                Ok(Some(AttachmentContent::File(file_content)))
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
                Ok(Some(AttachmentContent::Location(location_content)))
            }
        }
    }
}
