use std::ops::Deref;

use crate::events::comments::{
    CommentEventContent, CommentUpdateBuilder, CommentUpdateEventContent,
};
use matrix_sdk::ruma::{
    events::OriginalMessageLikeEvent, EventId, MilliSecondsSinceUnixEpoch, OwnedEventId,
    OwnedRoomId, OwnedUserId,
};
use serde::{Deserialize, Serialize};

use super::AnyEffektioModel;

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Comment {
    inner: CommentEventContent,

    /// The globally unique event identifier attached to this task
    pub event_id: OwnedEventId,

    /// The fully-qualified ID of the user who sent created this task
    pub sender: OwnedUserId,

    /// Timestamp in milliseconds on originating homeserver when the task was created
    pub origin_server_ts: MilliSecondsSinceUnixEpoch,

    /// The ID of the room of this task
    pub room_id: OwnedRoomId,
}
impl Deref for Comment {
    type Target = CommentEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl Comment {
    pub fn event_id(&self) -> &EventId {
        &self.event_id
    }

    pub fn updater(&self) -> CommentUpdateBuilder {
        CommentUpdateBuilder::default()
            .comment(self.event_id.clone())
            .to_owned()
    }

    pub fn key_from_event(event_id: &EventId) -> String {
        event_id.to_string()
    }
}

impl super::EffektioModel for Comment {
    fn indizes(&self) -> Vec<String> {
        self.belongs_to()
            .unwrap() // we always have some as comments
            .into_iter()
            .map(|v| format!("{v}::comments"))
            .collect()
    }

    fn key(&self) -> String {
        Self::key_from_event(&self.event_id)
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        let mut references = self
            .inner
            .reply_to
            .iter()
            .map(|e| e.event_id.to_string())
            .collect::<Vec<_>>();
        references.push(self.inner.on.event_id.to_string());
        Some(references)
    }

    fn transition(&mut self, model: &super::AnyEffektioModel) -> crate::Result<bool> {
        let AnyEffektioModel::CommentUpdate(update) = model else {
            return Ok(false)
        };

        update.apply(&mut self.inner)
    }
}

impl From<OriginalMessageLikeEvent<CommentEventContent>> for Comment {
    fn from(outer: OriginalMessageLikeEvent<CommentEventContent>) -> Self {
        let OriginalMessageLikeEvent {
            content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = outer;
        Comment {
            inner: content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
        }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct CommentUpdate {
    inner: CommentUpdateEventContent,

    /// The globally unique event identifier attached to this task update
    pub event_id: OwnedEventId,

    /// The fully-qualified ID of the user who sent created this task update
    pub sender: OwnedUserId,

    /// Timestamp in milliseconds on originating homeserver when the task update was created
    pub origin_server_ts: MilliSecondsSinceUnixEpoch,

    /// The ID of the room of this task update
    pub room_id: OwnedRoomId,
}

impl super::EffektioModel for CommentUpdate {
    fn indizes(&self) -> Vec<String> {
        vec![format!("{:}::history", self.inner.comment.event_id)]
    }

    fn key(&self) -> String {
        Self::key_from_event(&self.event_id)
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(vec![Comment::key_from_event(&self.inner.comment.event_id)])
    }
}

impl CommentUpdate {
    fn key_from_event(event_id: &EventId) -> String {
        event_id.to_string()
    }
}

impl Deref for CommentUpdate {
    type Target = CommentUpdateEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl From<OriginalMessageLikeEvent<CommentUpdateEventContent>> for CommentUpdate {
    fn from(outer: OriginalMessageLikeEvent<CommentUpdateEventContent>) -> Self {
        let OriginalMessageLikeEvent {
            content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = outer;
        CommentUpdate {
            inner: content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
        }
    }
}
