use acter_core::{
    events::comments::CommentBuilder,
    models::{self, ActerModel, AnyActerModel, Color},
};
use anyhow::{bail, Context, Result};
use core::time::Duration;
use futures::stream::StreamExt;
use matrix_sdk::{
    room::{Joined, Room},
    ruma::{events::room::message::TextMessageEventContent, OwnedEventId, OwnedUserId},
};
use std::ops::Deref;
use tokio::sync::broadcast::Receiver;

use super::{client::Client, RUNTIME};

impl Client {
    pub async fn wait_for_comment(
        &self,
        key: String,
        timeout: Option<Box<Duration>>,
    ) -> Result<Comment> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let AnyActerModel::Comment(comment) = me.wait_for(key.clone(), timeout).await? else {
                    bail!("{key} is not a comment");
                };
                let room = me
                    .core
                    .client()
                    .get_room(&comment.meta.room_id)
                    .context("Room not found")?;
                Ok(Comment {
                    client: me.clone(),
                    room,
                    inner: comment,
                })
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct Comment {
    client: Client,
    room: Room,
    inner: models::Comment,
}

impl Deref for Comment {
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

    pub fn sender(&self) -> OwnedUserId {
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

impl Deref for CommentsManager {
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
                let res = manager
                    .comments()
                    .await?
                    .into_iter()
                    .map(|inner| Comment {
                        client: client.clone(),
                        room: room.clone(),
                        inner,
                    })
                    .collect();
                Ok(res)
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

    pub fn subscribe_stream(&self) -> impl tokio_stream::Stream<Item = ()> {
        tokio_stream::wrappers::BroadcastStream::new(self.subscribe())
            .map(|f| f.unwrap_or_default())
    }

    pub fn subscribe(&self) -> tokio::sync::broadcast::Receiver<()> {
        self.client.subscribe(self.inner.update_key())
    }
}
