use super::Colorize;
use matrix_sdk::ruma::events::macros::EventContent;
use matrix_sdk::ruma::events::room::message::{
    ImageMessageEventContent, TextMessageEventContent, VideoMessageEventContent,
};
use serde::{Deserialize, Serialize};

/// The content that is specific to each message type variant.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(untagged)]
#[cfg_attr(not(feature = "unstable-exhaustive-types"), non_exhaustive)]
pub enum NewsContentType {
    /// An image message.
    Image(ImageMessageEventContent),
    /// A text message.
    Text(TextMessageEventContent),
    /// A video message.
    Video(VideoMessageEventContent),
}

/// The payload for our news event.
#[derive(Clone, Debug, Deserialize, Serialize, EventContent)]
#[ruma_event(type = "org.effektio.dev.news", kind = Message)]
pub struct NewsEventDevContent {
    pub contents: Vec<NewsContentType>,
    pub colors: Option<Colorize>,
}

/// The content that is specific to each news type variant.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(untagged)]
#[cfg_attr(not(feature = "unstable-exhaustive-types"), non_exhaustive)]
pub enum NewsEvent {
    Dev(NewsEventDevContent),
}
