use derive_getters::Getters;
use matrix_sdk::ruma::{events::OriginalMessageLikeEvent, EventId, OwnedUserId, RoomId};
use serde::{Deserialize, Serialize};
use std::ops::Deref;

use super::{AnyEffektioModel, EventMeta};

use crate::{
    events::tasks::{
        TaskEventContent, TaskListEventContent, TaskListUpdateBuilder, TaskListUpdateEventContent,
        TaskUpdateBuilder, TaskUpdateEventContent,
    },
    statics::KEYS,
};

static TASKS_KEY: &str = KEYS::TASKS;

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Task {
    inner: TaskEventContent,
    meta: EventMeta,
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

    pub fn subscribers(&self) -> Vec<OwnedUserId> {
        self.inner.subscribers.clone()
    }

    pub fn room_id(&self) -> &RoomId {
        &self.meta.room_id
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

    pub fn updater(&self) -> TaskUpdateBuilder {
        TaskUpdateBuilder::default()
            .task(self.meta.event_id.clone())
            .to_owned()
    }

    pub fn key_from_event(event_id: &EventId) -> String {
        event_id.to_string()
    }
}

impl super::EffektioModel for Task {
    fn indizes(&self) -> Vec<String> {
        vec![format!("{}::{TASKS_KEY}", self.inner.task_list_id.event_id)]
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }

    fn capabilities(&self) -> &[super::Capability] {
        &[super::Capability::Commentable]
    }

    async fn execute(self, store: &super::Store) -> crate::Result<Vec<String>> {
        super::default_model_execute(store, self.into()).await
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
            meta: EventMeta {
                room_id,
                event_id,
                sender,
                origin_server_ts,
            },
        }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct TaskUpdate {
    inner: TaskUpdateEventContent,
    meta: EventMeta,
}

impl super::EffektioModel for TaskUpdate {
    fn indizes(&self) -> Vec<String> {
        vec![format!("{:}::history", self.inner.task.event_id)]
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }

    async fn execute(self, store: &super::Store) -> crate::Result<Vec<String>> {
        super::default_model_execute(store, self.into()).await
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(vec![Task::key_from_event(&self.inner.task.event_id)])
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
            meta: EventMeta {
                room_id,
                event_id,
                sender,
                origin_server_ts,
            },
        }
    }
}
#[derive(Clone, Debug, Default, Deserialize, Serialize, Getters)]
pub struct TaskStats {
    has_tasks: bool,
    tasks_count: u32,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct TaskList {
    inner: TaskListEventContent,
    meta: EventMeta,
    task_stats: TaskStats,
}

impl Deref for TaskList {
    type Target = TaskListEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl TaskList {
    pub fn room_id(&self) -> &RoomId {
        &self.meta.room_id
    }
    pub fn stats(&self) -> &TaskStats {
        &self.task_stats
    }

    pub fn tasks_key(&self) -> String {
        format!("{}::{TASKS_KEY}", self.meta.event_id)
    }

    pub fn key_from_event(event_id: &EventId) -> String {
        event_id.to_string()
    }

    pub fn redacted(&self) -> bool {
        false
    }

    pub fn updater(&self) -> TaskListUpdateBuilder {
        TaskListUpdateBuilder::default()
            .task_list(self.meta.event_id.to_owned())
            .to_owned()
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
            meta: EventMeta {
                room_id,
                event_id,
                sender,
                origin_server_ts,
            },
            task_stats: Default::default(),
        }
    }
}

impl super::EffektioModel for TaskList {
    fn indizes(&self) -> Vec<String> {
        vec![
            format!("{}::{}", self.meta.room_id, KEYS::TASKS),
            KEYS::TASKS.to_owned(),
        ]
    }
    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }

    fn capabilities(&self) -> &[super::Capability] {
        &[super::Capability::Commentable]
    }

    async fn execute(self, store: &super::Store) -> crate::Result<Vec<String>> {
        super::default_model_execute(store, self.into()).await
    }

    fn transition(&mut self, model: &super::AnyEffektioModel) -> crate::Result<bool> {
        match model {
            super::AnyEffektioModel::TaskListUpdate(update) => update.apply(&mut self.inner),
            super::AnyEffektioModel::Task(task) => {
                let key = self.event_id().to_owned();
                tracing::trace!(?key, ?task, "adding task to list");
                self.task_stats.tasks_count += 1;
                self.task_stats.has_tasks = true;
                Ok(true)
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
    meta: EventMeta,
}

impl super::EffektioModel for TaskListUpdate {
    fn indizes(&self) -> Vec<String> {
        vec![format!(
            "tasklist-{:}::history",
            self.inner.task_list.event_id
        )]
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }

    async fn execute(self, store: &super::Store) -> crate::Result<Vec<String>> {
        super::default_model_execute(store, self.into()).await
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(vec![TaskList::key_from_event(
            &self.inner.task_list.event_id,
        )])
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
            meta: EventMeta {
                room_id,
                event_id,
                sender,
                origin_server_ts,
            },
        }
    }
}
