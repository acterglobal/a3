use std::{
    collections::{hash_map::Entry, HashMap},
    convert::{TryFrom, TryInto},
    ops::DerefMut,
};

use super::{client::Client, group::Group, RUNTIME};
use anyhow::{bail, Context, Result};
use async_broadcast::Receiver;
use effektio_core::{
    events::{
        self,
        tasks::{self, Priority, SyncTaskEvent, SyncTaskListEvent, TaskBuilder, TaskListBuilder},
        TextMessageEventContent,
    },
    executor::Executor,
    models::{self, AnyEffektioModel, EffektioModel},
    // models::,
    ruma::{
        events::{
            room::message::{RoomMessageEventContent, SyncRoomMessageEvent},
            MessageLikeEvent,
        },
        OwnedEventId, OwnedRoomId,
    },
    statics::KEYS,
    store::Store,
};
use futures_signals::signal::Mutable;
use matrix_sdk::{event_handler::Ctx, room::Joined, room::Room, Client as MatrixClient};

impl Client {
    pub async fn task_lists(&self) -> Result<Vec<TaskList>> {
        let mut task_lists = Vec::new();
        let mut rooms_map: HashMap<OwnedRoomId, Room> = HashMap::new();
        let client = self.clone();
        for mdl in self.store.get_list(KEYS::TASKS)? {
            #[allow(irrefutable_let_patterns)]
            if let AnyEffektioModel::TaskList(t) = mdl {
                let room_id = t.room_id().to_owned();
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
                    content: t,
                })
            } else {
                tracing::warn!("Non task list model found in `tasks` index: {:?}", mdl);
            }
        }
        Ok(task_lists)
    }
    pub async fn task_list(&self, key: &str) -> Result<TaskList> {
        let client = self.clone();
        let mdl = self.store.get(key).await?;

        let AnyEffektioModel::TaskList(task_list) = mdl else  {
            bail!("Not a Tasklist model: {key}")
        };
        let Some(room) = client.get_room(task_list.room_id()) else {
            bail!("Room not found for task_list item");
        };

        Ok(TaskList {
            client: client.clone(),
            room,
            content: task_list,
        })
    }
}

impl Group {
    pub async fn task_lists(&self) -> Result<Vec<TaskList>> {
        let mut task_lists = Vec::new();
        let room_id = self.room_id();
        for mdl in self.client.store().get_list(KEYS::TASKS)? {
            #[allow(irrefutable_let_patterns)]
            if let AnyEffektioModel::TaskList(t) = mdl {
                if t.room_id() == room_id {
                    task_lists.push(TaskList {
                        client: self.client.clone(),
                        room: self.room.clone(),
                        content: t,
                    })
                }
            } else {
                tracing::warn!("Non task list model found in `tasks` index: {:?}", mdl);
            }
        }
        Ok(task_lists)
    }
    pub async fn task_list(&self, key: &str) -> Result<TaskList> {
        let mdl = self.client.store().get(key).await?;

        let AnyEffektioModel::TaskList(task_list) = mdl else  {
            bail!("Not a Tasklist model: {key}")
        };
        assert!(
            self.room_id() == task_list.room_id(),
            "This task doesn't belong to this room"
        );

        Ok(TaskList {
            client: self.client.clone(),
            room: self.room.clone(),
            content: task_list,
        })
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

    pub fn description(&mut self, description: String) -> &mut Self {
        self.content
            .description(TextMessageEventContent::plain(description));
        self
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let inner = self.content.build()?;
        RUNTIME
            .spawn(async move {
                let resp = room.send(inner, None).await?;
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

impl std::ops::Deref for TaskList {
    type Target = models::TaskList;
    fn deref(&self) -> &Self::Target {
        &self.content
    }
}

impl TaskList {
    pub fn description_text(&self) -> Option<String> {
        self.description.as_ref().map(|t| t.body.clone())
    }

    pub fn sort_order(&self) -> u32 {
        self.content.sort_order.clone()
    }

    pub fn role(&self) -> Option<String> {
        self.content
            .role
            .as_ref()
            .map(|t| serde_json::to_string(t).ok())
            .flatten()
    }

    pub fn time_zone(&self) -> Option<String> {
        self.content.time_zone.as_ref().map(ToString::to_string)
    }
}

impl TaskList {
    pub fn client(&self) -> &Client {
        &self.client
    }

    pub async fn refresh(&self) -> Result<TaskList> {
        let key = self.content.key();
        let client = self.client.clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let AnyEffektioModel::TaskList(content) = client.store().get(&key).await? else {
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
        let key = self.content.key();
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

    pub async fn tasks(&self) -> Result<Vec<Task>> {
        let tasks = self.content.tasks.clone();
        if tasks.is_empty() {
            return Ok(vec![]);
        };
        let client = self.client.clone();
        let room = self.room.clone();
        Ok(RUNTIME
            .spawn(async move {
                client
                    .store()
                    .get_many(tasks)
                    .await
                    .into_iter()
                    .flatten()
                    .filter_map(|e| {
                        if let AnyEffektioModel::Task(content) = e {
                            Some(Task {
                                client: client.clone(),
                                room: room.clone(),
                                content,
                            })
                        } else {
                            None
                        }
                    })
                    .collect()
            })
            .await?)
    }
}

#[derive(Clone, Debug)]
pub struct Task {
    client: Client,
    room: Room,
    content: models::Task,
}

impl std::ops::Deref for Task {
    type Target = models::Task;
    fn deref(&self) -> &Self::Target {
        &self.content
    }
}

/// helpers for content
impl Task {
    pub fn description_text(&self) -> Option<String> {
        self.content.description.as_ref().map(|t| t.body.clone())
    }

    pub fn progress_percent(&self) -> Option<u8> {
        self.content.progress_percent.clone()
    }

    pub fn sort_order(&self) -> u32 {
        self.content.sort_order.clone()
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
}

/// Custom functions
impl Task {
    pub async fn refresh(&self) -> Result<Task> {
        let key = self.content.key();
        let client = self.client.clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let AnyEffektioModel::Task(content) = client.store().get(&key).await? else {
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
        let key = self.content.key();
        self.client.executor().subscribe(key)
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

    pub fn description(&mut self, description: String) -> &mut Self {
        self.content
            .description(TextMessageEventContent::plain(description));
        self
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let inner = self.content.build()?;
        RUNTIME
            .spawn(async move {
                let resp = room.send(inner, None).await?;
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

    pub fn description(&mut self, description: String) -> &mut Self {
        self.content
            .description(Some(Some(TextMessageEventContent::plain(description))));
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

    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let inner = self.content.build()?;
        RUNTIME
            .spawn(async move {
                let resp = room.send(inner, None).await?;
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

    pub fn description(&mut self, description: String) -> &mut Self {
        self.content
            .description(Some(TextMessageEventContent::plain(description)));
        self
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let inner = self.content.build()?;
        RUNTIME
            .spawn(async move {
                let resp = room.send(inner, None).await?;
                Ok(resp.event_id)
            })
            .await?
    }
}

impl Group {
    pub fn task_list_draft(&self) -> Result<TaskListDraft> {
        let matrix_sdk::room::Room::Joined(joined) = &self.inner.room else {
            bail!("You can't create tasks for groups we are not part on")
        };
        Ok(TaskListDraft {
            client: self.client.clone(),
            room: joined.clone(),
            content: Default::default(),
        })
    }
    pub fn task_list_draft_with_builder(&self, content: TaskListBuilder) -> Result<TaskListDraft> {
        let matrix_sdk::room::Room::Joined(joined) = &self.inner.room else {
            bail!("You can't create tasks for groups we are not part on")
        };
        Ok(TaskListDraft {
            client: self.client.clone(),
            room: joined.clone(),
            content,
        })
    }
}
