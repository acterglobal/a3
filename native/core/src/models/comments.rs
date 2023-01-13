use std::ops::Deref;

use crate::events::comments::{
    CommentBuilder, CommentEventContent, CommentUpdateBuilder, CommentUpdateEventContent,
};
use crate::store::Store;
use derive_getters::Getters;
use matrix_sdk::ruma::{events::OriginalMessageLikeEvent, EventId, OwnedEventId};
use serde::{Deserialize, Serialize};

use super::{AnyEffektioModel, EventMeta};

static COMMENTS_FIELD: &str = "comments";
static COMMENTS_STATS_FIELD: &str = "comments_stats";

#[derive(Clone, Debug, Default, Deserialize, Serialize, Getters)]
pub struct CommentsStats {
    has_comments: bool,
    total_comments_count: u32,
}

#[derive(Clone, Debug)]
pub struct CommentsManager {
    stats: CommentsStats,
    event_id: OwnedEventId,
    store: Store,
}

impl CommentsManager {
    pub async fn from_store_and_event_id(store: &Store, event_id: &EventId) -> CommentsManager {
        let store = store.clone();
        let stats = store
            .get_raw(&format!("{event_id}::{COMMENTS_STATS_FIELD}"))
            .await
            .unwrap_or_default();
        CommentsManager {
            store,
            stats,
            event_id: event_id.to_owned(),
        }
    }

    pub async fn comments(&self) -> crate::Result<Vec<Comment>> {
        Ok(self
            .store
            .get_list(&format!("{}::{COMMENTS_FIELD}", self.event_id))
            .await?
            .filter_map(|e| match e {
                AnyEffektioModel::Comment(c) => Some(c),
                _ => None,
            })
            .collect())
    }

    pub(crate) async fn add_comment(&mut self, _comment: &Comment) -> crate::Result<bool> {
        self.stats.has_comments = true;
        self.stats.total_comments_count += 1;
        Ok(true)
    }

    pub fn stats(&self) -> &CommentsStats {
        &self.stats
    }

    pub fn draft_builder(&self) -> CommentBuilder {
        CommentBuilder::default()
            .on(self.event_id.to_owned())
            .to_owned()
    }

    pub fn update_key(&self) -> String {
        format!("{}::{COMMENTS_STATS_FIELD}", self.event_id)
    }

    pub async fn save(&self) -> crate::Result<String> {
        let update_key = self.update_key();
        self.store.set_raw(&update_key, &self.stats).await?;
        Ok(update_key)
    }
}

impl Deref for CommentsManager {
    type Target = CommentsStats;
    fn deref(&self) -> &Self::Target {
        &self.stats
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Comment {
    inner: CommentEventContent,
    pub meta: EventMeta,
}

impl Deref for Comment {
    type Target = CommentEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl Comment {
    pub fn updater(&self) -> CommentUpdateBuilder {
        CommentUpdateBuilder::default()
            .comment(self.meta.event_id.to_owned())
            .to_owned()
    }

    pub fn reply_builder(&self) -> CommentBuilder {
        CommentBuilder::default()
            .on(self.on.event_id.to_owned())
            .reply_to(Some(self.meta.event_id.to_owned().into()))
            .to_owned()
    }
}

impl super::EffektioModel for Comment {
    fn indizes(&self) -> Vec<String> {
        self.belongs_to()
            .unwrap() // we always have some as comments
            .into_iter()
            .map(|v| format!("{v}::{COMMENTS_FIELD}"))
            .collect()
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }

    fn supports_comments(&self) -> bool {
        true
    }

    async fn execute(self, store: &Store) -> crate::Result<Vec<String>> {
        let belongs_to = self.belongs_to().unwrap();
        tracing::trace!(event_id=?self.event_id(), ?belongs_to, "applying comment");

        let mut managers = vec![];
        for p in belongs_to {
            let parent = store.get(&p).await?;
            if !parent.supports_comments() {
                tracing::error!(?parent, comment = ?self, "doesn't support comments. can't apply");
                continue;
            }

            // FIXME: what if we have this twice in the same loop?
            let mut manager =
                CommentsManager::from_store_and_event_id(store, parent.event_id()).await;
            if manager.add_comment(&self).await? {
                managers.push(manager);
            }
        }
        store.save(self.into()).await?;
        let mut updates = vec![];
        for manager in managers {
            updates.push(manager.save().await?);
        }
        Ok(updates)
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        let mut references = self
            .inner
            .reply_to
            .as_ref()
            .map(|r| {
                r.event_ids
                    .iter()
                    .map(ToString::to_string)
                    .collect::<Vec<_>>()
            })
            .unwrap_or_default();
        references.push(self.inner.on.event_id.to_string());
        Some(references)
    }

    fn transition(&mut self, model: &super::AnyEffektioModel) -> crate::Result<bool> {
        let AnyEffektioModel::CommentUpdate(update) = model else {
            return Ok(false)
        };

        update.apply(&mut self.inner)
    }
}

impl From<OriginalMessageLikeEvent<CommentEventContent>> for Comment {
    fn from(outer: OriginalMessageLikeEvent<CommentEventContent>) -> Self {
        let OriginalMessageLikeEvent {
            content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = outer;
        Comment {
            inner: content,
            meta: EventMeta {
                room_id,
                event_id,
                sender,
                origin_server_ts,
            },
        }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct CommentUpdate {
    inner: CommentUpdateEventContent,
    meta: EventMeta,
}

impl super::EffektioModel for CommentUpdate {
    fn indizes(&self) -> Vec<String> {
        vec![format!("{:}::history", self.inner.comment.event_id)]
    }
    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }
    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(vec![self.inner.comment.event_id.to_string()])
    }
    async fn execute(self, store: &super::Store) -> crate::Result<Vec<String>> {
        super::default_model_execute(store, self.into()).await
    }
}

impl Deref for CommentUpdate {
    type Target = CommentUpdateEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl From<OriginalMessageLikeEvent<CommentUpdateEventContent>> for CommentUpdate {
    fn from(outer: OriginalMessageLikeEvent<CommentUpdateEventContent>) -> Self {
        let OriginalMessageLikeEvent {
            content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = outer;
        CommentUpdate {
            inner: content,
            meta: EventMeta {
                room_id,
                event_id,
                sender,
                origin_server_ts,
            },
        }
    }
}
