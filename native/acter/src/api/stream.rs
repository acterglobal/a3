use anyhow::{bail, Context, Result};
use core::time::Duration;
use futures::stream::{Stream, StreamExt};
use matrix_sdk::{
    attachment::{
        AttachmentConfig, AttachmentInfo, BaseAudioInfo, BaseFileInfo, BaseImageInfo, BaseVideoInfo,
    },
    room::{Receipts, Room},
    ruma::{api::client::receipt::create_receipt, assign, UInt},
    RoomState,
};
use matrix_sdk_ui::timeline::{BackPaginationStatus, PaginationOptions, Timeline};
use ruma_common::EventId;
use ruma_events::{
    receipt::ReceiptThread,
    relation::Replacement,
    room::{
        message::{
            AudioInfo, AudioMessageEventContent, FileInfo, FileMessageEventContent,
            ImageMessageEventContent, LocationMessageEventContent, MessageType, Relation,
            RoomMessageEvent, RoomMessageEventContent, VideoInfo, VideoMessageEventContent,
        },
        ImageInfo,
    },
    MessageLikeEventType,
};
use std::{path::PathBuf, sync::Arc};
use tracing::info;

use super::{
    message::RoomMessage,
    utils::{remap_for_diff, ApiVectorDiff},
    RUNTIME,
};

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
                let options = PaginationOptions::single_request(count);
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

    pub async fn send_plain_message(&self, message: String) -> Result<bool> {
        if !self.is_joined() {
            bail!("Can't send message as plain text to a room we are not in");
        }
        let room = self.room.clone();
        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();
        let timeline = self.timeline.clone();

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }
                let content = RoomMessageEventContent::text_plain(message);
                timeline.send(content.into()).await;
                Ok(true)
            })
            .await?
    }

    pub async fn edit_plain_message(&self, event_id: String, new_msg: String) -> Result<bool> {
        if !self.is_joined() {
            bail!("Can't edit message as plain text to a room we are not in");
        }
        let room = self.room.clone();
        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();
        let timeline = self.timeline.clone();
        let event_id = EventId::parse(event_id)?;
        let client = self.room.client();

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }

                let timeline_event = room.event(&event_id).await?;
                let event_content = timeline_event
                    .event
                    .deserialize_as::<RoomMessageEvent>()
                    .context("Couldn't deserialise event")?;

                let mut sent_by_me = false;
                if let Some(user_id) = client.user_id() {
                    if user_id == event_content.sender() {
                        sent_by_me = true;
                    }
                }
                if !sent_by_me {
                    bail!("Can't edit an event not sent by own user");
                }

                let replacement = Replacement::new(
                    event_id.to_owned(),
                    MessageType::text_plain(new_msg.to_string()).into(),
                );
                let mut edited_content = RoomMessageEventContent::text_plain(new_msg);
                edited_content.relates_to = Some(Relation::Replacement(replacement));

                timeline.send(edited_content.into()).await;
                Ok(true)
            })
            .await?
    }

    pub async fn send_formatted_message(&self, markdown: String) -> Result<bool> {
        if !self.is_joined() {
            bail!("Can't send message as formatted text to a room we are not in");
        }
        let room = self.room.clone();
        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();
        let timeline = self.timeline.clone();

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }
                let content = RoomMessageEventContent::text_markdown(markdown);
                timeline.send(content.into()).await;
                Ok(true)
            })
            .await?
    }

    pub async fn edit_formatted_message(&self, event_id: String, new_msg: String) -> Result<bool> {
        if !self.is_joined() {
            bail!("Can't edit message as formatted text to a room we are not in");
        }
        let room = self.room.clone();
        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();
        let event_id = EventId::parse(event_id)?;
        let client = self.room.client();
        let timeline = self.timeline.clone();

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }

                let timeline_event = room.event(&event_id).await?;
                let event_content = timeline_event
                    .event
                    .deserialize_as::<RoomMessageEvent>()
                    .context("Couldn't deserialise event")?;

                let mut sent_by_me = false;
                if let Some(user_id) = client.user_id() {
                    if user_id == event_content.sender() {
                        sent_by_me = true;
                    }
                }
                if !sent_by_me {
                    bail!("Can't edit an event not sent by own user");
                }

                let replacement = Replacement::new(
                    event_id.to_owned(),
                    MessageType::text_markdown(new_msg.to_string()).into(),
                );
                let mut edited_content = RoomMessageEventContent::text_markdown(new_msg);
                edited_content.relates_to = Some(Relation::Replacement(replacement));

                timeline.send(edited_content.into()).await;
                Ok(true)
            })
            .await?
    }

    #[allow(clippy::too_many_arguments)]
    pub async fn send_image_message(
        &self,
        uri: String,
        name: String,
        mimetype: String,
        size: Option<u64>,
        width: Option<u64>,
        height: Option<u64>,
        blurhash: Option<String>,
    ) -> Result<bool> {
        if !self.is_joined() {
            bail!("Can't send message as image to a room we are not in")
        }
        let room = self.room.clone();
        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();
        let timeline = self.timeline.clone();

        let config = AttachmentConfig::new().info(AttachmentInfo::Image(BaseImageInfo {
            height: height.and_then(UInt::new),
            width: width.and_then(UInt::new),
            size: size.and_then(UInt::new),
            blurhash,
        }));
        let mime_type = mimetype.parse::<mime::Mime>()?;

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }
                timeline.send_attachment(uri, mime_type, config).await?;
                Ok(true)
            })
            .await?
    }

    #[allow(clippy::too_many_arguments)]
    pub async fn edit_image_message(
        &self,
        event_id: String,
        uri: String,
        name: String,
        mimetype: String,
        size: Option<u64>,
        width: Option<u64>,
        height: Option<u64>,
    ) -> Result<bool> {
        if !self.is_joined() {
            bail!("Can't edit message as image to a room we are not in");
        }
        let room = self.room.clone();
        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();
        let event_id = EventId::parse(event_id)?;
        let client = self.room.client();
        let timeline = self.timeline.clone();

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }

                let path = PathBuf::from(uri);
                let mut image_buf = std::fs::read(path)?;

                let timeline_event = room.event(&event_id).await?;
                let event_content = timeline_event
                    .event
                    .deserialize_as::<RoomMessageEvent>()
                    .context("Couldn't deserialise event")?;

                let mut sent_by_me = false;
                if let Some(user_id) = client.user_id() {
                    if user_id == event_content.sender() {
                        sent_by_me = true;
                    }
                }
                if !sent_by_me {
                    bail!("Can't edit an event not sent by own user");
                }

                let content_type = mimetype.parse::<mime::Mime>()?;
                let response = client.media().upload(&content_type, image_buf).await?;

                let info = assign!(ImageInfo::new(), {
                    height: height.and_then(UInt::new),
                    width: width.and_then(UInt::new),
                    mimetype: Some(mimetype),
                    size: size.and_then(UInt::new),
                });
                let mut image_content = ImageMessageEventContent::plain(name, response.content_uri);
                image_content.info = Some(Box::new(info));
                let mut edited_content =
                    RoomMessageEventContent::new(MessageType::Image(image_content.clone()));
                let replacement = Replacement::new(
                    event_id.to_owned(),
                    MessageType::Image(image_content).into(),
                );
                edited_content.relates_to = Some(Relation::Replacement(replacement));

                timeline.send(edited_content.into()).await;
                Ok(true)
            })
            .await?
    }

    pub async fn send_audio_message(
        &self,
        uri: String,
        name: String,
        mimetype: String,
        size: Option<u64>,
        secs: Option<u64>,
    ) -> Result<bool> {
        if !self.is_joined() {
            bail!("Can't send message as audio to a room we are not in");
        }
        let room = self.room.clone();
        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();
        let timeline = self.timeline.clone();

        let config = AttachmentConfig::new().info(AttachmentInfo::Audio(BaseAudioInfo {
            duration: secs.map(Duration::from_secs),
            size: size.and_then(UInt::new),
        }));
        let mime_type = mimetype.parse::<mime::Mime>()?;

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }
                timeline.send_attachment(uri, mime_type, config).await?;
                Ok(true)
            })
            .await?
    }

    #[allow(clippy::too_many_arguments)]
    pub async fn edit_audio_message(
        &self,
        event_id: String,
        uri: String,
        name: String,
        mimetype: String,
        size: Option<u64>,
        secs: Option<u64>,
    ) -> Result<bool> {
        if !self.is_joined() {
            bail!("Can't edit message as audio to a room we are not in");
        }
        let room = self.room.clone();
        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();
        let event_id = EventId::parse(event_id)?;
        let client = self.room.client();
        let timeline = self.timeline.clone();

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }

                let path = PathBuf::from(uri);
                let mut audio_buf = std::fs::read(path)?;

                let timeline_event = room.event(&event_id).await?;
                let event_content = timeline_event
                    .event
                    .deserialize_as::<RoomMessageEvent>()
                    .context("Couldn't deserialise event")?;

                let mut sent_by_me = false;
                if let Some(user_id) = client.user_id() {
                    if user_id == event_content.sender() {
                        sent_by_me = true;
                    }
                }
                if !sent_by_me {
                    bail!("Can't edit an event not sent by own user");
                }

                let content_type = mimetype.parse::<mime::Mime>()?;
                let response = client.media().upload(&content_type, audio_buf).await?;

                let info = assign!(AudioInfo::new(), {
                    duration: secs.map(Duration::from_secs),
                    mimetype: Some(mimetype),
                    size: size.and_then(UInt::new),
                });
                let mut audio_content = AudioMessageEventContent::plain(name, response.content_uri);
                audio_content.info = Some(Box::new(info));
                let mut edited_content =
                    RoomMessageEventContent::new(MessageType::Audio(audio_content.clone()));
                let replacement = Replacement::new(
                    event_id.to_owned(),
                    MessageType::Audio(audio_content).into(),
                );
                edited_content.relates_to = Some(Relation::Replacement(replacement));

                timeline.send(edited_content.into()).await;
                Ok(true)
            })
            .await?
    }

    #[allow(clippy::too_many_arguments)]
    pub async fn send_video_message(
        &self,
        uri: String,
        name: String,
        mimetype: String,
        size: Option<u64>,
        secs: Option<u64>,
        width: Option<u64>,
        height: Option<u64>,
        blurhash: Option<String>,
    ) -> Result<bool> {
        if !self.is_joined() {
            bail!("Can't send message as video to a room we are not in");
        }
        let room = self.room.clone();
        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();
        let timeline = self.timeline.clone();

        let config = AttachmentConfig::new().info(AttachmentInfo::Video(BaseVideoInfo {
            duration: secs.map(Duration::from_secs),
            height: height.and_then(UInt::new),
            width: width.and_then(UInt::new),
            size: size.and_then(UInt::new),
            blurhash,
        }));
        let mime_type = mimetype.parse::<mime::Mime>()?;

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }
                timeline.send_attachment(uri, mime_type, config).await?;
                Ok(true)
            })
            .await?
    }

    #[allow(clippy::too_many_arguments)]
    pub async fn edit_video_message(
        &self,
        event_id: String,
        uri: String,
        name: String,
        mimetype: String,
        size: Option<u64>,
        secs: Option<u64>,
        width: Option<u64>,
        height: Option<u64>,
    ) -> Result<bool> {
        if !self.is_joined() {
            bail!("Can't edit message as video to a room we are not in");
        }
        let room = self.room.clone();
        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();
        let event_id = EventId::parse(event_id)?;
        let client = self.room.client();
        let timeline = self.timeline.clone();

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }

                let path = PathBuf::from(uri);
                let mut video_buf = std::fs::read(path)?;

                let timeline_event = room.event(&event_id).await?;
                let event_content = timeline_event
                    .event
                    .deserialize_as::<RoomMessageEvent>()
                    .context("Couldn't deserialise event")?;

                let mut sent_by_me = false;
                if let Some(user_id) = client.user_id() {
                    if user_id == event_content.sender() {
                        sent_by_me = true;
                    }
                }
                if !sent_by_me {
                    bail!("Can't edit an event not sent by own user");
                }

                let content_type = mimetype.parse::<mime::Mime>()?;
                let response = client.media().upload(&content_type, video_buf).await?;

                let info = assign!(VideoInfo::new(), {
                    duration: secs.map(Duration::from_secs),
                    height: height.and_then(UInt::new),
                    width: width.and_then(UInt::new),
                    mimetype: Some(mimetype),
                    size: size.and_then(UInt::new),
                });
                let mut video_content = VideoMessageEventContent::plain(name, response.content_uri);
                video_content.info = Some(Box::new(info));
                let mut edited_content =
                    RoomMessageEventContent::new(MessageType::Video(video_content.clone()));
                let replacement = Replacement::new(
                    event_id.to_owned(),
                    MessageType::Video(video_content).into(),
                );
                edited_content.relates_to = Some(Relation::Replacement(replacement));

                timeline.send(edited_content.into()).await;
                Ok(true)
            })
            .await?
    }

    pub async fn send_file_message(
        &self,
        uri: String,
        name: String,
        mimetype: String,
        size: Option<u64>,
    ) -> Result<bool> {
        if !self.is_joined() {
            bail!("Can't send message as file to a room we are not in");
        }
        let room = self.room.clone();
        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();
        let timeline = self.timeline.clone();

        let config = AttachmentConfig::new().info(AttachmentInfo::File(BaseFileInfo {
            size: size.and_then(UInt::new),
        }));
        let mime_type = mimetype.parse::<mime::Mime>()?;

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }
                timeline.send_attachment(uri, mime_type, config).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn edit_file_message(
        &self,
        event_id: String,
        uri: String,
        name: String,
        mimetype: String,
        size: Option<u64>,
    ) -> Result<bool> {
        if !self.is_joined() {
            bail!("Can't edit message as file to a room we are not in");
        }
        let room = self.room.clone();
        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();
        let event_id = EventId::parse(event_id)?;
        let client = self.room.client();
        let timeline = self.timeline.clone();

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }

                let path = PathBuf::from(uri);
                let mut file_buf = std::fs::read(path)?;

                let timeline_event = room.event(&event_id).await?;
                let event_content = timeline_event
                    .event
                    .deserialize_as::<RoomMessageEvent>()
                    .context("Couldn't deserialise event")?;

                let mut sent_by_me = false;
                if let Some(user_id) = client.user_id() {
                    if user_id == event_content.sender() {
                        sent_by_me = true;
                    }
                }
                if !sent_by_me {
                    bail!("Can't edit an event not sent by own user");
                }

                let content_type = mimetype.parse::<mime::Mime>()?;
                let response = client.media().upload(&content_type, file_buf).await?;

                let info = assign!(FileInfo::new(), {
                    mimetype: Some(mimetype),
                    size: size.and_then(UInt::new),
                });
                let mut file_content = FileMessageEventContent::plain(name, response.content_uri);
                file_content.info = Some(Box::new(info));
                let mut edited_content =
                    RoomMessageEventContent::new(MessageType::File(file_content.clone()));
                let replacement =
                    Replacement::new(event_id.to_owned(), MessageType::File(file_content).into());
                edited_content.relates_to = Some(Relation::Replacement(replacement));

                timeline.send(edited_content.into()).await;
                Ok(true)
            })
            .await?
    }

    pub async fn send_location_message(&self, body: String, geo_uri: String) -> Result<bool> {
        if !self.is_joined() {
            bail!("Can't send message as location to a room we are not in");
        }
        let room = self.room.clone();
        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();
        let timeline = self.timeline.clone();

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }
                let location_content = LocationMessageEventContent::new(body, geo_uri);
                let content = RoomMessageEventContent::new(MessageType::Location(location_content));
                timeline.send(content.into()).await;
                Ok(true)
            })
            .await?
    }

    pub async fn edit_location_message(
        &self,
        event_id: String,
        body: String,
        geo_uri: String,
    ) -> Result<bool> {
        if !self.is_joined() {
            bail!("Can't edit message as location to a room we are not in");
        }
        let room = self.room.clone();
        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();
        let event_id = EventId::parse(event_id)?;
        let client = self.room.client();
        let timeline = self.timeline.clone();

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }

                let timeline_event = room.event(&event_id).await?;
                let event_content = timeline_event
                    .event
                    .deserialize_as::<RoomMessageEvent>()
                    .context("Couldn't deserialise event")?;

                let mut sent_by_me = false;
                if let Some(user_id) = client.user_id() {
                    if user_id == event_content.sender() {
                        sent_by_me = true;
                    }
                }
                if !sent_by_me {
                    bail!("Can't edit an event not sent by own user");
                }

                let location_content = LocationMessageEventContent::new(body, geo_uri);
                let mut edited_content =
                    RoomMessageEventContent::new(MessageType::Location(location_content.clone()));
                let replacement = Replacement::new(
                    event_id.to_owned(),
                    MessageType::Location(location_content).into(),
                );
                edited_content.relates_to = Some(Relation::Replacement(replacement));

                timeline.send(edited_content.into()).await;
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
}
