use acter_matrix::models::TextMessageContent;
use anyhow::{bail, Result};
use core::time::Duration;
use matrix_sdk::room::Room;
use matrix_sdk_base::ruma::{
    assign,
    events::{
        room::{
            message::{
                AudioInfo, AudioMessageEventContent, FileInfo, FileMessageEventContent,
                ImageMessageEventContent, LocationInfo, LocationMessageEventContent, MessageType,
                RoomMessageEventContentWithoutRelation, TextMessageEventContent,
                UrlPreview as RumaUrlPreview, VideoInfo, VideoMessageEventContent,
            },
            ImageInfo, MediaSource, ThumbnailInfo,
        },
        Mentions,
    },
    OwnedMxcUri, UInt, UserId,
};
use std::path::PathBuf;
use tracing::{info, warn};

#[derive(Clone, Debug)]
pub(crate) enum MsgContentDraft {
    TextPlain {
        body: String,
        url_previews: Vec<RumaUrlPreview>,
    },
    TextMarkdown {
        body: String,
        url_previews: Vec<RumaUrlPreview>,
    },
    TextHtml {
        html: String,
        plain: String,
        url_previews: Vec<RumaUrlPreview>,
    },
    Image {
        source: String,
        thumbnail_source: Option<String>,
        info: Option<ImageInfo>,
        filename: Option<String>,
    },
    Audio {
        source: String,
        info: Option<AudioInfo>,
        filename: Option<String>,
    },
    Video {
        source: String,
        thumbnail_source: Option<String>,
        info: Option<VideoInfo>,
        filename: Option<String>,
    },
    File {
        source: String,
        thumbnail_source: Option<String>,
        info: Option<FileInfo>,
        filename: Option<String>,
    },
    Location {
        body: String,
        geo_uri: String,
        thumbnail_source: Option<String>,
        info: Option<LocationInfo>,
    },
}

impl MsgContentDraft {
    fn mimetype(mut self, value: String) -> Self {
        match self {
            MsgContentDraft::Image { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    o.mimetype = Some(value);
                } else {
                    *info = Some(assign!(ImageInfo::new(), { mimetype: Some(value) }));
                }
            }
            MsgContentDraft::Audio { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    o.mimetype = Some(value);
                } else {
                    *info = Some(assign!(AudioInfo::new(), { mimetype: Some(value) }));
                }
            }
            MsgContentDraft::Video { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    o.mimetype = Some(value);
                } else {
                    *info = Some(assign!(VideoInfo::new(), { mimetype: Some(value) }));
                }
            }
            MsgContentDraft::File { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    o.mimetype = Some(value);
                } else {
                    *info = Some(assign!(FileInfo::new(), { mimetype: Some(value) }));
                }
            }
            _ => {
                warn!("mimetype is available for only image/audio/video/file");
            }
        }
        self
    }

    fn add_ref_details(&mut self, ref_details: crate::RefDetails) -> Result<()> {
        match self {
            MsgContentDraft::TextHtml { url_previews, .. }
            | MsgContentDraft::TextMarkdown { url_previews, .. }
            | MsgContentDraft::TextPlain { url_previews, .. } => {
                url_previews.push(ref_details.try_into()?);
            }
            _ => bail!("Url Preview not supported"),
        };
        Ok(())
    }

    fn add_url_preview(&mut self, preview: RumaUrlPreview) -> Result<()> {
        match self {
            MsgContentDraft::TextHtml { url_previews, .. }
            | MsgContentDraft::TextMarkdown { url_previews, .. }
            | MsgContentDraft::TextPlain { url_previews, .. } => {
                url_previews.push(preview);
            }
            _ => bail!("Url Preview not supported"),
        };
        Ok(())
    }

    fn size(mut self, value: u64) -> Self {
        match self {
            MsgContentDraft::Image { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    o.size = UInt::new(value);
                } else {
                    *info = Some(assign!(ImageInfo::new(), { size: UInt::new(value) }));
                }
            }
            MsgContentDraft::Audio { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    o.size = UInt::new(value);
                } else {
                    *info = Some(assign!(AudioInfo::new(), { size: UInt::new(value) }));
                }
            }
            MsgContentDraft::Video { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    o.size = UInt::new(value);
                } else {
                    *info = Some(assign!(VideoInfo::new(), { size: UInt::new(value) }));
                }
            }
            MsgContentDraft::File { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    o.size = UInt::new(value);
                } else {
                    *info = Some(assign!(FileInfo::new(), { size: UInt::new(value) }));
                }
            }
            _ => {
                warn!("size is available for only image/audio/video/file");
            }
        }
        self
    }

    fn width(mut self, value: u64) -> Self {
        match self {
            MsgContentDraft::Image { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    o.width = UInt::new(value);
                } else {
                    *info = Some(assign!(ImageInfo::new(), { width: UInt::new(value) }));
                }
            }
            MsgContentDraft::Video { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    o.width = UInt::new(value);
                } else {
                    *info = Some(assign!(VideoInfo::new(), { width: UInt::new(value) }));
                }
            }
            _ => warn!("width is available for only image/video"),
        }
        self
    }

    fn height(mut self, value: u64) -> Self {
        match self {
            MsgContentDraft::Image { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    o.height = UInt::new(value);
                } else {
                    *info = Some(assign!(ImageInfo::new(), { height: UInt::new(value) }));
                }
            }
            MsgContentDraft::Video { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    o.height = UInt::new(value);
                } else {
                    *info = Some(assign!(VideoInfo::new(), { height: UInt::new(value) }));
                }
            }
            _ => warn!("height is available for only image/video"),
        }
        self
    }

    fn thumbnail_image(mut self, source: String, mimetype: String) -> Self {
        match self {
            MsgContentDraft::Image {
                ref mut thumbnail_source,
                ref mut info,
                ..
            } => {
                *thumbnail_source = Some(source);
                if let Some(o) = info.as_mut() {
                    if let Some(a) = o.thumbnail_info.as_mut() {
                        a.mimetype = Some(mimetype);
                    } else {
                        o.thumbnail_info = Some(Box::new(assign!(
                            ThumbnailInfo::new(),
                            { mimetype: Some(mimetype) }
                        )));
                    }
                } else {
                    *info = Some(assign!(ImageInfo::new(), {
                        thumbnail_info: Some(Box::new(assign!(
                            ThumbnailInfo::new(),
                            { mimetype: Some(mimetype) }
                        )))
                    }));
                }
            }
            MsgContentDraft::Video {
                ref mut thumbnail_source,
                ref mut info,
                ..
            } => {
                *thumbnail_source = Some(source);
                if let Some(o) = info.as_mut() {
                    if let Some(a) = o.thumbnail_info.as_mut() {
                        a.mimetype = Some(mimetype);
                    } else {
                        o.thumbnail_info = Some(Box::new(assign!(
                            ThumbnailInfo::new(),
                            { mimetype: Some(mimetype) }
                        )));
                    }
                } else {
                    *info = Some(assign!(VideoInfo::new(), {
                        thumbnail_info: Some(Box::new(assign!(
                            ThumbnailInfo::new(),
                            { mimetype: Some(mimetype) }
                        )))
                    }));
                }
            }
            MsgContentDraft::File {
                ref mut thumbnail_source,
                ref mut info,
                ..
            } => {
                *thumbnail_source = Some(source);
                if let Some(o) = info.as_mut() {
                    if let Some(a) = o.thumbnail_info.as_mut() {
                        a.mimetype = Some(mimetype);
                    } else {
                        o.thumbnail_info = Some(Box::new(assign!(
                            ThumbnailInfo::new(),
                            { mimetype: Some(mimetype) }
                        )));
                    }
                } else {
                    *info = Some(assign!(FileInfo::new(), {
                        thumbnail_info: Some(Box::new(assign!(
                            ThumbnailInfo::new(),
                            { mimetype: Some(mimetype) }
                        )))
                    }));
                }
            }
            MsgContentDraft::Location {
                ref mut thumbnail_source,
                ref mut info,
                ..
            } => {
                *thumbnail_source = Some(source);
                if let Some(o) = info.as_mut() {
                    if let Some(a) = o.thumbnail_info.as_mut() {
                        a.mimetype = Some(mimetype);
                    } else {
                        o.thumbnail_info = Some(Box::new(assign!(
                            ThumbnailInfo::new(),
                            { mimetype: Some(mimetype) }
                        )));
                    }
                } else {
                    *info = Some(assign!(LocationInfo::new(), {
                        thumbnail_info: Some(Box::new(assign!(
                            ThumbnailInfo::new(),
                            { mimetype: Some(mimetype) }
                        )))
                    }));
                }
            }
            _ => warn!("thumbnail_source is available for only image/video/file/location"),
        }
        self
    }

    fn thumbnail_info(mut self, value: ThumbnailInfo) -> Self {
        match self {
            MsgContentDraft::Image { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    // will keep mimetype if exists
                    if let Some(i) = o.thumbnail_info.as_mut() {
                        i.size = value.size;
                        i.width = value.width;
                        i.height = value.height;
                    } else {
                        o.thumbnail_info = Some(Box::new(value));
                    }
                } else {
                    *info =
                        Some(assign!(ImageInfo::new(), { thumbnail_info: Some(Box::new(value)) }));
                }
            }
            MsgContentDraft::Video { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    // will keep mimetype if exists
                    if let Some(i) = o.thumbnail_info.as_mut() {
                        i.size = value.size;
                        i.width = value.width;
                        i.height = value.height;
                    } else {
                        o.thumbnail_info = Some(Box::new(value));
                    }
                } else {
                    *info =
                        Some(assign!(VideoInfo::new(), { thumbnail_info: Some(Box::new(value)) }));
                }
            }
            MsgContentDraft::File { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    // will keep mimetype if exists
                    if let Some(i) = o.thumbnail_info.as_mut() {
                        i.size = value.size;
                        i.width = value.width;
                        i.height = value.height;
                    } else {
                        o.thumbnail_info = Some(Box::new(value));
                    }
                } else {
                    *info =
                        Some(assign!(FileInfo::new(), { thumbnail_info: Some(Box::new(value)) }));
                }
            }
            MsgContentDraft::Location { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    // will keep mimetype if exists
                    if let Some(i) = o.thumbnail_info.as_mut() {
                        i.size = value.size;
                        i.width = value.width;
                        i.height = value.height;
                    } else {
                        o.thumbnail_info = Some(Box::new(value));
                    }
                } else {
                    *info = Some(
                        assign!(LocationInfo::new(), { thumbnail_info: Some(Box::new(value)) }),
                    );
                }
            }
            _ => warn!("thumbnail_info is available for only image/video/file/location"),
        }
        self
    }

    fn duration(mut self, value: u64) -> Self {
        match self {
            MsgContentDraft::Audio { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    o.duration = Some(Duration::from_secs(value));
                } else {
                    *info = Some(
                        assign!(AudioInfo::new(), { duration: Some(Duration::from_secs(value)) }),
                    );
                }
            }
            MsgContentDraft::Video { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    o.duration = Some(Duration::from_secs(value));
                } else {
                    *info = Some(
                        assign!(VideoInfo::new(), { duration: Some(Duration::from_secs(value)) }),
                    );
                }
            }
            _ => warn!("duration is available for only audio/video"),
        }
        self
    }

    fn blurhash(mut self, value: String) -> Self {
        match self {
            MsgContentDraft::Image { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    o.blurhash = Some(value);
                } else {
                    *info = Some(assign!(ImageInfo::new(), { blurhash: Some(value) }));
                }
            }
            MsgContentDraft::Video { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    o.blurhash = Some(value);
                } else {
                    *info = Some(assign!(VideoInfo::new(), { blurhash: Some(value) }));
                }
            }
            _ => warn!("blurhash is available for only image/video"),
        }
        self
    }

    fn filename(mut self, value: String) -> Self {
        match self {
            MsgContentDraft::Image {
                source,
                thumbnail_source,
                info,
                ..
            } => {
                return MsgContentDraft::Image {
                    source,
                    thumbnail_source,
                    filename: Some(value),
                    info,
                };
            }
            MsgContentDraft::Video {
                source,
                thumbnail_source,
                info,
                ..
            } => {
                return MsgContentDraft::Video {
                    source,
                    thumbnail_source,
                    filename: Some(value),
                    info,
                };
            }
            MsgContentDraft::Audio { source, info, .. } => {
                return MsgContentDraft::Audio {
                    source,
                    filename: Some(value),
                    info,
                };
            }
            MsgContentDraft::File {
                source,
                thumbnail_source,
                info,
                ..
            } => {
                return MsgContentDraft::File {
                    source,
                    thumbnail_source,
                    filename: Some(value),
                    info,
                };
            }
            _ => warn!("filename is available for only file"),
        }
        self
    }

    fn geo_uri(mut self, value: String) -> Self {
        match self {
            MsgContentDraft::Location {
                ref mut geo_uri, ..
            } => {
                *geo_uri = value;
            }
            _ => warn!("geo_uri is available for only location"),
        }
        self
    }
}

#[derive(Clone, Debug)]
pub struct MsgDraft {
    pub(crate) inner: MsgContentDraft,
    pub(crate) mentions: Mentions,
}

impl MsgDraft {
    pub fn add_mention(&self, user_id: String) -> Result<Self> {
        let MsgDraft {
            inner,
            mut mentions,
        } = self.clone();
        let user_id = UserId::parse(user_id)?;
        mentions.user_ids.insert(user_id);
        Ok(MsgDraft { inner, mentions })
    }

    pub fn add_ref_details(&self, ref_details: Box<crate::RefDetails>) -> Result<Self> {
        let MsgDraft {
            mut inner,
            mut mentions,
        } = self.clone();
        inner.add_ref_details(*ref_details)?;
        Ok(MsgDraft { inner, mentions })
    }

    pub fn add_url_preview(&self, preview: Box<crate::LocalUrlPreview>) -> Result<Self> {
        let MsgDraft {
            mut inner,
            mut mentions,
        } = self.clone();
        inner.add_url_preview((*preview).into())?;
        Ok(MsgDraft { inner, mentions })
    }

    pub fn add_room_mention(&self, mention: bool) -> Result<Self> {
        let MsgDraft {
            inner,
            mut mentions,
        } = self.clone();
        mentions.room = mention;
        Ok(MsgDraft { inner, mentions })
    }

    pub fn mimetype(&self, value: String) -> Self {
        let MsgDraft { inner, mentions } = self.clone();
        MsgDraft {
            inner: inner.mimetype(value),
            mentions,
        }
    }
    pub fn size(&self, value: u64) -> Self {
        let MsgDraft { inner, mentions } = self.clone();
        MsgDraft {
            inner: inner.size(value),
            mentions,
        }
    }
    pub fn width(&self, value: u64) -> Self {
        let MsgDraft { inner, mentions } = self.clone();
        MsgDraft {
            inner: inner.width(value),
            mentions,
        }
    }
    pub fn height(&self, value: u64) -> Self {
        let MsgDraft { inner, mentions } = self.clone();
        MsgDraft {
            inner: inner.height(value),
            mentions,
        }
    }
    pub fn thumbnail_image(&self, source: String, mimetype: String) -> Self {
        let MsgDraft { inner, mentions } = self.clone();
        MsgDraft {
            inner: inner.thumbnail_image(source, mimetype),
            mentions,
        }
    }
    pub fn thumbnail_info(
        &self,
        width: Option<u64>,
        height: Option<u64>,
        size: Option<u64>,
    ) -> Self {
        let mut value = assign!(ThumbnailInfo::new(), {
            width: width.and_then(UInt::new),
            height: height.and_then(UInt::new),
            size: size.and_then(UInt::new),
        });
        let MsgDraft { inner, mentions } = self.clone();
        MsgDraft {
            inner: inner.thumbnail_info(value),
            mentions,
        }
    }
    pub fn duration(&self, value: u64) -> Self {
        let MsgDraft { inner, mentions } = self.clone();
        MsgDraft {
            inner: inner.duration(value),
            mentions,
        }
    }
    pub fn blurhash(&self, value: String) -> Self {
        let MsgDraft { inner, mentions } = self.clone();
        MsgDraft {
            inner: inner.blurhash(value),
            mentions,
        }
    }
    pub fn geo_uri(&self, value: String) -> Self {
        let MsgDraft { inner, mentions } = self.clone();
        MsgDraft {
            inner: inner.geo_uri(value),
            mentions,
        }
    }
    pub fn filename(&self, value: String) -> Self {
        let MsgDraft { inner, mentions } = self.clone();
        MsgDraft {
            inner: inner.filename(value),
            mentions,
        }
    }
}

impl MsgDraft {
    pub(crate) fn new(inner: MsgContentDraft) -> Self {
        MsgDraft {
            inner,
            mentions: Mentions::new(),
        }
    }

    pub(crate) async fn into_room_msg(
        self,
        room: &Room,
    ) -> Result<RoomMessageEventContentWithoutRelation> {
        let MsgDraft { inner, mentions } = self;
        let event_content = RoomMessageEventContentWithoutRelation::new(match inner {
            MsgContentDraft::TextPlain { body, url_previews } => {
                let mut inner = TextMessageEventContent::plain(body);
                if !url_previews.is_empty() {
                    inner.url_previews = Some(url_previews.clone());
                }
                MessageType::Text(inner)
            }
            MsgContentDraft::TextMarkdown { body, url_previews } => {
                let mut inner = TextMessageEventContent::markdown(body);
                if !url_previews.is_empty() {
                    inner.url_previews = Some(url_previews.clone());
                }
                MessageType::Text(inner)
            }
            MsgContentDraft::TextHtml {
                html,
                plain,
                url_previews,
            } => {
                let mut inner = TextMessageEventContent::html(plain, html);
                if !url_previews.is_empty() {
                    inner.url_previews = Some(url_previews.clone());
                }
                MessageType::Text(inner)
            }

            MsgContentDraft::Location {
                body,
                geo_uri,
                thumbnail_source,
                info,
            } => {
                let is_encrypted = room.latest_encryption_state().await?.is_encrypted();
                let mut info = info.expect("location info needed");
                if let Some(thumb_src) = thumbnail_source {
                    let thumb_path = PathBuf::from(thumb_src);
                    info.thumbnail_source = if is_encrypted {
                        let mut reader = std::fs::File::open(thumb_path)?;
                        let encrypted_file =
                            room.client().upload_encrypted_file(&mut reader).await?;
                        Some(MediaSource::Encrypted(Box::new(encrypted_file)))
                    } else {
                        let mimetype = info
                            .thumbnail_info
                            .as_ref()
                            .and_then(|i| i.mimetype.clone())
                            .expect("thumbnail mimetype needed");
                        let content_type = mimetype.parse::<mime::Mime>()?;
                        let mut image_buf = std::fs::read(thumb_path)?;
                        let response = room
                            .client()
                            .media()
                            .upload(&content_type, image_buf, None)
                            .await?;
                        Some(MediaSource::Plain(response.content_uri))
                    };
                }
                let mut location_content = LocationMessageEventContent::new(body, geo_uri);
                location_content.info = Some(Box::new(info));
                MessageType::Location(location_content)
            }

            MsgContentDraft::Image {
                source,
                thumbnail_source,
                info,
                filename,
            } => {
                let is_encrypted = room.latest_encryption_state().await?.is_encrypted();
                let mut info = info.expect("image info needed");
                if let Some(thumb_src) = thumbnail_source {
                    let thumb_path = PathBuf::from(thumb_src);
                    info.thumbnail_source = if is_encrypted {
                        let mut reader = std::fs::File::open(thumb_path)?;
                        let encrypted_file =
                            room.client().upload_encrypted_file(&mut reader).await?;
                        Some(MediaSource::Encrypted(Box::new(encrypted_file)))
                    } else {
                        let mimetype = info
                            .thumbnail_info
                            .as_ref()
                            .and_then(|i| i.mimetype.clone())
                            .expect("thumbnail mimetype needed");
                        let content_type = mimetype.parse::<mime::Mime>()?;
                        let mut image_buf = std::fs::read(thumb_path)?;
                        let response = room
                            .client()
                            .media()
                            .upload(&content_type, image_buf, None)
                            .await?;
                        Some(MediaSource::Plain(response.content_uri))
                    };
                }
                let path = PathBuf::from(source);
                let mut image_content = if is_encrypted {
                    let mut reader = std::fs::File::open(path.clone())?;
                    let encrypted_file = room.client().upload_encrypted_file(&mut reader).await?;
                    let body = path
                        .file_name()
                        .expect("it is not file")
                        .to_string_lossy()
                        .to_string();
                    ImageMessageEventContent::encrypted(body, encrypted_file)
                } else {
                    let mimetype = info.mimetype.clone().expect("mimetype needed");
                    let content_type = mimetype.parse::<mime::Mime>()?;
                    let mut image_buf = std::fs::read(path.clone())?;
                    let response = room
                        .client()
                        .media()
                        .upload(&content_type, image_buf, None)
                        .await?;
                    let body = path
                        .file_name()
                        .expect("it is not file")
                        .to_string_lossy()
                        .to_string();
                    ImageMessageEventContent::plain(body, response.content_uri)
                };
                image_content.info = Some(Box::new(info));
                image_content.filename = filename;
                MessageType::Image(image_content)
            }
            MsgContentDraft::Audio {
                source,
                info,
                filename,
            } => {
                let info = info.expect("audio info needed");
                let path = PathBuf::from(source);
                let mut audio_content = if room.latest_encryption_state().await?.is_encrypted() {
                    let mut reader = std::fs::File::open(path.clone())?;
                    let encrypted_file = room.client().upload_encrypted_file(&mut reader).await?;
                    let body = path
                        .file_name()
                        .expect("it is not file")
                        .to_string_lossy()
                        .to_string();
                    AudioMessageEventContent::encrypted(body, encrypted_file)
                } else {
                    let mimetype = info.mimetype.clone().expect("mimetype needed");
                    let content_type = mimetype.parse::<mime::Mime>()?;
                    let mut audio_buf = std::fs::read(path.clone())?;
                    let response = room
                        .client()
                        .media()
                        .upload(&content_type, audio_buf, None)
                        .await?;
                    let body = path
                        .file_name()
                        .expect("it is not file")
                        .to_string_lossy()
                        .to_string();
                    AudioMessageEventContent::plain(body, response.content_uri)
                };
                audio_content.info = Some(Box::new(info));
                audio_content.filename = filename;
                MessageType::Audio(audio_content)
            }
            MsgContentDraft::Video {
                source,
                thumbnail_source,
                info,
                filename,
            } => {
                let is_encrypted = room.latest_encryption_state().await?.is_encrypted();
                let mut info = info.expect("video info needed");
                if let Some(thumb_src) = thumbnail_source {
                    let thumb_path = PathBuf::from(thumb_src);
                    info.thumbnail_source = if is_encrypted {
                        let mut reader = std::fs::File::open(thumb_path)?;
                        let encrypted_file =
                            room.client().upload_encrypted_file(&mut reader).await?;
                        Some(MediaSource::Encrypted(Box::new(encrypted_file)))
                    } else {
                        let mimetype = info
                            .thumbnail_info
                            .as_ref()
                            .and_then(|i| i.mimetype.clone())
                            .expect("thumbnail mimetype needed");
                        let content_type = mimetype.parse::<mime::Mime>()?;
                        let mut image_buf = std::fs::read(thumb_path)?;
                        let response = room
                            .client()
                            .media()
                            .upload(&content_type, image_buf, None)
                            .await?;
                        Some(MediaSource::Plain(response.content_uri))
                    };
                }
                let path = PathBuf::from(source);
                let mut video_content = if is_encrypted {
                    let mut reader = std::fs::File::open(path.clone())?;
                    let encrypted_file = room.client().upload_encrypted_file(&mut reader).await?;
                    let body = path
                        .file_name()
                        .expect("it is not file")
                        .to_string_lossy()
                        .to_string();
                    VideoMessageEventContent::encrypted(body, encrypted_file)
                } else {
                    let mimetype = info.mimetype.clone().expect("mimetype needed");
                    let content_type = mimetype.parse::<mime::Mime>()?;
                    let mut video_buf = std::fs::read(path.clone())?;
                    let response = room
                        .client()
                        .media()
                        .upload(&content_type, video_buf, None)
                        .await?;
                    let body = path
                        .file_name()
                        .expect("it is not file")
                        .to_string_lossy()
                        .to_string();
                    VideoMessageEventContent::plain(body, response.content_uri)
                };
                video_content.info = Some(Box::new(info));
                video_content.filename = filename;
                MessageType::Video(video_content)
            }
            MsgContentDraft::File {
                source,
                thumbnail_source,
                info,
                filename,
            } => {
                let is_encrypted = room.latest_encryption_state().await?.is_encrypted();
                let mut info = info.expect("file info needed");
                if let Some(thumb_src) = thumbnail_source {
                    let thumb_path = PathBuf::from(thumb_src);
                    info.thumbnail_source = if is_encrypted {
                        let mut reader = std::fs::File::open(thumb_path)?;
                        let encrypted_file =
                            room.client().upload_encrypted_file(&mut reader).await?;
                        Some(MediaSource::Encrypted(Box::new(encrypted_file)))
                    } else {
                        let mimetype = info
                            .thumbnail_info
                            .as_ref()
                            .and_then(|i| i.mimetype.clone())
                            .expect("thumbnail mimetype needed");
                        let content_type = mimetype.parse::<mime::Mime>()?;
                        let mut image_buf = std::fs::read(thumb_path)?;
                        let response = room
                            .client()
                            .media()
                            .upload(&content_type, image_buf, None)
                            .await?;
                        Some(MediaSource::Plain(response.content_uri))
                    };
                }
                let path = PathBuf::from(source);
                let mut file_content = if room.latest_encryption_state().await?.is_encrypted() {
                    let mut reader = std::fs::File::open(path.clone())?;
                    let encrypted_file = room.client().upload_encrypted_file(&mut reader).await?;
                    let body = path
                        .file_name()
                        .expect("it is not file")
                        .to_string_lossy()
                        .to_string();
                    FileMessageEventContent::encrypted(body, encrypted_file)
                } else {
                    let mimetype = info.mimetype.clone().expect("mimetype needed");
                    let content_type = mimetype.parse::<mime::Mime>()?;
                    let mut file_buf = std::fs::read(path.clone())?;
                    let response = room
                        .client()
                        .media()
                        .upload(&content_type, file_buf, None)
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
                MessageType::File(file_content)
            }
        });
        Ok(event_content.add_mentions(mentions))
    }
}
