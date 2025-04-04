use matrix_sdk_base::ruma::events::{
    room::{message::MessageType, ImageInfo, MediaSource as SdkMediaSource},
    sticker::StickerMediaSource,
    MessageLikeEventType, StateEventType,
};
use matrix_sdk_ui::timeline::{PollState, Sticker as SdkSticker};
use serde::{Deserialize, Serialize};

use super::MsgContent;
use crate::MediaSource;

#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum TimelineEventContent {
    Message(MsgContent),
    RedactedMessage,
    Sticker(Sticker),
    UnableToDecrypt,
    FailedToParseMessageLike {
        event_type: MessageLikeEventType,
        error: String,
    },
    FailedToParseState {
        event_type: StateEventType,
        state_key: String,
        error: String,
    },
    Poll(PollContent),
    CallInvite,
    CallNotify,
}

impl TryFrom<&MessageType> for TimelineEventContent {
    type Error = ();

    fn try_from(value: &MessageType) -> Result<Self, Self::Error> {
        match value {
            MessageType::Text(content) => {
                Ok(TimelineEventContent::Message(MsgContent::from(content)))
            }
            MessageType::Emote(content) => {
                Ok(TimelineEventContent::Message(MsgContent::from(content)))
            }
            MessageType::Image(content) => {
                Ok(TimelineEventContent::Message(MsgContent::from(content)))
            }
            MessageType::Audio(content) => {
                Ok(TimelineEventContent::Message(MsgContent::from(content)))
            }
            MessageType::Video(content) => {
                Ok(TimelineEventContent::Message(MsgContent::from(content)))
            }
            MessageType::File(content) => {
                Ok(TimelineEventContent::Message(MsgContent::from(content)))
            }
            MessageType::Location(content) => {
                Ok(TimelineEventContent::Message(MsgContent::from(content)))
            }
            MessageType::Notice(content) => {
                Ok(TimelineEventContent::Message(MsgContent::from(content)))
            }
            MessageType::ServerNotice(content) => {
                Ok(TimelineEventContent::Message(MsgContent::from(content)))
            }
            _ => Err(()),
        }
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct Sticker {
    body: String,
    source: SdkMediaSource,
    info: ImageInfo,
}

impl TryFrom<&SdkSticker> for Sticker {
    type Error = ();

    fn try_from(value: &SdkSticker) -> Result<Self, Self::Error> {
        let content = value.content();
        let source = match &content.source {
            StickerMediaSource::Plain(url) => SdkMediaSource::Plain(url.clone()),
            StickerMediaSource::Encrypted(file) => SdkMediaSource::Encrypted(file.clone()),
            _ => {
                return Err(());
            }
        };
        Ok(Sticker {
            body: content.body.clone(),
            source,
            info: content.info.clone(),
        })
    }
}

impl Sticker {
    pub fn body(&self) -> String {
        self.body.clone()
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
        self.info.size.map(Into::into)
    }

    pub fn width(&self) -> Option<u64> {
        self.info.width.map(Into::into)
    }

    pub fn height(&self) -> Option<u64> {
        self.info.height.map(Into::into)
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct PollContent {
    fallback_text: Option<String>,
}

impl From<&PollState> for PollContent {
    fn from(value: &PollState) -> Self {
        PollContent {
            fallback_text: value.fallback_text(),
        }
    }
}

impl PollContent {
    pub fn fallback_text(&self) -> Option<String> {
        self.fallback_text.clone()
    }
}
