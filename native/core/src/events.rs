use matrix_sdk::ruma::{
    self,
    events::{
        macros::EventContent,
        SyncMessageEvent,
        room::message::{
            ImageMessageEventContent,
            TextMessageEventContent,
            VideoMessageEventContent,
        }
    },
    identifiers::EventId,
};
use serde::{Deserialize, Serialize};

/// Customize the color scheme
#[derive(Clone, Debug, Deserialize, Serialize, EventContent)]
#[ruma_event(type = "org.effektio.dev.colors")]
pub struct Colorize {
    /// The foreground color to be used, as HEX
    pub color: String,
    /// The background color to be used, as HEX
    pub background: String,
}

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
    Dev(NewsEventDevContent)
}