use std::ops::Deref;

use crate::{
    events::tasks::{TaskEventContent, TaskListEventContent},
    statics::KEYS,
};
use matrix_sdk::ruma::{events::OriginalMessageLikeEvent, OwnedEventId, OwnedRoomId};
use serde::{Deserialize, Serialize};

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
}

impl super::EffektioModel for Task {
    /// The indizes this model should be added to
    fn indizes(&self) -> Vec<String> {
        vec![]
    }
    /// The key to store this model under
    fn key(&self) -> String {
        format!("task-{:}", self.event_id)
    }
    /// The models to inform about this model as it belongs to that
    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(vec![format!(
            "tasklist-{:}",
            self.inner.content.task_list_id.event_id
        )])
    }
    /// handle transition
    fn transition(&mut self, model: &super::AnyEffektioModel) -> crate::Result<bool> {
        unimplemented!("not yet existing")
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
pub struct TaskList {
    inner: OriginalMessageLikeEvent<TaskListEventContent>,
    pub tasks: Vec<Task>,
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
    pub fn name(&self) -> &String {
        &self.inner.content.name
    }
}

impl super::EffektioModel for TaskList {
    /// The indizes this model should be added to
    fn indizes(&self) -> Vec<String> {
        vec![KEYS::TASKS.to_owned()]
    }
    /// The key to store this model under
    fn key(&self) -> String {
        format!("tasklist-{:}", self.inner.event_id)
    }
    /// handle transition
    fn transition(&mut self, model: &super::AnyEffektioModel) -> crate::Result<bool> {
        let super::AnyEffektioModel::Task(task) = model else {
            return Ok(false)
        };

        tracing::trace!(key = self.key(), ?task, "adding task to list");

        self.tasks.push(task.clone().into());
        Ok(true)
    }
}
