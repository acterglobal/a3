use derive_builder::Builder;
use derive_getters::Getters;
use matrix_sdk::ruma::events::macros::EventContent;
use serde::{Deserialize, Serialize};

use super::{BelongsTo, References, TextMessageEventContent, Update};

/// Comment Event
#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder, Getters)]
#[ruma_event(type = "global.acter.dev.comment", kind = MessageLike)]
#[builder(name = "CommentBuilder", derive(Debug))]
pub struct CommentEventContent {
    #[builder(setter(into))]
    #[serde(rename = "m.relates_to")]
    pub on: BelongsTo,
    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub reply_to: Option<References>,
    pub content: TextMessageEventContent,
}

/// The Comment Update Event
#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder)]
#[ruma_event(type = "global.acter.dev.comment.update", kind = MessageLike)]
#[builder(name = "CommentUpdateBuilder", derive(Debug))]
pub struct CommentUpdateEventContent {
    #[builder(setter(into))]
    #[serde(rename = "m.relates_to")]
    pub comment: Update,
    pub content: TextMessageEventContent,
}

impl CommentUpdateEventContent {
    pub fn apply(&self, task: &mut CommentEventContent) -> crate::Result<bool> {
        task.content = self.content.clone();
        Ok(true)
    }
}
