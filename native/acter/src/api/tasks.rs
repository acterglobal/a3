use acter_core::{
    events::{
        tasks::{self, Priority, TaskBuilder, TaskListBuilder},
        Display, RefDetails as CoreRefDetails, RefPreview,
    },
    models::{self, can_redact, ActerModel, AnyActerModel, TaskStats},
    referencing::{IndexKey, SectionIndex, SpecialListsIndex},
};
use anyhow::{bail, Context, Result};
use chrono::DateTime;
use futures::stream::StreamExt;
use matrix_sdk::room::Room;
use matrix_sdk_base::{
    ruma::{
        events::{room::message::TextMessageEventContent, MessageLikeEventType},
        EventId, OwnedEventId, OwnedRoomId, OwnedUserId,
    },
    RoomState,
};
use scc::ebr::Owned;
use std::{
    collections::{hash_map::Entry, HashMap},
    ops::Deref,
};
use tokio::sync::broadcast::Receiver;
use tokio_stream::{wrappers::BroadcastStream, Stream};
use tracing::warn;

use crate::MsgContent;

use super::{client::Client, deep_linking::RefDetails, spaces::Space, RUNTIME};

impl Client {
    pub async fn task_list(&self, key: String, timeout: Option<u8>) -> Result<TaskList> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let AnyActerModel::TaskList(content) = me.wait_for(key.clone(), timeout).await?
                else {
                    bail!("{key} is not a task");
                };
                let room = me.room_by_id_typed(content.room_id())?;
                Ok(TaskList {
                    client: me.clone(),
                    room,
                    content,
                })
            })
            .await?
    }

    pub async fn wait_for_task(&self, key: String, timeout: Option<u8>) -> Result<Task> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let AnyActerModel::Task(content) = me.wait_for(key.clone(), timeout).await? else {
                    bail!("{key} is not a task");
                };
                let room = me.room_by_id_typed(content.room_id())?;
                Ok(Task {
                    client: me.clone(),
                    room,
                    content,
                })
            })
            .await?
    }

    pub async fn task_lists(&self) -> Result<Vec<TaskList>> {
        let me = self.clone();
        Ok(self
            .models_of_list_with_room(IndexKey::Section(SectionIndex::Tasks))
            .await?
            .map(|(inner, room)| TaskList {
                client: self.clone(),
                room,
                content: inner,
            })
            .collect())
    }

    pub async fn my_open_tasks(&self) -> Result<Vec<Task>> {
        let me = self.clone();
        Ok(self
            .models_of_list_with_room(IndexKey::Special(SpecialListsIndex::MyOpenTasks))
            .await?
            .map(|(inner, room)| Task {
                client: self.clone(),
                room,
                content: inner,
            })
            .collect())
    }

    pub fn subscribe_my_open_tasks_stream(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.subscribe_my_open_tasks()).map(|_| true)
    }

    pub fn subscribe_my_open_tasks(&self) -> Receiver<()> {
        self.executor()
            .subscribe(IndexKey::Special(SpecialListsIndex::MyOpenTasks))
    }
}

impl Space {
    pub async fn task_lists(&self) -> Result<Vec<TaskList>> {
        let client = self.client.clone();
        let room = self.room.clone();
        Ok(client
            .models_of_list_with_room_under_check(
                IndexKey::RoomSection(room.room_id().to_owned(), SectionIndex::Tasks),
                move |_r| Ok(room.clone()),
            )
            .await?
            .map(|(inner, room)| TaskList {
                client: client.clone(),
                room: room.clone(),
                content: inner,
            })
            .collect())
    }
    #[cfg(any(test, feature = "testing"))]
    pub async fn task_list(&self, key: OwnedEventId) -> Result<TaskList> {
        let room_id = self.room_id().to_owned();
        let (model, room) = self
            .client
            .model_with_room::<acter_core::models::TaskList>(key)
            .await?;

        if room_id != model.room_id() {
            bail!("This task doesn’t belong to this room");
        }

        Ok(TaskList {
            client: self.client.clone(),
            room: room.clone(),
            content: model,
        })
    }
}

#[derive(Clone, Debug)]
pub struct TaskListDraft {
    client: Client,
    room: Room,
    content: TaskListBuilder,
}

impl TaskListDraft {
    pub fn name(&mut self, name: String) -> &mut Self {
        self.content.name(name);
        self
    }

    pub fn description_text(&mut self, body: String) -> &mut Self {
        let desc = TextMessageEventContent::plain(body);
        self.content.description(Some(desc));
        self
    }

    pub fn description_markdown(&mut self, body: String) -> &mut Self {
        let desc = TextMessageEventContent::markdown(body);
        self.content.description(Some(desc));
        self
    }

    pub fn description_html(&mut self, body: String, html_body: String) -> &mut Self {
        let desc = TextMessageEventContent::html(body, html_body);
        self.content.description(Some(desc));
        self
    }

    pub fn unset_description(&mut self) -> &mut Self {
        self.content.description(None);
        self
    }

    pub fn sort_order(&mut self, sort_order: u32) -> &mut Self {
        self.content.sort_order(sort_order);
        self
    }

    #[allow(clippy::ptr_arg)]
    pub fn keywords(&mut self, keywords: &mut Vec<String>) -> &mut Self {
        self.content.keywords(keywords.to_vec());
        self
    }

    pub fn unset_keywords(&mut self) -> &mut Self {
        self.content.keywords(vec![]);
        self
    }

    #[allow(clippy::ptr_arg)]
    pub fn categories(&mut self, categories: &mut Vec<String>) -> &mut Self {
        self.content.categories(categories.to_vec());
        self
    }

    pub fn unset_categories(&mut self) -> &mut Self {
        self.content.categories(vec![]);
        self
    }

    pub fn display(&mut self, display: Box<Display>) -> &mut Self {
        self.content.display(Some(*display));
        self
    }

    pub fn unset_display(&mut self) -> &mut Self {
        self.content.display(None);
        self
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let my_id = self.client.user_id()?;
        let content = self.content.build()?;

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::RoomMessage)
                    .await?;
                if !permitted {
                    bail!("No permissions to send message in this room");
                }
                let response = room.send(content).await?;
                Ok(response.event_id)
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct TaskList {
    client: Client,
    room: Room,
    content: models::TaskList,
}

impl Deref for TaskList {
    type Target = models::TaskList;
    fn deref(&self) -> &Self::Target {
        &self.content
    }
}

/// helpers for content
impl TaskList {
    pub fn name(&self) -> String {
        self.content.name.to_owned()
    }

    pub fn description(&self) -> Option<MsgContent> {
        self.content.description.as_ref().map(MsgContent::from)
    }

    pub fn role(&self) -> Option<String> {
        self.content
            .role
            .as_ref()
            .and_then(|t| serde_json::to_string(t).ok())
    }

    pub fn sort_order(&self) -> u32 {
        self.content.sort_order
    }

    pub fn display(&self) -> Option<Display> {
        self.content.display.clone()
    }

    pub fn event_id_str(&self) -> String {
        self.content.event_id().to_string()
    }

    pub fn time_zone(&self) -> Option<String> {
        self.content.time_zone.as_ref().map(ToString::to_string)
    }

    pub fn keywords(&self) -> Vec<String> {
        // don’t use cloned().
        // create string vector to deallocate string item using toDartString().
        // apply this way for only function that string vector is calculated indirectly.
        let mut result = vec![];
        for keyword in &self.content.keywords {
            result.push(keyword.to_owned());
        }
        result
    }

    pub fn categories(&self) -> Vec<String> {
        // don’t use cloned().
        // create string vector to deallocate string item using toDartString().
        // apply this way for only function that string vector is calculated indirectly.
        let mut result = vec![];
        for category in &self.content.categories {
            result.push(category.to_owned());
        }
        result
    }

    pub fn space(&self) -> Space {
        Space::new(
            self.client.clone(),
            crate::Room::new(self.client.core.clone(), self.room.clone()),
        )
    }

    pub fn space_id_str(&self) -> String {
        self.room.room_id().to_string()
    }

    pub async fn ref_details(&self) -> Result<RefDetails> {
        let room = self.room.clone();
        let client = self.client.clone();
        let target_id = self.content.event_id().to_owned();
        let room_id = self.room.room_id().to_owned();
        let title = self.content.name.clone();

        RUNTIME
            .spawn(async move {
                let via = room.route().await?;
                let room_display_name = room.cached_display_name();
                Ok(RefDetails::new(
                    client,
                    CoreRefDetails::TaskList {
                        target_id,
                        room_id: Some(room_id),
                        via,
                        preview: RefPreview::new(Some(title), room_display_name),
                        action: Default::default(),
                    },
                ))
            })
            .await?
    }
}

// custom functions
impl TaskList {
    pub fn client(&self) -> &Client {
        &self.client
    }

    pub async fn refresh(&self) -> Result<TaskList> {
        let key = self.content.event_id().to_owned();
        let client = self.client.clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let AnyActerModel::TaskList(content) = client.store().get(&key).await? else {
                    bail!("Refreshing failed. {key} not a task")
                };
                Ok(TaskList {
                    client,
                    room,
                    content,
                })
            })
            .await?
    }

    pub async fn can_redact(&self) -> Result<bool> {
        let sender = self.content.sender().to_owned();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move { Ok(can_redact(&room, &sender).await?) })
            .await?
    }

    pub fn subscribe_stream(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.subscribe()).map(|_| true)
    }

    pub fn subscribe(&self) -> Receiver<()> {
        let key = self.content.event_id().to_owned();
        self.client.subscribe(key)
    }

    fn is_joined(&self) -> bool {
        matches!(self.room.state(), RoomState::Joined)
    }

    pub fn task_builder(&self) -> Result<TaskDraft> {
        if !self.is_joined() {
            bail!("Can only create tasks in joined rooms");
        }
        let mut content = TaskBuilder::default();
        content.task_list_id(self.event_id().to_owned());
        Ok(TaskDraft {
            client: self.client.clone(),
            room: self.room.clone(),
            content,
        })
    }

    pub fn update_builder(&self) -> Result<TaskListUpdateBuilder> {
        if !self.is_joined() {
            bail!("Can only update tasks in joined rooms");
        }
        Ok(TaskListUpdateBuilder {
            client: self.client.clone(),
            room: self.room.clone(),
            content: self.content.updater(),
        })
    }

    pub fn tasks_stats(&self) -> Result<TaskStats> {
        Ok(self.content.stats().clone())
    }

    pub async fn tasks(&self) -> Result<Vec<Task>> {
        self.tasks_with_filter(|_| true).await
    }

    pub async fn task(&self, task_id: String) -> Result<Task> {
        let event_id = EventId::parse(task_id)?;
        self.tasks_with_filter(move |t| t.event_id() == event_id)
            .await?
            .into_iter()
            .next()
            .context("Task not found")
    }

    async fn tasks_with_filter<F>(&self, filter: F) -> Result<Vec<Task>>
    where
        F: Fn(&acter_core::models::Task) -> bool + Send + Sync + 'static,
    {
        let tasks_key = self.content.tasks_key();
        let client = self.client.clone();
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                let res = client
                    .store()
                    .get_list(&tasks_key)
                    .await
                    .into_iter()
                    .flatten()
                    .filter_map(|e| {
                        if let AnyActerModel::Task(content) = e {
                            if filter(&content) {
                                return Some(Task {
                                    client: client.clone(),
                                    room: room.clone(),
                                    content,
                                });
                            }
                        }
                        None
                    })
                    .collect();
                Ok(res)
            })
            .await?
    }

    pub async fn comments(&self) -> Result<crate::CommentsManager> {
        let client = self.client.clone();
        let room = self.room.clone();
        let event_id = self.content.event_id().to_owned();
        crate::CommentsManager::new(client, room, event_id).await
    }

    pub async fn attachments(&self) -> Result<crate::AttachmentsManager> {
        let client = self.client.clone();
        let room = self.room.clone();
        let event_id = self.content.event_id().to_owned();
        crate::AttachmentsManager::new(client, room, event_id).await
    }
}

#[derive(Clone, Debug)]
pub struct Task {
    client: Client,
    room: Room,
    content: models::Task,
}

impl Deref for Task {
    type Target = models::Task;
    fn deref(&self) -> &Self::Target {
        &self.content
    }
}

/// helpers for content
impl Task {
    pub fn title(&self) -> String {
        self.content.title().to_owned()
    }

    pub fn event_id_str(&self) -> String {
        self.content.event_id().to_string()
    }

    pub fn display(&self) -> Option<Display> {
        self.content.display.clone()
    }

    pub fn task_list_id_str(&self) -> String {
        self.content.task_list_id.event_id.to_string()
    }

    pub fn description(&self) -> Option<MsgContent> {
        self.content.description.as_ref().map(MsgContent::from)
    }

    pub fn sort_order(&self) -> u32 {
        self.content.sort_order
    }

    pub fn room_id_str(&self) -> String {
        self.content.room_id().to_string()
    }

    pub fn author(&self) -> OwnedUserId {
        self.content.meta.sender.clone()
    }

    pub fn author_str(&self) -> String {
        self.content.meta.sender.to_string()
    }

    pub fn assignees_str(&self) -> Vec<String> {
        self.content
            .assignees()
            .into_iter()
            .map(|a| a.to_string())
            .collect()
    }

    pub fn priority(&self) -> Option<u8> {
        Some(match self.content.priority {
            Priority::Undefined => return None,
            Priority::Highest => 1,
            Priority::SecondHighest => 2,
            Priority::Three => 3,
            Priority::Four => 4,
            Priority::Five => 5,
            Priority::Six => 6,
            Priority::Seven => 7,
            Priority::SecondLowest => 8,
            Priority::Lowest => 9,
        })
    }

    pub fn is_done(&self) -> bool {
        self.content.is_done()
    }

    pub fn progress_percent(&self) -> Option<u8> {
        self.content.progress_percent
    }

    pub fn keywords(&self) -> Vec<String> {
        // don’t use cloned().
        // create string vector to deallocate string item using toDartString().
        // apply this way for only function that string vector is calculated indirectly.
        let mut result = vec![];
        for keyword in &self.content.keywords {
            result.push(keyword.to_owned());
        }
        result
    }

    pub fn categories(&self) -> Vec<String> {
        // don’t use cloned().
        // create string vector to deallocate string item using toDartString().
        // apply this way for only function that string vector is calculated indirectly.
        let mut result = vec![];
        for category in &self.content.categories {
            result.push(category.to_owned());
        }
        result
    }
}

/// Custom functions
impl Task {
    pub async fn refresh(&self) -> Result<Task> {
        let key = self.content.event_id().to_owned();
        let client = self.client.clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let AnyActerModel::Task(content) = client.store().get(&key).await? else {
                    bail!("Refreshing failed. {key} not a task")
                };
                Ok(Task {
                    client,
                    room,
                    content,
                })
            })
            .await?
    }

    pub async fn can_redact(&self) -> Result<bool> {
        let sender = self.content.sender().to_owned();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move { Ok(can_redact(&room, &sender).await?) })
            .await?
    }

    fn is_joined(&self) -> bool {
        matches!(self.room.state(), RoomState::Joined)
    }

    pub fn is_assigned_to_me(&self) -> bool {
        let assignees = self.content.assignees();
        if assignees.is_empty() {
            return false;
        }
        let Ok(user_id) = self.client.account().map(|a| a.user_id()) else {
            return false;
        };
        assignees.contains(&user_id)
    }

    pub async fn assign_self(&self) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Can only update tasks in joined rooms");
        }
        let room = self.room.clone();
        let my_id = self.client.user_id()?;
        let content = self.content.self_assign_event_content();

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::RoomMessage)
                    .await?;
                if !permitted {
                    bail!("No permissions to send message in this room");
                }
                let response = room.send(content).await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn unassign_self(&self) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Can only update tasks in joined rooms");
        }
        let room = self.room.clone();
        let my_id = self.client.user_id()?;
        let content = self.content.self_unassign_event_content();

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::RoomMessage)
                    .await?;
                if !permitted {
                    bail!("No permissions to send message in this room");
                }
                let response = room.send(content).await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub fn update_builder(&self) -> Result<TaskUpdateBuilder> {
        if !self.is_joined() {
            bail!("Can only update tasks in joined rooms");
        }
        Ok(TaskUpdateBuilder {
            client: self.client.clone(),
            room: self.room.clone(),
            content: self.content.updater(),
        })
    }

    pub fn subscribe_stream(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.subscribe()).map(|_| true)
    }

    pub fn subscribe(&self) -> Receiver<()> {
        let key = self.content.event_id().to_owned();
        self.client.subscribe(key)
    }

    pub async fn comments(&self) -> Result<crate::CommentsManager> {
        let client = self.client.clone();
        let room = self.room.clone();
        let event_id = self.content.event_id().to_owned();
        crate::CommentsManager::new(client, room, event_id).await
    }

    pub async fn attachments(&self) -> Result<crate::AttachmentsManager> {
        let client = self.client.clone();
        let room = self.room.clone();
        let event_id = self.content.event_id().to_owned();
        crate::AttachmentsManager::new(client, room, event_id).await
    }
}

#[derive(Clone)]
pub struct TaskDraft {
    client: Client,
    room: Room,
    content: TaskBuilder,
}

impl TaskDraft {
    pub fn title(&mut self, title: String) -> &mut Self {
        self.content.title(title);
        self
    }

    pub fn description_text(&mut self, body: String) -> &mut Self {
        let desc = TextMessageEventContent::plain(body);
        self.content.description(Some(desc));
        self
    }

    pub fn description_html(&mut self, body: String, html_body: String) -> &mut Self {
        let desc = TextMessageEventContent::html(body, html_body);
        self.content.description(Some(desc));
        self
    }

    pub fn unset_description(&mut self) -> &mut Self {
        self.content.description(None);
        self
    }

    pub fn sort_order(&mut self, sort_order: u32) -> &mut Self {
        self.content.sort_order(sort_order);
        self
    }

    pub fn due_date(&mut self, year: i32, month: u32, day: u32) -> &mut Self {
        self.content
            .due_date(chrono::NaiveDate::from_ymd_opt(year, month, day));
        self
    }

    pub fn unset_due_date(&mut self) -> &mut Self {
        self.content.due_date(None);
        self
    }

    pub fn utc_due_time_of_day(&mut self, seconds: i32) -> &mut Self {
        self.content.utc_due_time_of_day(Some(seconds));
        self
    }
    pub fn unset_utc_due_time_of_day(&mut self) -> &mut Self {
        self.content.utc_due_time_of_day(None);
        self
    }

    pub fn utc_start_from_rfc3339(&mut self, utc_start: String) -> Result<()> {
        let dt = DateTime::parse_from_rfc3339(&utc_start)?.into();
        self.content.utc_start(Some(dt));
        Ok(())
    }

    pub fn utc_start_from_rfc2822(&mut self, utc_start: String) -> Result<()> {
        let dt = DateTime::parse_from_rfc2822(&utc_start)?.into();
        self.content.utc_start(Some(dt));
        Ok(())
    }

    pub fn utc_start_from_format(&mut self, utc_start: String, format: String) -> Result<()> {
        let dt = DateTime::parse_from_str(&utc_start, &format)?.into();
        self.content.utc_start(Some(dt));
        Ok(())
    }

    pub fn unset_utc_start(&mut self) -> &mut Self {
        self.content.utc_start(None);
        self
    }

    pub fn progress_percent(&mut self, mut progress_percent: u8) -> &mut Self {
        if progress_percent > 100 {
            // ensure the builder won’t kill us later
            progress_percent = 100;
        }
        self.content.progress_percent(Some(progress_percent));
        self
    }

    pub fn unset_progress_percent(&mut self) -> &mut Self {
        self.content.progress_percent(None);
        self
    }

    #[allow(clippy::ptr_arg)]
    pub fn keywords(&mut self, keywords: &mut Vec<String>) -> &mut Self {
        self.content.keywords(keywords.to_vec());
        self
    }

    pub fn unset_keywords(&mut self) -> &mut Self {
        self.content.keywords(vec![]);
        self
    }

    #[allow(clippy::ptr_arg)]
    pub fn categories(&mut self, categories: &mut Vec<String>) -> &mut Self {
        self.content.categories(categories.to_vec());
        self
    }

    pub fn unset_categories(&mut self) -> &mut Self {
        self.content.categories(vec![]);
        self
    }

    pub fn display(&mut self, display: Box<Display>) -> &mut Self {
        self.content.display(Some(*display));
        self
    }

    pub fn unset_display(&mut self) -> &mut Self {
        self.content.display(None);
        self
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let my_id = self.client.user_id()?;
        let content = self.content.build()?;

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::RoomMessage)
                    .await?;
                if !permitted {
                    bail!("No permissions to send message in this room");
                }
                let response = room.send(content).await?;
                Ok(response.event_id)
            })
            .await?
    }
}

#[derive(Clone)]
pub struct TaskUpdateBuilder {
    client: Client,
    room: Room,
    content: tasks::TaskUpdateBuilder,
}

impl TaskUpdateBuilder {
    pub fn title(&mut self, title: String) -> &mut Self {
        self.content.title(Some(title));
        self
    }

    pub fn unset_title_update(&mut self) -> &mut Self {
        self.content.title(None);
        self
    }

    pub fn description_text(&mut self, body: String) -> &mut Self {
        let desc = TextMessageEventContent::plain(body);
        self.content.description(Some(Some(desc)));
        self
    }

    pub fn description_html(&mut self, body: String, html_body: String) -> &mut Self {
        let desc = TextMessageEventContent::html(body, html_body);
        self.content.description(Some(Some(desc)));
        self
    }

    pub fn unset_description(&mut self) -> &mut Self {
        self.content.description(Some(None));
        self
    }

    pub fn unset_description_update(&mut self) -> &mut Self {
        self.content
            .description(None::<Option<TextMessageEventContent>>);
        self
    }

    pub fn sort_order(&mut self, sort_order: u32) -> &mut Self {
        self.content.sort_order(Some(sort_order));
        self
    }

    pub fn unset_sort_order_update(&mut self) -> &mut Self {
        self.content.sort_order(None);
        self
    }

    pub fn display(&mut self, display: Box<Display>) -> &mut Self {
        self.content.display(Some(Some(*display)));
        self
    }

    pub fn unset_display(&mut self) -> &mut Self {
        self.content.display(Some(None));
        self
    }

    pub fn unset_display_update(&mut self) -> &mut Self {
        self.content.display(None::<Option<Display>>);
        self
    }

    #[allow(clippy::ptr_arg)]
    pub fn keywords(&mut self, keywords: &mut Vec<String>) -> &mut Self {
        self.content.keywords(Some(keywords.to_vec()));
        self
    }

    pub fn unset_keywords(&mut self) -> &mut Self {
        self.content.keywords(Some(vec![]));
        self
    }

    pub fn unset_keywords_update(&mut self) -> &mut Self {
        self.content.keywords(None);
        self
    }

    #[allow(clippy::ptr_arg)]
    pub fn categories(&mut self, categories: &mut Vec<String>) -> &mut Self {
        self.content.categories(Some(categories.to_vec()));
        self
    }

    pub fn unset_categories(&mut self) -> &mut Self {
        self.content.categories(Some(vec![]));
        self
    }

    pub fn unset_categories_update(&mut self) -> &mut Self {
        self.content.categories(None);
        self
    }
    pub fn mark_done(&mut self) -> &mut Self {
        self.content.progress_percent(Some(Some(100)));
        self
    }

    pub fn mark_undone(&mut self) -> &mut Self {
        self.content.progress_percent(Some(None));
        self
    }

    pub fn due_date(&mut self, year: i32, month: u32, day: u32) -> &mut Self {
        self.content
            .due_date(Some(chrono::NaiveDate::from_ymd_opt(year, month, day)));
        self
    }
    pub fn unset_due_date(&mut self) -> &mut Self {
        self.content.due_date(Some(None));
        self
    }

    pub fn unset_due_date_update(&mut self) -> &mut Self {
        self.content.due_date(None);
        self
    }

    pub fn utc_due_time_of_day(&mut self, seconds: i32) -> &mut Self {
        self.content.utc_due_time_of_day(Some(Some(seconds)));
        self
    }
    pub fn unset_utc_due_time_of_day(&mut self) -> &mut Self {
        self.content.utc_due_time_of_day(Some(None));
        self
    }

    pub fn unset_utc_due_time_of_day_update(&mut self) -> &mut Self {
        self.content.utc_due_time_of_day(None);
        self
    }

    pub fn utc_start_from_rfc3339(&mut self, utc_start: String) -> Result<()> {
        let dt = DateTime::parse_from_rfc3339(&utc_start)?.into();
        self.content.utc_start(Some(Some(dt)));
        Ok(())
    }

    pub fn utc_start_from_rfc2822(&mut self, utc_start: String) -> Result<()> {
        let dt = DateTime::parse_from_rfc2822(&utc_start)?.into();
        self.content.utc_start(Some(Some(dt)));
        Ok(())
    }

    pub fn utc_start_from_format(&mut self, utc_start: String, format: String) -> Result<()> {
        let dt = DateTime::parse_from_str(&utc_start, &format)?.into();
        self.content.utc_start(Some(Some(dt)));
        Ok(())
    }

    pub fn unset_utc_start(&mut self) -> &mut Self {
        self.content.utc_start(Some(None));
        self
    }

    pub fn unset_utc_start_update(&mut self) -> &mut Self {
        self.content.utc_start(None);
        self
    }

    pub fn progress_percent(&mut self, mut progress_percent: u8) -> &mut Self {
        if progress_percent > 100 {
            // ensure the builder won’t kill us later
            progress_percent = 100;
        }
        self.content.progress_percent(Some(Some(progress_percent)));
        self
    }

    pub fn unset_progress_percent(&mut self) -> &mut Self {
        self.content.progress_percent(Some(None));
        self
    }

    pub fn unset_progress_percent_update(&mut self) -> &mut Self {
        self.content.progress_percent(None);
        self
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let my_id = self.client.user_id()?;
        let content = self.content.build()?;

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::RoomMessage)
                    .await?;
                if !permitted {
                    bail!("No permissions to send message in this room");
                }
                let response = room.send(content).await?;
                Ok(response.event_id)
            })
            .await?
    }
}

#[derive(Clone)]
pub struct TaskListUpdateBuilder {
    client: Client,
    room: Room,
    content: tasks::TaskListUpdateBuilder,
}

impl TaskListUpdateBuilder {
    pub fn name(&mut self, name: String) -> &mut Self {
        self.content.name(Some(name));
        self
    }

    pub fn unset_name(&mut self) -> &mut Self {
        self.content.name(None);
        self
    }

    pub fn description_text(&mut self, body: String) -> &mut Self {
        let desc = TextMessageEventContent::plain(body);
        self.content.description(Some(desc));
        self
    }

    pub fn description_html(&mut self, body: String, html_body: String) -> &mut Self {
        let desc = TextMessageEventContent::html(body, html_body);
        self.content.description(Some(desc));
        self
    }

    pub fn unset_description(&mut self) -> &mut Self {
        self.content.description(Some(None));
        self
    }

    pub fn unset_description_update(&mut self) -> &mut Self {
        self.content
            .description(None::<Option<TextMessageEventContent>>);
        self
    }

    pub fn sort_order(&mut self, sort_order: u32) -> &mut Self {
        self.content.sort_order(Some(sort_order));
        self
    }

    #[allow(clippy::ptr_arg)]
    pub fn keywords(&mut self, keywords: &mut Vec<String>) -> &mut Self {
        self.content.keywords(Some(keywords.to_vec()));
        self
    }

    pub fn unset_keywords(&mut self) -> &mut Self {
        self.content.keywords(Some(vec![]));
        self
    }

    pub fn unset_keywords_update(&mut self) -> &mut Self {
        self.content.keywords(None);
        self
    }

    #[allow(clippy::ptr_arg)]
    pub fn categories(&mut self, categories: &mut Vec<String>) -> &mut Self {
        self.content.categories(Some(categories.to_vec()));
        self
    }

    pub fn unset_categories(&mut self) -> &mut Self {
        self.content.categories(Some(vec![]));
        self
    }

    pub fn unset_categories_update(&mut self) -> &mut Self {
        self.content.categories(None);
        self
    }

    pub fn display(&mut self, display: Box<Display>) -> &mut Self {
        self.content.display(Some(Some(*display)));
        self
    }

    pub fn unset_display(&mut self) -> &mut Self {
        self.content.display(Some(None));
        self
    }

    pub fn unset_display_update(&mut self) -> &mut Self {
        self.content.display(None::<Option<Display>>);
        self
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let my_id = self.client.user_id()?;
        let content = self.content.build()?;

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::RoomMessage)
                    .await?;
                if !permitted {
                    bail!("No permissions to send message in this room");
                }
                let response = room.send(content).await?;
                Ok(response.event_id)
            })
            .await?
    }
}

impl Space {
    pub fn task_list_draft(&self) -> Result<TaskListDraft> {
        if !self.inner.is_joined() {
            bail!("Unable to create tasks for spaces we are not part on");
        }
        Ok(TaskListDraft {
            client: self.client.clone(),
            room: self.inner.room.clone(),
            content: Default::default(),
        })
    }

    pub fn task_list_draft_with_builder(&self, content: TaskListBuilder) -> Result<TaskListDraft> {
        if !self.inner.is_joined() {
            bail!("Unable to create tasks for spaces we are not part on");
        }
        Ok(TaskListDraft {
            client: self.client.clone(),
            room: self.inner.room.clone(),
            content,
        })
    }
}
