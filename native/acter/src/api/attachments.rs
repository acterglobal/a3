use acter_core::{
    events::attachments::{AttachmentBuilder, AttachmentContent},
    models::{self, ActerModel, AnyActerModel, Color},
};
use anyhow::{bail, Context, Result};
use core::time::Duration;
use matrix_sdk::room::{Joined, Room};
use ruma::{
    assign,
    events::room::{
        message::{
            AudioInfo, AudioMessageEventContent, FileInfo, FileMessageEventContent,
            ImageMessageEventContent, VideoInfo, VideoMessageEventContent,
        },
        ImageInfo,
    },
    MxcUri, OwnedEventId, OwnedUserId, UInt,
};
use std::{fs, ops::Deref, path::PathBuf};
use tokio::sync::broadcast::Receiver;

use super::{api::FfiBuffer, client::Client, RUNTIME};
use futures::stream::StreamExt;

use crate::{AudioDesc, FileDesc, ImageDesc, VideoDesc};

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

    pub fn image_desc(&self) -> Option<ImageDesc> {
        self.inner.content().image().and_then(|content| {
            content
                .info
                .map(|info| ImageDesc::new(content.body, content.source, *info))
        })
    }

    pub async fn image_binary(&self) -> Result<FfiBuffer<u8>> {
        // any variable in self can't be called directly in spawn
        let content = self.inner.content().image().context("Not an image")?;
        self.client.source_binary(content.source).await
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
        let content = self.inner.content().audio().context("Not an audio")?;
        self.client.source_binary(content.source).await
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
        let content = self.inner.content().video().context("Not a video")?;
        self.client.source_binary(content.source).await
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
        let content = self.inner.content().file().context("Not a file")?;
        self.client.source_binary(content.source).await
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
    room: Joined,
    inner: AttachmentBuilder,
}

impl AttachmentDraft {
    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let inner = self.inner.build()?;
        RUNTIME
            .spawn(async move {
                let resp = room.send(inner, None).await?;
                Ok(resp.event_id)
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

    pub fn attachment_draft(&self) -> Result<AttachmentDraft> {
        let Room::Joined(joined) = &self.room else {
            bail!("Can only attachment in joined rooms");
        };
        Ok(AttachmentDraft {
            client: self.client.clone(),
            room: joined.clone(),
            inner: self.inner.draft_builder(),
        })
    }

    #[allow(clippy::too_many_arguments)]
    pub async fn image_attachment_draft(
        &self,
        body: String,
        url_or_path: String,
        size: Option<u64>,
        width: Option<u64>,
        height: Option<u64>,
        blurhash: Option<String>,
    ) -> Result<AttachmentDraft> {
        let client = self.client.clone();
        let Room::Joined(room) = self.room.clone() else {
            bail!("Can only attachment in joined rooms");
        };
        let r = room.clone();
        let image_content = RUNTIME
            .spawn(async move {
                let url = Box::<MxcUri>::from(url_or_path.as_str()); // http not allowed for remote url
                if url.is_valid() {
                    return anyhow::Ok(ImageMessageEventContent::plain(body, url.into(), None));
                }
                let path = PathBuf::from(url_or_path.clone());
                let guess = mime_guess::from_path(path.clone());
                let content_type = guess.first().context("No MIME type")?;
                let mimetype = content_type.to_string();
                if !mimetype.starts_with("image/") {
                    bail!("Image attachment accepts only image file");
                }
                let mut content = if r.is_encrypted().await? {
                    let mut reader = fs::File::open(url_or_path)?;
                    let encrypted_file = client
                        .prepare_encrypted_file(&content_type, &mut reader)
                        .await?;
                    ImageMessageEventContent::encrypted(body, encrypted_file)
                } else {
                    let buf = fs::read(url_or_path)?;
                    let response = client.media().upload(&content_type, buf).await?;
                    ImageMessageEventContent::plain(body, response.content_uri, None)
                };
                let info = assign!(ImageInfo::new(), {
                    height: height.and_then(UInt::new),
                    width: width.and_then(UInt::new),
                    mimetype: Some(mimetype),
                    size: size.and_then(UInt::new),
                    blurhash,
                });
                content.info = Some(Box::new(info));
                anyhow::Ok(content)
            })
            .await??;

        let mut builder = self.inner.draft_builder();
        builder.content(AttachmentContent::Image(image_content));

        Ok(AttachmentDraft {
            client: self.client.clone(),
            room,
            inner: builder,
        })
    }

    pub async fn audio_attachment_draft(
        &self,
        body: String,
        url_or_path: String,
        secs: Option<u64>,
        size: Option<u64>,
    ) -> Result<AttachmentDraft> {
        let client = self.client.clone();
        let Room::Joined(room) = self.room.clone() else {
            bail!("Can only attachment in joined rooms");
        };
        let r = room.clone();
        let audio_content = RUNTIME
            .spawn(async move {
                let url = Box::<MxcUri>::from(url_or_path.as_str()); // http not allowed for remote url
                if url.is_valid() {
                    return anyhow::Ok(AudioMessageEventContent::plain(body, url.into(), None));
                }
                let path = PathBuf::from(url_or_path.clone());
                let guess = mime_guess::from_path(path.clone());
                let content_type = guess.first().context("No MIME type")?;
                let mimetype = content_type.to_string();
                if !mimetype.starts_with("audio/") {
                    bail!("Audio attachment accepts only audio file");
                }
                let mut content = if r.is_encrypted().await? {
                    let mut reader = fs::File::open(url_or_path)?;
                    let encrypted_file = client
                        .prepare_encrypted_file(&content_type, &mut reader)
                        .await?;
                    AudioMessageEventContent::encrypted(body, encrypted_file)
                } else {
                    let buf = fs::read(url_or_path)?;
                    let response = client.media().upload(&content_type, buf).await?;
                    AudioMessageEventContent::plain(body, response.content_uri, None)
                };
                let info = assign!(AudioInfo::new(), {
                    duration: secs.map(|x| Duration::new(x, 0)),
                    mimetype: Some(mimetype),
                    size: size.and_then(UInt::new),
                });
                content.info = Some(Box::new(info));
                anyhow::Ok(content)
            })
            .await??;

        let mut builder = self.inner.draft_builder();
        builder.content(AttachmentContent::Audio(audio_content));

        Ok(AttachmentDraft {
            client: self.client.clone(),
            room,
            inner: builder,
        })
    }

    #[allow(clippy::too_many_arguments)]
    pub async fn video_attachment_draft(
        &self,
        body: String,
        url_or_path: String,
        secs: Option<u64>,
        height: Option<u64>,
        width: Option<u64>,
        size: Option<u64>,
        blurhash: Option<String>,
    ) -> Result<AttachmentDraft> {
        let client = self.client.clone();
        let Room::Joined(room) = self.room.clone() else {
            bail!("Can only attachment in joined rooms");
        };
        let r = room.clone();
        let video_content = RUNTIME
            .spawn(async move {
                let url = Box::<MxcUri>::from(url_or_path.as_str()); // http not allowed for remote url
                if url.is_valid() {
                    return anyhow::Ok(VideoMessageEventContent::plain(body, url.into(), None));
                }
                let path = PathBuf::from(url_or_path.clone());
                let guess = mime_guess::from_path(path.clone());
                let content_type = guess.first().context("No MIME type")?;
                let mimetype = content_type.to_string();
                if !mimetype.starts_with("video/") {
                    bail!("Video attachment accepts only video file");
                }
                let mut content = if r.is_encrypted().await? {
                    let mut reader = fs::File::open(url_or_path)?;
                    let encrypted_file = client
                        .prepare_encrypted_file(&content_type, &mut reader)
                        .await?;
                    VideoMessageEventContent::encrypted(body, encrypted_file)
                } else {
                    let buf = fs::read(url_or_path)?;
                    let response = client.media().upload(&content_type, buf).await?;
                    VideoMessageEventContent::plain(body, response.content_uri, None)
                };
                let info = assign!(VideoInfo::new(), {
                    duration: secs.map(|x| Duration::new(x, 0)),
                    height: height.and_then(UInt::new),
                    width: width.and_then(UInt::new),
                    mimetype: Some(mimetype),
                    size: size.and_then(UInt::new),
                    blurhash,
                });
                content.info = Some(Box::new(info));
                anyhow::Ok(content)
            })
            .await??;

        let mut builder = self.inner.draft_builder();
        builder.content(AttachmentContent::Video(video_content));

        Ok(AttachmentDraft {
            client: self.client.clone(),
            room,
            inner: builder,
        })
    }

    pub async fn file_attachment_draft(
        &self,
        body: String,
        url_or_path: String,
        size: Option<u64>,
    ) -> Result<AttachmentDraft> {
        let client = self.client.clone();
        let Room::Joined(room) = self.room.clone() else {
            bail!("Can only attachment in joined rooms");
        };
        let r = room.clone();
        let file_content = RUNTIME
            .spawn(async move {
                let url = Box::<MxcUri>::from(url_or_path.as_str()); // http not allowed for remote url
                if url.is_valid() {
                    return anyhow::Ok(FileMessageEventContent::plain(body, url.into(), None));
                }
                let path = PathBuf::from(url_or_path.clone());
                let guess = mime_guess::from_path(path.clone());
                let content_type = guess
                    .first()
                    .unwrap_or(mime_guess::mime::APPLICATION_OCTET_STREAM);
                let mimetype = content_type.to_string();
                let mut content = if r.is_encrypted().await? {
                    let mut reader = fs::File::open(url_or_path)?;
                    let encrypted_file = client
                        .prepare_encrypted_file(&content_type, &mut reader)
                        .await?;
                    FileMessageEventContent::encrypted(body, encrypted_file)
                } else {
                    let buf = fs::read(url_or_path)?;
                    let response = client.media().upload(&content_type, buf).await?;
                    FileMessageEventContent::plain(body, response.content_uri, None)
                };
                let info = assign!(FileInfo::new(), {
                    mimetype: Some(mimetype),
                    size: size.and_then(UInt::new),
                });
                content.info = Some(Box::new(info));
                anyhow::Ok(content)
            })
            .await??;

        let mut builder = self.inner.draft_builder();
        builder.content(AttachmentContent::File(file_content));
        Ok(AttachmentDraft {
            client: self.client.clone(),
            room,
            inner: builder,
        })
    }

    pub fn subscribe_stream(&self) -> impl tokio_stream::Stream<Item = bool> {
        self.client.subscribe_stream(self.inner.update_key())
    }

    pub fn subscribe(&self) -> tokio::sync::broadcast::Receiver<()> {
        self.client.subscribe(self.inner.update_key())
    }
}
