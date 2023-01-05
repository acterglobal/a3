use super::{BelongsTo, Reference, TextMessageEventContent, Update};
use derive_builder::Builder;
use derive_getters::Getters;
use matrix_sdk::ruma::events::macros::EventContent;
use serde::{Deserialize, Serialize};

/// Comment Event
#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder, Getters)]
#[ruma_event(type = "org.effektio.dev.comment", kind = MessageLike)]
#[builder(name = "CommentBuilder", derive(Debug))]
pub struct CommentEventContent {
    #[builder(setter(into))]
    #[serde(rename = "m.relates_to")]
    pub on: BelongsTo,
    #[builder(setter(into))]
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub reply_to: Vec<Reference>,
    pub text: TextMessageEventContent,
}

/// The Comment Update Event
#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder)]
#[ruma_event(type = "org.effektio.dev.comment.update", kind = MessageLike)]
#[builder(name = "CommentUpdateBuilder", derive(Debug))]
pub struct CommentUpdateEventContent {
    #[builder(setter(into))]
    #[serde(rename = "m.relates_to")]
    pub comment: Update,
    pub text: TextMessageEventContent,
}

impl CommentUpdateEventContent {
    pub fn apply(&self, task: &mut CommentEventContent) -> crate::Result<bool> {
        task.text = self.text.clone();
        Ok(true)
    }
}
