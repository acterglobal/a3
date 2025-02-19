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

// if you change the order of these enum variables, enum value will change and parsing of old content will fail
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(untagged)]
pub enum FallbackNewsContent {
    /// An image message.
    Image(ImageMessageEventContent),
    /// A video message.
    Video(VideoMessageEventContent),
    /// A text message.
    Text(TextMessageEventContent),
    /// An audio message.
    Audio(AudioMessageEventContent),
    /// A file message.
    File(FileMessageEventContent),
    /// A location message.
    Location(LocationMessageEventContent),
}

impl FallbackNewsContent {
    pub fn type_str(&self) -> String {
        match self {
            FallbackNewsContent::Audio(_) => "audio".to_owned(),
            FallbackNewsContent::File(_) => "file".to_owned(),
            FallbackNewsContent::Image(_) => "image".to_owned(),
            FallbackNewsContent::Location(_) => "location".to_owned(),
            FallbackNewsContent::Text(_) => "text".to_owned(),
            FallbackNewsContent::Video(_) => "video".to_owned(),
        }
    }

    pub fn audio(&self) -> Option<AudioMessageEventContent> {
        match self {
            FallbackNewsContent::Audio(content) => Some(content.clone()),
            _ => None,
        }
    }

    pub fn file(&self) -> Option<FileMessageEventContent> {
        match self {
            FallbackNewsContent::File(content) => Some(content.clone()),
            _ => None,
        }
    }

    pub fn image(&self) -> Option<ImageMessageEventContent> {
        match self {
            FallbackNewsContent::Image(content) => Some(content.clone()),
            _ => None,
        }
    }

    pub fn location(&self) -> Option<LocationMessageEventContent> {
        match self {
            FallbackNewsContent::Location(content) => Some(content.clone()),
            _ => None,
        }
    }

    pub fn text(&self) -> Option<TextMessageEventContent> {
        match self {
            FallbackNewsContent::Text(content) => Some(content.clone()),
            _ => None,
        }
    }

    pub fn video(&self) -> Option<VideoMessageEventContent> {
        match self {
            FallbackNewsContent::Video(content) => Some(content.clone()),
            _ => None,
        }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(tag = "type")]
pub enum NewsContent {
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
    /// Backwards-compatible fallback support for previous untagged version
    /// only for reading existing events.
    #[serde(untagged)]
    Fallback(FallbackNewsContent),
}

impl NewsContent {
    pub fn type_str(&self) -> String {
        match self {
            NewsContent::File(_) => "file".to_owned(),
            NewsContent::Image(_) => "image".to_owned(),
            NewsContent::Location(_) => "location".to_owned(),
            NewsContent::Text(_) => "text".to_owned(),
            NewsContent::Audio(_) => "audio".to_owned(),
            NewsContent::Video(_) => "video".to_owned(),
            NewsContent::Fallback(f) => f.type_str(),
        }
    }
    pub fn text_str(&self) -> String {
        match self {
            NewsContent::Image(ImageMessageEventContent { body, .. })
            | NewsContent::Fallback(FallbackNewsContent::Image(ImageMessageEventContent {
                body,
                ..
            }))
            | NewsContent::File(FileMessageEventContent { body, .. })
            | NewsContent::Fallback(FallbackNewsContent::File(FileMessageEventContent {
                body,
                ..
            }))
            | NewsContent::Location(LocationMessageEventContent { body, .. })
            | NewsContent::Fallback(FallbackNewsContent::Location(LocationMessageEventContent {
                body,
                ..
            }))
            | NewsContent::Video(VideoMessageEventContent { body, .. })
            | NewsContent::Fallback(FallbackNewsContent::Video(VideoMessageEventContent {
                body,
                ..
            }))
            | NewsContent::Audio(AudioMessageEventContent { body, .. })
            | NewsContent::Fallback(FallbackNewsContent::Audio(AudioMessageEventContent {
                body,
                ..
            })) => body.clone(),

            NewsContent::Text(TextMessageEventContent {
                formatted, body, ..
            })
            | NewsContent::Fallback(FallbackNewsContent::Text(TextMessageEventContent {
                formatted,
                body,
                ..
            })) => {
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
            NewsContent::Text(body) => Some(body.clone()),
            NewsContent::Fallback(f) => f.text(),
            _ => None,
        }
    }

    pub fn audio(&self) -> Option<AudioMessageEventContent> {
        match self {
            NewsContent::Audio(body) => Some(body.clone()),
            NewsContent::Fallback(f) => f.audio(),
            _ => None,
        }
    }

    pub fn video(&self) -> Option<VideoMessageEventContent> {
        match self {
            NewsContent::Video(body) => Some(body.clone()),
            NewsContent::Fallback(f) => f.video(),
            _ => None,
        }
    }

    pub fn file(&self) -> Option<FileMessageEventContent> {
        match self {
            NewsContent::File(content) => Some(content.clone()),
            NewsContent::Fallback(f) => f.file(),
            _ => None,
        }
    }

    pub fn image(&self) -> Option<ImageMessageEventContent> {
        match self {
            NewsContent::Image(content) => Some(content.clone()),
            NewsContent::Fallback(f) => f.image(),
            _ => None,
        }
    }

    pub fn location(&self) -> Option<LocationMessageEventContent> {
        match self {
            NewsContent::Location(content) => Some(content.clone()),
            NewsContent::Fallback(f) => f.location(),
            _ => None,
        }
    }
}
/// A news slide represents one full-sized slide of news
#[derive(Clone, Debug, Builder, Deserialize, Getters, Serialize)]
pub struct NewsSlide {
    /// A slide must contain some news-worthy content
    #[serde(flatten)]
    pub content: NewsContent,

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

/// The payload for our news creation event.
#[derive(Clone, Debug, Builder, Deserialize, Serialize, Getters, EventContent)]
#[ruma_event(type = "global.acter.dev.news", kind = MessageLike)]
#[builder(name = "NewsEntryBuilder", derive(Debug))]
pub struct NewsEntryEventContent {
    /// A news entry may have one or more slides of news
    /// which are scrolled through horizontally
    pub slides: Vec<NewsSlide>,
}

/// The payload for our news update event.
#[derive(Clone, Debug, Builder, Deserialize, Serialize, EventContent)]
#[ruma_event(type = "global.acter.dev.news.update", kind = MessageLike)]
#[builder(name = "NewsEntryUpdateBuilder", derive(Debug))]
pub struct NewsEntryUpdateEventContent {
    #[builder(setter(into))]
    #[serde(rename = "m.relates_to")]
    pub news_entry: Update,

    /// A news entry may have one or more slides of news
    /// which are scrolled through horizontally
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub slides: Option<Vec<NewsSlide>>,
}

impl NewsEntryUpdateEventContent {
    pub fn apply(&self, task: &mut NewsEntryEventContent) -> Result<bool> {
        let mut updated = false;
        if let Some(slides) = &self.slides {
            task.slides.clone_from(slides);
            updated = true;
        }
        Ok(updated)
    }
}
