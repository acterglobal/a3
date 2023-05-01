use core::time::Duration;
use matrix_sdk::ruma::{
    events::room::{
        message::{AudioInfo, FileInfo, VideoInfo},
        ImageInfo, MediaSource as MatrixMediaSource, ThumbnailInfo as MatrixThumbnailInfo,
    },
    OwnedUserId,
};

pub fn duration_from_secs(secs: u64) -> Duration {
    Duration::from_secs(secs)
}

pub struct MediaSource {
    inner: MatrixMediaSource,
}

impl MediaSource {
    pub fn url(&self) -> String {
        match self.inner.clone() {
            MatrixMediaSource::Plain(url) => url.to_string(),
            MatrixMediaSource::Encrypted(file) => file.url.to_string(),
        }
    }
}

#[derive(Clone)]
pub struct ThumbnailInfo {
    inner: MatrixThumbnailInfo,
}

impl ThumbnailInfo {
    pub fn mimetype(&self) -> Option<String> {
        self.inner.mimetype.clone()
    }

    pub fn size(&self) -> Option<u64> {
        self.inner.size.map(u64::from)
    }

    pub fn width(&self) -> Option<u64> {
        self.inner.width.map(u64::from)
    }

    pub fn height(&self) -> Option<u64> {
        self.inner.height.map(u64::from)
    }
}

#[derive(Clone, Debug)]
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
}

#[derive(Clone, Debug)]
pub struct ImageDesc {
    name: String,
    source: Option<MatrixMediaSource>,
    info: ImageInfo,
}

impl ImageDesc {
    pub fn new(name: String, source: Option<MatrixMediaSource>, info: ImageInfo) -> Self {
        ImageDesc { name, source, info }
    }

    pub fn name(&self) -> String {
        self.name.clone()
    }

    pub fn source(&self) -> Option<MediaSource> {
        self.source.clone().map(|inner| MediaSource { inner })
    }

    pub fn mimetype(&self) -> Option<String> {
        self.info.mimetype.clone()
    }

    pub fn size(&self) -> Option<u64> {
        self.info.size.map(u64::from)
    }

    pub fn width(&self) -> Option<u64> {
        self.info.width.map(u64::from)
    }

    pub fn height(&self) -> Option<u64> {
        self.info.height.map(u64::from)
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

#[derive(Clone, Debug)]
pub struct AudioDesc {
    name: String,
    source: MatrixMediaSource,
    info: AudioInfo,
}

impl AudioDesc {
    pub fn new(name: String, source: MatrixMediaSource, info: AudioInfo) -> Self {
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

    pub fn mimetype(&self) -> Option<String> {
        self.info.mimetype.clone()
    }

    pub fn size(&self) -> Option<u64> {
        self.info.size.map(u64::from)
    }

    pub fn duration(&self) -> Option<u64> {
        self.info.duration.map(|x| x.as_secs())
    }
}

#[derive(Clone, Debug)]
pub struct VideoDesc {
    name: String,
    source: MatrixMediaSource,
    info: VideoInfo,
}

impl VideoDesc {
    pub fn new(name: String, source: MatrixMediaSource, info: VideoInfo) -> Self {
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
        self.info.size.map(u64::from)
    }

    pub fn width(&self) -> Option<u64> {
        self.info.width.map(u64::from)
    }

    pub fn height(&self) -> Option<u64> {
        self.info.height.map(u64::from)
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

#[derive(Clone, Debug)]
pub struct FileDesc {
    name: String,
    source: MatrixMediaSource,
    info: FileInfo,
}

impl FileDesc {
    pub fn new(name: String, source: MatrixMediaSource, info: FileInfo) -> Self {
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
        self.info.size.map(u64::from)
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

#[derive(Clone, Debug)]
pub struct ReactionDesc {
    count: u64,
    senders: Vec<OwnedUserId>,
}

impl ReactionDesc {
    pub(crate) fn new(count: u64, senders: Vec<OwnedUserId>) -> Self {
        ReactionDesc { count, senders }
    }

    pub fn count(&self) -> u64 {
        self.count
    }

    pub fn senders(&self) -> Vec<String> {
        self.senders.iter().map(|x| x.to_string()).collect()
    }
}
