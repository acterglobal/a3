use acter_core::{
    events::{
        tasks::{self, Priority, TaskBuilder, TaskListBuilder},
        UtcDateTime,
    },
    models::{self, ActerModel, AnyActerModel, Color, TaskStats},
    statics::KEYS,
};
use anyhow::{bail, Context, Result};
use async_broadcast::Receiver;
use chrono::DateTime;
use core::time::Duration;
use matrix_sdk::{
    room::{Joined, Room},
    ruma::{
        events::room::message::TextMessageEventContent, OwnedEventId, OwnedRoomId, OwnedUserId,
    },
};
use std::{
    collections::{hash_map::Entry, HashMap},
    ops::Deref,
};

use super::{client::Client, spaces::Space, RUNTIME};

impl Client {
    pub async fn wait_for_task_list(
        &self,
        key: String,
        timeout: Option<Box<Duration>>,
    ) -> Result<TaskList> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let AnyActerModel::TaskList(content) = me.wait_for(key.clone(), timeout).await? else {
                    bail!("{key} is not a task");
                };
                let room = me
                    .core
                    .client()
                    .get_room(content.room_id())
                    .context("Room not found")?;
                Ok(TaskList {
                    client: me.clone(),
                    room,
                    content,
                })
            })
            .await?
    }

    pub async fn wait_for_task(&self, key: String, timeout: Option<Box<Duration>>) -> Result<Task> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let AnyActerModel::Task(content) = me.wait_for(key.clone(), timeout).await? else {
                    bail!("{key} is not a task");
                };
                let room = me
                    .core
                    .client()
                    .get_room(content.room_id())
                    .context("Room not found")?;
                Ok(Task {
                    client: me.clone(),
                    room,
                    content,
                })
            })
            .await?
    }

    pub async fn task_lists(&self) -> Result<Vec<TaskList>> {
        let mut task_lists = Vec::new();
        let mut rooms_map: HashMap<OwnedRoomId, Room> = HashMap::new();
        let client = self.clone();
        RUNTIME
            .spawn(async move {
                for mdl in client.store().get_list(KEYS::TASKS).await? {
                    #[allow(irrefutable_let_patterns)]
                    if let AnyActerModel::TaskList(content) = mdl {
                        let room_id = content.room_id().to_owned();
                        let room = match rooms_map.entry(room_id) {
                            Entry::Occupied(t) => t.get().clone(),
                            Entry::Vacant(e) => {
                                if let Some(room) = client.get_room(e.key()) {
                                    e.insert(room.clone());
                                    room
                                } else {
                                    /// User not part of the room anymore, ignore
                                    continue;
                                }
                            }
                        };
                        task_lists.push(TaskList {
                            client: client.clone(),
                            room,
                            content,
                        })
                    } else {
                        tracing::warn!("Non task list model found in `tasks` index: {:?}", mdl);
                    }
                }
                Ok(task_lists)
            })
            .await?
    }

    pub async fn task_list(&self, key: String) -> Result<TaskList> {
        let client = self.clone();
        RUNTIME
            .spawn(async move {
                let mdl = client.store().get(key.as_str()).await?;

                let AnyActerModel::TaskList(content) = mdl else  {
                    bail!("Not a Tasklist model: {key}")
                };
                let Some(room) = client.get_room(content.room_id()) else {
                    bail!("Room not found for task_list item");
                };

                Ok(TaskList {
                    client: client.clone(),
                    room,
                    content,
                })
            })
            .await?
    }
}

impl Space {
    pub async fn task_lists(&self) -> Result<Vec<TaskList>> {
        let mut task_lists = Vec::new();
        let room_id = self.room_id().to_owned();
        let client = self.client.clone();
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                let k = format!("{room_id}::{}", KEYS::TASKS);
                for mdl in client.store().get_list(&k).await? {
                    #[allow(irrefutable_let_patterns)]
                    if let AnyActerModel::TaskList(content) = mdl {
                        task_lists.push(TaskList {
                            client: client.clone(),
                            room: room.clone(),
                            content,
                        });
                    } else {
                        tracing::warn!("Non task list model found in `tasks` index: {:?}", mdl);
                    }
                }
                Ok(task_lists)
            })
            .await?
    }

    pub async fn task_list(&self, key: String) -> Result<TaskList> {
        let room_id = self.room_id().to_owned();
        let client = self.client.clone();
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                let mdl = client.store().get(key.as_str()).await?;

                let AnyActerModel::TaskList(content) = mdl else  {
                    bail!("Not a Tasklist model: {key}")
                };
                assert!(
                    room_id == content.room_id(),
                    "This task doesn't belong to this room"
                );

                Ok(TaskList {
                    client: client.clone(),
                    room: room.clone(),
                    content,
                })
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct TaskListDraft {
    client: Client,
    room: Joined,
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

    pub fn unset_description(&mut self) -> &mut Self {
        self.content.description(None);
        self
    }

    pub fn sort_order(&mut self, sort_order: u32) -> &mut Self {
        self.content.sort_order(sort_order);
        self
    }

    pub fn color(&mut self, color: Box<Color>) -> &mut Self {
        self.content.color(Some(Box::into_inner(color)));
        self
    }

    pub fn unset_color(&mut self) -> &mut Self {
        self.content.color(None);
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

    #[allow(clippy::ptr_arg)]
    pub fn subscribers(&mut self, subscribers: &mut Vec<OwnedUserId>) -> &mut Self {
        self.content.subscribers(subscribers.to_vec());
        self
    }

    pub fn unset_subscribers(&mut self) -> &mut Self {
        self.content.subscribers(vec![]);
        self
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let content = self.content.build()?;
        RUNTIME
            .spawn(async move {
                let resp = room.send(content, None).await?;
                Ok(resp.event_id)
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

impl TaskList {
    pub fn name(&self) -> String {
        self.content.name.clone()
    }

    pub fn description_text(&self) -> Option<String> {
        self.description.as_ref().map(|t| t.body.clone())
    }

    pub fn subscribers(&self) -> Vec<OwnedUserId> {
        self.content.subscribers.clone()
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

    pub fn color(&self) -> Option<Color> {
        self.content.color.clone()
    }

    pub fn time_zone(&self) -> Option<String> {
        self.content.time_zone.as_ref().map(ToString::to_string)
    }

    pub fn keywords(&self) -> Vec<String> {
        // don't use cloned().
        // create string vector to deallocate string item using toDartString().
        // apply this way for only function that string vector is calculated indirectly.
        let mut result = vec![];
        for keyword in &self.content.keywords {
            result.push(keyword.to_owned());
        }
        result
    }

    pub fn categories(&self) -> Vec<String> {
        // don't use cloned().
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
            crate::Room {
                room: self.room.clone(),
            },
        )
    }
}

impl TaskList {
    pub fn client(&self) -> &Client {
        &self.client
    }

    pub async fn refresh(&self) -> Result<TaskList> {
        let key = self.content.event_id().to_string();
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

    pub fn subscribe(&self) -> Receiver<()> {
        let key = self.content.event_id().to_string();
        self.client.executor().subscribe(key)
    }

    pub fn task_builder(&self) -> Result<TaskDraft> {
        let Room::Joined(joined) = &self.room else {
            bail!("Can only create tasks in joined rooms");
        };
        let mut content = TaskBuilder::default();
        content.task_list_id(self.event_id().to_owned());
        Ok(TaskDraft {
            client: self.client.clone(),
            room: joined.clone(),
            content,
        })
    }

    pub fn update_builder(&self) -> Result<TaskListUpdateBuilder> {
        let Room::Joined(joined) = &self.room else {
            bail!("Can only update tasks in joined rooms");
        };
        Ok(TaskListUpdateBuilder {
            client: self.client.clone(),
            room: joined.clone(),
            content: self.content.updater(),
        })
    }

    pub fn tasks_stats(&self) -> Result<TaskStats> {
        Ok(self.content.stats().clone())
    }

    pub async fn tasks(&self) -> Result<Vec<Task>> {
        if !self.content.stats().has_tasks() {
            return Ok(vec![]);
        };
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
                            Some(Task {
                                client: client.clone(),
                                room: room.clone(),
                                content,
                            })
                        } else {
                            None
                        }
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

        RUNTIME
            .spawn(async move {
                let inner =
                    models::CommentsManager::from_store_and_event_id(client.store(), &event_id)
                        .await;
                Ok(crate::CommentsManager::new(client, room, inner))
            })
            .await?
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
        self.content.title.clone()
    }

    pub fn description_text(&self) -> Option<String> {
        self.content.description.as_ref().map(|t| t.body.clone())
    }

    pub fn assignees(&self) -> Vec<OwnedUserId> {
        self.content.assignees.clone()
    }

    pub fn subscribers(&self) -> Vec<OwnedUserId> {
        self.content.subscribers.clone()
    }

    pub fn sort_order(&self) -> u32 {
        self.content.sort_order
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

    pub fn utc_due(&self) -> Option<UtcDateTime> {
        self.content.utc_due
    }

    pub fn utc_start(&self) -> Option<UtcDateTime> {
        self.content.utc_start
    }

    pub fn color(&self) -> Option<Color> {
        self.content.color.clone()
    }

    pub fn is_done(&self) -> bool {
        self.content.is_done()
    }

    pub fn progress_percent(&self) -> Option<u8> {
        self.content.progress_percent
    }

    pub fn keywords(&self) -> Vec<String> {
        // don't use cloned().
        // create string vector to deallocate string item using toDartString().
        // apply this way for only function that string vector is calculated indirectly.
        let mut result = vec![];
        for keyword in &self.content.keywords {
            result.push(keyword.to_owned());
        }
        result
    }

    pub fn categories(&self) -> Vec<String> {
        // don't use cloned().
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
        let key = self.content.event_id().to_string();
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

    pub fn update_builder(&self) -> Result<TaskUpdateBuilder> {
        let Room::Joined(joined) = &self.room else {
            bail!("Can only update tasks in joined rooms");
        };
        Ok(TaskUpdateBuilder {
            client: self.client.clone(),
            room: joined.clone(),
            content: self.content.updater(),
        })
    }

    pub fn subscribe(&self) -> Receiver<()> {
        let key = self.content.event_id().to_string();
        self.client.executor().subscribe(key)
    }

    pub async fn comments(&self) -> Result<crate::CommentsManager> {
        let client = self.client.clone();
        let room = self.room.clone();
        let event_id = self.content.event_id().to_owned();

        RUNTIME
            .spawn(async move {
                let inner =
                    models::CommentsManager::from_store_and_event_id(client.store(), &event_id)
                        .await;
                Ok(crate::CommentsManager::new(client, room, inner))
            })
            .await?
    }
}

#[derive(Clone)]
pub struct TaskDraft {
    client: Client,
    room: Joined,
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

    pub fn unset_description(&mut self) -> &mut Self {
        self.content.description(None);
        self
    }

    pub fn sort_order(&mut self, sort_order: u32) -> &mut Self {
        self.content.sort_order(sort_order);
        self
    }

    pub fn color(&mut self, color: Box<Color>) -> &mut Self {
        self.content.color(Some(Box::into_inner(color)));
        self
    }

    pub fn unset_color(&mut self) -> &mut Self {
        self.content.color(None);
        self
    }

    pub fn utc_due_from_rfc3339(&mut self, utc_due: String) -> Result<()> {
        let dt = DateTime::parse_from_rfc3339(&utc_due)?.into();
        self.content.utc_due(Some(dt));
        Ok(())
    }

    pub fn utc_due_from_rfc2822(&mut self, utc_due: String) -> Result<()> {
        let dt = DateTime::parse_from_rfc2822(&utc_due)?.into();
        self.content.utc_due(Some(dt));
        Ok(())
    }

    pub fn utc_due_from_format(&mut self, utc_due: String, format: String) -> Result<()> {
        let dt = DateTime::parse_from_str(&utc_due, &format)?.into();
        self.content.utc_due(Some(dt));
        Ok(())
    }

    pub fn unset_utc_due(&mut self) -> &mut Self {
        self.content.utc_due(None);
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
            // ensure the builder won't kill us later
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

    #[allow(clippy::ptr_arg)]
    pub fn subscribers(&mut self, subscribers: &mut Vec<OwnedUserId>) -> &mut Self {
        self.content.subscribers(subscribers.to_vec());
        self
    }

    pub fn unset_subscribers(&mut self) -> &mut Self {
        self.content.subscribers(vec![]);
        self
    }

    #[allow(clippy::ptr_arg)]
    pub fn assignees(&mut self, assignees: &mut Vec<OwnedUserId>) -> &mut Self {
        self.content.assignees(assignees.to_vec());
        self
    }

    pub fn unset_assignees(&mut self) -> &mut Self {
        self.content.assignees(vec![]);
        self
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let content = self.content.build()?;
        RUNTIME
            .spawn(async move {
                let resp = room.send(content, None).await?;
                Ok(resp.event_id)
            })
            .await?
    }
}

#[derive(Clone)]
pub struct TaskUpdateBuilder {
    client: Client,
    room: Joined,
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

    pub fn color(&mut self, color: Box<Color>) -> &mut Self {
        self.content.color(Some(Some(Box::into_inner(color))));
        self
    }

    pub fn unset_color(&mut self) -> &mut Self {
        self.content.color(Some(None));
        self
    }

    pub fn unset_color_update(&mut self) -> &mut Self {
        self.content.color(None::<Option<Color>>);
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

    #[allow(clippy::ptr_arg)]
    pub fn subscribers(&mut self, subscribers: &mut Vec<OwnedUserId>) -> &mut Self {
        self.content.subscribers(Some(subscribers.to_vec()));
        self
    }

    pub fn unset_subscribers(&mut self) -> &mut Self {
        self.content.subscribers(Some(vec![]));
        self
    }

    pub fn unset_subscribers_update(&mut self) -> &mut Self {
        self.content.subscribers(None);
        self
    }

    #[allow(clippy::ptr_arg)]
    pub fn assignees(&mut self, assignees: &mut Vec<OwnedUserId>) -> &mut Self {
        self.content.assignees(Some(assignees.to_vec()));
        self
    }

    pub fn unset_assignees(&mut self) -> &mut Self {
        self.content.assignees(Some(vec![]));
        self
    }

    pub fn unset_assignees_update(&mut self) -> &mut Self {
        self.content.assignees(None);
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

    pub fn utc_due_from_rfc3339(&mut self, utc_due: String) -> Result<()> {
        let dt = DateTime::parse_from_rfc3339(&utc_due)?.into();
        self.content.utc_due(Some(Some(dt)));
        Ok(())
    }

    pub fn utc_due_from_rfc2822(&mut self, utc_due: String) -> Result<()> {
        let dt = DateTime::parse_from_rfc2822(&utc_due)?.into();
        self.content.utc_due(Some(Some(dt)));
        Ok(())
    }

    pub fn utc_due_from_format(&mut self, utc_due: String, format: String) -> Result<()> {
        let dt = DateTime::parse_from_str(&utc_due, &format)?.into();
        self.content.utc_due(Some(Some(dt)));
        Ok(())
    }

    pub fn unset_utc_due(&mut self) -> &mut Self {
        self.content.utc_due(Some(None));
        self
    }

    pub fn unset_utc_due_update(&mut self) -> &mut Self {
        self.content.utc_due(None);
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
            // ensure the builder won't kill us later
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
        let content = self.content.build()?;
        RUNTIME
            .spawn(async move {
                let resp = room.send(content, None).await?;
                Ok(resp.event_id)
            })
            .await?
    }
}

#[derive(Clone)]
pub struct TaskListUpdateBuilder {
    client: Client,
    room: Joined,
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

    pub fn color(&mut self, color: Box<Color>) -> &mut Self {
        self.content.color(Some(Box::into_inner(color)));
        self
    }

    pub fn unset_color(&mut self) -> &mut Self {
        self.content.color(Some(None));
        self
    }

    pub fn unset_color_update(&mut self) -> &mut Self {
        self.content.color(None::<Option<Color>>);
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

    #[allow(clippy::ptr_arg)]
    pub fn subscribers(&mut self, subscribers: &mut Vec<OwnedUserId>) -> &mut Self {
        self.content.subscribers(Some(subscribers.to_vec()));
        self
    }

    pub fn unset_subscribers(&mut self) -> &mut Self {
        self.content.subscribers(Some(vec![]));
        self
    }

    pub fn unset_subscribers_update(&mut self) -> &mut Self {
        self.content.subscribers(None);
        self
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let content = self.content.build()?;
        RUNTIME
            .spawn(async move {
                let resp = room.send(content, None).await?;
                Ok(resp.event_id)
            })
            .await?
    }
}

impl Space {
    pub fn task_list_draft(&self) -> Result<TaskListDraft> {
        let Room::Joined(joined) = &self.inner.room else {
            bail!("You can't create tasks for spaces we are not part on")
        };
        Ok(TaskListDraft {
            client: self.client.clone(),
            room: joined.clone(),
            content: Default::default(),
        })
    }

    pub fn task_list_draft_with_builder(&self, content: TaskListBuilder) -> Result<TaskListDraft> {
        let Room::Joined(joined) = &self.inner.room else {
            bail!("You can't create tasks for spaces we are not part on")
        };
        Ok(TaskListDraft {
            client: self.client.clone(),
            room: joined.clone(),
            content,
        })
    }
}
