use matrix_sdk::ruma::{events::OriginalMessageLikeEvent, EventId, OwnedUserId, RoomId};
use serde::{Deserialize, Serialize};
use std::ops::Deref;

use super::{
    super::{default_model_execute, ActerModel, AnyActerModel, Capability, EventMeta, Store},
    TaskList, TASKS_KEY,
};
use crate::{
    events::tasks::{TaskEventContent, TaskUpdateBuilder, TaskUpdateEventContent},
    Result,
};

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

    pub fn utc_due_rfc3339(&self) -> Option<String> {
        self.inner
            .utc_due
            .as_ref()
            .map(|d| d.to_rfc3339_opts(chrono::SecondsFormat::Secs, true))
    }

    pub fn utc_start_rfc3339(&self) -> Option<String> {
        self.inner
            .utc_start
            .as_ref()
            .map(|d| d.to_rfc3339_opts(chrono::SecondsFormat::Secs, true))
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

impl ActerModel for Task {
    fn indizes(&self) -> Vec<String> {
        vec![format!("{}::{TASKS_KEY}", self.inner.task_list_id.event_id)]
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }

    fn capabilities(&self) -> &[Capability] {
        &[Capability::Commentable, Capability::HasAttachments]
    }

    async fn execute(self, store: &Store) -> Result<Vec<String>> {
        default_model_execute(store, self.into()).await
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(vec![TaskList::key_from_event(
            &self.inner.task_list_id.event_id,
        )])
    }

    fn transition(&mut self, model: &AnyActerModel) -> Result<bool> {
        let AnyActerModel::TaskUpdate(update) = model else {
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

impl ActerModel for TaskUpdate {
    fn indizes(&self) -> Vec<String> {
        vec![format!("{:}::history", self.inner.task.event_id)]
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }

    async fn execute(self, store: &Store) -> Result<Vec<String>> {
        default_model_execute(store, self.into()).await
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
