use std::ops::Deref;

use crate::{
    events::tasks::{
        TaskEventContent, TaskListEventContent, TaskListUpdateBuilder, TaskListUpdateEventContent,
        TaskUpdateBuilder, TaskUpdateEventContent,
    },
    statics::KEYS,
};
use matrix_sdk::ruma::{events::OriginalMessageLikeEvent, EventId, RoomId};
use serde::{Deserialize, Serialize};

use super::AnyEffektioModel;

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Task {
    inner: OriginalMessageLikeEvent<TaskEventContent>,
}
impl Deref for Task {
    type Target = TaskEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner.content
    }
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

    pub fn event_id(&self) -> &EventId {
        &self.inner.event_id
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
        Self::key_from_event(&self.inner.event_id)
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

        update.apply(&mut self.inner.content)
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
        Self::key_from_event(&self.inner.event_id)
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
    type Target = TaskUpdateEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner.content
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
    type Target = TaskListEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner.content
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
    pub fn event_id(&self) -> &EventId {
        &self.inner.event_id
    }
    pub fn room_id(&self) -> &RoomId {
        &self.inner.room_id
    }
    pub fn updater(&self) -> TaskListUpdateBuilder {
        TaskListUpdateBuilder::default()
            .task_list(self.inner.event_id.to_owned())
            .to_owned()
    }
}

impl super::EffektioModel for TaskList {
    fn indizes(&self) -> Vec<String> {
        vec![KEYS::TASKS.to_owned()]
    }

    fn key(&self) -> String {
        Self::key_from_event(&self.inner.event_id)
    }

    fn transition(&mut self, model: &super::AnyEffektioModel) -> crate::Result<bool> {
        match model {
            super::AnyEffektioModel::TaskListUpdate(update) => {
                update.apply(&mut self.inner.content)
            }
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
    inner: OriginalMessageLikeEvent<TaskListUpdateEventContent>,
}

impl super::EffektioModel for TaskListUpdate {
    fn indizes(&self) -> Vec<String> {
        vec![format!(
            "tasklist-{:}::history",
            self.inner.content.task_list.event_id
        )]
    }

    fn key(&self) -> String {
        Self::key_from_event(&self.inner.event_id)
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(vec![TaskList::key_from_event(
            &self.inner.content.task_list.event_id,
        )])
    }
}

impl TaskListUpdate {
    fn key_from_event(event_id: &EventId) -> String {
        format!("task_list-update-{event_id}")
    }
}

impl Deref for TaskListUpdate {
    type Target = TaskListUpdateEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner.content
    }
}

impl From<OriginalMessageLikeEvent<TaskListUpdateEventContent>> for TaskListUpdate {
    fn from(inner: OriginalMessageLikeEvent<TaskListUpdateEventContent>) -> Self {
        TaskListUpdate { inner }
    }
}
