use acter_matrix::{
    events::comments::{self, CommentBuilder},
    models::{self, can_redact, ActerModel, AnyActerModel},
};
use anyhow::{bail, Result};
use futures::stream::StreamExt;
use matrix_sdk::room::Room;
use matrix_sdk_base::{
    ruma::{
        events::{room::message::TextMessageEventContent, MessageLikeEventType},
        OwnedEventId, OwnedUserId,
    },
    RoomState,
};
use std::ops::Deref;
use tokio::sync::broadcast::Receiver;
use tokio_stream::{wrappers::BroadcastStream, Stream};

use crate::MsgContent;

use super::{client::Client, RUNTIME};

impl Client {
    pub async fn wait_for_comment(&self, key: String, timeout: Option<u8>) -> Result<Comment> {
        let client = self.clone();
        RUNTIME
            .spawn(async move {
                let AnyActerModel::Comment(comment) = client.wait_for(key.clone(), timeout).await?
                else {
                    bail!("{key} is not a comment");
                };
                let room = client.room_by_id_typed(&comment.meta.room_id)?;
                Ok(Comment {
                    client,
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
    pub(crate) fn new(client: Client, room: Room, inner: models::Comment) -> Self {
        Comment {
            client,
            room,
            inner,
        }
    }

    fn is_joined(&self) -> bool {
        matches!(self.room.state(), RoomState::Joined)
    }

    pub fn reply_draft(&self) -> Result<CommentDraft> {
        if !self.is_joined() {
            bail!("Can only comment in joined rooms");
        }
        Ok(CommentDraft {
            client: self.client.clone(),
            room: self.room.clone(),
            inner: self.inner.reply_builder(),
        })
    }

    pub async fn refresh(&self) -> Result<Comment> {
        let key = self.inner.event_id().to_owned();
        let client = self.client.clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let AnyActerModel::Comment(inner) = client.store().get(&key).await? else {
                    bail!("Refreshing failed. {key} not a comment")
                };
                Ok(Comment::new(client, room, inner))
            })
            .await?
    }

    pub async fn can_redact(&self) -> Result<bool> {
        let sender = self.sender();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move { Ok(can_redact(&room, &sender).await?) })
            .await?
    }

    pub fn sender(&self) -> OwnedUserId {
        self.inner.meta.sender.clone()
    }

    pub fn origin_server_ts(&self) -> u64 {
        self.inner.meta.timestamp.get().into()
    }

    pub fn msg_content(&self) -> MsgContent {
        (&self.inner.content).into()
    }

    pub fn update_builder(&self) -> Result<CommentUpdateBuilder> {
        if !self.is_joined() {
            bail!("Can only update comments in joined rooms");
        }
        Ok(CommentUpdateBuilder {
            client: self.client.clone(),
            room: self.room.clone(),
            inner: self.inner.updater(),
        })
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
    room: Room,
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
        let my_id = self.client.user_id()?;
        let inner = self.inner.build()?;

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::RoomMessage)
                    .await?;
                if !permitted {
                    bail!("No permissions to send message in this room");
                }
                let response = room.send(inner).await?;
                Ok(response.event_id)
            })
            .await?
    }
}

#[derive(Clone)]
pub struct CommentUpdateBuilder {
    client: Client,
    room: Room,
    inner: comments::CommentUpdateBuilder,
}

impl CommentUpdateBuilder {
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
        let my_id = self.client.user_id()?;
        let inner = self.inner.build()?;

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::RoomMessage)
                    .await?;
                if !permitted {
                    bail!("No permissions to send message in this room");
                }
                let response = room.send(inner).await?;
                Ok(response.event_id)
            })
            .await?
    }
}

impl CommentsManager {
    pub(crate) async fn new(
        client: Client,
        room: Room,
        event_id: OwnedEventId,
    ) -> Result<CommentsManager> {
        RUNTIME
            .spawn(async move {
                let inner =
                    models::CommentsManager::from_store_and_event_id(client.store(), &event_id)
                        .await;
                Ok(CommentsManager {
                    client,
                    room,
                    inner,
                })
            })
            .await?
    }

    pub fn object_id_str(&self) -> String {
        self.inner.event_id().to_string()
    }

    pub fn room_id_str(&self) -> String {
        self.room.room_id().to_string()
    }

    pub fn stats(&self) -> models::CommentsStats {
        self.inner.stats().clone()
    }

    pub async fn reload(&self) -> Result<CommentsManager> {
        let client = self.client.clone();
        let room = self.room.clone();
        let event_id = self.inner.event_id().to_owned();
        CommentsManager::new(client, room, event_id).await
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
                    .map(|comment| Comment {
                        client: client.clone(),
                        room: room.clone(),
                        inner: comment,
                    })
                    .collect();
                Ok(res)
            })
            .await?
    }

    fn is_joined(&self) -> bool {
        matches!(self.room.state(), RoomState::Joined)
    }

    pub fn comment_draft(&self) -> Result<CommentDraft> {
        if !self.is_joined() {
            bail!("Can only comment in joined rooms");
        }
        Ok(CommentDraft {
            client: self.client.clone(),
            room: self.room.clone(),
            inner: self.inner.draft_builder(),
        })
    }

    pub fn subscribe_stream(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.subscribe()).map(|_| true)
    }

    pub fn subscribe(&self) -> Receiver<()> {
        self.client.subscribe(self.inner.update_key())
    }
}
