use acter_core::models::status::{
    membership::{MembershipChange, ProfileChange},
    room_state::OtherState,
};
use matrix_sdk_base::ruma::{
    events::{
        room::{ImageInfo, MediaSource as SdkMediaSource},
        sticker::{StickerEventContent, StickerMediaSource},
        MessageLikeEventType, StateEventType,
    },
    OwnedMxcUri, OwnedUserId,
};
use matrix_sdk_ui::timeline::{Message, PollState, Sticker as SdkSticker};
use serde::{Deserialize, Serialize};

use super::msg_content::MsgContent;
use crate::{MediaSource, ReactionRecord};

#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum TimelineEventContent {
    Message(MsgContent),
    RedactedMessage,
    Sticker(Sticker),
    UnableToDecrypt,
    MembershipChange(MembershipChange),
    ProfileChange(ProfileChange),
    OtherState(OtherState),
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
