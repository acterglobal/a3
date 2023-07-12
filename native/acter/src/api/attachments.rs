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
use std::ops::Deref;
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
    pub fn image_attachment_draft(
        &self,
        body: String,
        url: String,
        mimetype: Option<String>,
        size: Option<u64>,
        width: Option<u64>,
        height: Option<u64>,
        blurhash: Option<String>,
    ) -> Result<AttachmentDraft> {
        let Room::Joined(joined) = &self.room else {
            bail!("Can only attachment in joined rooms");
        };
        let info = assign!(ImageInfo::new(), {
            height: height.and_then(UInt::new),
            width: width.and_then(UInt::new),
            mimetype,
            size: size.and_then(UInt::new),
            blurhash,
        });
        let url = Box::<MxcUri>::from(url.as_str());
        let mut builder = self.inner.draft_builder();

        builder.content(AttachmentContent::Image(ImageMessageEventContent::plain(
            body,
            url.into(),
            Some(Box::new(info)),
        )));
        Ok(AttachmentDraft {
            client: self.client.clone(),
            room: joined.clone(),
            inner: builder,
        })
    }

    pub fn audio_attachment_draft(
        &self,
        body: String,
        url: String,
        secs: Option<u64>,
        mimetype: Option<String>,
        size: Option<u64>,
    ) -> Result<AttachmentDraft> {
        let Room::Joined(joined) = &self.room else {
            bail!("Can only attachment in joined rooms");
        };
        let info = assign!(AudioInfo::new(), {
            duration: secs.map(|x| Duration::new(x, 0)),
            mimetype,
            size: size.and_then(UInt::new),
        });
        let url = Box::<MxcUri>::from(url.as_str());
        let mut builder = self.inner.draft_builder();

        builder.content(AttachmentContent::Audio(AudioMessageEventContent::plain(
            body,
            url.into(),
            Some(Box::new(info)),
        )));
        Ok(AttachmentDraft {
            client: self.client.clone(),
            room: joined.clone(),
            inner: builder,
        })
    }

    #[allow(clippy::too_many_arguments)]
    pub fn video_attachment_draft(
        &self,
        body: String,
        url: String,
        secs: Option<u64>,
        height: Option<u64>,
        width: Option<u64>,
        mimetype: Option<String>,
        size: Option<u64>,
        blurhash: Option<String>,
    ) -> Result<AttachmentDraft> {
        let Room::Joined(joined) = &self.room else {
            bail!("Can only attachment in joined rooms");
        };
        let info = assign!(VideoInfo::new(), {
            duration: secs.map(|x| Duration::new(x, 0)),
            height: height.and_then(UInt::new),
            width: width.and_then(UInt::new),
            mimetype,
            size: size.and_then(UInt::new),
            blurhash,
        });
        let url = Box::<MxcUri>::from(url.as_str());
        let mut builder = self.inner.draft_builder();

        builder.content(AttachmentContent::Video(VideoMessageEventContent::plain(
            body,
            url.into(),
            Some(Box::new(info)),
        )));
        Ok(AttachmentDraft {
            client: self.client.clone(),
            room: joined.clone(),
            inner: builder,
        })
    }

    pub fn file_attachment_draft(
        &self,
        body: String,
        url: String,
        mimetype: Option<String>,
        size: Option<u64>,
    ) -> Result<AttachmentDraft> {
        let Room::Joined(joined) = &self.room else {
            bail!("Can only attachment in joined rooms");
        };
        let mut builder = self.inner.draft_builder();
        let size = size.and_then(UInt::new);
        builder.content(AttachmentContent::File(FileMessageEventContent::plain(
            body,
            url.into(),
            Some(Box::new(assign!(FileInfo::new(), {mimetype, size}))),
        )));
        Ok(AttachmentDraft {
            client: self.client.clone(),
            room: joined.clone(),
            inner: builder,
        })
    }

    pub fn subscribe_stream(&self) -> impl tokio_stream::Stream<Item = ()> {
        tokio_stream::wrappers::BroadcastStream::new(self.subscribe())
            .map(|f| f.unwrap_or_default())
    }

    pub fn subscribe(&self) -> tokio::sync::broadcast::Receiver<()> {
        self.client.subscribe(self.inner.update_key())
    }
}
