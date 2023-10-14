use derive_builder::Builder;
use derive_getters::Getters;
use ruma_events::{
    macros::EventContent,
    room::message::{
        AudioMessageEventContent, FileMessageEventContent, ImageMessageEventContent,
        LocationMessageEventContent, VideoMessageEventContent,
    },
};
use serde::{Deserialize, Serialize};

use super::{BelongsTo, Update};
use crate::Result;

// if you change the order of these enum variables, enum value will change and parsing of old content will fail
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(untagged)]
pub enum AttachmentContent {
    /// An image
    Image(ImageMessageEventContent),
    /// A location
    Location(LocationMessageEventContent),
    /// A video message.
    Video(VideoMessageEventContent),
    /// An audio message.
    Audio(AudioMessageEventContent),
    /// A file message.
    File(FileMessageEventContent),
}

impl AttachmentContent {
    pub fn type_str(&self) -> String {
        match self {
            AttachmentContent::Audio(_) => "audio".to_owned(),
            AttachmentContent::File(_) => "file".to_owned(),
            AttachmentContent::Image(_) => "image".to_owned(),
            AttachmentContent::Location(_) => "location".to_owned(),
            AttachmentContent::Video(_) => "video".to_owned(),
        }
    }

    pub fn audio(&self) -> Option<AudioMessageEventContent> {
        match self {
            AttachmentContent::Audio(content) => Some(content.clone()),
            _ => None,
        }
    }

    pub fn file(&self) -> Option<FileMessageEventContent> {
        match self {
            AttachmentContent::File(content) => Some(content.clone()),
            _ => None,
        }
    }

    pub fn image(&self) -> Option<ImageMessageEventContent> {
        match self {
            AttachmentContent::Image(content) => Some(content.clone()),
            _ => None,
        }
    }

    pub fn location(&self) -> Option<LocationMessageEventContent> {
        match self {
            AttachmentContent::Location(content) => Some(content.clone()),
            _ => None,
        }
    }

    pub fn video(&self) -> Option<VideoMessageEventContent> {
        match self {
            AttachmentContent::Video(content) => Some(content.clone()),
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
