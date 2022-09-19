pub use matrix_sdk::ruma::{
    events::room::message::{
        ImageMessageEventContent, TextMessageEventContent, VideoMessageEventContent,
    },
    EventId,
};

mod comments;
mod common;
mod labels;
mod news;
pub mod tasks;

pub use comments::{CommentEvent, CommentEventDevContent};
pub use common::{BelongsTo, Color, Colorize, TimeZone, UtcDateTime};
pub use labels::Labels;
pub use news::{NewsContentType, NewsEvent, NewsEventDevContent};
use serde::{Deserialize, Serialize};

use crate::models::AnyEffektioModel;

#[derive(Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum AnyBelongTo {
    Task(tasks::OriginalTaskEvent),
}

impl AnyBelongTo {
    pub fn belongs_to(&self) -> &EventId {
        match self {
            AnyBelongTo::Task(t) => t.content.task_list_id.event_id.as_ref(),
        }
    }
}

#[derive(Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum AnyCreation {
    TaskList(tasks::OriginalTaskListEvent),
}

#[derive(Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum AnyEffektioEvent {
    BelongsTo(AnyBelongTo),
    Creation(AnyCreation),
}

impl AnyEffektioEvent {
    pub fn belongs_to(&self) -> Option<&AnyBelongTo> {
        if let AnyEffektioEvent::BelongsTo(b) = self {
            Some(b)
        } else {
            None
        }
    }
    pub fn create(self) -> Option<AnyEffektioModel> {
        if let AnyEffektioEvent::Creation(create) = self {
            Some(create.into())
        } else {
            None
        }
    }
}
