use acter_core::events::{
    attachments::{AttachmentContent, FallbackAttachmentContent},
    rsvp::RsvpStatus,
    ColorizeBuilder, ObjRefBuilder, Position, RefDetails, RefDetailsBuilder,
};
use anyhow::{Context, Result};
use core::time::Duration;
use matrix_sdk::media::{MediaFormat, MediaThumbnailSize};
use ruma::UInt;
use ruma_client_api::media::get_content_thumbnail;
use ruma_common::{EventId, MilliSecondsSinceUnixEpoch, OwnedDeviceId, OwnedMxcUri, OwnedUserId};
use ruma_events::{
    room::{
        message::{
            AudioInfo, AudioMessageEventContent, EmoteMessageEventContent, FileInfo,
            FileMessageEventContent, ImageMessageEventContent, LocationInfo,
            LocationMessageEventContent, TextMessageEventContent, UnstableAudioDetailsContentBlock,
            VideoInfo, VideoMessageEventContent,
        },
        ImageInfo, MediaSource as SdkMediaSource, ThumbnailInfo as SdkThumbnailInfo,
    },
    sticker::StickerEventContent,
};
use serde::{Deserialize, Serialize};
use std::str::FromStr;

use super::api::FfiBuffer;

pub fn duration_from_secs(secs: u64) -> Duration {
    Duration::from_secs(secs)
}

pub struct OptionString {
    text: Option<String>,
}

impl OptionString {
    pub(crate) fn new(text: Option<String>) -> Self {
        OptionString { text }
    }

    pub fn text(&self) -> Option<String> {
        self.text.clone()
    }
}

pub struct OptionBuffer {
    pub(crate) data: Option<Vec<u8>>,
}

impl OptionBuffer {
    pub(crate) fn new(data: Option<Vec<u8>>) -> Self {
        OptionBuffer { data }
    }

    pub fn data(&self) -> Option<FfiBuffer<u8>> {
        self.data.clone().map(FfiBuffer::new)
    }
}

pub struct OptionRsvpStatus {
    pub(crate) status: Option<RsvpStatus>,
}

impl OptionRsvpStatus {
    pub(crate) fn new(status: Option<RsvpStatus>) -> Self {
        OptionRsvpStatus { status }
    }

    pub fn status(&self) -> Option<RsvpStatus> {
        self.status.clone()
    }

    pub fn status_str(&self) -> Option<String> {
        self.status.as_ref().map(|x| x.to_string())
    }
}

pub struct MediaSource {
    inner: SdkMediaSource,
}

impl MediaSource {
    pub fn url(&self) -> String {
        match self.inner.clone() {
            SdkMediaSource::Plain(url) => url.to_string(),
            SdkMediaSource::Encrypted(file) => file.url.to_string(),
        }
    }
}

#[derive(Clone)]
pub struct ThumbnailInfo {
    inner: SdkThumbnailInfo,
}

impl ThumbnailInfo {
    pub fn mimetype(&self) -> Option<String> {
        self.inner.mimetype.clone()
    }

    pub fn size(&self) -> Option<u64> {
        self.inner.size.map(|x| x.into())
    }

    pub fn width(&self) -> Option<u64> {
        self.inner.width.map(|x| x.into())
    }

    pub fn height(&self) -> Option<u64> {
        self.inner.height.map(|x| x.into())
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum MsgContent {
    Text {
        body: String,
        formatted_body: Option<String>,
    },
    Image {
        body: String,
        source: SdkMediaSource,
        info: Option<ImageInfo>,
    },
    Audio {
        body: String,
        source: SdkMediaSource,
        info: Option<AudioInfo>,
        audio: Option<UnstableAudioDetailsContentBlock>,
    },
    Video {
        body: String,
        source: SdkMediaSource,
        info: Option<VideoInfo>,
    },
    File {
        body: String,
        source: SdkMediaSource,
        info: Option<FileInfo>,
        filename: Option<String>,
    },
    Location {
        body: String,
        geo_uri: String,
        info: Option<LocationInfo>,
    },
}

impl From<&TextMessageEventContent> for MsgContent {
    fn from(value: &TextMessageEventContent) -> Self {
        MsgContent::Text {
            body: value.body.clone(),
            formatted_body: value.formatted.clone().map(|x| x.body),
        }
    }
}

impl From<TextMessageEventContent> for MsgContent {
    fn from(value: TextMessageEventContent) -> Self {
        MsgContent::Text {
            body: value.body,
            formatted_body: value.formatted.map(|x| x.body),
        }
    }
}

impl From<&ImageMessageEventContent> for MsgContent {
    fn from(value: &ImageMessageEventContent) -> Self {
        MsgContent::Image {
            body: value.body.clone(),
            source: value.source.clone(),
            info: value.info.as_ref().map(|x| *x.clone()),
        }
    }
}

impl From<&AudioMessageEventContent> for MsgContent {
    fn from(value: &AudioMessageEventContent) -> Self {
        MsgContent::Audio {
            body: value.body.clone(),
            source: value.source.clone(),
            info: value.info.as_ref().map(|x| *x.clone()),
            audio: value.audio.clone(),
        }
    }
}

impl From<&VideoMessageEventContent> for MsgContent {
    fn from(value: &VideoMessageEventContent) -> Self {
        MsgContent::Video {
            body: value.body.clone(),
            source: value.source.clone(),
            info: value.info.as_ref().map(|x| *x.clone()),
        }
    }
}

impl From<&FileMessageEventContent> for MsgContent {
    fn from(value: &FileMessageEventContent) -> Self {
        MsgContent::File {
            body: value.body.clone(),
            source: value.source.clone(),
            info: value.info.as_ref().map(|x| *x.clone()),
            filename: value.filename.clone(),
        }
    }
}

impl From<&LocationMessageEventContent> for MsgContent {
    fn from(value: &LocationMessageEventContent) -> Self {
        MsgContent::Location {
            body: value.body.clone(),
            geo_uri: value.geo_uri.clone(),
            info: value.info.as_ref().map(|x| *x.clone()),
        }
    }
}

impl From<&EmoteMessageEventContent> for MsgContent {
    fn from(value: &EmoteMessageEventContent) -> Self {
        MsgContent::Text {
            body: value.body.clone(),
            formatted_body: value.formatted.clone().map(|x| x.body),
        }
    }
}

impl From<&StickerEventContent> for MsgContent {
    fn from(value: &StickerEventContent) -> Self {
        MsgContent::Image {
            body: value.body.clone(),
            source: SdkMediaSource::Plain(value.url.clone()),
            info: Some(value.info.clone()),
        }
    }
}

impl From<&AttachmentContent> for MsgContent {
    fn from(value: &AttachmentContent) -> Self {
        match value {
            AttachmentContent::Image(content)
            | AttachmentContent::Fallback(FallbackAttachmentContent::Image(content)) => {
                MsgContent::Image {
                    body: content.body.clone(),
                    source: content.source.clone(),
                    info: content.info.as_ref().map(|x| *x.clone()),
                }
            }
            AttachmentContent::Audio(content)
            | AttachmentContent::Fallback(FallbackAttachmentContent::Audio(content)) => {
                MsgContent::Audio {
                    body: content.body.clone(),
                    source: content.source.clone(),
                    info: content.info.as_ref().map(|x| *x.clone()),
                    audio: content.audio.clone(),
                }
            }
            AttachmentContent::Video(content)
            | AttachmentContent::Fallback(FallbackAttachmentContent::Video(content)) => {
                MsgContent::Video {
                    body: content.body.clone(),
                    source: content.source.clone(),
                    info: content.info.as_ref().map(|x| *x.clone()),
                }
            }
            AttachmentContent::File(content)
            | AttachmentContent::Fallback(FallbackAttachmentContent::File(content)) => {
                MsgContent::File {
                    body: content.body.clone(),
                    source: content.source.clone(),
                    info: content.info.as_ref().map(|x| *x.clone()),
                    filename: content.filename.clone(),
                }
            }
            AttachmentContent::Location(content)
            | AttachmentContent::Fallback(FallbackAttachmentContent::Location(content)) => {
                MsgContent::Location {
                    body: content.body.clone(),
                    geo_uri: content.geo_uri.clone(),
                    info: content.info.as_ref().map(|x| *x.clone()),
                }
            }
        }
    }
}

impl MsgContent {
    pub(crate) fn from_text(body: String) -> Self {
        MsgContent::Text {
            body,
            formatted_body: None,
        }
    }

    pub(crate) fn from_image(body: String, source: OwnedMxcUri) -> Self {
        MsgContent::Image {
            body,
            source: SdkMediaSource::Plain(source),
            info: Some(ImageInfo::new()),
        }
    }

    pub fn body(&self) -> String {
        match self {
            MsgContent::Text { body, .. } => body.clone(),
            MsgContent::Image { body, .. } => body.clone(),
            MsgContent::Audio { body, .. } => body.clone(),
            MsgContent::Video { body, .. } => body.clone(),
            MsgContent::File { body, .. } => body.clone(),
            MsgContent::Location { body, .. } => body.clone(),
        }
    }

    pub fn formatted_body(&self) -> Option<String> {
        match self {
            MsgContent::Text { formatted_body, .. } => formatted_body.clone(),
            _ => None,
        }
    }

    pub fn source(&self) -> Option<MediaSource> {
        match self {
            MsgContent::Image { source, .. } => Some(MediaSource {
                inner: source.clone(),
            }),
            MsgContent::Audio { source, .. } => Some(MediaSource {
                inner: source.clone(),
            }),
            MsgContent::Video { source, .. } => Some(MediaSource {
                inner: source.clone(),
            }),
            MsgContent::File { source, .. } => Some(MediaSource {
                inner: source.clone(),
            }),
            _ => None,
        }
    }

    pub fn mimetype(&self) -> Option<String> {
        match self {
            MsgContent::Image { info, .. } => info.as_ref().and_then(|x| x.mimetype.clone()),
            MsgContent::Audio { info, .. } => info.as_ref().and_then(|x| x.mimetype.clone()),
            MsgContent::Video { info, .. } => info.as_ref().and_then(|x| x.mimetype.clone()),
            MsgContent::File { info, .. } => info.as_ref().and_then(|x| x.mimetype.clone()),
            _ => None,
        }
    }

    pub fn size(&self) -> Option<u64> {
        match self {
            MsgContent::Image { info, .. } => info.as_ref().and_then(|x| x.size.map(|x| x.into())),
            MsgContent::Audio { info, .. } => info.as_ref().and_then(|x| x.size.map(|x| x.into())),
            MsgContent::Video { info, .. } => info.as_ref().and_then(|x| x.size.map(|x| x.into())),
            MsgContent::File { info, .. } => info.as_ref().and_then(|x| x.size.map(|x| x.into())),
            _ => None,
        }
    }

    pub fn width(&self) -> Option<u64> {
        match self {
            MsgContent::Image { info, .. } => info.as_ref().and_then(|x| x.width.map(|x| x.into())),
            MsgContent::Video { info, .. } => info.as_ref().and_then(|x| x.width.map(|x| x.into())),
            _ => None,
        }
    }

    pub fn height(&self) -> Option<u64> {
        match self {
            MsgContent::Image { info, .. } => {
                info.as_ref().and_then(|x| x.height.map(|x| x.into()))
            }
            MsgContent::Video { info, .. } => {
                info.as_ref().and_then(|x| x.height.map(|x| x.into()))
            }
            _ => None,
        }
    }

    pub fn thumbnail_source(&self) -> Option<MediaSource> {
        match self {
            MsgContent::Image { info, .. } => info.as_ref().and_then(|x| {
                x.thumbnail_source
                    .as_ref()
                    .map(|y| MediaSource { inner: y.clone() })
            }),
            MsgContent::Video { info, .. } => info.as_ref().and_then(|x| {
                x.thumbnail_source
                    .as_ref()
                    .map(|y| MediaSource { inner: y.clone() })
            }),
            MsgContent::File { info, .. } => info.as_ref().and_then(|x| {
                x.thumbnail_source
                    .as_ref()
                    .map(|y| MediaSource { inner: y.clone() })
            }),
            MsgContent::Location { info, .. } => info.as_ref().and_then(|x| {
                x.thumbnail_source
                    .as_ref()
                    .map(|y| MediaSource { inner: y.clone() })
            }),
            _ => None,
        }
    }

    pub fn thumbnail_info(&self) -> Option<ThumbnailInfo> {
        match self {
            MsgContent::Image { info, .. } => info.as_ref().and_then(|x| {
                x.thumbnail_info
                    .as_ref()
                    .map(|y| ThumbnailInfo { inner: *y.clone() })
            }),
            MsgContent::Video { info, .. } => info.as_ref().and_then(|x| {
                x.thumbnail_info
                    .as_ref()
                    .map(|y| ThumbnailInfo { inner: *y.clone() })
            }),
            MsgContent::File { info, .. } => info.as_ref().and_then(|x| {
                x.thumbnail_info
                    .as_ref()
                    .map(|y| ThumbnailInfo { inner: *y.clone() })
            }),
            MsgContent::Location { info, .. } => info.as_ref().and_then(|x| {
                x.thumbnail_info
                    .as_ref()
                    .map(|y| ThumbnailInfo { inner: *y.clone() })
            }),
            _ => None,
        }
    }

    pub fn duration(&self) -> Option<u64> {
        match self {
            MsgContent::Audio { info, .. } => {
                info.as_ref().and_then(|x| x.duration.map(|y| y.as_secs()))
            }
            MsgContent::Video { info, .. } => {
                info.as_ref().and_then(|x| x.duration.map(|y| y.as_secs()))
            }
            _ => None,
        }
    }

    pub fn blurhash(&self) -> Option<String> {
        match self {
            MsgContent::Image { info, .. } => info.as_ref().and_then(|x| x.blurhash.clone()),
            MsgContent::Video { info, .. } => info.as_ref().and_then(|x| x.blurhash.clone()),
            _ => None,
        }
    }

    pub fn filename(&self) -> Option<String> {
        match self {
            MsgContent::File { filename, .. } => filename.clone(),
            _ => None,
        }
    }

    pub fn geo_uri(&self) -> Option<String> {
        match self {
            MsgContent::Location { geo_uri, .. } => Some(geo_uri.clone()),
            _ => None,
        }
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct ReactionRecord {
    sender_id: OwnedUserId,
    timestamp: MilliSecondsSinceUnixEpoch,
    sent_by_me: bool,
}

impl ReactionRecord {
    pub(crate) fn new(
        sender_id: OwnedUserId,
        timestamp: MilliSecondsSinceUnixEpoch,
        sent_by_me: bool,
    ) -> Self {
        ReactionRecord {
            sender_id,
            timestamp,
            sent_by_me,
        }
    }

    pub fn sender_id(&self) -> OwnedUserId {
        self.sender_id.clone()
    }

    pub fn sent_by_me(&self) -> bool {
        self.sent_by_me
    }

    pub fn timestamp(&self) -> u64 {
        self.timestamp.get().into()
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct DeviceRecord {
    device_id: OwnedDeviceId,
    display_name: Option<String>,
    last_seen_ts: Option<MilliSecondsSinceUnixEpoch>,
    last_seen_ip: Option<String>,
    is_verified: bool,
    is_active: bool,
    is_me: bool,
}

impl DeviceRecord {
    pub(crate) fn new(
        device_id: OwnedDeviceId,
        display_name: Option<String>,
        last_seen_ts: Option<MilliSecondsSinceUnixEpoch>,
        last_seen_ip: Option<String>,
        is_verified: bool,
        is_active: bool,
        is_me: bool,
    ) -> Self {
        DeviceRecord {
            device_id,
            display_name,
            last_seen_ts,
            last_seen_ip,
            is_verified,
            is_active,
            is_me,
        }
    }

    pub fn device_id(&self) -> OwnedDeviceId {
        self.device_id.clone()
    }

    pub fn display_name(&self) -> Option<String> {
        self.display_name.clone()
    }

    pub fn last_seen_ts(&self) -> Option<u64> {
        self.last_seen_ts.map(|x| x.get().into())
    }

    pub fn last_seen_ip(&self) -> Option<String> {
        self.last_seen_ip.clone()
    }

    pub fn is_verified(&self) -> bool {
        self.is_verified
    }

    pub fn is_me(&self) -> bool {
        self.is_me
    }

    pub fn is_active(&self) -> bool {
        self.is_active
    }
}

#[derive(Clone, Debug)]
pub struct ThumbnailSize {
    width: UInt,
    height: UInt,
}

impl ThumbnailSize {
    pub(crate) fn new(width: u64, height: u64) -> Result<Self> {
        let width = UInt::new(width).context("invalid thumbnail width")?;
        let height = UInt::new(height).context("invalid thumbnail height")?;
        Ok(ThumbnailSize { width, height })
    }

    pub(crate) fn width(&self) -> UInt {
        self.width
    }

    pub(crate) fn height(&self) -> UInt {
        self.height
    }

    pub fn parse_into_media_format(thumb_size: Option<Box<ThumbnailSize>>) -> MediaFormat {
        match thumb_size {
            Some(thumb_size) => MediaFormat::from(thumb_size),
            None => MediaFormat::File,
        }
    }
}

impl From<Box<ThumbnailSize>> for MediaFormat {
    fn from(val: Box<ThumbnailSize>) -> Self {
        MediaFormat::Thumbnail(MediaThumbnailSize {
            method: get_content_thumbnail::v3::Method::Scale,
            width: val.width,
            height: val.height,
        })
    }
}

pub fn new_thumb_size(width: u64, height: u64) -> Result<ThumbnailSize> {
    ThumbnailSize::new(width, height)
}

pub fn new_colorize_builder(
    color: Option<u32>,
    background: Option<u32>,
) -> Result<ColorizeBuilder> {
    let mut builder = ColorizeBuilder::default();
    if let Some(color) = color {
        builder.color(color);
    }
    if let Some(background) = background {
        builder.background(background);
    }
    Ok(builder)
}

pub fn new_task_ref_builder(
    target_id: String,
    room_id: Option<String>,
    task_list: String,
    action: Option<String>,
) -> Result<RefDetailsBuilder> {
    let target_id = EventId::parse(target_id)?;
    let task_list = EventId::parse(task_list)?;
    let mut builder = RefDetailsBuilder::new_task_ref_builder(target_id, task_list);
    if let Some(room_id) = room_id {
        builder.room_id(room_id);
    }
    if let Some(action) = action {
        builder.action(action);
    }
    Ok(builder)
}

pub fn new_task_list_ref_builder(
    target_id: String,
    room_id: Option<String>,
    action: Option<String>,
) -> Result<RefDetailsBuilder> {
    let target_id = EventId::parse(target_id)?;
    let mut builder = RefDetailsBuilder::new_task_list_ref_builder(target_id);
    if let Some(room_id) = room_id {
        builder.room_id(room_id);
    }
    if let Some(action) = action {
        builder.action(action);
    }
    Ok(builder)
}

pub fn new_calendar_event_ref_builder(
    target_id: String,
    room_id: Option<String>,
    action: Option<String>,
) -> Result<RefDetailsBuilder> {
    let target_id = EventId::parse(target_id)?;
    let mut builder = RefDetailsBuilder::new_calendar_event_ref_builder(target_id);
    if let Some(room_id) = room_id {
        builder.room_id(room_id);
    }
    if let Some(action) = action {
        builder.action(action);
    }
    Ok(builder)
}

pub fn new_link_ref_builder(title: String, uri: String) -> Result<RefDetailsBuilder> {
    let builder = RefDetailsBuilder::new_link_ref_builder(title, uri);
    Ok(builder)
}

#[allow(clippy::boxed_local)]
pub fn new_obj_ref_builder(
    position: Option<String>,
    reference: Box<RefDetails>,
) -> Result<ObjRefBuilder> {
    if let Some(p) = position {
        let p = Position::from_str(&p)?;
        Ok(ObjRefBuilder::new(Some(p), *reference))
    } else {
        Ok(ObjRefBuilder::new(None, *reference))
    }
}
