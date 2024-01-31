use anyhow::{bail, Context, Result};
use core::time::Duration;
use futures::stream::{Stream, StreamExt};
use matrix_sdk::{
    attachment::{
        AttachmentConfig, AttachmentInfo, BaseAudioInfo, BaseFileInfo, BaseImageInfo, BaseVideoInfo,
    },
    room::{Receipts, Room},
    Client as SdkClient, RoomState,
};
use matrix_sdk_ui::timeline::{BackPaginationStatus, PaginationOptions, Timeline};
use ruma::{assign, UInt};
use ruma_client_api::receipt::create_receipt;
use ruma_common::{EventId, OwnedEventId, OwnedTransactionId};
use ruma_events::{
    receipt::ReceiptThread,
    relation::Annotation,
    room::{
        message::{
            AudioInfo, AudioMessageEventContent, FileInfo, FileMessageEventContent, ForwardThread,
            ImageMessageEventContent, LocationInfo, LocationMessageEventContent, MessageType,
            RoomMessageEvent, RoomMessageEventContent, RoomMessageEventContentWithoutRelation,
            VideoInfo, VideoMessageEventContent,
        },
        ImageInfo,
    },
    MessageLikeEventType,
};
use std::{path::PathBuf, sync::Arc};
use tracing::info;

use crate::{Client, RoomMessage, RUNTIME};

use super::utils::{remap_for_diff, ApiVectorDiff};

pub type TimelineDiff = ApiVectorDiff<RoomMessage>;

#[derive(Clone)]
pub struct TimelineStream {
    room: Room,
    timeline: Arc<Timeline>,
}

impl TimelineStream {
    pub fn new(room: Room, timeline: Arc<Timeline>) -> Self {
        TimelineStream { room, timeline }
    }

    pub fn diff_stream(&self) -> impl Stream<Item = TimelineDiff> {
        let timeline = self.timeline.clone();
        let room = self.room.clone();

        async_stream::stream! {
            let (timeline_items, mut timeline_stream) = timeline.subscribe().await;
            yield TimelineDiff::current_items(timeline_items.clone().into_iter().map(|x| RoomMessage::from((x, room.clone()))).collect());

            let mut remap = timeline_stream.map(|diff| remap_for_diff(
                diff,
                |x| RoomMessage::from((x, room.clone())),
            ));

            while let Some(d) = remap.next().await {
                yield d
            }
        }
    }

    pub async fn paginate_backwards(&self, mut count: u16) -> Result<bool> {
        let timeline = self.timeline.clone();

        RUNTIME
            .spawn(async move {
                let mut back_pagination_status = timeline.back_pagination_status();
                let (timeline_items, mut timeline_stream) = timeline.subscribe().await;
                let options = PaginationOptions::simple_request(count);
                timeline.paginate_backwards(options).await?;
                loop {
                    if let Some(status) = back_pagination_status.next().await {
                        if status == BackPaginationStatus::Idle {
                            return Ok(true); // has more
                        }
                        if status == BackPaginationStatus::TimelineStartReached {
                            return Ok(false); // no more
                        }
                    }
                }
            })
            .await?
    }

    fn is_joined(&self) -> bool {
        matches!(self.room.state(), RoomState::Joined)
    }

    pub async fn send_message(&self, draft: Box<MsgContentDraft>) -> Result<bool> {
        if !self.is_joined() {
            bail!("Unable to send message in a room we are not in");
        }
        let room = self.room.clone();
        let my_id = room
            .client()
            .user_id()
            .context("You must be logged in to do that")?
            .to_owned();
        let timeline = self.timeline.clone();

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Unable to find me in room")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permissions to send message in this room");
                }
                match *draft {
                    MsgContentDraft::TextPlain { body } => {
                        let content = RoomMessageEventContent::text_plain(body);
                        timeline.send(content.into()).await;
                    }
                    MsgContentDraft::TextMarkdown { body } => {
                        let content = RoomMessageEventContent::text_markdown(body);
                        timeline.send(content.into()).await;
                    }
                    MsgContentDraft::Image { source, info } => {
                        let mut config = AttachmentConfig::new();
                        let mut mime_type = None;
                        if let Some(value) = info {
                            config = config.info(AttachmentInfo::Image(BaseImageInfo {
                                height: value.height,
                                width: value.width,
                                size: value.size,
                                blurhash: value.blurhash.clone(),
                            }));
                            if let Some(mimetype) = value.mimetype {
                                mime_type = Some(mimetype.parse::<mime::Mime>()?);
                            }
                        }
                        let mime_type = mime_type.expect("mime type needed");
                        timeline.send_attachment(source, mime_type, config).await?;
                    }
                    MsgContentDraft::Audio { source, info } => {
                        let mut config = AttachmentConfig::new();
                        let mut mime_type = None;
                        if let Some(value) = info {
                            config = config.info(AttachmentInfo::Audio(BaseAudioInfo {
                                duration: value.duration,
                                size: value.size,
                            }));
                            if let Some(mimetype) = value.mimetype {
                                mime_type = Some(mimetype.parse::<mime::Mime>()?);
                            }
                        }
                        let mime_type = mime_type.expect("mime type needed");
                        timeline.send_attachment(source, mime_type, config).await?;
                    }
                    MsgContentDraft::Video { source, info } => {
                        let mut config = AttachmentConfig::new();
                        let mut mime_type = None;
                        if let Some(value) = info {
                            config = config.info(AttachmentInfo::Video(BaseVideoInfo {
                                duration: value.duration,
                                width: value.width,
                                height: value.height,
                                size: value.size,
                                blurhash: value.blurhash.clone(),
                            }));
                            if let Some(mimetype) = value.mimetype {
                                mime_type = Some(mimetype.parse::<mime::Mime>()?);
                            }
                        }
                        let mime_type = mime_type.expect("mime type needed");
                        timeline.send_attachment(source, mime_type, config).await?;
                    }
                    MsgContentDraft::File {
                        source,
                        info,
                        filename,
                    } => {
                        let mut config = AttachmentConfig::new();
                        let mut mime_type = None;
                        if let Some(value) = info {
                            config = config
                                .info(AttachmentInfo::File(BaseFileInfo { size: value.size }));
                            if let Some(mimetype) = value.mimetype {
                                mime_type = Some(mimetype.parse::<mime::Mime>()?);
                            }
                        }
                        let mime_type = mime_type.expect("mime type needed");
                        timeline.send_attachment(source, mime_type, config).await?;
                    }
                    MsgContentDraft::Location {
                        body,
                        geo_uri,
                        info,
                    } => {
                        let location_content = LocationMessageEventContent::new(body, geo_uri);
                        let content =
                            RoomMessageEventContent::new(MessageType::Location(location_content));
                        timeline.send(content.into()).await;
                    }
                }
                Ok(true)
            })
            .await?
    }

    pub async fn edit_message(
        &self,
        event_id: String,
        draft: Box<MsgContentDraft>,
    ) -> Result<bool> {
        if !self.is_joined() {
            bail!("Unable to edit message in a room we are not in");
        }
        let room = self.room.clone();
        let my_id = room
            .client()
            .user_id()
            .context("You must be logged in to do that")?
            .to_owned();
        let timeline = self.timeline.clone();
        let event_id = EventId::parse(event_id)?;
        let client = self.room.client();

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Unable to find me in room")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permissions to send message in this room");
                }

                let event_content = room
                    .event(&event_id)
                    .await?
                    .event
                    .deserialize_as::<RoomMessageEvent>()?;

                let mut sent_by_me = false;
                if let Some(user_id) = client.user_id() {
                    if user_id == event_content.sender() {
                        sent_by_me = true;
                    }
                }
                if !sent_by_me {
                    bail!("Unable to edit an event not sent by own user");
                }

                let edit_item = timeline
                    .item_by_event_id(&event_id)
                    .await
                    .context("Not found which item would be edited")?;
                let new_content = draft.into_edited_content(client, room, event_id).await?;
                timeline.edit(new_content, &edit_item).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn reply_message(
        &self,
        event_id: String,
        draft: Box<MsgContentDraft>,
    ) -> Result<bool> {
        if !self.is_joined() {
            bail!("Unable to send reply in a room we are not in");
        }
        let room = self.room.clone();
        let my_id = room
            .client()
            .user_id()
            .context("You must be logged in to do that")?
            .to_owned();
        let timeline = self.timeline.clone();
        let event_id = EventId::parse(event_id)?;
        let client = self.room.client();

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Unable to find me in room")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permissions to send message in this room");
                }

                let reply_item = timeline
                    .item_by_event_id(&event_id)
                    .await
                    .context("Not found which item would be replied to")?;
                let content = draft.into_replied_content(client, room).await?;
                timeline
                    .send_reply(content, &reply_item, ForwardThread::Yes)
                    .await?;
                Ok(true)
            })
            .await?
    }

    pub async fn send_single_receipt(
        &self,
        receipt_type: String,
        thread: String,
        event_id: String,
    ) -> Result<bool> {
        let timeline = self.timeline.clone();
        let receipt_type = match receipt_type.as_str() {
            "FullyRead" => create_receipt::v3::ReceiptType::FullyRead,
            "Read" => create_receipt::v3::ReceiptType::Read,
            "ReadPrivate" => create_receipt::v3::ReceiptType::ReadPrivate,
            _ => {
                bail!("Wrong receipt type")
            }
        };
        let thread = match thread.as_str() {
            "Main" => ReceiptThread::Main,
            "Unthreaded" => ReceiptThread::Unthreaded,
            _ => {
                bail!("Wrong receipt thread")
            }
        };
        let event_id = EventId::parse(event_id)?;

        RUNTIME
            .spawn(async move {
                timeline
                    .send_single_receipt(receipt_type, thread, event_id)
                    .await?;
                Ok(true)
            })
            .await?
    }

    pub async fn send_multiple_receipts(
        &self,
        fully_read: Option<String>,
        public_read_receipt: Option<String>,
        private_read_receipt: Option<String>,
    ) -> Result<bool> {
        let timeline = self.timeline.clone();
        let fully_read = match fully_read {
            Some(x) => match EventId::parse(x) {
                Ok(event_id) => Some(event_id),
                Err(_) => {
                    bail!("full read param should be event id")
                }
            },
            None => None,
        };
        let public_read_receipt = match public_read_receipt {
            Some(x) => match EventId::parse(x) {
                Ok(event_id) => Some(event_id),
                Err(_) => {
                    bail!("public read receipt param should be event id")
                }
            },
            None => None,
        };
        let private_read_receipt = match private_read_receipt {
            Some(x) => match EventId::parse(x) {
                Ok(event_id) => Some(event_id),
                Err(_) => {
                    bail!("private read receipt param should be event id")
                }
            },
            None => None,
        };

        RUNTIME
            .spawn(async move {
                let receipts = Receipts::new()
                    .fully_read_marker(fully_read)
                    .public_read_receipt(public_read_receipt)
                    .private_read_receipt(private_read_receipt);
                timeline.send_multiple_receipts(receipts).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn toggle_reaction(&self, event_id: String, key: String) -> Result<bool> {
        if !self.is_joined() {
            bail!("Unable to send reaction in a room we are not in");
        }
        let room = self.room.clone();
        let my_id = room
            .client()
            .user_id()
            .context("You must be logged in to do that")?
            .to_owned();
        let timeline = self.timeline.clone();
        let event_id = EventId::parse(event_id)?;

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Unable to find me in room")?;
                if !member.can_send_message(MessageLikeEventType::Reaction) {
                    bail!("No permissions to send reaction in this room");
                }
                let annotation = Annotation::new(event_id, key);
                timeline.toggle_reaction(&annotation).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn retry_send(&self, txn_id: String) -> Result<bool> {
        let timeline = self.timeline.clone();
        let txn_id = OwnedTransactionId::from(txn_id);

        let room = self.room.clone();
        let my_id = room
            .client()
            .user_id()
            .context("You must be logged in to do that")?
            .to_owned();

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Unable to find me in room")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permissions to send message in this room");
                }

                timeline.retry_send(&txn_id).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn cancel_send(&self, txn_id: String) -> Result<bool> {
        let timeline = self.timeline.clone();
        let txn_id = OwnedTransactionId::from(txn_id);

        let room = self.room.clone();
        let my_id = room
            .client()
            .user_id()
            .context("You must be logged in to do that")?
            .to_owned();

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Unable to find me in room")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permissions to send message in this room");
                }

                timeline.cancel_send(&txn_id).await;
                Ok(true)
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub enum MsgContentDraft {
    TextPlain {
        body: String,
    },
    TextMarkdown {
        body: String,
    },
    Image {
        source: String,
        info: Option<ImageInfo>,
    },
    Audio {
        source: String,
        info: Option<AudioInfo>,
    },
    Video {
        source: String,
        info: Option<VideoInfo>,
    },
    File {
        source: String,
        info: Option<FileInfo>,
        filename: Option<String>,
    },
    Location {
        body: String,
        geo_uri: String,
        info: Option<LocationInfo>,
    },
}

impl MsgContentDraft {
    pub fn size(&self, value: u64) -> Self {
        match self {
            MsgContentDraft::Image { source, info } => {
                let mut new_info = info
                    .clone()
                    .expect("image info should be already allocated from construction");
                new_info.size = UInt::new(value);
                MsgContentDraft::Image {
                    source: source.clone(),
                    info: Some(new_info),
                }
            }
            MsgContentDraft::Audio { source, info } => {
                let mut new_info = info
                    .clone()
                    .expect("audio info should be already allocated from construction");
                new_info.size = UInt::new(value);
                MsgContentDraft::Audio {
                    source: source.clone(),
                    info: Some(new_info),
                }
            }
            MsgContentDraft::Video { source, info } => {
                let mut new_info = info
                    .clone()
                    .expect("video info should be already allocated from construction");
                new_info.size = UInt::new(value);
                MsgContentDraft::Video {
                    source: source.clone(),
                    info: Some(new_info),
                }
            }
            MsgContentDraft::File {
                source,
                info,
                filename,
            } => {
                let mut new_info = info
                    .clone()
                    .expect("file info should be already allocated from construction");
                new_info.size = UInt::new(value);
                MsgContentDraft::File {
                    source: source.clone(),
                    info: Some(new_info),
                    filename: filename.clone(),
                }
            }
            _ => {
                unreachable!("size is available for only image/audio/video/file");
            }
        }
    }

    pub fn width(&self, value: u64) -> Self {
        match self {
            MsgContentDraft::Image { source, info } => {
                let mut new_info = info
                    .clone()
                    .expect("image info should be already allocated from construction");
                new_info.width = UInt::new(value);
                MsgContentDraft::Image {
                    source: source.clone(),
                    info: Some(new_info),
                }
            }
            MsgContentDraft::Video { source, info } => {
                let mut new_info = info
                    .clone()
                    .expect("video info should be already allocated from construction");
                new_info.width = UInt::new(value);
                MsgContentDraft::Video {
                    source: source.clone(),
                    info: Some(new_info),
                }
            }
            _ => {
                unreachable!("width is available for only image/video");
            }
        }
    }

    pub fn height(&self, value: u64) -> Self {
        match self {
            MsgContentDraft::Image { source, info } => {
                let mut new_info = info
                    .clone()
                    .expect("image info should be already allocated from construction");
                new_info.height = UInt::new(value);
                MsgContentDraft::Image {
                    source: source.clone(),
                    info: Some(new_info),
                }
            }
            MsgContentDraft::Video { source, info } => {
                let mut new_info = info
                    .clone()
                    .expect("video info should be already allocated from construction");
                new_info.height = UInt::new(value);
                MsgContentDraft::Video {
                    source: source.clone(),
                    info: Some(new_info),
                }
            }
            _ => {
                unreachable!("height is available for only image/video");
            }
        }
    }

    pub fn duration(&self, value: u64) -> Self {
        match self {
            MsgContentDraft::Audio { source, info } => {
                let mut new_info = info
                    .clone()
                    .expect("audio info should be already allocated from construction");
                new_info.duration = Some(Duration::from_secs(value));
                MsgContentDraft::Audio {
                    source: source.clone(),
                    info: Some(new_info),
                }
            }
            MsgContentDraft::Video { source, info } => {
                let mut new_info = info
                    .clone()
                    .expect("video info should be already allocated from construction");
                new_info.duration = Some(Duration::from_secs(value));
                MsgContentDraft::Video {
                    source: source.clone(),
                    info: Some(new_info),
                }
            }
            _ => {
                unreachable!("duration is available for only audio/video");
            }
        }
    }

    pub fn blurhash(&self, value: String) -> Self {
        match self {
            MsgContentDraft::Image { source, info } => {
                let mut new_info = info
                    .clone()
                    .expect("image info should be already allocated from construction");
                new_info.blurhash = Some(value);
                MsgContentDraft::Image {
                    source: source.clone(),
                    info: Some(new_info),
                }
            }
            MsgContentDraft::Video { source, info } => {
                let mut new_info = info
                    .clone()
                    .expect("video info should be already allocated from construction");
                new_info.blurhash = Some(value);
                MsgContentDraft::Video {
                    source: source.clone(),
                    info: Some(new_info),
                }
            }
            _ => {
                unreachable!("blurhash is available for only image/video");
            }
        }
    }

    pub fn filename(&self, value: String) -> Self {
        match self {
            MsgContentDraft::File { source, info, .. } => MsgContentDraft::File {
                source: source.clone(),
                info: info.clone(),
                filename: Some(value),
            },
            _ => {
                unreachable!("filename is available for only file");
            }
        }
    }

    pub fn geo_uri(&self, value: String) -> Self {
        match self {
            MsgContentDraft::Location {
                body,
                geo_uri,
                info,
            } => MsgContentDraft::Location {
                body: body.clone(),
                geo_uri: geo_uri.clone(),
                info: info.clone(),
            },
            _ => {
                unreachable!("geo_uri is available for only location");
            }
        }
    }

    async fn into_edited_content(
        self, // into_* fn takes self by value not reference
        client: SdkClient,
        room: Room,
        event_id: OwnedEventId,
    ) -> Result<RoomMessageEventContent> {
        match self {
            MsgContentDraft::TextPlain { body } => Ok(RoomMessageEventContent::text_plain(body)),
            MsgContentDraft::TextMarkdown { body } => {
                Ok(RoomMessageEventContent::text_markdown(body))
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
                let edited_content =
                    RoomMessageEventContent::new(MessageType::Image(image_content));
                Ok(edited_content)
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
                let edited_content =
                    RoomMessageEventContent::new(MessageType::Audio(audio_content));
                Ok(edited_content)
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
                let edited_content =
                    RoomMessageEventContent::new(MessageType::Video(video_content));
                Ok(edited_content)
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
                let edited_content = RoomMessageEventContent::new(MessageType::File(file_content));
                Ok(edited_content)
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
                let edited_content =
                    RoomMessageEventContent::new(MessageType::Location(location_content));
                Ok(edited_content)
            }
        }
    }

    async fn into_replied_content(
        self, // into_* fn takes self by value not reference
        client: SdkClient,
        room: Room,
    ) -> Result<RoomMessageEventContentWithoutRelation> {
        match self {
            MsgContentDraft::TextPlain { body } => {
                let replied_content = RoomMessageEventContentWithoutRelation::text_plain(body);
                Ok(replied_content)
            }
            MsgContentDraft::TextMarkdown { body } => {
                let replied_content = RoomMessageEventContentWithoutRelation::text_markdown(body);
                Ok(replied_content)
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
                let replied_content =
                    RoomMessageEventContentWithoutRelation::new(MessageType::Image(image_content));
                Ok(replied_content)
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
                let replied_content =
                    RoomMessageEventContentWithoutRelation::new(MessageType::Audio(audio_content));
                Ok(replied_content)
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
                let replied_content =
                    RoomMessageEventContentWithoutRelation::new(MessageType::Video(video_content));
                Ok(replied_content)
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
                let replied_content =
                    RoomMessageEventContentWithoutRelation::new(MessageType::File(file_content));
                Ok(replied_content)
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
                let replied_content = RoomMessageEventContentWithoutRelation::new(
                    MessageType::Location(location_content),
                );
                Ok(replied_content)
            }
        }
    }
}

impl Client {
    pub fn text_plain_draft(&self, body: String) -> MsgContentDraft {
        MsgContentDraft::TextPlain { body }
    }

    pub fn text_markdown_draft(&self, body: String) -> MsgContentDraft {
        MsgContentDraft::TextMarkdown { body }
    }

    pub fn image_draft(&self, source: String, mimetype: String) -> MsgContentDraft {
        let info = assign!(ImageInfo::new(), {
            mimetype: Some(mimetype),
        });
        MsgContentDraft::Image {
            source,
            info: Some(info),
        }
    }

    pub fn audio_draft(&self, source: String, mimetype: String) -> MsgContentDraft {
        let info = assign!(AudioInfo::new(), {
            mimetype: Some(mimetype),
        });
        MsgContentDraft::Audio {
            source,
            info: Some(info),
        }
    }

    pub fn video_draft(&self, source: String, mimetype: String) -> MsgContentDraft {
        let info = assign!(VideoInfo::new(), {
            mimetype: Some(mimetype),
        });
        MsgContentDraft::Video {
            source,
            info: Some(info),
        }
    }

    pub fn file_draft(&self, source: String, mimetype: String) -> MsgContentDraft {
        let info = assign!(FileInfo::new(), {
            mimetype: Some(mimetype),
        });
        MsgContentDraft::File {
            source,
            info: Some(info),
            filename: None,
        }
    }

    pub fn location_draft(&self, body: String, geo_uri: String) -> MsgContentDraft {
        MsgContentDraft::Location {
            body,
            geo_uri,
            info: None,
        }
    }
}
