use derive_getters::Getters;
use matrix_sdk_base::ruma::{
    events::OriginalMessageLikeEvent, EventId, OwnedEventId, OwnedUserId, UserId,
};
use serde::{Deserialize, Serialize};
use std::{collections::HashMap, ops::Deref};
use tracing::{error, trace};

use super::{ActerModel, AnyActerModel, Capability, EventMeta};
use crate::{
    events::rsvp::{RsvpBuilder, RsvpEventContent},
    referencing::{ExecuteReference, IndexKey, ModelParam, ObjectListIndex},
    store::Store,
    Result,
};

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
    fn stats_field_for(parent: OwnedEventId) -> ExecuteReference {
        ExecuteReference::ModelParam(parent, ModelParam::RsvpStats)
    }

    pub async fn from_store_and_event_id(store: &Store, event_id: &EventId) -> RsvpManager {
        let store = store.clone();
        let stats = store
            .get_raw(&Self::stats_field_for(event_id.to_owned()).as_storage_key())
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

    pub async fn rsvp_entries(&self) -> Result<HashMap<OwnedUserId, Rsvp>> {
        let mut entries = HashMap::new();
        for mdl in self
            .store
            .get_list(&Rsvp::index_for(self.event_id.clone()))
            .await?
        {
            if let AnyActerModel::Rsvp(c) = mdl {
                let key = c.clone().meta.sender;
                entries.entry(key).or_insert(c); // we ignore older entries
            }
        }
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
        RsvpBuilder::default().to(self.event_id.clone()).to_owned()
    }

    pub fn update_key(&self) -> ExecuteReference {
        Self::stats_field_for(self.event_id.clone())
    }

    pub async fn save(&self) -> Result<ExecuteReference> {
        let update_key = self.update_key();
        self.store
            .set_raw(&update_key.as_storage_key(), &self.stats)
            .await?;
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
    pub fn index_for(parent: OwnedEventId) -> IndexKey {
        IndexKey::ObjectList(parent, ObjectListIndex::Rsvp)
    }
}

impl ActerModel for Rsvp {
    fn indizes(&self, _user_id: &UserId) -> Vec<IndexKey> {
        vec![
            Rsvp::index_for(self.inner.to.event_id.clone()),
            IndexKey::ObjectHistory(self.inner.to.event_id.clone()),
            IndexKey::RoomHistory(self.meta.room_id.clone()),
            IndexKey::AllHistory,
        ]
    }

    fn event_meta(&self) -> &EventMeta {
        &self.meta
    }

    fn capabilities(&self) -> &[Capability] {
        &[]
    }

    async fn execute(self, store: &Store) -> Result<Vec<ExecuteReference>> {
        let belongs_to = self.inner.to.event_id.clone();
        trace!(event_id=?self.event_id(), ?belongs_to, "applying rsvp");

        let manager = {
            let model = store.get(&belongs_to).await?;
            if !model.capabilities().contains(&Capability::RSVPable) {
                error!(?model, rsvp = ?self, "doesn’t support entries. can’t apply");
                None
            } else {
                let mut manager =
                    RsvpManager::from_store_and_event_id(store, model.event_id()).await;
                trace!(event_id=?self.event_id(), "adding rsvp entry");
                if manager.add_rsvp_entry(&self)? {
                    trace!(event_id=?self.event_id(), "added rsvp entry");
                    Some(manager)
                } else {
                    None
                }
            }
        };

        let mut updates = store.save(self.clone().into()).await?;
        trace!(event_id=?self.event_id(), "saved rsvp entry");
        if let Some(manager) = manager {
            updates.push(manager.save().await?);
        }
        Ok(updates)
    }

    fn belongs_to(&self) -> Option<Vec<OwnedEventId>> {
        // the higher ups don’t need to be bothered by this
        None
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
                redacted: None,
            },
        }
    }
}
