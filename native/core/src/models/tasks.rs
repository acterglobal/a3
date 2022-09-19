use std::ops::Deref;

use crate::events::tasks::{TaskEventContent, TaskListEventContent};
use matrix_sdk::ruma::{events::OriginalMessageLikeEvent, OwnedEventId, OwnedRoomId};
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Task {
    inner: OriginalMessageLikeEvent<TaskEventContent>,
}

impl Deref for Task {
    type Target = OriginalMessageLikeEvent<TaskEventContent>;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct TaskList {
    inner: OriginalMessageLikeEvent<TaskListEventContent>,
    tasks: Vec<Task>,
}

impl Deref for TaskList {
    type Target = OriginalMessageLikeEvent<TaskListEventContent>;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl From<OriginalMessageLikeEvent<TaskListEventContent>> for TaskList {
    fn from(inner: OriginalMessageLikeEvent<TaskListEventContent>) -> Self {
        TaskList {
            inner,
            tasks: Default::default(),
        }
    }
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
