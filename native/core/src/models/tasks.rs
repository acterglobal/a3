use std::ops::Deref;

use crate::{
    events::tasks::{
        TaskEventContent, TaskListEventContent, TaskListUpdateBuilder, TaskListUpdateEventContent,
        TaskUpdateBuilder, TaskUpdateEventContent,
    },
    statics::KEYS,
};
use matrix_sdk::ruma::{
    events::OriginalMessageLikeEvent, EventId, MilliSecondsSinceUnixEpoch, OwnedEventId,
    OwnedRoomId, OwnedUserId, RoomId,
};
use serde::{Deserialize, Serialize};

use super::AnyEffektioModel;

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Task {
    inner: TaskEventContent,

    /// The globally unique event identifier attached to this task
    pub event_id: OwnedEventId,

    /// The fully-qualified ID of the user who sent created this task
    pub sender: OwnedUserId,

    /// Timestamp in milliseconds on originating homeserver when the task was created
    pub origin_server_ts: MilliSecondsSinceUnixEpoch,

    /// The ID of the room of this task
    pub room_id: OwnedRoomId,
}
impl Deref for Task {
    type Target = TaskEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl Task {
    pub fn title(&self) -> &String {
        &self.inner.title
    }

    pub fn is_done(&self) -> bool {
        self.inner
            .progress_percent
            .map(|u| u >= 100)
            .unwrap_or_default()
    }

    pub fn percent(&self) -> Option<u8> {
        self.inner.progress_percent
    }

    pub fn event_id(&self) -> &EventId {
        &self.event_id
    }

    pub fn updater(&self) -> TaskUpdateBuilder {
        TaskUpdateBuilder::default()
            .task(self.event_id.clone())
            .to_owned()
    }

    pub fn key_from_event(event_id: &EventId) -> String {
        event_id.to_string()
    }
}

impl super::EffektioModel for Task {
    fn indizes(&self) -> Vec<String> {
        vec![]
    }

    fn key(&self) -> String {
        Self::key_from_event(&self.event_id)
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(vec![TaskList::key_from_event(
            &self.inner.task_list_id.event_id,
        )])
    }

    fn transition(&mut self, model: &super::AnyEffektioModel) -> crate::Result<bool> {
        let AnyEffektioModel::TaskUpdate(update) = model else {
            return Ok(false)
        };

        update.apply(&mut self.inner)
    }
}

impl From<OriginalMessageLikeEvent<TaskEventContent>> for Task {
    fn from(outer: OriginalMessageLikeEvent<TaskEventContent>) -> Self {
        let OriginalMessageLikeEvent {
            content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = outer;
        Task {
            inner: content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
        }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct TaskUpdate {
    inner: TaskUpdateEventContent,

    /// The globally unique event identifier attached to this task update
    pub event_id: OwnedEventId,

    /// The fully-qualified ID of the user who sent created this task update
    pub sender: OwnedUserId,

    /// Timestamp in milliseconds on originating homeserver when the task update was created
    pub origin_server_ts: MilliSecondsSinceUnixEpoch,

    /// The ID of the room of this task update
    pub room_id: OwnedRoomId,
}

impl super::EffektioModel for TaskUpdate {
    fn indizes(&self) -> Vec<String> {
        vec![format!("{:}::history", self.inner.task.event_id)]
    }

    fn key(&self) -> String {
        Self::key_from_event(&self.event_id)
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(vec![Task::key_from_event(&self.inner.task.event_id)])
    }
}

impl TaskUpdate {
    fn key_from_event(event_id: &EventId) -> String {
        event_id.to_string()
    }
}

impl Deref for TaskUpdate {
    type Target = TaskUpdateEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl From<OriginalMessageLikeEvent<TaskUpdateEventContent>> for TaskUpdate {
    fn from(outer: OriginalMessageLikeEvent<TaskUpdateEventContent>) -> Self {
        let OriginalMessageLikeEvent {
            content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = outer;
        TaskUpdate {
            inner: content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
        }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct TaskList {
    inner: TaskListEventContent,

    /// The globally unique event identifier attached to this task
    pub event_id: OwnedEventId,

    /// The fully-qualified ID of the user who sent created this task
    pub sender: OwnedUserId,

    /// Timestamp in milliseconds on originating homeserver when the task was created
    pub origin_server_ts: MilliSecondsSinceUnixEpoch,

    /// The ID of the room of this task
    pub room_id: OwnedRoomId,
    pub tasks: Vec<String>,
}

impl Deref for TaskList {
    type Target = TaskListEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl From<OriginalMessageLikeEvent<TaskListEventContent>> for TaskList {
    fn from(outer: OriginalMessageLikeEvent<TaskListEventContent>) -> Self {
        let OriginalMessageLikeEvent {
            content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = outer;
        TaskList {
            inner: content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
            tasks: Default::default(),
        }
    }
}

impl TaskList {
    pub fn key_from_event(event_id: &EventId) -> String {
        event_id.to_string()
    }
    pub fn redacted(&self) -> bool {
        false
    }
    pub fn event_id(&self) -> &EventId {
        &self.event_id
    }
    pub fn room_id(&self) -> &RoomId {
        &self.room_id
    }
    pub fn updater(&self) -> TaskListUpdateBuilder {
        TaskListUpdateBuilder::default()
            .task_list(self.event_id.to_owned())
            .to_owned()
    }
}

impl super::EffektioModel for TaskList {
    fn indizes(&self) -> Vec<String> {
        vec![KEYS::TASKS.to_owned()]
    }

    fn key(&self) -> String {
        Self::key_from_event(&self.event_id)
    }

    fn transition(&mut self, model: &super::AnyEffektioModel) -> crate::Result<bool> {
        match model {
            super::AnyEffektioModel::TaskListUpdate(update) => update.apply(&mut self.inner),
            super::AnyEffektioModel::Task(task) => {
                tracing::trace!(key = self.key(), ?task, "adding task to list");
                let key = task.key();

                if !self.tasks.iter().any(|k| k == &key) {
                    // new item, add it
                    self.tasks.push(key);
                    Ok(true)
                } else {
                    Ok(false)
                }
            }
            _ => {
                tracing::warn!(?model, "Trying to transition with an unknown model");
                Ok(false)
            }
        }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct TaskListUpdate {
    inner: TaskListUpdateEventContent,

    /// The globally unique event identifier attached to this task
    pub event_id: OwnedEventId,

    /// The fully-qualified ID of the user who sent created this task
    pub sender: OwnedUserId,

    /// Timestamp in milliseconds on originating homeserver when the task was created
    pub origin_server_ts: MilliSecondsSinceUnixEpoch,

    /// The ID of the room of this task
    pub room_id: OwnedRoomId,
}

impl super::EffektioModel for TaskListUpdate {
    fn indizes(&self) -> Vec<String> {
        vec![format!(
            "tasklist-{:}::history",
            self.inner.task_list.event_id
        )]
    }

    fn key(&self) -> String {
        Self::key_from_event(&self.event_id)
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(vec![TaskList::key_from_event(
            &self.inner.task_list.event_id,
        )])
    }
}

impl TaskListUpdate {
    fn key_from_event(event_id: &EventId) -> String {
        event_id.to_string()
    }
}

impl Deref for TaskListUpdate {
    type Target = TaskListUpdateEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl From<OriginalMessageLikeEvent<TaskListUpdateEventContent>> for TaskListUpdate {
    fn from(outer: OriginalMessageLikeEvent<TaskListUpdateEventContent>) -> Self {
        let OriginalMessageLikeEvent {
            content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = outer;
        TaskListUpdate {
            inner: content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
        }
    }
}
