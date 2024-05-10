use derive_builder::Builder;
use derive_getters::Getters;
use ruma_events::room::message::{
    AudioMessageEventContent, FileMessageEventContent, ImageMessageEventContent,
    LocationMessageEventContent, MessageType, VideoMessageEventContent,
};
use ruma_macros::EventContent;
use serde::{Deserialize, Serialize};

use super::{BelongsTo, Update};
use crate::Result;

// if you change the order of these enum variables, enum value will change and parsing of old content will fail
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(untagged)]
pub enum FallbackAttachmentContent {
    /// An image
    Image(ImageMessageEventContent),
    /// A video message.
    Video(VideoMessageEventContent),
    /// An audio message.
    Audio(AudioMessageEventContent),
    /// A file message.
    File(FileMessageEventContent),
    /// A location
    Location(LocationMessageEventContent),
}

impl FallbackAttachmentContent {
    pub fn type_str(&self) -> String {
        match self {
            FallbackAttachmentContent::Image(_) => "image".to_owned(),
            FallbackAttachmentContent::Video(_) => "video".to_owned(),
            FallbackAttachmentContent::Audio(_) => "audio".to_owned(),
            FallbackAttachmentContent::File(_) => "file".to_owned(),
            FallbackAttachmentContent::Location(_) => "location".to_owned(),
        }
    }

    pub fn image(&self) -> Option<ImageMessageEventContent> {
        match self {
            FallbackAttachmentContent::Image(content) => Some(content.clone()),
            _ => None,
        }
    }

    pub fn video(&self) -> Option<VideoMessageEventContent> {
        match self {
            FallbackAttachmentContent::Video(content) => Some(content.clone()),
            _ => None,
        }
    }

    pub fn audio(&self) -> Option<AudioMessageEventContent> {
        match self {
            FallbackAttachmentContent::Audio(content) => Some(content.clone()),
            _ => None,
        }
    }

    pub fn file(&self) -> Option<FileMessageEventContent> {
        match self {
            FallbackAttachmentContent::File(content) => Some(content.clone()),
            _ => None,
        }
    }

    pub fn location(&self) -> Option<LocationMessageEventContent> {
        match self {
            FallbackAttachmentContent::Location(content) => Some(content.clone()),
            _ => None,
        }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(tag = "type")]
pub enum AttachmentContent {
    /// An image message.
    Image(ImageMessageEventContent),
    /// A video message.
    Video(VideoMessageEventContent),
    /// An audio message.
    Audio(AudioMessageEventContent),
    /// A file message
    File(FileMessageEventContent),
    /// A location message.
    Location(LocationMessageEventContent),
    /// Backwards-compatible fallback support for previous untagged version
    /// only for reading existing events.
    #[serde(untagged)]
    Fallback(FallbackAttachmentContent),
}

impl TryFrom<MessageType> for AttachmentContent {
    type Error = ();

    fn try_from(value: MessageType) -> std::prelude::v1::Result<Self, Self::Error> {
        Ok(match value {
            MessageType::Image(content) => AttachmentContent::Image(content),
            MessageType::Video(content) => AttachmentContent::Video(content),
            MessageType::Audio(content) => AttachmentContent::Audio(content),
            MessageType::File(content) => AttachmentContent::File(content),
            MessageType::Location(content) => AttachmentContent::Location(content),
            _ => return Err(()),
        })
    }
}

impl AttachmentContent {
    pub fn type_str(&self) -> String {
        match self {
            AttachmentContent::Image(_) => "image".to_owned(),
            AttachmentContent::Video(_) => "video".to_owned(),
            AttachmentContent::Audio(_) => "audio".to_owned(),
            AttachmentContent::File(_) => "file".to_owned(),
            AttachmentContent::Location(_) => "location".to_owned(),
            AttachmentContent::Fallback(f) => f.type_str(),
        }
    }

    pub fn image(&self) -> Option<ImageMessageEventContent> {
        match self {
            AttachmentContent::Image(content) => Some(content.clone()),
            AttachmentContent::Fallback(f) => f.image(),
            _ => None,
        }
    }

    pub fn video(&self) -> Option<VideoMessageEventContent> {
        match self {
            AttachmentContent::Video(body) => Some(body.clone()),
            AttachmentContent::Fallback(f) => f.video(),
            _ => None,
        }
    }

    pub fn audio(&self) -> Option<AudioMessageEventContent> {
        match self {
            AttachmentContent::Audio(body) => Some(body.clone()),
            AttachmentContent::Fallback(f) => f.audio(),
            _ => None,
        }
    }

    pub fn file(&self) -> Option<FileMessageEventContent> {
        match self {
            AttachmentContent::File(content) => Some(content.clone()),
            AttachmentContent::Fallback(f) => f.file(),
            _ => None,
        }
    }

    pub fn location(&self) -> Option<LocationMessageEventContent> {
        match self {
            AttachmentContent::Location(content) => Some(content.clone()),
            AttachmentContent::Fallback(f) => f.location(),
            _ => None,
        }
    }
}

/// Attachment Event
#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder, Getters)]
#[ruma_event(type = "global.acter.dev.attachment", kind = MessageLike)]
#[builder(name = "AttachmentBuilder", derive(Debug))]
pub struct AttachmentEventContent {
    #[builder(setter(into))]
    #[serde(rename = "m.relates_to")]
    pub on: BelongsTo,

    pub content: AttachmentContent,
}

/// The Attachment Update Event
#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder)]
#[ruma_event(type = "global.acter.dev.attachment.update", kind = MessageLike)]
#[builder(name = "AttachmentUpdateBuilder", derive(Debug))]
pub struct AttachmentUpdateEventContent {
    #[builder(setter(into))]
    #[serde(rename = "m.relates_to")]
    pub attachment: Update,

    pub content: AttachmentContent,
}

impl AttachmentUpdateEventContent {
    pub fn apply(&self, task: &mut AttachmentEventContent) -> Result<bool> {
        task.content = self.content.clone();
        Ok(true)
    }
}
