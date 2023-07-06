use derive_builder::Builder;
use derive_getters::Getters;
use matrix_sdk::ruma::{
    events::{
        macros::EventContent,
        room::{
            message::{
                AudioInfo, AudioMessageEventContent, FileInfo, FileMessageEventContent,
                ImageMessageEventContent, TextMessageEventContent, VideoInfo,
                VideoMessageEventContent,
            },
            ImageInfo,
        },
    },
    OwnedMxcUri,
};
use serde::{Deserialize, Serialize};

use super::{Colorize, ObjRef, Update};
use crate::util::deserialize_some;

// if you change the order of these enum variables, enum value will change and parsing of old content will fail
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(untagged)]
pub enum NewsContent {
    /// An image message.
    Image(ImageMessageEventContent),
    /// A text message.
    Text(TextMessageEventContent),
    /// A video message.
    Video(VideoMessageEventContent),
    /// An audio message.
    Audio(AudioMessageEventContent),
    /// A file message.
    File(FileMessageEventContent),
}

impl NewsContent {
    pub fn type_str(&self) -> String {
        match self {
            NewsContent::Audio(_) => "audio".to_owned(),
            NewsContent::File(_) => "file".to_owned(),
            NewsContent::Image(_) => "image".to_owned(),
            NewsContent::Text(_) => "text".to_owned(),
            NewsContent::Video(_) => "video".to_owned(),
        }
    }

    pub fn audio(&self) -> Option<AudioMessageEventContent> {
        match self {
            NewsContent::Audio(content) => Some(content.clone()),
            _ => None,
        }
    }

    pub fn file(&self) -> Option<FileMessageEventContent> {
        match self {
            NewsContent::File(content) => Some(content.clone()),
            _ => None,
        }
    }

    pub fn image(&self) -> Option<ImageMessageEventContent> {
        match self {
            NewsContent::Image(content) => Some(content.clone()),
            _ => None,
        }
    }

    pub fn text(&self) -> Option<TextMessageEventContent> {
        match self {
            NewsContent::Text(content) => Some(content.clone()),
            _ => None,
        }
    }

    pub fn video(&self) -> Option<VideoMessageEventContent> {
        match self {
            NewsContent::Video(content) => Some(content.clone()),
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
}

impl NewsSlide {
    pub fn new_text(body: String) -> Self {
        NewsSlide {
            content: NewsContent::Text(TextMessageEventContent::plain(body)),
            references: vec![],
        }
    }

    pub fn new_image(body: String, url: OwnedMxcUri, info: Option<Box<ImageInfo>>) -> Self {
        NewsSlide {
            content: NewsContent::Image(ImageMessageEventContent::plain(body, url, info)),
            references: vec![],
        }
    }

    pub fn new_audio(body: String, url: OwnedMxcUri, info: Option<Box<AudioInfo>>) -> Self {
        NewsSlide {
            content: NewsContent::Audio(AudioMessageEventContent::plain(body, url, info)),
            references: vec![],
        }
    }

    pub fn new_video(body: String, url: OwnedMxcUri, info: Option<Box<VideoInfo>>) -> Self {
        NewsSlide {
            content: NewsContent::Video(VideoMessageEventContent::plain(body, url, info)),
            references: vec![],
        }
    }

    pub fn new_file(body: String, url: OwnedMxcUri, info: Option<Box<FileInfo>>) -> Self {
        NewsSlide {
            content: NewsContent::File(FileMessageEventContent::plain(body, url, info)),
            references: vec![],
        }
    }
}

/// The payload for our news creation event.
#[derive(Clone, Debug, Builder, Deserialize, Serialize, Getters, EventContent)]
#[ruma_event(type = "global.acter.dev.news", kind = MessageLike)]
#[builder(name = "NewsEntryBuilder", derive(Debug))]
pub struct NewsEntryEventContent {
    /// A news entry may have one or more slides of news
    /// which are scrolled through horizontally
    slides: Vec<NewsSlide>,

    /// You can define custom background and foreground colors
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    colors: Option<Colorize>,
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

    /// You can define custom background and foreground colors
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub colors: Option<Option<Colorize>>,
}

impl NewsEntryUpdateEventContent {
    pub fn apply(&self, task: &mut NewsEntryEventContent) -> crate::Result<bool> {
        let mut updated = false;
        if let Some(slides) = &self.slides {
            task.slides = slides.clone();
            updated = true;
        }
        if let Some(colors) = &self.colors {
            task.colors = colors.clone();
            updated = true;
        }
        Ok(updated)
    }
}
