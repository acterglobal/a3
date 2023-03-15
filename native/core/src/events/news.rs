use matrix_sdk::ruma::events::macros::EventContent;
use serde::{Deserialize, Serialize};

use super::{
    Colorize, ImageMessageEventContent, ObjRef, TextMessageEventContent, VideoMessageEventContent,
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

/// A news slide represents one full-sized slide of news
#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct NewsSlide {
    /// A slide must contain some news-worthy content
    #[serde(flatten)]
    content: NewsContent,
    /// A slide may optionally contain references to other items
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    references: Vec<ObjRef>,
}

/// The payload for our news event.
#[derive(Clone, Debug, Default, Deserialize, Serialize, EventContent)]
#[ruma_event(type = "global.acter.dev.news", kind = MessageLike)]
pub struct NewsEntryEventContent {
    /// A news entry may have one or more slides of news
    /// which are scrolled through horizontally
    pub slides: Vec<NewsSlide>,
    /// You can define custom background and foreground colors
    pub colors: Option<Colorize>,
}
