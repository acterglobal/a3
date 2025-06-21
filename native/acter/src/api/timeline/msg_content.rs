use acter_core::events::{
    attachments::{AttachmentContent, FallbackAttachmentContent},
    news::{FallbackNewsContent, NewsContent},
};
use matrix_sdk_base::ruma::{
    events::room::{
        message::{
            AudioInfo, AudioMessageEventContent, EmoteMessageEventContent, FileInfo,
            FileMessageEventContent, ImageMessageEventContent, LimitType, LocationInfo,
            LocationMessageEventContent, NoticeMessageEventContent,
            ServerNoticeMessageEventContent, ServerNoticeType, TextMessageEventContent,
            UnstableAudioDetailsContentBlock, UrlPreview as RumaUrlPreview, VideoInfo,
            VideoMessageEventContent,
        },
        ImageInfo, MediaSource as SdkMediaSource,
    },
    OwnedMxcUri,
};
use serde::{Deserialize, Serialize};

use crate::{MediaSource, ThumbnailInfo, UrlPreview};

#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum MsgContent {
    Text {
        body: String,
        formatted_body: Option<String>,
        url_previews: Vec<RumaUrlPreview>,
    },
    Image {
        body: String,
        source: SdkMediaSource,
        info: Option<ImageInfo>,
        filename: Option<String>,
    },
    Audio {
        body: String,
        source: SdkMediaSource,
        info: Option<AudioInfo>,
        audio: Option<UnstableAudioDetailsContentBlock>,
        filename: Option<String>,
    },
    Video {
        body: String,
        source: SdkMediaSource,
        info: Option<VideoInfo>,
        filename: Option<String>,
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
    Link {
        name: Option<String>,
        link: String,
    },
    Notice {
        body: String,
        formatted_body: Option<String>,
    },
    ServerNotice {
        body: String,
        server_notice_type: ServerNoticeType,
        admin_contact: Option<String>,
        limit_type: Option<LimitType>,
    },
}

impl TryFrom<&NewsContent> for MsgContent {
    type Error = ();

    fn try_from(value: &NewsContent) -> Result<Self, Self::Error> {
        match value {
            // everything else we have to fallback to the body-text thing ...
            NewsContent::Fallback(FallbackNewsContent::Text(msg_content))
            | NewsContent::Text(msg_content) => Ok(MsgContent::from(msg_content)),
            NewsContent::Fallback(FallbackNewsContent::Video(msg_content))
            | NewsContent::Video(msg_content) => Ok(MsgContent::from(msg_content)),
            NewsContent::Fallback(FallbackNewsContent::Audio(msg_content))
            | NewsContent::Audio(msg_content) => Ok(MsgContent::from(msg_content)),
            NewsContent::Fallback(FallbackNewsContent::File(msg_content))
            | NewsContent::File(msg_content) => Ok(MsgContent::from(msg_content)),
            NewsContent::Fallback(FallbackNewsContent::Location(msg_content))
            | NewsContent::Location(msg_content) => Ok(MsgContent::from(msg_content)),

            _ => Err(()),
        }
    }
}

impl From<&TextMessageEventContent> for MsgContent {
    fn from(value: &TextMessageEventContent) -> Self {
        MsgContent::Text {
            body: value.body.clone(),
            formatted_body: value.formatted.as_ref().map(|x| x.body.clone()),
            url_previews: value.url_previews.clone().unwrap_or_default(),
        }
    }
}

impl From<TextMessageEventContent> for MsgContent {
    fn from(value: TextMessageEventContent) -> Self {
        MsgContent::Text {
            body: value.body,
            formatted_body: value.formatted.map(|x| x.body),
            url_previews: value.url_previews.clone().unwrap_or_default(),
        }
    }
}

impl From<&ImageMessageEventContent> for MsgContent {
    fn from(value: &ImageMessageEventContent) -> Self {
        MsgContent::Image {
            body: value.body.clone(),
            source: value.source.clone(),
            info: value.info.clone().map(Box::into_inner),
            filename: value.filename.clone(),
        }
    }
}

impl From<&AudioMessageEventContent> for MsgContent {
    fn from(value: &AudioMessageEventContent) -> Self {
        MsgContent::Audio {
            body: value.body.clone(),
            source: value.source.clone(),
            info: value.info.clone().map(Box::into_inner),
            audio: value.audio.clone(),
            filename: value.filename.clone(),
        }
    }
}

impl From<&VideoMessageEventContent> for MsgContent {
    fn from(value: &VideoMessageEventContent) -> Self {
        MsgContent::Video {
            body: value.body.clone(),
            source: value.source.clone(),
            info: value.info.clone().map(Box::into_inner),
            filename: value.filename.clone(),
        }
    }
}

impl From<&FileMessageEventContent> for MsgContent {
    fn from(value: &FileMessageEventContent) -> Self {
        MsgContent::File {
            body: value.body.clone(),
            source: value.source.clone(),
            info: value.info.clone().map(Box::into_inner),
            filename: value.filename.clone(),
        }
    }
}

impl From<&LocationMessageEventContent> for MsgContent {
    fn from(value: &LocationMessageEventContent) -> Self {
        MsgContent::Location {
            body: value.body.clone(),
            geo_uri: value.geo_uri.clone(),
            info: value.info.clone().map(Box::into_inner),
        }
    }
}

impl From<&EmoteMessageEventContent> for MsgContent {
    fn from(value: &EmoteMessageEventContent) -> Self {
        MsgContent::Text {
            body: value.body.clone(),
            formatted_body: value.formatted.as_ref().map(|x| x.body.clone()),
            url_previews: Default::default(),
        }
    }
}

impl From<&NoticeMessageEventContent> for MsgContent {
    fn from(value: &NoticeMessageEventContent) -> Self {
        MsgContent::Notice {
            body: value.body.clone(),
            formatted_body: value.formatted.as_ref().map(|x| x.body.clone()),
        }
    }
}

impl From<&ServerNoticeMessageEventContent> for MsgContent {
    fn from(value: &ServerNoticeMessageEventContent) -> Self {
        MsgContent::ServerNotice {
            body: value.body.clone(),
            server_notice_type: value.server_notice_type.clone(),
            admin_contact: value.admin_contact.clone(),
            limit_type: value.limit_type.clone(),
        }
    }
}

impl TryFrom<&AttachmentContent> for MsgContent {
    type Error = ();

    fn try_from(value: &AttachmentContent) -> Result<Self, Self::Error> {
        match value {
            AttachmentContent::Image(content)
            | AttachmentContent::Fallback(FallbackAttachmentContent::Image(content)) => {
                Ok(MsgContent::Image {
                    body: content.body.clone(),
                    source: content.source.clone(),
                    info: content.info.clone().map(Box::into_inner),
                    filename: content.filename.clone(),
                })
            }
            AttachmentContent::Audio(content)
            | AttachmentContent::Fallback(FallbackAttachmentContent::Audio(content)) => {
                Ok(MsgContent::Audio {
                    body: content.body.clone(),
                    source: content.source.clone(),
                    info: content.info.clone().map(Box::into_inner),
                    audio: content.audio.clone(),
                    filename: content.filename.clone(),
                })
            }
            AttachmentContent::Video(content)
            | AttachmentContent::Fallback(FallbackAttachmentContent::Video(content)) => {
                Ok(MsgContent::Video {
                    body: content.body.clone(),
                    source: content.source.clone(),
                    info: content.info.clone().map(Box::into_inner),
                    filename: content.filename.clone(),
                })
            }
            AttachmentContent::File(content)
            | AttachmentContent::Fallback(FallbackAttachmentContent::File(content)) => {
                Ok(MsgContent::File {
                    body: content.body.clone(),
                    source: content.source.clone(),
                    info: content.info.clone().map(Box::into_inner),
                    filename: content.filename.clone(),
                })
            }
            AttachmentContent::Location(content)
            | AttachmentContent::Fallback(FallbackAttachmentContent::Location(content)) => {
                Ok(MsgContent::Location {
                    body: content.body.clone(),
                    geo_uri: content.geo_uri.clone(),
                    info: content.info.clone().map(Box::into_inner),
                })
            }
            AttachmentContent::Link(content) => Ok(MsgContent::Link {
                name: content.name.clone(),
                link: content.link.clone(),
            }),
            AttachmentContent::Reference(_) => Err(()),
        }
    }
}

impl MsgContent {
    pub(crate) fn from_text(body: String) -> Self {
        MsgContent::Text {
            body,
            formatted_body: None,
            url_previews: Default::default(),
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
            MsgContent::Link { link, .. } => link.clone(),
            MsgContent::Notice { body, .. } => body.clone(),
            MsgContent::ServerNotice { body, .. } => body.clone(),
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
            MsgContent::Image { info, .. } => info.as_ref().and_then(|x| x.size.map(Into::into)),
            MsgContent::Audio { info, .. } => info.as_ref().and_then(|x| x.size.map(Into::into)),
            MsgContent::Video { info, .. } => info.as_ref().and_then(|x| x.size.map(Into::into)),
            MsgContent::File { info, .. } => info.as_ref().and_then(|x| x.size.map(Into::into)),
            _ => None,
        }
    }

    pub fn width(&self) -> Option<u64> {
        match self {
            MsgContent::Image { info, .. } => info.as_ref().and_then(|x| x.width.map(Into::into)),
            MsgContent::Video { info, .. } => info.as_ref().and_then(|x| x.width.map(Into::into)),
            _ => None,
        }
    }

    pub fn height(&self) -> Option<u64> {
        match self {
            MsgContent::Image { info, .. } => info.as_ref().and_then(|x| x.height.map(Into::into)),
            MsgContent::Video { info, .. } => info.as_ref().and_then(|x| x.height.map(Into::into)),
            _ => None,
        }
    }

    pub fn thumbnail_source(&self) -> Option<MediaSource> {
        match self {
            MsgContent::Image { info, .. } => info
                .as_ref()
                .and_then(|x| x.thumbnail_source.as_ref().map(MediaSource::from)),
            MsgContent::Video { info, .. } => info
                .as_ref()
                .and_then(|x| x.thumbnail_source.as_ref().map(MediaSource::from)),
            MsgContent::File { info, .. } => info
                .as_ref()
                .and_then(|x| x.thumbnail_source.as_ref().map(MediaSource::from)),
            MsgContent::Location { info, .. } => info
                .as_ref()
                .and_then(|x| x.thumbnail_source.as_ref().map(MediaSource::from)),
            _ => None,
        }
    }

    pub fn thumbnail_info(&self) -> Option<ThumbnailInfo> {
        match self {
            MsgContent::Image { info, .. } => info
                .as_ref()
                .and_then(|x| x.thumbnail_info.as_deref().map(ThumbnailInfo::from)),
            MsgContent::Video { info, .. } => info
                .as_ref()
                .and_then(|x| x.thumbnail_info.as_deref().map(ThumbnailInfo::from)),
            MsgContent::File { info, .. } => info
                .as_ref()
                .and_then(|x| x.thumbnail_info.as_deref().map(ThumbnailInfo::from)),
            MsgContent::Location { info, .. } => info
                .as_ref()
                .and_then(|x| x.thumbnail_info.as_deref().map(ThumbnailInfo::from)),
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
            MsgContent::Image { filename, .. } => filename.clone(),
            MsgContent::Audio { filename, .. } => filename.clone(),
            MsgContent::Video { filename, .. } => filename.clone(),
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

    pub fn link(&self) -> Option<String> {
        match self {
            MsgContent::Link { link, .. } => Some(link.clone()),
            _ => None,
        }
    }

    pub fn url_previews(&self) -> Vec<UrlPreview> {
        match self {
            MsgContent::Text { url_previews, .. } => {
                url_previews.iter().map(UrlPreview::from).collect()
            }
            _ => vec![],
        }
    }

    pub fn has_url_previews(&self) -> bool {
        match self {
            MsgContent::Text { url_previews, .. } => !url_previews.is_empty(),
            _ => false,
        }
    }
}
