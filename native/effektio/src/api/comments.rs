use std::{
    collections::{hash_map::Entry, HashMap},
    convert::{TryFrom, TryInto},
    ops::Deref,
    ops::DerefMut,
};

use crate::UserId;

use super::{client::Client, group::Group, RUNTIME};
use anyhow::{bail, Context, Result};
use async_broadcast::Receiver;
use core::time::Duration;
use effektio_core::{
    events::{self, comments::CommentBuilder, TextMessageEventContent, UtcDateTime},
    executor::Executor,
    models::{self, AnyEffektioModel, Color, EffektioModel},
    // models::,
    ruma::{
        events::{
            room::message::{RoomMessageEventContent, SyncRoomMessageEvent},
            MessageLikeEvent,
        },
        EventId, OwnedEventId, OwnedRoomId,
    },
    statics::KEYS,
    store::Store,
    util::DateTime,
};
use futures_signals::signal::Mutable;
use matrix_sdk::{event_handler::Ctx, room::Joined, room::Room, Client as MatrixClient};

impl Client {
    pub async fn wait_for_comment(
        &self,
        key: String,
        timeout: Option<Box<Duration>>,
    ) -> Result<Comment> {
        let AnyEffektioModel::Comment(comment) = self.wait_for(key.clone(), timeout).await? else {
            bail!("{key} is not a comment");
        };
        let room = self
            .core
            .client()
            .get_room(&comment.meta.room_id)
            .context("Room not found")?;
        Ok(Comment {
            client: self.clone(),
            room,
            inner: comment,
        })
    }
}

#[derive(Clone, Debug)]
pub struct Comment {
    client: Client,
    room: Room,
    inner: models::Comment,
}

impl std::ops::Deref for Comment {
    type Target = models::Comment;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl Comment {
    pub fn reply_draft(&self) -> Result<CommentDraft> {
        let Room::Joined(joined) = &self.room else {
            bail!("Can only comment in joined rooms");
        };
        Ok(CommentDraft {
            client: self.client.clone(),
            room: joined.clone(),
            inner: self.inner.reply_builder(),
        })
    }

    pub fn sender(&self) -> UserId {
        self.inner.meta.sender.clone()
    }

    pub fn origin_server_ts(&self) -> u64 {
        self.inner.meta.origin_server_ts.get().into()
    }

    pub fn content_text(&self) -> String {
        self.inner.content.body.clone()
    }
    pub fn content_formatted(&self) -> Option<String> {
        self.inner
            .content
            .formatted
            .as_ref()
            .map(|f| f.body.clone())
    }
}

#[derive(Clone, Debug)]
pub struct CommentsManager {
    client: Client,
    room: Room,
    inner: models::CommentsManager,
}

impl std::ops::Deref for CommentsManager {
    type Target = models::CommentsManager;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

pub struct CommentDraft {
    client: Client,
    room: Joined,
    inner: CommentBuilder,
}

impl CommentDraft {
    pub fn content_text(&mut self, body: String) -> &mut Self {
        self.inner.content(TextMessageEventContent::plain(body));
        self
    }

    pub fn content_formatted(&mut self, body: String, html_body: String) -> &mut Self {
        self.inner
            .content(TextMessageEventContent::html(body, html_body));
        self
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let inner = self.inner.build()?;
        RUNTIME
            .spawn(async move {
                let resp = room.send(inner, None).await?;
                Ok(resp.event_id)
            })
            .await?
    }
}

impl CommentsManager {
    pub(crate) fn new(
        client: Client,
        room: Room,
        inner: models::CommentsManager,
    ) -> CommentsManager {
        CommentsManager {
            client,
            room,
            inner,
        }
    }
    pub fn stats(&self) -> models::CommentsStats {
        self.inner.stats().clone()
    }

    pub fn has_comments(&self) -> bool {
        *self.stats().has_comments()
    }

    pub fn comments_count(&self) -> u32 {
        *self.stats().total_comments_count()
    }

    pub async fn comments(&self) -> Result<Vec<Comment>> {
        let manager = self.inner.clone();
        let client = self.client.clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                Ok(manager
                    .comments()
                    .await?
                    .into_iter()
                    .map(|inner| Comment {
                        client: client.clone(),
                        room: room.clone(),
                        inner,
                    })
                    .collect())
            })
            .await?
    }

    pub fn comment_draft(&self) -> Result<CommentDraft> {
        let Room::Joined(joined) = &self.room else {
            bail!("Can only comment in joined rooms");
        };
        Ok(CommentDraft {
            client: self.client.clone(),
            room: joined.clone(),
            inner: self.inner.draft_builder(),
        })
    }

    pub fn subscribe(&self) -> Receiver<()> {
        self.client.executor().subscribe(self.inner.update_key())
    }
}
