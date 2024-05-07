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
use ruma_client_api::{receipt::create_receipt, sync::sync_events::v3::Rooms};
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
    Mentions, MessageLikeEventType,
};
use std::{ops::Deref, path::PathBuf, sync::Arc};
use tracing::info;

use crate::{Client, RoomMessage, RUNTIME};

use super::utils::{remap_for_diff, ApiVectorDiff};

pub type RoomMessageDiff = ApiVectorDiff<RoomMessage>;

#[derive(Clone)]
pub struct TimelineStream {
    room: Room,
    timeline: Arc<Timeline>,
}

impl TimelineStream {
    pub fn new(room: Room, timeline: Arc<Timeline>) -> Self {
        TimelineStream { room, timeline }
    }

    pub fn messages_stream(&self) -> impl Stream<Item = RoomMessageDiff> {
        let timeline = self.timeline.clone();
        let user_id = self
            .room
            .client()
            .user_id()
            .expect("User must be logged in")
            .to_owned();

        async_stream::stream! {
            let (timeline_items, mut timeline_stream) = timeline.subscribe().await;
            yield RoomMessageDiff::current_items(timeline_items.clone().into_iter().map(|x| RoomMessage::from((x, user_id.clone()))).collect());

            let mut remap = timeline_stream.map(|diff| remap_for_diff(
                diff,
                |x| RoomMessage::from((x, user_id.clone())),
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

    pub async fn get_message(&self, event_id: String) -> Result<RoomMessage> {
        let event_id = OwnedEventId::try_from(event_id)?;

        let timeline = self.timeline.clone();
        let user_id = self
            .room
            .client()
            .user_id()
            .expect("User is logged in")
            .to_owned();

        RUNTIME
            .spawn(async move {
                let Some(tl) = timeline.item_by_event_id(&event_id).await else {
                    bail!("Event not found")
                };
                Ok(RoomMessage::from((tl, user_id)))
            })
            .await?
    }

    fn is_joined(&self) -> bool {
        matches!(self.room.state(), RoomState::Joined)
    }

    pub async fn send_message(&self, draft: Box<MsgDraft>) -> Result<bool> {
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
                let msg = draft.into_room_msg(&room).await?;
                timeline.send(msg.with_relation(None).into()).await;
                Ok(true)
            })
            .await?
    }

    pub async fn edit_message(&self, event_id: String, draft: Box<MsgDraft>) -> Result<bool> {
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
                let new_content = draft.into_room_msg(&room).await?;
                timeline
                    .edit(new_content.with_relation(None), &edit_item)
                    .await?;
                Ok(true)
            })
            .await?
    }

    pub async fn reply_message(&self, event_id: String, draft: Box<MsgDraft>) -> Result<bool> {
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
                let content = draft.into_room_msg(&room).await?;
                timeline
                    .send_reply(
                        content.with_relation(None).into(),
                        &reply_item,
                        ForwardThread::Yes,
                    )
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
pub(crate) enum MsgContentDraft {
    TextPlain {
        body: String,
    },
    TextMarkdown {
        body: String,
    },
    TextHtml {
        html: String,
        plain: String,
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
}

#[derive(Clone, Debug)]
pub struct MsgDraft {
    pub(crate) inner: MsgContentDraft,
    pub(crate) mentions: Mentions,
}

impl MsgDraft {
    pub fn add_mention(&mut self, user_id: String) -> Result<bool> {
        self.mentions.user_ids.insert(user_id.parse()?);
        Ok(true)
    }
    pub fn add_room_mention(&mut self, mention: bool) -> Result<bool> {
        self.mentions.room = mention;
        Ok(true)
    }
}

impl MsgDraft {
    fn new(inner: MsgContentDraft) -> Self {
        MsgDraft {
            inner,
            mentions: Mentions::new(),
        }
    }

    async fn into_room_msg(self, room: &Room) -> Result<RoomMessageEventContentWithoutRelation> {
        let MsgDraft { inner, mentions } = self;

        Ok(
            match inner {
                MsgContentDraft::TextPlain { body } => {
                    RoomMessageEventContentWithoutRelation::text_plain(body)
                }
                MsgContentDraft::TextMarkdown { body } => {
                    RoomMessageEventContentWithoutRelation::text_markdown(body)
                }
                MsgContentDraft::TextHtml { html, plain } => {
                    RoomMessageEventContentWithoutRelation::text_html(plain, html)
                }

                MsgContentDraft::Location {
                    body,
                    geo_uri,
                    info,
                } => RoomMessageEventContentWithoutRelation::new(MessageType::Location(
                    LocationMessageEventContent::new(body, geo_uri),
                )),

                MsgContentDraft::Image { source, info } => {
                    let info = info.expect("image info needed");
                    let mimetype = info.mimetype.clone().expect("mimetype needed");
                    let content_type = mimetype.parse::<mime::Mime>()?;
                    let path = PathBuf::from(source);
                    let mut image_content = if room.is_encrypted().await? {
                        let mut reader = std::fs::File::open(path.clone())?;
                        let encrypted_file = room
                            .client()
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
                        let response = room
                            .client()
                            .media()
                            .upload(&content_type, image_buf)
                            .await?;
                        let body = path
                            .file_name()
                            .expect("it is not file")
                            .to_string_lossy()
                            .to_string();
                        ImageMessageEventContent::plain(body, response.content_uri)
                    };
                    image_content.info = Some(Box::new(info));
                    RoomMessageEventContentWithoutRelation::new(MessageType::Image(image_content))
                }
                MsgContentDraft::Audio { source, info } => {
                    let info = info.expect("audio info needed");
                    let mimetype = info.mimetype.clone().expect("mimetype needed");
                    let content_type = mimetype.parse::<mime::Mime>()?;
                    let path = PathBuf::from(source);
                    let mut audio_content = if room.is_encrypted().await? {
                        let mut reader = std::fs::File::open(path.clone())?;
                        let encrypted_file = room
                            .client()
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
                        let response = room
                            .client()
                            .media()
                            .upload(&content_type, audio_buf)
                            .await?;
                        let body = path
                            .file_name()
                            .expect("it is not file")
                            .to_string_lossy()
                            .to_string();
                        AudioMessageEventContent::plain(body, response.content_uri)
                    };
                    audio_content.info = Some(Box::new(info));
                    RoomMessageEventContentWithoutRelation::new(MessageType::Audio(audio_content))
                }
                MsgContentDraft::Video { source, info } => {
                    let info = info.expect("video info needed");
                    let mimetype = info.mimetype.clone().expect("mimetype needed");
                    let content_type = mimetype.parse::<mime::Mime>()?;
                    let path = PathBuf::from(source);
                    let mut video_content = if room.is_encrypted().await? {
                        let mut reader = std::fs::File::open(path.clone())?;
                        let encrypted_file = room
                            .client()
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
                        let response = room
                            .client()
                            .media()
                            .upload(&content_type, video_buf)
                            .await?;
                        let body = path
                            .file_name()
                            .expect("it is not file")
                            .to_string_lossy()
                            .to_string();
                        VideoMessageEventContent::plain(body, response.content_uri)
                    };
                    video_content.info = Some(Box::new(info));
                    RoomMessageEventContentWithoutRelation::new(MessageType::Video(video_content))
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
                        let encrypted_file = room
                            .client()
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
                        let response = room
                            .client()
                            .media()
                            .upload(&content_type, file_buf)
                            .await?;
                        let body = path
                            .file_name()
                            .expect("it is not file")
                            .to_string_lossy()
                            .to_string();
                        FileMessageEventContent::plain(body, response.content_uri)
                    };
                    file_content.info = Some(Box::new(info));
                    file_content.filename = filename;
                    RoomMessageEventContentWithoutRelation::new(MessageType::File(file_content))
                }
            }
            .add_mentions(mentions), // add the mentions
        )
    }
}

impl Client {
    pub fn text_plain_draft(&self, body: String) -> MsgDraft {
        MsgDraft::new(MsgContentDraft::TextPlain { body })
    }

    pub fn text_markdown_draft(&self, body: String) -> MsgDraft {
        MsgDraft::new(MsgContentDraft::TextMarkdown { body })
    }

    pub fn text_html_draft(&self, html: String, plain: String) -> MsgDraft {
        MsgDraft::new(MsgContentDraft::TextHtml { html, plain })
    }

    pub fn image_draft(&self, source: String, mimetype: String) -> MsgDraft {
        let info = assign!(ImageInfo::new(), {
            mimetype: Some(mimetype),
        });
        MsgDraft::new(MsgContentDraft::Image {
            source,
            info: Some(info),
        })
    }

    pub fn audio_draft(&self, source: String, mimetype: String) -> MsgDraft {
        let info = assign!(AudioInfo::new(), {
            mimetype: Some(mimetype),
        });
        MsgDraft::new(MsgContentDraft::Audio {
            source,
            info: Some(info),
        })
    }

    pub fn video_draft(&self, source: String, mimetype: String) -> MsgDraft {
        let info = assign!(VideoInfo::new(), {
            mimetype: Some(mimetype),
        });
        MsgDraft::new(MsgContentDraft::Video {
            source,
            info: Some(info),
        })
    }

    pub fn file_draft(&self, source: String, mimetype: String) -> MsgDraft {
        let info = assign!(FileInfo::new(), {
            mimetype: Some(mimetype),
        });
        MsgDraft::new(MsgContentDraft::File {
            source,
            info: Some(info),
            filename: None,
        })
    }

    pub fn location_draft(&self, body: String, geo_uri: String) -> MsgDraft {
        MsgDraft::new(MsgContentDraft::Location {
            body,
            geo_uri,
            info: None,
        })
    }
}
