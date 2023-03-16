use crate::util::deserialize_some;
use derive_getters::Getters;
use derive_builder::Builder;
use matrix_sdk::ruma::events::macros::EventContent;
use serde::{Deserialize, Serialize};

use super::{
    Colorize, ImageMessageEventContent, ObjRef, TextMessageEventContent, Update,
    VideoMessageEventContent,
};

/// The content that is specific to
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(untagged)]
pub enum NewsContent {
    /// An image message.
    Image(ImageMessageEventContent),
    /// A text message.
    Text(TextMessageEventContent),
    /// A video message.
    Video(VideoMessageEventContent),
}

impl NewsContent {
    pub fn type_str(&self) -> String {
        match self {
            NewsContent::Image(_) => "image".to_owned(),
            NewsContent::Text(_) => "text".to_owned(),
            NewsContent::Video(_) => "video".to_owned(),
        }
    }

    pub fn image(&self) -> Option<ImageMessageEventContent> {
        let NewsContent::Image(i) = self else {
            return None;
        };
        Some(i.clone())
    }
    
    pub fn text(&self) -> Option<TextMessageEventContent> {
        let NewsContent::Text(i) = self else {
            return None;
        };
        Some(i.clone())
    }

    pub fn video(&self) -> Option<VideoMessageEventContent> {
        let NewsContent::Video(i) = self else {
            return None;
        };
        Some(i.clone())
    }
}

/// A news slide represents one full-sized slide of news
#[derive(Clone, Debug, Builder, Deserialize, Getters,Serialize)]
pub struct NewsSlide {
    /// A slide must contain some news-worthy content
    #[serde(flatten)]
    content: NewsContent,
    /// A slide may optionally contain references to other items
    #[builder(default)]
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    references: Vec<ObjRef>,
}

/// The payload for our news event.
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

/// The payload for our news event.
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
