use acter_core::models::TextMessageContent;
use core::time::Duration;
use ruma_common::{MilliSecondsSinceUnixEpoch, OwnedDeviceId, OwnedUserId};
use ruma_events::room::{
    message::{AudioInfo, FileInfo, TextMessageEventContent, VideoInfo},
    ImageInfo, MediaSource as SdkMediaSource, ThumbnailInfo as SdkThumbnailInfo,
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
pub struct TextDesc {
    body: String,
    formatted_body: Option<String>,
}

impl TextDesc {
    pub fn new(body: String, formatted_body: Option<String>) -> Self {
        TextDesc {
            body,
            formatted_body,
        }
    }

    pub fn body(&self) -> String {
        self.body.clone()
    }

    pub(crate) fn set_body(&mut self, text: String) {
        self.body = text;
    }

    pub fn formatted_body(&self) -> Option<String> {
        self.formatted_body.clone()
    }

    pub(crate) fn set_formatted_body(&mut self, text: Option<String>) {
        self.formatted_body = text;
    }
    pub fn has_formatted(&self) -> bool {
        self.formatted_body.is_some()
    }
}

impl From<&TextMessageEventContent> for TextDesc {
    fn from(value: &TextMessageEventContent) -> Self {
        Self {
            body: value.body.clone(),
            formatted_body: value.formatted.as_ref().map(|x| x.body.clone()),
        }
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct ImageDesc {
    name: String,
    source: SdkMediaSource,
    info: ImageInfo,
}

impl ImageDesc {
    pub fn new(name: String, source: SdkMediaSource, info: ImageInfo) -> Self {
        ImageDesc { name, source, info }
    }

    pub fn name(&self) -> String {
        self.name.clone()
    }

    pub fn source(&self) -> MediaSource {
        MediaSource {
            inner: self.source.clone(),
        }
    }

    pub fn mimetype(&self) -> Option<String> {
        self.info.mimetype.clone()
    }

    pub fn size(&self) -> Option<u64> {
        self.info.size.map(|x| x.into())
    }

    pub fn width(&self) -> Option<u64> {
        self.info.width.map(|x| x.into())
    }

    pub fn height(&self) -> Option<u64> {
        self.info.height.map(|x| x.into())
    }

    pub fn thumbnail_info(&self) -> Option<ThumbnailInfo> {
        self.info
            .thumbnail_info
            .clone()
            .map(|x| ThumbnailInfo { inner: *x })
    }

    pub fn thumbnail_source(&self) -> Option<MediaSource> {
        self.info
            .thumbnail_source
            .clone()
            .map(|inner| MediaSource { inner })
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct AudioDesc {
    name: String,
    source: SdkMediaSource,
    info: AudioInfo,
}

impl AudioDesc {
    pub fn new(name: String, source: SdkMediaSource, info: AudioInfo) -> Self {
        AudioDesc { name, source, info }
    }

    pub fn name(&self) -> String {
        self.name.clone()
    }

    pub fn source(&self) -> MediaSource {
        MediaSource {
            inner: self.source.clone(),
        }
    }

    pub fn duration(&self) -> Option<u64> {
        self.info.duration.map(|x| x.as_secs())
    }

    pub fn mimetype(&self) -> Option<String> {
        self.info.mimetype.clone()
    }

    pub fn size(&self) -> Option<u64> {
        self.info.size.map(|x| x.into())
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct VideoDesc {
    name: String,
    source: SdkMediaSource,
    info: VideoInfo,
}

impl VideoDesc {
    pub fn new(name: String, source: SdkMediaSource, info: VideoInfo) -> Self {
        VideoDesc { name, source, info }
    }

    pub fn name(&self) -> String {
        self.name.clone()
    }

    pub fn source(&self) -> MediaSource {
        MediaSource {
            inner: self.source.clone(),
        }
    }

    pub fn blurhash(&self) -> Option<String> {
        self.info.blurhash.clone()
    }

    pub fn duration(&self) -> Option<u64> {
        self.info.duration.map(|x| x.as_secs())
    }

    pub fn mimetype(&self) -> Option<String> {
        self.info.mimetype.clone()
    }

    pub fn size(&self) -> Option<u64> {
        self.info.size.map(|x| x.into())
    }

    pub fn width(&self) -> Option<u64> {
        self.info.width.map(|x| x.into())
    }

    pub fn height(&self) -> Option<u64> {
        self.info.height.map(|x| x.into())
    }

    pub fn thumbnail_info(&self) -> Option<ThumbnailInfo> {
        self.info
            .thumbnail_info
            .clone()
            .map(|x| ThumbnailInfo { inner: *x })
    }

    pub fn thumbnail_source(&self) -> Option<MediaSource> {
        self.info
            .thumbnail_source
            .clone()
            .map(|inner| MediaSource { inner })
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct FileDesc {
    name: String,
    source: SdkMediaSource,
    info: FileInfo,
}

impl FileDesc {
    pub fn new(name: String, source: SdkMediaSource, info: FileInfo) -> Self {
        FileDesc { name, source, info }
    }

    pub fn name(&self) -> String {
        self.name.clone()
    }

    pub fn source(&self) -> MediaSource {
        MediaSource {
            inner: self.source.clone(),
        }
    }

    pub fn mimetype(&self) -> Option<String> {
        self.info.mimetype.clone()
    }

    pub fn size(&self) -> Option<u64> {
        self.info.size.map(|x| x.into())
    }

    pub fn thumbnail_info(&self) -> Option<ThumbnailInfo> {
        self.info
            .thumbnail_info
            .clone()
            .map(|x| ThumbnailInfo { inner: *x })
    }

    pub fn thumbnail_source(&self) -> Option<MediaSource> {
        self.info
            .thumbnail_source
            .clone()
            .map(|inner| MediaSource { inner })
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct LocationDesc {
    body: String,
    geo_uri: String,
    thumbnail_source: Option<SdkMediaSource>,
    thumbnail_info: Option<SdkThumbnailInfo>,
}

impl LocationDesc {
    pub fn new(body: String, geo_uri: String) -> Self {
        LocationDesc {
            body,
            geo_uri,
            thumbnail_source: None,
            thumbnail_info: None,
        }
    }

    pub fn body(&self) -> String {
        self.body.clone()
    }

    pub fn geo_uri(&self) -> String {
        self.geo_uri.clone()
    }

    pub(crate) fn set_thumbnail_source(&mut self, value: SdkMediaSource) {
        self.thumbnail_source = Some(value);
    }

    pub fn thumbnail_source(&self) -> Option<MediaSource> {
        self.thumbnail_source
            .clone()
            .map(|inner| MediaSource { inner })
    }

    pub(crate) fn set_thumbnail_info(&mut self, value: SdkThumbnailInfo) {
        self.thumbnail_info = Some(value);
    }

    pub fn thumbnail_info(&self) -> Option<ThumbnailInfo> {
        self.thumbnail_info
            .clone()
            .map(|inner| ThumbnailInfo { inner })
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
}

impl DeviceRecord {
    pub(crate) fn new(
        device_id: OwnedDeviceId,
        display_name: Option<String>,
        last_seen_ts: Option<MilliSecondsSinceUnixEpoch>,
        last_seen_ip: Option<String>,
        is_verified: bool,
        is_active: bool,
    ) -> Self {
        DeviceRecord {
            device_id,
            display_name,
            last_seen_ts,
            last_seen_ip,
            is_verified,
            is_active,
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

    pub fn is_active(&self) -> bool {
        self.is_active
    }
}
