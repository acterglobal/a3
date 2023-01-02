use std::ops::Deref;

use crate::{
    events::tasks::{
        TaskEventContent, TaskListEventContent, TaskUpdateBuilder, TaskUpdateEventContent,
    },
    statics::KEYS,
};
use matrix_sdk::ruma::{events::OriginalMessageLikeEvent, EventId, OwnedEventId, OwnedRoomId};
use serde::{Deserialize, Serialize};

use super::AnyEffektioModel;

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Task {
    inner: OriginalMessageLikeEvent<TaskEventContent>,
}

impl Task {
    pub fn title(&self) -> &String {
        &self.inner.content.title
    }

    pub fn is_done(&self) -> bool {
        self.inner
            .content
            .progress_percent
            .map(|u| u >= 100)
            .unwrap_or_default()
    }

    pub fn percent(&self) -> Option<u8> {
        self.inner.content.progress_percent
    }

    pub fn updater(&self) -> TaskUpdateBuilder {
        TaskUpdateBuilder::default()
            .task(self.inner.event_id.to_owned())
            .to_owned()
    }

    pub fn key_from_event(event_id: &EventId) -> String {
        format!("task-{event_id}")
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
            &self.inner.content.task_list_id.event_id,
        )])
    }

    fn transition(&mut self, model: &super::AnyEffektioModel) -> crate::Result<bool> {
        let AnyEffektioModel::TaskUpdate(update) = model else {
            return Ok(false)
        };

        update.content.apply(&mut self.inner.content)
    }
}

impl Deref for Task {
    type Target = OriginalMessageLikeEvent<TaskEventContent>;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl From<OriginalMessageLikeEvent<TaskEventContent>> for Task {
    fn from(inner: OriginalMessageLikeEvent<TaskEventContent>) -> Self {
        Task { inner }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct TaskUpdate {
    inner: OriginalMessageLikeEvent<TaskUpdateEventContent>,
}

impl super::EffektioModel for TaskUpdate {
    fn indizes(&self) -> Vec<String> {
        vec![format!(
            "task-{:}::history",
            self.inner.content.task.event_id
        )]
    }

    fn key(&self) -> String {
        Self::key_from_event(&self.event_id)
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(vec![Task::key_from_event(
            &self.inner.content.task.event_id,
        )])
    }
}

impl TaskUpdate {
    fn key_from_event(event_id: &EventId) -> String {
        format!("task-update-{event_id}")
    }
}

impl Deref for TaskUpdate {
    type Target = OriginalMessageLikeEvent<TaskUpdateEventContent>;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl From<OriginalMessageLikeEvent<TaskUpdateEventContent>> for TaskUpdate {
    fn from(inner: OriginalMessageLikeEvent<TaskUpdateEventContent>) -> Self {
        TaskUpdate { inner }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct TaskList {
    inner: OriginalMessageLikeEvent<TaskListEventContent>,
    pub tasks: Vec<String>,
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
    pub fn key_from_event(event_id: &EventId) -> String {
        format!("tasklist-{event_id}")
    }
    pub fn redacted(&self) -> bool {
        false
    }
    pub fn event_id(&self) -> OwnedEventId {
        self.inner.event_id.clone()
    }
    pub fn room_id(&self) -> OwnedRoomId {
        self.inner.room_id.clone()
    }
    pub fn name(&self) -> &String {
        &self.inner.content.name
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
        let super::AnyEffektioModel::Task(task) = model else {
            return Ok(false)
        };

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
}
