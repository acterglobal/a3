use ruma_common::{EventId, OwnedUserId, RoomId, UserId};
use ruma_events::OriginalMessageLikeEvent;
use serde::{Deserialize, Serialize};
use std::ops::Deref;

use super::{
    super::{default_model_execute, ActerModel, AnyActerModel, Capability, EventMeta, Store},
    KEYS,
};
use crate::{
    events::tasks::{
        TaskEventContent, TaskSelfAssignEventContent, TaskSelfUnassignEventContent,
        TaskUpdateBuilder, TaskUpdateEventContent,
    },
    Result,
};

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Task {
    inner: TaskEventContent,
    pub meta: EventMeta,

    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    assignees: Vec<OwnedUserId>,
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

    pub fn assignees(&self) -> Vec<OwnedUserId> {
        self.assignees.clone()
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

    pub fn is_assigned(&self, user_id: &UserId) -> bool {
        self.assignees.iter().any(|o| o == user_id)
    }

    pub fn percent(&self) -> Option<u8> {
        self.inner.progress_percent
    }

    pub fn due_date(&self) -> Option<String> {
        self.inner
            .due_date
            .map(|d| d.format("%Y-%m-%d").to_string())
    }

    pub fn utc_due_time_of_day(&self) -> Option<i32> {
        self.inner.utc_due_time_of_day
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

    pub fn self_assign_event_content(&self) -> TaskSelfAssignEventContent {
        TaskSelfAssignEventContent {
            task: self.meta.event_id.clone().into(),
        }
    }

    pub fn self_unassign_event_content(&self) -> TaskSelfUnassignEventContent {
        TaskSelfUnassignEventContent {
            task: self.meta.event_id.clone().into(),
        }
    }
}

impl ActerModel for Task {
    fn indizes(&self, user_id: &UserId) -> Vec<String> {
        let tasks_key = KEYS::TASKS;
        let task_list_id_idx = format!("{}::{tasks_key}", self.inner.task_list_id.event_id);
        if self.is_assigned(user_id) {
            if self.is_done() {
                return vec![KEYS::MY_DONE_TASKS.to_owned(), task_list_id_idx];
            } else {
                return vec![KEYS::MY_OPEN_TASKS.to_owned(), task_list_id_idx];
            }
        }
        // not mine
        vec![task_list_id_idx]
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
            Capability::Attachmentable,
            Capability::Reactable,
        ]
    }

    async fn execute(self, store: &Store) -> Result<Vec<String>> {
        default_model_execute(store, self.into()).await
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(vec![self.inner.task_list_id.event_id.to_string()])
    }

    fn transition(&mut self, model: &AnyActerModel) -> Result<bool> {
        match model {
            AnyActerModel::TaskUpdate(update) => update.apply(&mut self.inner),
            AnyActerModel::TaskSelfAssign(update) => update.apply(self),
            AnyActerModel::TaskSelfUnassign(update) => update.apply(self),
            _ => Ok(false),
        }
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
            assignees: Vec::with_capacity(0),
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

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct TaskUpdate {
    inner: TaskUpdateEventContent,
    meta: EventMeta,
}

impl ActerModel for TaskUpdate {
    fn indizes(&self, _user_id: &UserId) -> Vec<String> {
        vec![format!("{:}::history", self.inner.task.event_id)]
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
        Some(vec![self.inner.task.event_id.to_string()])
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
                redacted: None,
            },
        }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct TaskSelfAssign {
    inner: TaskSelfAssignEventContent,
    meta: EventMeta,
}

impl TaskSelfAssign {
    fn apply(&self, task: &mut Task) -> Result<bool> {
        let new_user_id = self.meta.sender.clone();
        // remove any existing instance of the user in the list.
        task.assignees.retain(|u| u != &new_user_id);
        // add it at the new first entry;
        task.assignees.insert(0, new_user_id);
        Ok(true)
    }
}

impl ActerModel for TaskSelfAssign {
    fn indizes(&self, _user_id: &UserId) -> Vec<String> {
        vec![format!("{:}::history", self.inner.task.event_id)]
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
        Some(vec![self.inner.task.event_id.to_string()])
    }
}

impl From<OriginalMessageLikeEvent<TaskSelfAssignEventContent>> for TaskSelfAssign {
    fn from(outer: OriginalMessageLikeEvent<TaskSelfAssignEventContent>) -> Self {
        let OriginalMessageLikeEvent {
            content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = outer;
        TaskSelfAssign {
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

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct TaskSelfUnassign {
    inner: TaskSelfUnassignEventContent,
    meta: EventMeta,
}

impl TaskSelfUnassign {
    fn apply(&self, task: &mut Task) -> Result<bool> {
        let new_user_id = self.meta.sender.clone();
        // remove the user from the list.
        task.assignees.retain(|u| u != &new_user_id);
        Ok(true)
    }
}

impl ActerModel for TaskSelfUnassign {
    fn indizes(&self, _user_id: &UserId) -> Vec<String> {
        vec![format!("{:}::history", self.inner.task.event_id)]
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
        Some(vec![self.inner.task.event_id.to_string()])
    }
}

impl From<OriginalMessageLikeEvent<TaskSelfUnassignEventContent>> for TaskSelfUnassign {
    fn from(outer: OriginalMessageLikeEvent<TaskSelfUnassignEventContent>) -> Self {
        let OriginalMessageLikeEvent {
            content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = outer;
        TaskSelfUnassign {
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
