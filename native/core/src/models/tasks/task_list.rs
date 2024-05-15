use derive_getters::Getters;
use ruma_common::{EventId, RoomId, UserId};
use ruma_events::OriginalMessageLikeEvent;
use serde::{Deserialize, Serialize};
use std::ops::Deref;
use tracing::{trace, warn};

use super::super::{
    default_model_execute, ActerModel, AnyActerModel, Capability, EventMeta, Store,
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
        format!("{}::{}", self.meta.event_id, KEYS::TASKS::TASKS)
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
                redacted: None,
            },
            task_stats: Default::default(),
        }
    }
}

impl ActerModel for TaskList {
    fn indizes(&self, _user_id: &UserId) -> Vec<String> {
        vec![
            format!("{}::{}", self.meta.room_id, KEYS::TASKS::TASKS),
            KEYS::TASKS::TASKS.to_owned(),
        ]
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }
    fn room_id(&self) -> &RoomId {
        &self.meta.room_id
    }

    fn capabilities(&self) -> &[Capability] {
        &[
            Capability::Commentable,
            Capability::Reactable,
            Capability::Attachmentable,
        ]
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
    fn indizes(&self, _user_id: &UserId) -> Vec<String> {
        vec![format!(
            "tasklist-{:}::history",
            self.inner.task_list.event_id
        )]
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }
    fn room_id(&self) -> &RoomId {
        &self.meta.room_id
    }

    async fn execute(self, store: &Store) -> Result<Vec<String>> {
        default_model_execute(store, self.into()).await
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(vec![self.inner.task_list.event_id.to_string()])
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
                redacted: None,
            },
        }
    }
}
