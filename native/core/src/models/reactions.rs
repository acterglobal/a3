use derive_getters::Getters;
use ruma_common::{EventId, OwnedEventId, OwnedUserId};
use ruma_events::{reaction::ReactionEventContent, OriginalMessageLikeEvent};
use serde::{Deserialize, Serialize};
use std::{collections::HashMap, ops::Deref};
use tracing::{error, trace};

use super::{AnyActerModel, EventMeta};
use crate::{store::Store, Result};

static REACTION_FIELD: &str = "reactions";
static REACTION_STATS_FIELD: &str = "reaction_stats";

#[derive(Clone, Debug, Default, Deserialize, Serialize, Getters)]
pub struct ReactionStats {
    has_reaction_entries: bool,
    total_reaction_count: u32,
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
        format!("{r}::{REACTION_STATS_FIELD}")
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

    pub async fn reaction_entries(&self) -> Result<HashMap<OwnedUserId, Reaction>> {
        let mut entries = HashMap::new();
        for mdl in self
            .store
            .get_list(&Reaction::index_for(&self.event_id))
            .await?
        {
            if let AnyActerModel::Reaction(c) = mdl {
                let key = c.clone().meta.sender;
                entries.insert(key, c);
            }
        }
        Ok(entries)
    }

    pub(crate) fn add_reaction_entry(&mut self, _entry: &Reaction) -> Result<bool> {
        self.stats.has_reaction_entries = true;
        self.stats.total_reaction_count += 1;
        Ok(true)
    }

    pub fn stats(&self) -> &ReactionStats {
        &self.stats
    }

    fn update_key(&self) -> String {
        Self::stats_field_for(&self.event_id)
    }

    pub async fn save(&self) -> Result<String> {
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
        format!("{r}::{REACTION_FIELD}")
    }
}

impl super::ActerModel for Reaction {
    fn indizes(&self) -> Vec<String> {
        self.belongs_to()
            .unwrap() // we always have some as entries
            .into_iter()
            .map(|v| Reaction::index_for(&v))
            .collect()
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }

    fn capabilities(&self) -> &[super::Capability] {
        &[super::Capability::Reactable]
    }

    async fn execute(self, store: &Store) -> Result<Vec<String>> {
        let belongs_to = self.belongs_to().unwrap();
        trace!(event_id=?self.event_id(), ?belongs_to, "applying reaction");

        let mut managers = vec![];
        for m in belongs_to {
            let model = store.get(&m).await?;
            if !model.capabilities().contains(&super::Capability::Reactable) {
                error!(?model, rsvp = ?self, "doesn't support entries. can't apply");
                continue;
            }

            // FIXME: what if we have this twice in the same loop?
            let mut manager =
                ReactionManager::from_store_and_event_id(store, model.event_id()).await;
            trace!(event_id=?self.event_id(), "adding reaction entry");
            if manager.add_reaction_entry(&self)? {
                trace!(event_id=?self.event_id(), "added reaction entry");
                managers.push(manager);
            }
        }
        let mut updates = store.save(self.clone().into()).await?;
        trace!(event_id=?self.event_id(), "saved reaction entry");
        for manager in managers {
            updates.push(manager.save().await?);
        }
        Ok(updates)
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(vec![self.inner.relates_to.event_id.to_string()])
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
