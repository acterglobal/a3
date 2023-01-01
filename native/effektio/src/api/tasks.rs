use std::{
    collections::{hash_map::Entry, HashMap},
    convert::{TryFrom, TryInto},
};

use super::{client::Client, group::Group, RUNTIME};
use anyhow::{bail, Context, Result};
use async_broadcast::Receiver;
use effektio_core::{
    events::{
        self,
        tasks::{self, SyncTaskEvent, SyncTaskListEvent, TaskBuilder, TaskListBuilder},
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
        let mut rooms_map: HashMap<OwnedRoomId, Joined> = HashMap::new();
        let client = self.clone();
        for mdl in self.store.get_list(KEYS::TASKS)? {
            #[allow(irrefutable_let_patterns)]
            if let AnyEffektioModel::TaskList(t) = mdl {
                let room_id = t.room_id();
                let room = match rooms_map.entry(room_id) {
                    Entry::Occupied(t) => t.get().clone(),
                    Entry::Vacant(e) => {
                        if let Some(joined) = client.get_joined_room(e.key()) {
                            e.insert(joined.clone());
                            joined
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
    room: Joined,
    content: models::TaskList,
}

impl std::ops::Deref for TaskList {
    type Target = models::TaskList;
    fn deref(&self) -> &Self::Target {
        &self.content
    }
}

impl TaskList {
    pub fn client(&self) -> &Client {
        &self.client
    }

    pub fn task_builder(&self) -> TaskDraft {
        let mut content = TaskBuilder::default();
        content.task_list_id(self.event_id());
        TaskDraft {
            client: self.client.clone(),
            room: self.room.clone(),
            content: content,
        }
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
                    .filter_map(|o| o)
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
    room: Joined,
    content: models::Task,
}

impl std::ops::Deref for Task {
    type Target = models::Task;
    fn deref(&self) -> &Self::Target {
        &self.content
    }
}

impl Task {
    pub fn update_builder(&self) -> TaskUpdateBuilder {
        TaskUpdateBuilder {
            client: self.client.clone(),
            room: self.room.clone(),
            content: self.content.updater(),
        }
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
