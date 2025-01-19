use derive_getters::Getters;
use matrix_sdk_base::ruma::{events::OriginalMessageLikeEvent, EventId, OwnedEventId, UserId};
use serde::{Deserialize, Serialize};
use std::ops::Deref;
use tracing::{error, info, trace};

use super::{default_model_execute, ActerModel, AnyActerModel, Capability, EventMeta};
use crate::{
    events::comments::{
        CommentBuilder, CommentEventContent, CommentUpdateBuilder, CommentUpdateEventContent,
    },
    store::Store,
    util::{is_false, is_zero},
    Result,
};

static COMMENTS_FIELD: &str = "comments";
static COMMENTS_STATS_FIELD: &str = "comments_stats";

#[derive(Clone, Debug, Default, Deserialize, Serialize, Getters)]
pub struct CommentsStats {
    #[serde(default, skip_serializing_if = "is_false")]
    pub has_comments: bool,
    #[serde(default, skip_serializing_if = "is_zero")]
    pub total_comments_count: u32,
}

#[derive(Clone, Debug)]
pub struct CommentsManager {
    stats: CommentsStats,
    event_id: OwnedEventId,
    store: Store,
}

impl CommentsManager {
    fn stats_field_for<T: AsRef<str>>(parent: &T) -> String {
        let r = parent.as_ref();
        format!("{r}::{COMMENTS_STATS_FIELD}")
    }

    pub async fn from_store_and_event_id(store: &Store, event_id: &EventId) -> CommentsManager {
        let store = store.clone();

        let stats = match store.get_raw(&Self::stats_field_for(&event_id)).await {
            Ok(e) => e,
            Err(error) => {
                info!(
                    ?error,
                    ?event_id,
                    "failed to read reaction stats. starting with default"
                );
                Default::default()
            }
        };
        CommentsManager {
            store,
            stats,
            event_id: event_id.to_owned(),
        }
    }

    pub async fn comments(&self) -> Result<Vec<Comment>> {
        let comments = self
            .store
            .get_list(&Comment::index_for(&self.event_id))
            .await?
            .filter_map(|e| match e {
                AnyActerModel::Comment(c) => Some(c),
                _ => None,
            })
            .collect();
        Ok(comments)
    }

    pub(crate) async fn add_comment(&mut self, _comment: &Comment) -> Result<bool> {
        self.stats.has_comments = true;
        self.stats.total_comments_count += 1;
        Ok(true)
    }

    pub fn stats(&self) -> CommentsStats {
        self.stats.clone()
    }

    pub fn draft_builder(&self) -> CommentBuilder {
        CommentBuilder::default()
            .on(self.event_id.to_owned())
            .to_owned()
    }

    pub fn update_key(&self) -> String {
        Self::stats_field_for(&self.event_id)
    }

    pub async fn save(&self) -> Result<String> {
        let update_key = self.update_key();
        self.store.set_raw(&update_key, &self.stats).await?;
        Ok(update_key)
    }

    pub fn event_id(&self) -> &EventId {
        &self.event_id
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
    pub(crate) inner: CommentEventContent,
    pub meta: EventMeta,
}

impl Deref for Comment {
    type Target = CommentEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl Comment {
    pub fn index_for<T: AsRef<str>>(parent: &T) -> String {
        let r = parent.as_ref();
        format!("{r}::{COMMENTS_FIELD}")
    }

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

    fn belongs_to_inner(&self) -> Vec<String> {
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
        references
    }
}

impl ActerModel for Comment {
    fn indizes(&self, _user_id: &UserId) -> Vec<String> {
        self.belongs_to_inner()
            .into_iter()
            .map(|v| Comment::index_for(&v))
            .collect()
    }

    fn event_meta(&self) -> &EventMeta {
        &self.meta
    }

    fn capabilities(&self) -> &[Capability] {
        &[Capability::Commentable, Capability::Reactable]
    }

    async fn execute(self, store: &Store) -> Result<Vec<String>> {
        let belongs_to = self.belongs_to_inner();
        trace!(event_id=?self.event_id(), ?belongs_to, "applying comment");

        let mut managers = vec![];
        for p in belongs_to {
            let parent = store.get(&p).await?;
            if !parent.capabilities().contains(&Capability::Commentable) {
                error!(?parent, comment = ?self, "doesn’t support comments. can’t apply");
                continue;
            }

            // FIXME: what if we have this twice in the same loop?
            let mut manager =
                CommentsManager::from_store_and_event_id(store, parent.event_id()).await;
            if manager.add_comment(&self).await? {
                managers.push(manager);
            }
        }
        let mut updates = store.save(self.clone().into()).await?;
        trace!(event_id=?self.event_id(), "saved comment");
        for manager in managers {
            updates.push(manager.save().await?);
        }
        Ok(updates)
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        // Do not trigger the parent to update, we have a manager
        None
    }

    fn transition(&mut self, model: &AnyActerModel) -> Result<bool> {
        let AnyActerModel::CommentUpdate(update) = model else {
            return Ok(false);
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
                redacted: None,
            },
        }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct CommentUpdate {
    inner: CommentUpdateEventContent,
    meta: EventMeta,
}

impl ActerModel for CommentUpdate {
    fn indizes(&self, _user_id: &UserId) -> Vec<String> {
        vec![format!("{:}::history", self.inner.comment.event_id)]
    }
    fn event_meta(&self) -> &EventMeta {
        &self.meta
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(vec![self.inner.comment.event_id.to_string()])
    }

    async fn execute(self, store: &Store) -> Result<Vec<String>> {
        default_model_execute(store, self.into()).await
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
                redacted: None,
            },
        }
    }
}
