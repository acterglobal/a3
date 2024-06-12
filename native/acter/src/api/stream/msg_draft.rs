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
use matrix_sdk_ui::timeline::Timeline;
use ruma::{assign, UInt};
use ruma_client_api::{receipt::create_receipt, sync::sync_events::v3::Rooms};
use ruma_common::{EventId, OwnedEventId, OwnedTransactionId, UserId};
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
use tracing::{info, warn};

use crate::{Client, RoomMessage, RUNTIME};

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
    fn size(mut self, value: u64) -> Self {
        match self {
            MsgContentDraft::Image { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    o.size = UInt::new(value)
                } else {
                    *info = Some(assign!(ImageInfo::new(), { size : UInt::new(value)}));
                }
            }
            MsgContentDraft::Audio { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    o.size = UInt::new(value)
                } else {
                    *info = Some(assign!(AudioInfo::new(), { size : UInt::new(value)}));
                }
            }
            MsgContentDraft::Video { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    o.size = UInt::new(value)
                } else {
                    *info = Some(assign!(VideoInfo::new(), { size : UInt::new(value)}));
                }
            }
            MsgContentDraft::File { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    o.size = UInt::new(value)
                } else {
                    *info = Some(assign!(FileInfo::new(), { size : UInt::new(value)}));
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
                    o.width = UInt::new(value)
                } else {
                    *info = Some(assign!(ImageInfo::new(), { width : UInt::new(value)}));
                }
            }
            MsgContentDraft::Video { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    o.width = UInt::new(value)
                } else {
                    *info = Some(assign!(VideoInfo::new(), { width : UInt::new(value)}));
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
                    o.height = UInt::new(value)
                } else {
                    *info = Some(assign!(ImageInfo::new(), { height : UInt::new(value)}));
                }
            }
            MsgContentDraft::Video { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    o.height = UInt::new(value)
                } else {
                    *info = Some(assign!(VideoInfo::new(), { height : UInt::new(value)}));
                }
            }
            _ => warn!("height is available for only image/video"),
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
                        assign!(AudioInfo::new(), { duration : Some(Duration::from_secs(value)) } ),
                    );
                }
            }
            MsgContentDraft::Video { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    o.duration = Some(Duration::from_secs(value));
                } else {
                    *info = Some(
                        assign!(VideoInfo::new(), { duration : Some(Duration::from_secs(value))}),
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
                    o.blurhash = Some(value)
                } else {
                    *info = Some(assign!(ImageInfo::new(), { blurhash : Some(value)}));
                }
            }
            MsgContentDraft::Video { ref mut info, .. } => {
                if let Some(o) = info.as_mut() {
                    o.blurhash = Some(value)
                } else {
                    *info = Some(assign!(VideoInfo::new(), { blurhash : Some(value)}));
                }
            }
            _ => warn!("blurhash is available for only image/video"),
        }
        self
    }

    fn filename(mut self, value: String) -> Self {
        match self {
            MsgContentDraft::File {
                source,
                info,
                filename: _,
            } => {
                return MsgContentDraft::File {
                    source,
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
        let user_id = UserId::parse(&user_id)?;
        mentions.user_ids.insert(user_id);
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
        let event_content = match inner {
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
        };
        Ok(event_content.add_mentions(mentions))
    }
}
