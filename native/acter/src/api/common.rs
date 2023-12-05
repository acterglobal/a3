use acter_core::{events::attachments::AttachmentContent, models::TextMessageContent};
use core::time::Duration;
use ruma_common::{MilliSecondsSinceUnixEpoch, OwnedDeviceId, OwnedMxcUri, OwnedUserId};
use ruma_events::{
    location::{AssetContent, LocationContent},
    message::TextContentBlock,
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
    data: Option<Vec<u8>>,
}

impl OptionBuffer {
    pub(crate) fn new(data: Option<Vec<u8>>) -> Self {
        OptionBuffer { data }
    }

    pub fn data(&self) -> Option<FfiBuffer<u8>> {
        self.data.clone().map(FfiBuffer::new)
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
pub enum ContentDesc {
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
        asset: Option<AssetContent>,
        location: Option<LocationContent>,
        message: Option<TextContentBlock>,
        ts: Option<MilliSecondsSinceUnixEpoch>,
    },
}

impl From<&TextMessageEventContent> for ContentDesc {
    fn from(value: &TextMessageEventContent) -> Self {
        ContentDesc::Text {
            body: value.body.clone(),
            formatted_body: value.formatted.as_ref().map(|x| x.body.clone()),
        }
    }
}

impl From<&ImageMessageEventContent> for ContentDesc {
    fn from(value: &ImageMessageEventContent) -> Self {
        ContentDesc::Image {
            body: value.body.clone(),
            source: value.source.clone(),
            info: value.info.as_ref().map(|x| *x.clone()),
        }
    }
}

impl From<&AudioMessageEventContent> for ContentDesc {
    fn from(value: &AudioMessageEventContent) -> Self {
        ContentDesc::Audio {
            body: value.body.clone(),
            source: value.source.clone(),
            info: value.info.as_ref().map(|x| *x.clone()),
            audio: value.audio.clone(),
        }
    }
}

impl From<&VideoMessageEventContent> for ContentDesc {
    fn from(value: &VideoMessageEventContent) -> Self {
        ContentDesc::Video {
            body: value.body.clone(),
            source: value.source.clone(),
            info: value.info.as_ref().map(|x| *x.clone()),
        }
    }
}

impl From<&FileMessageEventContent> for ContentDesc {
    fn from(value: &FileMessageEventContent) -> Self {
        ContentDesc::File {
            body: value.body.clone(),
            source: value.source.clone(),
            info: value.info.as_ref().map(|x| *x.clone()),
            filename: value.filename.clone(),
        }
    }
}

impl From<&LocationMessageEventContent> for ContentDesc {
    fn from(value: &LocationMessageEventContent) -> Self {
        ContentDesc::Location {
            body: value.body.clone(),
            geo_uri: value.geo_uri.clone(),
            info: value.info.as_ref().map(|x| *x.clone()),
            asset: value.asset.clone(),
            location: value.location.clone(),
            message: value.message.clone(),
            ts: value.ts,
        }
    }
}

impl From<&EmoteMessageEventContent> for ContentDesc {
    fn from(value: &EmoteMessageEventContent) -> Self {
        ContentDesc::Text {
            body: value.body.clone(),
            formatted_body: value.formatted.as_ref().map(|x| x.body.clone()),
        }
    }
}

impl From<&StickerEventContent> for ContentDesc {
    fn from(value: &StickerEventContent) -> Self {
        ContentDesc::Image {
            body: value.body.clone(),
            source: SdkMediaSource::Plain(value.url.clone()),
            info: Some(value.info.clone()),
        }
    }
}

impl From<&AttachmentContent> for ContentDesc {
    fn from(value: &AttachmentContent) -> Self {
        match value {
            AttachmentContent::Image(content) => ContentDesc::Image {
                body: content.body.clone(),
                source: content.source.clone(),
                info: content.info.as_ref().map(|x| *x.clone()),
            },
            AttachmentContent::Audio(content) => ContentDesc::Audio {
                body: content.body.clone(),
                source: content.source.clone(),
                info: content.info.as_ref().map(|x| *x.clone()),
                audio: content.audio.clone(),
            },
            AttachmentContent::Video(content) => ContentDesc::Video {
                body: content.body.clone(),
                source: content.source.clone(),
                info: content.info.as_ref().map(|x| *x.clone()),
            },
            AttachmentContent::File(content) => ContentDesc::File {
                body: content.body.clone(),
                source: content.source.clone(),
                info: content.info.as_ref().map(|x| *x.clone()),
                filename: content.filename.clone(),
            },
            AttachmentContent::Location(content) => ContentDesc::Location {
                body: content.body.clone(),
                geo_uri: content.geo_uri.clone(),
                info: content.info.as_ref().map(|x| *x.clone()),
                asset: content.asset.clone(),
                location: content.location.clone(),
                message: content.message.clone(),
                ts: content.ts,
            },
        }
    }
}

impl ContentDesc {
    pub(crate) fn from_text(body: String) -> Self {
        ContentDesc::Text {
            body,
            formatted_body: None,
        }
    }

    pub(crate) fn from_image(body: String, source: OwnedMxcUri) -> Self {
        ContentDesc::Image {
            body,
            source: SdkMediaSource::Plain(source),
            info: Some(ImageInfo::new()),
        }
    }

    pub fn body(&self) -> String {
        match self {
            ContentDesc::Text { body, .. } => body.clone(),
            ContentDesc::Image { body, .. } => body.clone(),
            ContentDesc::Audio { body, .. } => body.clone(),
            ContentDesc::Video { body, .. } => body.clone(),
            ContentDesc::File { body, .. } => body.clone(),
            ContentDesc::Location { body, .. } => body.clone(),
        }
    }

    pub fn formatted_body(&self) -> Option<String> {
        match self {
            ContentDesc::Text { formatted_body, .. } => formatted_body.clone(),
            _ => None,
        }
    }

    pub fn source(&self) -> Option<MediaSource> {
        match self {
            ContentDesc::Image { source, .. } => Some(MediaSource {
                inner: source.clone(),
            }),
            ContentDesc::Audio { source, .. } => Some(MediaSource {
                inner: source.clone(),
            }),
            ContentDesc::Video { source, .. } => Some(MediaSource {
                inner: source.clone(),
            }),
            ContentDesc::File { source, .. } => Some(MediaSource {
                inner: source.clone(),
            }),
            _ => None,
        }
    }

    pub fn mimetype(&self) -> Option<String> {
        match self {
            ContentDesc::Image { info, .. } => info.as_ref().and_then(|x| x.mimetype.clone()),
            ContentDesc::Audio { info, .. } => info.as_ref().and_then(|x| x.mimetype.clone()),
            ContentDesc::Video { info, .. } => info.as_ref().and_then(|x| x.mimetype.clone()),
            ContentDesc::File { info, .. } => info.as_ref().and_then(|x| x.mimetype.clone()),
            _ => None,
        }
    }

    pub fn size(&self) -> Option<u64> {
        match self {
            ContentDesc::Image { info, .. } => info.as_ref().and_then(|x| x.size.map(|x| x.into())),
            ContentDesc::Audio { info, .. } => info.as_ref().and_then(|x| x.size.map(|x| x.into())),
            ContentDesc::Video { info, .. } => info.as_ref().and_then(|x| x.size.map(|x| x.into())),
            ContentDesc::File { info, .. } => info.as_ref().and_then(|x| x.size.map(|x| x.into())),
            _ => None,
        }
    }

    pub fn width(&self) -> Option<u64> {
        match self {
            ContentDesc::Image { info, .. } => {
                info.as_ref().and_then(|x| x.width.map(|x| x.into()))
            }
            ContentDesc::Video { info, .. } => {
                info.as_ref().and_then(|x| x.width.map(|x| x.into()))
            }
            _ => None,
        }
    }

    pub fn height(&self) -> Option<u64> {
        match self {
            ContentDesc::Image { info, .. } => {
                info.as_ref().and_then(|x| x.height.map(|x| x.into()))
            }
            ContentDesc::Video { info, .. } => {
                info.as_ref().and_then(|x| x.height.map(|x| x.into()))
            }
            _ => None,
        }
    }

    pub fn thumbnail_source(&self) -> Option<MediaSource> {
        match self {
            ContentDesc::Image { info, .. } => info.as_ref().and_then(|x| {
                x.thumbnail_source
                    .as_ref()
                    .map(|y| MediaSource { inner: y.clone() })
            }),
            ContentDesc::Video { info, .. } => info.as_ref().and_then(|x| {
                x.thumbnail_source
                    .as_ref()
                    .map(|y| MediaSource { inner: y.clone() })
            }),
            ContentDesc::File { info, .. } => info.as_ref().and_then(|x| {
                x.thumbnail_source
                    .as_ref()
                    .map(|y| MediaSource { inner: y.clone() })
            }),
            ContentDesc::Location { info, .. } => info.as_ref().and_then(|x| {
                x.thumbnail_source
                    .as_ref()
                    .map(|y| MediaSource { inner: y.clone() })
            }),
            _ => None,
        }
    }

    pub fn thumbnail_info(&self) -> Option<ThumbnailInfo> {
        match self {
            ContentDesc::Image { info, .. } => info.as_ref().and_then(|x| {
                x.thumbnail_info
                    .as_ref()
                    .map(|y| ThumbnailInfo { inner: *y.clone() })
            }),
            ContentDesc::Video { info, .. } => info.as_ref().and_then(|x| {
                x.thumbnail_info
                    .as_ref()
                    .map(|y| ThumbnailInfo { inner: *y.clone() })
            }),
            ContentDesc::File { info, .. } => info.as_ref().and_then(|x| {
                x.thumbnail_info
                    .as_ref()
                    .map(|y| ThumbnailInfo { inner: *y.clone() })
            }),
            ContentDesc::Location { info, .. } => info.as_ref().and_then(|x| {
                x.thumbnail_info
                    .as_ref()
                    .map(|y| ThumbnailInfo { inner: *y.clone() })
            }),
            _ => None,
        }
    }

    pub fn duration(&self) -> Option<u64> {
        match self {
            ContentDesc::Audio { info, .. } => {
                info.as_ref().and_then(|x| x.duration.map(|y| y.as_secs()))
            }
            ContentDesc::Video { info, .. } => {
                info.as_ref().and_then(|x| x.duration.map(|y| y.as_secs()))
            }
            _ => None,
        }
    }

    pub fn blurhash(&self) -> Option<String> {
        match self {
            ContentDesc::Image { info, .. } => info.as_ref().and_then(|x| x.blurhash.clone()),
            ContentDesc::Video { info, .. } => info.as_ref().and_then(|x| x.blurhash.clone()),
            _ => None,
        }
    }

    pub fn filename(&self) -> Option<String> {
        match self {
            ContentDesc::File { filename, .. } => filename.clone(),
            _ => None,
        }
    }

    pub fn geo_uri(&self) -> Option<String> {
        match self {
            ContentDesc::Location { geo_uri, .. } => Some(geo_uri.clone()),
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
