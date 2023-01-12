mod color;
mod comments;
mod faq;
mod news;
mod tag;
mod tasks;

pub use crate::store::Store;
pub use color::Color;
pub use comments::{Comment, CommentUpdate, CommentsManager, CommentsStats};
pub use core::fmt::Debug;
pub use faq::Faq;
use matrix_sdk::ruma::{
    events::{AnySyncTimelineEvent, AnyTimelineEvent, MessageLikeEvent},
    serde::Raw,
    EventId, MilliSecondsSinceUnixEpoch, OwnedEventId, OwnedRoomId, OwnedUserId, RoomId,
};
pub use news::News;
use serde::{Deserialize, Serialize};
pub use tag::Tag;
pub use tasks::{Task, TaskList, TaskListUpdate, TaskStats, TaskUpdate};

use enum_dispatch::enum_dispatch;

use crate::events::{
    comments::{
        OriginalCommentEvent, OriginalCommentUpdateEvent, SyncCommentEvent, SyncCommentUpdateEvent,
    },
    tasks::{
        OriginalTaskEvent, OriginalTaskListEvent, OriginalTaskUpdateEvent, SyncTaskEvent,
        SyncTaskListEvent, SyncTaskUpdateEvent,
    },
};

#[enum_dispatch(AnyEffektioModel)]
pub trait EffektioModel: Debug {
    fn indizes(&self) -> Vec<String>;
    /// The key to store this model under
    fn event_id(&self) -> &EventId;
    /// The models to inform about this model as it belongs to that
    fn belongs_to(&self) -> Option<Vec<String>> {
        None
    }

    /// activate to enable commenting support for this type of model
    fn supports_comments(&self) -> bool {
        false
    }
    /// handle transition
    fn transition(&mut self, model: &AnyEffektioModel) -> crate::Result<bool> {
        tracing::error!(?self, ?model, "Transition has not been implemented");
        Ok(false)
    }
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct EventMeta {
    /// The globally unique event identifier attached to this task
    pub event_id: OwnedEventId,

    /// The fully-qualified ID of the user who sent created this task
    pub sender: OwnedUserId,

    /// Timestamp in milliseconds on originating homeserver when the task was created
    pub origin_server_ts: MilliSecondsSinceUnixEpoch,

    /// The ID of the room of this task
    pub room_id: OwnedRoomId,
}

#[enum_dispatch]
#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum AnyEffektioModel {
    TaskList,
    TaskListUpdate,
    Task,
    TaskUpdate,
    // more generics
    Comment,
    CommentUpdate,
}

impl AnyEffektioModel {
    pub fn is_comment(&self) -> bool {
        matches!(self, AnyEffektioModel::Comment(_))
    }
    pub fn from_raw_tlevent(raw: &Raw<AnyTimelineEvent>) -> Option<Self> {
        let Ok(Some(m_type)) = raw.get_field("type") else {
            return None;
        };

        match m_type {
            "org.effektio.dev.tasklist" => Some(AnyEffektioModel::TaskList(
                raw.deserialize_as::<OriginalTaskListEvent>()
                    .map_err(|error| {
                        tracing::error!(?error, ?raw, "parsing task list event failed")
                    })
                    .ok()?
                    .into(),
            )),
            "org.effektio.dev.task" => Some(AnyEffektioModel::Task(
                raw.deserialize_as::<OriginalTaskEvent>()
                    .map_err(|error| tracing::error!(?error, ?raw, "parsing task event failed"))
                    .ok()?
                    .into(),
            )),
            "org.effektio.dev.task.update" => Some(AnyEffektioModel::TaskUpdate(
                raw.deserialize_as::<OriginalTaskUpdateEvent>()
                    .map_err(|error| {
                        tracing::error!(?error, ?raw, "parsing task update event failed")
                    })
                    .ok()?
                    .into(),
            )),

            // generics

            // comments
            "org.effektio.dev.comment" => Some(AnyEffektioModel::Comment(
                raw.deserialize_as::<OriginalCommentEvent>()
                    .map_err(|error| {
                        tracing::error!(?error, ?raw, "parsing task update event failed")
                    })
                    .ok()?
                    .into(),
            )),
            "org.effektio.dev.comment.update" => Some(AnyEffektioModel::CommentUpdate(
                raw.deserialize_as::<OriginalCommentUpdateEvent>()
                    .map_err(|error| {
                        tracing::error!(?error, ?raw, "parsing task update event failed")
                    })
                    .ok()?
                    .into(),
            )),

            _ => {
                if m_type.starts_with("org.effektio.") {
                    tracing::error!(?raw, "{m_type} not implemented");
                }
                None
            }
        }
    }
    pub fn from_raw_synctlevent(raw: &Raw<AnySyncTimelineEvent>, room_id: &RoomId) -> Option<Self> {
        let Ok(Some(m_type)) = raw.get_field("type") else {
            return None;
        };

        match m_type {
            "org.effektio.dev.tasklist" => match raw
                .deserialize_as::<SyncTaskListEvent>()
                .map_err(|error| tracing::error!(?error, ?raw, "parsing task list event failed"))
                .ok()?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Some(AnyEffektioModel::TaskList(t.into())),
                _ => None,
            },
            "org.effektio.dev.task" => match raw
                .deserialize_as::<SyncTaskEvent>()
                .map_err(|error| tracing::error!(?error, ?raw, "parsing task event failed"))
                .ok()?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Some(AnyEffektioModel::Task(t.into())),
                _ => None,
            },
            "org.effektio.dev.task.update" => match raw
                .deserialize_as::<SyncTaskUpdateEvent>()
                .map_err(|error| tracing::error!(?error, ?raw, "parsing task update event failed"))
                .ok()?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Some(AnyEffektioModel::TaskUpdate(t.into())),
                _ => None,
            },

            // generic

            // comments
            "org.effektio.dev.comment" => match raw
                .deserialize_as::<SyncCommentEvent>()
                .map_err(|error| tracing::error!(?error, ?raw, "parsing task update event failed"))
                .ok()?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Some(AnyEffektioModel::Comment(t.into())),
                _ => None,
            },
            "org.effektio.dev.comment.update" => match raw
                .deserialize_as::<SyncCommentUpdateEvent>()
                .map_err(|error| tracing::error!(?error, ?raw, "parsing task update event failed"))
                .ok()?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Some(AnyEffektioModel::CommentUpdate(t.into())),
                _ => None,
            },

            // unimplemented cases
            _ => {
                if m_type.starts_with("org.effektio.") {
                    tracing::error!(?raw, "{m_type} not implemented");
                }
                None
            }
        }
    }
}

#[cfg(feature = "with-mocks")]
pub mod mocks {
    pub use super::color::mocks::ColorFaker;
    pub use super::faq::gen_mocks as gen_mock_faqs;
    pub use super::news::gen_mocks as gen_mock_news;
}

#[cfg(test)]
mod test {
    use super::*;
    use crate::Result;
    use serde_json;
    #[test]
    fn ensure_minimal_tasklist_parses() -> Result<()> {
        let json_raw = r#"{"type":"org.effektio.dev.tasklist",
            "room_id":"!euhIDqDVvVXulrhWgN:ds9.effektio.org","sender":"@odo:ds9.effektio.org",
            "content":{"name":"Daily Security Brief"},"origin_server_ts":1672407531453,
            "unsigned":{"age":11523850},
            "event_id":"$KwumA4L3M-duXu0I3UA886LvN-BDCKAyxR1skNfnh3c",
            "user_id":"@odo:ds9.effektio.org","age":11523850}"#;
        let event = serde_json::from_str::<Raw<AnyTimelineEvent>>(json_raw)?;
        let _effektio_ev = AnyEffektioModel::from_raw_tlevent(&event).unwrap();
        // assert!(matches!(event, AnyCreation::TaskList(_)));
        Ok(())
    }
}
