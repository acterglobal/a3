use derive_getters::Getters;
use matrix_sdk::ruma::{events::OriginalMessageLikeEvent, EventId, RoomId};
use serde::{Deserialize, Serialize};
use std::ops::Deref;
use tracing::{trace, warn};

use super::{
    super::{default_model_execute, ActerModel, AnyActerModel, Capability, EventMeta, Store},
    TASKS_KEY,
};
use crate::{
    events::tasks::{TaskListEventContent, TaskListUpdateBuilder, TaskListUpdateEventContent},
    statics::KEYS,
    Result,
};

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

impl ActerModel for TaskList {
    fn indizes(&self) -> Vec<String> {
        vec![
            format!("{}::{}", self.meta.room_id, KEYS::TASKS),
            KEYS::TASKS.to_owned(),
        ]
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }

    fn capabilities(&self) -> &[Capability] {
        &[Capability::Commentable]
    }

    async fn execute(self, store: &Store) -> Result<Vec<String>> {
        default_model_execute(store, self.into()).await
    }

    fn transition(&mut self, model: &AnyActerModel) -> Result<bool> {
        match model {
            AnyActerModel::TaskListUpdate(update) => update.apply(&mut self.inner),
            AnyActerModel::Task(task) => {
                let key = self.event_id().to_owned();
                trace!(?key, ?task, "adding task to list");
                self.task_stats.tasks_count += 1;
                self.task_stats.has_tasks = true;
                Ok(true)
            }
            _ => {
                warn!(?model, "Trying to transition with an unknown model");
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

impl ActerModel for TaskListUpdate {
    fn indizes(&self) -> Vec<String> {
        vec![format!(
            "tasklist-{:}::history",
            self.inner.task_list.event_id
        )]
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }

    async fn execute(self, store: &Store) -> Result<Vec<String>> {
        default_model_execute(store, self.into()).await
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
