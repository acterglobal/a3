use super::TextMessageEventContent;
use matrix_sdk::ruma::events::macros::EventContent;
use serde::{Deserialize, Serialize};

/// The payload for our Comment event.
#[derive(Clone, Debug, Deserialize, Serialize, EventContent)]
#[ruma_event(type = "org.effektio.dev.comment", kind = MessageLike)]
pub struct CommentEventDevContent {
    pub text: TextMessageEventContent,
}

/// The content that is specific to each Comment type variant.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(untagged)]
#[cfg_attr(not(feature = "unstable-exhaustive-types"), non_exhaustive)]
pub enum CommentEvent {
    Dev(CommentEventDevContent),
}
