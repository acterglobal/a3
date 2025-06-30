use derive_builder::Builder;
use derive_getters::Getters;
use matrix_sdk_base::ruma::events::{
    macros::EventContent,
    room::message::{
        AudioMessageEventContent, FileMessageEventContent, ImageMessageEventContent,
        LocationMessageEventContent, TextMessageEventContent, VideoMessageEventContent,
    },
};
use serde::{Deserialize, Serialize};

use super::{Colorize, ObjRef, Update};
use crate::{util::deserialize_some, Result};

#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(tag = "type")]
pub enum StoryContent {
    /// An image message.
    Image(ImageMessageEventContent),
    /// A video message.
    Video(VideoMessageEventContent),
    /// A text message.
    Text(TextMessageEventContent),
    /// An audio message.
    Audio(AudioMessageEventContent),
    /// A file message
    File(FileMessageEventContent),
    /// A location message.
    Location(LocationMessageEventContent),
}

impl StoryContent {
    pub fn type_str(&self) -> String {
        match self {
            StoryContent::File(_) => "file".to_owned(),
            StoryContent::Image(_) => "image".to_owned(),
            StoryContent::Location(_) => "location".to_owned(),
            StoryContent::Text(_) => "text".to_owned(),
            StoryContent::Audio(_) => "audio".to_owned(),
            StoryContent::Video(_) => "video".to_owned(),
        }
    }
    pub fn text_str(&self) -> String {
        match self {
            StoryContent::Image(ImageMessageEventContent { body, .. })
            | StoryContent::File(FileMessageEventContent { body, .. })
            | StoryContent::Location(LocationMessageEventContent { body, .. })
            | StoryContent::Video(VideoMessageEventContent { body, .. })
            | StoryContent::Audio(AudioMessageEventContent { body, .. }) => body.clone(),

            StoryContent::Text(TextMessageEventContent {
                formatted, body, ..
            }) => {
                if let Some(formatted) = formatted {
                    formatted.body.clone()
                } else {
                    body.clone()
                }
            }
        }
    }

    pub fn text(&self) -> Option<TextMessageEventContent> {
        match self {
            StoryContent::Text(body) => Some(body.clone()),
            _ => None,
        }
    }

    pub fn audio(&self) -> Option<AudioMessageEventContent> {
        match self {
            StoryContent::Audio(body) => Some(body.clone()),
            _ => None,
        }
    }

    pub fn video(&self) -> Option<VideoMessageEventContent> {
        match self {
            StoryContent::Video(body) => Some(body.clone()),
            _ => None,
        }
    }

    pub fn file(&self) -> Option<FileMessageEventContent> {
        match self {
            StoryContent::File(content) => Some(content.clone()),
            _ => None,
        }
    }

    pub fn image(&self) -> Option<ImageMessageEventContent> {
        match self {
            StoryContent::Image(content) => Some(content.clone()),
            _ => None,
        }
    }

    pub fn location(&self) -> Option<LocationMessageEventContent> {
        match self {
            StoryContent::Location(content) => Some(content.clone()),
            _ => None,
        }
    }
}
/// A Story slide represents one full-sized slide of Story
#[derive(Clone, Debug, Builder, Deserialize, Getters, Serialize)]
pub struct StorySlide {
    /// A slide must contain some Story-worthy content
    #[serde(flatten)]
    pub content: StoryContent,

    /// A slide may optionally contain references to other items
    #[builder(default)]
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub references: Vec<ObjRef>,

    /// You can define custom background and foreground colors
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub colors: Option<Colorize>,
}

/// The payload for our Story creation event.
#[derive(Clone, Debug, Builder, Deserialize, Serialize, Getters, EventContent)]
#[ruma_event(type = "global.acter.dev.story", kind = MessageLike)]
#[builder(name = "StoryBuilder", derive(Debug))]
pub struct StoryEventContent {
    /// A Story entry may have one or more slides of Story
    /// which are scrolled through horizontally
    pub slides: Vec<StorySlide>,
}

/// The payload for our Story update event.
#[derive(Clone, Debug, Builder, Deserialize, Serialize, EventContent)]
#[ruma_event(type = "global.acter.dev.story.update", kind = MessageLike)]
#[builder(name = "StoryUpdateBuilder", derive(Debug))]
pub struct StoryUpdateEventContent {
    #[builder(setter(into))]
    #[serde(rename = "m.relates_to")]
    pub story_entry: Update,

    /// A Story entry may have one or more slides of Story
    /// which are scrolled through horizontally
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub slides: Option<Vec<StorySlide>>,
}

impl StoryUpdateEventContent {
    pub fn apply(&self, task: &mut StoryEventContent) -> Result<bool> {
        let mut updated = false;
        if let Some(slides) = &self.slides {
            task.slides.clone_from(slides);
            updated = true;
        }
        Ok(updated)
    }
}
