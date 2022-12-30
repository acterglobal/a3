use std::{
    collections::{hash_map::Entry, HashMap},
    convert::{TryFrom, TryInto},
};

use super::{client::Client, group::Group, RUNTIME};
use anyhow::{bail, Context, Result};
use effektio_core::{
    events::{
        self,
        tasks::{self, SyncTaskEvent, SyncTaskListEvent, TaskBuilder, TaskListBuilder},
        TextMessageEventContent,
    },
    executor::Executor,
    models::{self, AnyEffektioModel},
    // models::,
    ruma::{
        events::{
            room::message::{RoomMessageEventContent, SyncRoomMessageEvent},
            MessageLikeEvent,
        },
        OwnedEventId, OwnedRoomId,
    },
    statics::KEYS,
};
use futures_signals::signal::Mutable;
use matrix_sdk::{event_handler::Ctx, room::Joined, room::Room, Client as MatrixClient};

impl Client {
    pub(crate) async fn init_tasks(&self) {
        // let executor = self.executor.clone();
        // self.client.add_event_handler_context(executor);
        // self.client.add_event_handler(
        //     |ev: SyncTaskListEvent,
        //      room: Room,
        //      client: MatrixClient,
        //      Ctx(executor): Ctx<Executor>| async move {
        //         // Common usage: Room event plus room and client.
        //         if let MessageLikeEvent::Original(o) = ev.into_full_event(room.room_id().to_owned())
        //         {
        //             tracing::trace!(room_id=?room.room_id(), user_id=?client.user_id(), event = ?o, "handling tasklist");
        //             executor.handle(o.into()).await;
        //         }
        //     },
        // );
        // self.client.add_event_handler(
        //     |ev: SyncTaskEvent,
        //      room: Room,
        //      client: MatrixClient,
        //      Ctx(executor): Ctx<Executor>| async move {
        //         // Common usage: Room event plus room and client.
        //         if let MessageLikeEvent::Original(o) = ev.into_full_event(room.room_id().to_owned())
        //         {
        //             tracing::trace!(room_id=?room.room_id(), user_id=?client.user_id(), event = ?o, "handling task");
        //             executor.handle(o.into()).await;
        //         }
        //     },
        // );
    }

    pub async fn task_lists(&self) -> Result<Vec<TaskList>> {
        let mut task_lists = Vec::new();
        let mut rooms_map: HashMap<OwnedRoomId, Joined> = HashMap::new();
        let client = self.client.clone();
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
    client: MatrixClient,
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
    client: MatrixClient,
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
    pub fn task_builder(&self) -> TaskDraft {
        let mut content = TaskBuilder::default();
        content.task_list_id(self.event_id());
        TaskDraft {
            client: self.client.clone(),
            room: self.room.clone(),
            content: content,
        }
    }

    pub fn tasks(&self) -> Vec<Task> {
        self.content
            .tasks
            .iter()
            .map(|task| Task {
                client: self.client.clone(),
                room: self.room.clone(),
                content: task.clone(),
            })
            .collect()
    }
}

#[derive(Clone, Debug)]
pub struct Task {
    client: MatrixClient,
    room: Joined,
    content: models::Task,
}

impl std::ops::Deref for Task {
    type Target = models::Task;
    fn deref(&self) -> &Self::Target {
        &self.content
    }
}

#[derive(Clone)]
pub struct TaskDraft {
    client: MatrixClient,
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

impl Group {
    pub fn task_list_draft(&self) -> Result<TaskListDraft> {
        if let matrix_sdk::room::Room::Joined(joined) = &self.inner.room {
            Ok(TaskListDraft {
                client: self.client.clone(),
                room: joined.clone(),
                content: Default::default(),
            })
        } else {
            bail!("You can't create todos for groups we are not part on")
        }
    }
    pub fn task_list_draft_with_builder(&self, content: TaskListBuilder) -> Result<TaskListDraft> {
        if let matrix_sdk::room::Room::Joined(joined) = &self.inner.room {
            Ok(TaskListDraft {
                client: self.client.clone(),
                room: joined.clone(),
                content,
            })
        } else {
            bail!("You can't create todos for groups we are not part on")
        }
    }
}
