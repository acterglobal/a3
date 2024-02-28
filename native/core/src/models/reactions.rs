use derive_getters::Getters;
use ruma_common::{EventId, OwnedEventId, OwnedUserId, UserId};
use ruma_events::{reaction::ReactionEventContent, relation::Annotation, OriginalMessageLikeEvent};
use serde::{Deserialize, Serialize};
use std::{collections::HashMap, ops::Deref};
use tracing::{error, trace};

use super::{ActerModel, AnyActerModel, Capability, EventMeta, RedactedActerModel};
use crate::{store::Store, Result};

// We understand all unicode [Red Heart](https://emojipedia.org/red-heart#technical) as quick-likes
static LIKE_HEART: &str = "\u{2764}\u{FE0F}";
static REACTIONS_FIELD: &str = "reactions";
static REACTIONS_STATS_FIELD: &str = "reactions_stats";

#[derive(Clone, Debug, Default, Deserialize, Serialize, Getters)]
pub struct ReactionStats {
    #[serde(default, skip_serializing_if = "is_false")]
    pub has_reaction_entries: bool,
    #[serde(default, skip_serializing_if = "is_false")]
    pub has_like_reactions: bool,
    #[serde(default, skip_serializing_if = "is_zero")]
    pub total_like_reactions: u32,
    #[serde(default, skip_serializing_if = "is_false")]
    pub user_has_liked: bool,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub user_likes: Vec<OwnedEventId>,
    #[serde(default, skip_serializing_if = "is_false")]
    pub user_has_reacted: bool,
    #[serde(default, skip_serializing_if = "is_zero")]
    pub total_reaction_count: u32,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub user_reactions: Vec<OwnedEventId>,
}
/// This is only used for serialize
#[allow(clippy::trivially_copy_pass_by_ref)]
fn is_zero(num: &u32) -> bool {
    *num == 0
}

/// This is only used for serialize
#[allow(clippy::trivially_copy_pass_by_ref)]
fn is_false(val: &bool) -> bool {
    *val == false
}

#[derive(Clone, Debug)]
pub struct ReactionManager {
    stats: ReactionStats,
    event_id: OwnedEventId,
    store: Store,
}

impl ReactionManager {
    fn stats_field_for<T: AsRef<str>>(parent: &T) -> String {
        let r = parent.as_ref();
        format!("{r}::{REACTIONS_STATS_FIELD}")
    }

    pub async fn from_store_and_event_id(store: &Store, event_id: &EventId) -> ReactionManager {
        let store = store.clone();
        let stats = store
            .get_raw(&Self::stats_field_for(&event_id))
            .await
            .unwrap_or_default();
        ReactionManager {
            store,
            stats,
            event_id: event_id.to_owned(),
        }
    }

    pub fn event_id(&self) -> OwnedEventId {
        self.event_id.clone()
    }

    pub async fn get_reacted_user_event(
        &self,
        user_id: &UserId,
        filter: fn(&Reaction) -> bool,
    ) -> Result<Option<Reaction>> {
        for mdl in self
            .store
            .get_list(&Reaction::index_for(&self.event_id))
            .await?
        {
            if let AnyActerModel::Reaction(c) = mdl {
                if c.meta.sender == user_id && filter(&c) {
                    return Ok(Some(c));
                }
            }
        }
        Ok(None)
    }

    pub fn construct_like_event(&self) -> ReactionEventContent {
        self.construct_reaction_event(LIKE_HEART.to_string())
    }

    pub fn construct_reaction_event(&self, key: String) -> ReactionEventContent {
        ReactionEventContent::new(Annotation::new(self.event_id.clone(), key))
    }

    pub async fn reaction_entries(&self) -> Result<HashMap<OwnedUserId, Reaction>> {
        let mut entries = HashMap::new();
        for mdl in self
            .store
            .get_list(&Reaction::index_for(&self.event_id))
            .await?
        {
            if let AnyActerModel::Reaction(c) = mdl {
                let sender = c.clone().meta.sender;
                entries.insert(sender, c);
            }
        }
        Ok(entries)
    }

    pub(crate) fn add_reaction_entry(&mut self, entry: &Reaction) -> Result<bool> {
        self.stats.has_reaction_entries = true;
        self.stats.total_reaction_count += 1;
        let is_my_reaction = self.store.user_id() == entry.meta.sender;

        if is_my_reaction {
            self.stats.user_has_reacted = true;
            self.stats.user_reactions.push(entry.meta.event_id.clone());
        }

        if entry.inner.relates_to.key == LIKE_HEART {
            self.stats.has_like_reactions = true;
            self.stats.total_like_reactions += 1;

            if is_my_reaction {
                self.stats.user_has_liked = true;
                self.stats.user_likes.push(entry.meta.event_id.clone());
            }
        }
        Ok(true)
    }

    pub(crate) fn redact_reaction_entry(
        &mut self,
        entry: &Reaction,
        _redaction: &RedactedActerModel,
    ) -> Result<bool> {
        let was_my_reaction = self.store.user_id() == entry.meta.sender;

        self.stats.total_reaction_count = self
            .stats
            .total_reaction_count
            .checked_sub(1)
            .unwrap_or_default();
        self.stats.has_reaction_entries = self.stats.total_reaction_count > 0;
        if was_my_reaction {
            self.stats
                .user_reactions
                .retain(|e| e != &entry.meta.event_id); // only keep the others
            self.stats.user_has_reacted = self.stats.user_reactions.len() > 0
        }

        if entry.inner.relates_to.key == LIKE_HEART {
            self.stats.has_like_reactions = true;
            self.stats.total_like_reactions = self
                .stats
                .total_like_reactions
                .checked_sub(1)
                .unwrap_or_default();
            self.stats.has_like_reactions = self.stats.total_like_reactions > 0;

            if was_my_reaction {
                self.stats.user_likes.retain(|e| e != &entry.meta.event_id); // only keep the others
                self.stats.user_has_liked = self.stats.user_likes.len() > 0
            }
        }
        Ok(true)
    }

    pub fn stats(&self) -> ReactionStats {
        self.stats.clone()
    }

    pub fn update_key(&self) -> String {
        Self::stats_field_for(&self.event_id)
    }

    pub async fn save(&self) -> Result<String> {
        trace!(?self.stats, ?self.event_id, "Updated entry");
        let update_key = self.update_key();
        self.store.set_raw(&update_key, &self.stats).await?;
        Ok(update_key)
    }
}

impl Deref for ReactionManager {
    type Target = ReactionStats;
    fn deref(&self) -> &Self::Target {
        &self.stats
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Reaction {
    pub(crate) inner: ReactionEventContent,
    pub meta: EventMeta,
}

impl Deref for Reaction {
    type Target = ReactionEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl Reaction {
    pub fn index_for<T: AsRef<str>>(parent: &T) -> String {
        let r = parent.as_ref();
        format!("{r}::{REACTIONS_FIELD}")
    }

    async fn apply(
        &self,
        store: &Store,
        redaction_model: Option<RedactedActerModel>,
    ) -> Result<Vec<String>> {
        let belongs_to = self.belongs_to().unwrap();
        trace!(event_id=?self.event_id(), ?belongs_to, "applying reaction");

        let mut managers = vec![];
        for m in belongs_to {
            let model = store.get(&m).await?;
            if !model.capabilities().contains(&Capability::Reactable) {
                error!(?model, reaction = ?self, "doesn't support entries. can't apply");
                continue;
            }

            // FIXME: what if we have this twice in the same loop?
            let mut manager =
                ReactionManager::from_store_and_event_id(store, model.event_id()).await;
            trace!(event_id=?self.event_id(), "adding reaction entry");
            if let Some(redacted) = redaction_model.as_ref() {
                if manager.redact_reaction_entry(&self, &redacted)? {
                    trace!(event_id=?self.event_id(), "added reaction entry");
                    managers.push(manager);
                }
            } else {
                if manager.add_reaction_entry(&self)? {
                    trace!(event_id=?self.event_id(), "added reaction entry");
                    managers.push(manager);
                }
            }
        }
        let mut updates = store.save(self.clone().into()).await?;
        trace!(event_id=?self.event_id(), "saved reaction entry");
        for manager in managers {
            updates.push(manager.save().await?);
        }
        Ok(updates)
    }
}

impl ActerModel for Reaction {
    fn indizes(&self, _user_id: &UserId) -> Vec<String> {
        self.belongs_to()
            .expect("we always have some as entries")
            .into_iter()
            .map(|v| Reaction::index_for(&v))
            .collect()
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }

    async fn execute(self, store: &Store) -> Result<Vec<String>> {
        self.apply(store, None).await
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(vec![self.inner.relates_to.event_id.to_string()])
    }

    // custom redaction code
    async fn redact(
        &self,
        store: &Store,
        redaction_model: RedactedActerModel,
    ) -> crate::Result<Vec<String>> {
        self.apply(store, Some(redaction_model)).await
    }
}

impl From<OriginalMessageLikeEvent<ReactionEventContent>> for Reaction {
    fn from(outer: OriginalMessageLikeEvent<ReactionEventContent>) -> Self {
        let OriginalMessageLikeEvent {
            content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = outer;
        Reaction {
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
