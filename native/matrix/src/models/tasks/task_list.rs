use derive_getters::Getters;
use matrix_sdk::ruma::OwnedEventId;
use matrix_sdk_base::ruma::{events::OriginalMessageLikeEvent, RoomId, UserId};
use serde::{Deserialize, Serialize};
use std::ops::Deref;
use tracing::{trace, warn};

use super::super::{
    default_model_execute, ActerModel, AnyActerModel, Capability, EventMeta, Store,
};
use crate::{
    events::tasks::{TaskListEventContent, TaskListUpdateBuilder, TaskListUpdateEventContent},
    referencing::{ExecuteReference, IndexKey, ObjectListIndex, SectionIndex},
    Result,
};

#[derive(Clone, Debug, Default, Deserialize, Serialize, Getters)]
pub struct TaskStats {
    has_tasks: bool,
    tasks_count: u32,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct TaskList {
    pub(crate) inner: TaskListEventContent,
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

    pub fn tasks_key(&self) -> IndexKey {
        IndexKey::ObjectList(self.meta.event_id.clone(), ObjectListIndex::Tasks)
    }

    pub fn sender(&self) -> &UserId {
        &self.meta.sender
    }

    pub fn redacted(&self) -> bool {
        false
    }

    pub fn updater(&self) -> TaskListUpdateBuilder {
        TaskListUpdateBuilder::default()
            .task_list(self.meta.event_id.clone())
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
    fn indizes(&self, _user_id: &UserId) -> Vec<IndexKey> {
        vec![
            IndexKey::Section(SectionIndex::Tasks),
            IndexKey::RoomSection(self.meta.room_id.clone(), SectionIndex::Tasks),
            IndexKey::ObjectHistory(self.meta.event_id.clone()),
            IndexKey::RoomHistory(self.meta.room_id.clone()),
            IndexKey::AllHistory,
        ]
    }

    fn event_meta(&self) -> &EventMeta {
        &self.meta
    }

    fn capabilities(&self) -> &[Capability] {
        &[
            Capability::Commentable,
            Capability::Reactable,
            Capability::Attachmentable,
        ]
    }

    async fn execute(self, store: &Store) -> Result<Vec<ExecuteReference>> {
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
    pub(crate) inner: TaskListUpdateEventContent,
    meta: EventMeta,
}

impl ActerModel for TaskListUpdate {
    fn indizes(&self, _user_id: &UserId) -> Vec<IndexKey> {
        vec![
            IndexKey::AllHistory,
            IndexKey::RoomHistory(self.meta.room_id.clone()),
            IndexKey::ObjectHistory(self.inner.task_list.event_id.clone()),
        ]
    }

    fn event_meta(&self) -> &EventMeta {
        &self.meta
    }

    async fn execute(self, store: &Store) -> Result<Vec<ExecuteReference>> {
        default_model_execute(store, self.into()).await
    }

    fn belongs_to(&self) -> Option<Vec<OwnedEventId>> {
        Some(vec![self.inner.task_list.event_id.clone()])
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
