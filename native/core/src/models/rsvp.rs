use derive_getters::Getters;
use ruma_common::{events::OriginalMessageLikeEvent, EventId, OwnedEventId};
use serde::{Deserialize, Serialize};
use std::ops::Deref;
use tracing::{error, trace};

use super::{AnyActerModel, EventMeta};
use crate::{
    events::rsvp::{RsvpBuilder, RsvpEventContent},
    store::Store,
    Result,
};

static RSVP_FIELD: &str = "rsvp";
static RSVP_STATS_FIELD: &str = "rsvp_stats";

#[derive(Clone, Debug, Default, Deserialize, Serialize, Getters)]
pub struct RsvpStats {
    has_rsvp_entries: bool,
    total_rsvp_count: u32,
}

#[derive(Clone, Debug)]
pub struct RsvpManager {
    stats: RsvpStats,
    event_id: OwnedEventId,
    store: Store,
}

impl RsvpManager {
    fn stats_field_for<T: AsRef<str>>(parent: &T) -> String {
        let r = parent.as_ref();
        format!("{r}::{RSVP_STATS_FIELD}")
    }

    pub async fn from_store_and_event_id(store: &Store, event_id: &EventId) -> RsvpManager {
        let store = store.clone();
        let stats = store
            .get_raw(&Self::stats_field_for(&event_id))
            .await
            .unwrap_or_default();
        RsvpManager {
            store,
            stats,
            event_id: event_id.to_owned(),
        }
    }

    pub fn event_id(&self) -> OwnedEventId {
        self.event_id.clone()
    }

    pub async fn rsvp_entries(&self) -> Result<Vec<Rsvp>> {
        let entries = self
            .store
            .get_list(&Rsvp::index_for(&self.event_id))
            .await?
            .filter_map(|e| match e {
                AnyActerModel::Rsvp(c) => Some(c),
                _ => None,
            })
            .collect();
        Ok(entries)
    }

    pub(crate) fn add_rsvp_entry(&mut self, _entry: &Rsvp) -> Result<bool> {
        self.stats.has_rsvp_entries = true;
        self.stats.total_rsvp_count += 1;
        Ok(true)
    }

    pub fn stats(&self) -> &RsvpStats {
        &self.stats
    }

    pub fn draft_builder(&self) -> RsvpBuilder {
        RsvpBuilder::default()
            .to(self.event_id.to_owned())
            .to_owned()
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

impl Deref for RsvpManager {
    type Target = RsvpStats;
    fn deref(&self) -> &Self::Target {
        &self.stats
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Rsvp {
    pub(crate) inner: RsvpEventContent,
    pub meta: EventMeta,
}

impl Deref for Rsvp {
    type Target = RsvpEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl Rsvp {
    pub fn index_for<T: AsRef<str>>(parent: &T) -> String {
        let r = parent.as_ref();
        format!("{r}::{RSVP_FIELD}")
    }
}

impl super::ActerModel for Rsvp {
    fn indizes(&self) -> Vec<String> {
        self.belongs_to()
            .unwrap() // we always have some as entries
            .into_iter()
            .map(|v| Rsvp::index_for(&v))
            .collect()
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }

    fn capabilities(&self) -> &[super::Capability] {
        &[super::Capability::Commentable]
    }

    async fn execute(self, store: &Store) -> Result<Vec<String>> {
        let belongs_to = self.belongs_to().unwrap();
        trace!(event_id=?self.event_id(), ?belongs_to, "applying rsvp");

        let mut managers = vec![];
        for m in belongs_to {
            let model = store.get(&m).await?;
            if !model
                .capabilities()
                .contains(&super::Capability::Commentable)
            {
                error!(?model, rsvp = ?self, "doesn't support entries. can't apply");
                continue;
            }

            // FIXME: what if we have this twice in the same loop?
            let mut manager = RsvpManager::from_store_and_event_id(store, model.event_id()).await;
            trace!(event_id=?self.event_id(), "adding rsvp entry");
            if manager.add_rsvp_entry(&self)? {
                trace!(event_id=?self.event_id(), "added rsvp entry");
                managers.push(manager);
            }
        }
        let mut updates = store.save(self.clone().into()).await?;
        trace!(event_id=?self.event_id(), "saved rsvp entry");
        for manager in managers {
            updates.push(manager.save().await?);
        }
        Ok(updates)
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(vec![self.inner.to.event_id.to_string()])
    }
}

impl From<OriginalMessageLikeEvent<RsvpEventContent>> for Rsvp {
    fn from(outer: OriginalMessageLikeEvent<RsvpEventContent>) -> Self {
        let OriginalMessageLikeEvent {
            content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = outer;
        Rsvp {
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
