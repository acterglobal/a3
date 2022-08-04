use crate::events::tasks::{TaskEventContent, TaskListEventContent};
use matrix_sdk::ruma::{events::OriginalMessageLikeEvent, OwnedEventId, OwnedRoomId};
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct TaskList {
    inner: OriginalMessageLikeEvent<TaskListEventContent>,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Task {
    inner: OriginalMessageLikeEvent<TaskEventContent>,
    tasks: Vec<TaskList>,
}

impl TaskList {
    pub fn redacted(&self) -> bool {
        false
    }
    pub fn event_id(&self) -> OwnedEventId {
        self.inner.event_id.clone()
    }
    pub fn room_id(&self) -> OwnedRoomId {
        self.inner.room_id.clone()
    }
    pub fn name(&self) -> Option<String> {
        Some(self.inner.content.name.clone())
    }
}
