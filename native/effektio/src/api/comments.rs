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
        self.inner.stats().has_comments().clone()
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
    // pub async fn refresh(&self) -> Result<CommentsManager> {
    //     let key = self.inner.event_id();
    //     let client = self.client.clone();
    //     let room = self.room.clone();

    //     RUNTIME
    //         .spawn(async move {
    //             let AnyEffektioModel::CommentsManager(inner) = client.store().get_raw(&key).await? else {
    //                 bail!("Refreshing failed. {key} not a task")
    //             };
    //             Ok(CommentsManager {
    //                 client,
    //                 room,
    //                 inner,
    //             })
    //         })
    //         .await?
    // }

    pub fn subscribe(&self) -> Receiver<()> {
        self.client.executor().subscribe(self.inner.update_key())
    }
}

// impl Group {
//     pub async fn comments(&self, key: &str) -> Result<CommentsManager> {
//         let client = self.client.clone();
//         let room = self.room.clone();
//         let event_id = EventId::parse(key)?;

//         RUNTIME
//             .spawn(async move {
//                 let inner =
//                     models::CommentsManager::from_store_and_event_id(client.store(), &event_id)
//                         .await;
//                 Ok(CommentsManager {
//                     client,
//                     room,
//                     inner,
//                 })
//             })
//             .await?
//     }
// }
