use super::{client::Client, group::Group, RUNTIME};
use anyhow::{bail, Context, Result};
use effektio_core::{
    events,
    // models::,
    ruma::{OwnedEventId, OwnedRoomId},
};
use futures_signals::signal::Mutable;
use matrix_sdk::{room::Joined, Client as MatrixClient};
use std::ffi::OsStr;
use std::fs::File;
use std::path::PathBuf; // FIXME: make these optional for wasm

impl Client {}

#[derive(Clone)]
pub struct TaskListDraft {
    client: MatrixClient,
    room: Joined,
    content: events::TaskListBuilder,
}

impl std::ops::DerefMut for TaskListDraft {
    fn deref_mut(&mut self) -> &mut Self::Target {
        &mut self.content
    }
}

impl std::ops::Deref for TaskListDraft {
    type Target = events::TaskListBuilder;
    fn deref(&self) -> &Self::Target {
        &self.content
    }
}

impl TaskListDraft {
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
}
