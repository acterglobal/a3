use derive_getters::Getters;
use matrix_sdk_base::ruma::{
    events::OriginalMessageLikeEvent, EventId, OwnedEventId, OwnedUserId, UserId,
};
use serde::{Deserialize, Serialize};
use std::{collections::HashMap, ops::Deref};
use tracing::{error, trace};

use super::{ActerModel, AnyActerModel, Capability, EventMeta};
use crate::{
    events::explicit_invites::ExplicitInviteEventContent,
    referencing::{ExecuteReference, IndexKey, ModelParam, ObjectListIndex},
    store::Store,
    Result,
};

#[derive(Clone, Debug, Default, Deserialize, Serialize, Getters)]
pub struct InviteStats {
    invited: Vec<OwnedUserId>,
}

#[derive(Clone, Debug)]
pub struct InvitationsManager {
    stats: InviteStats,
    event_id: OwnedEventId,
    store: Store,
}

impl InvitationsManager {
    fn stats_field_for(parent: OwnedEventId) -> ExecuteReference {
        ExecuteReference::ModelParam(parent, ModelParam::InviteStats)
    }

    pub async fn from_store_and_event_id(store: &Store, event_id: &EventId) -> InvitationsManager {
        let store = store.clone();
        let stats = store
            .get_raw(&Self::stats_field_for(event_id.to_owned()).as_storage_key())
            .await
            .unwrap_or_default();
        InvitationsManager {
            store,
            stats,
            event_id: event_id.to_owned(),
        }
    }

    pub fn event_id(&self) -> OwnedEventId {
        self.event_id.clone()
    }

    pub fn invited(&self) -> &Vec<OwnedUserId> {
        &self.stats.invited
    }

    pub async fn invite_entries(&self) -> Result<HashMap<OwnedUserId, ExplicitInvite>> {
        let mut entries = HashMap::new();
        for mdl in self
            .store
            .get_list(&ExplicitInvite::index_for(self.event_id.clone()))
            .await?
        {
            if let AnyActerModel::ExplicitInvite(c) = mdl {
                let key = c.clone().meta.sender;
                entries.entry(key).or_insert(c); // we ignore older entries
            }
        }
        Ok(entries)
    }

    pub(crate) fn add_invite_entry(&mut self, entry: &ExplicitInvite) -> Result<bool> {
        for user_id in &entry.inner.mention.user_ids {
            if !self.stats.invited.contains(user_id) {
                self.stats.invited.push(user_id.clone());
            }
        }
        Ok(true)
    }

    pub fn stats(&self) -> &InviteStats {
        &self.stats
    }

    pub fn update_key(&self) -> ExecuteReference {
        Self::stats_field_for(self.event_id.to_owned())
    }

    pub async fn save(&self) -> Result<ExecuteReference> {
        let update_key = self.update_key();
        self.store
            .set_raw(&update_key.as_storage_key(), &self.stats)
            .await?;
        Ok(update_key)
    }
}

impl Deref for InvitationsManager {
    type Target = InviteStats;
    fn deref(&self) -> &Self::Target {
        &self.stats
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct ExplicitInvite {
    pub(crate) inner: ExplicitInviteEventContent,
    pub meta: EventMeta,
}

impl Deref for ExplicitInvite {
    type Target = ExplicitInviteEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl ExplicitInvite {
    pub fn index_for(parent: OwnedEventId) -> IndexKey {
        IndexKey::ObjectList(parent, ObjectListIndex::Invites)
    }
}

impl ActerModel for ExplicitInvite {
    fn indizes(&self, _user_id: &UserId) -> Vec<IndexKey> {
        vec![
            ExplicitInvite::index_for(self.inner.to.event_id.clone()),
            IndexKey::ObjectHistory(self.inner.to.event_id.to_owned()),
            IndexKey::RoomHistory(self.meta.room_id.clone()),
        ]
    }

    fn event_meta(&self) -> &EventMeta {
        &self.meta
    }

    fn capabilities(&self) -> &[Capability] {
        &[]
    }

    async fn execute(self, store: &Store) -> Result<Vec<ExecuteReference>> {
        let belongs_to = self.inner.to.event_id.to_owned();
        trace!(event_id=?self.event_id(), ?belongs_to, "applying invite");

        let manager = {
            let model = store.get(&belongs_to).await?;
            if !model.capabilities().contains(&Capability::Inviteable) {
                error!(?model, invite = ?self, "doesn’t support entries. can’t apply");
                None
            } else {
                let mut manager =
                    InvitationsManager::from_store_and_event_id(store, model.event_id()).await;
                trace!(event_id=?self.event_id(), "adding invite entry");
                if manager.add_invite_entry(&self)? {
                    trace!(event_id=?self.event_id(), "added invite entry");
                    Some(manager)
                } else {
                    None
                }
            }
        };

        let mut updates = store.save(self.clone().into()).await?;
        trace!(event_id=?self.event_id(), "saved invite entry");
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

impl From<OriginalMessageLikeEvent<ExplicitInviteEventContent>> for ExplicitInvite {
    fn from(outer: OriginalMessageLikeEvent<ExplicitInviteEventContent>) -> Self {
        let OriginalMessageLikeEvent {
            content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = outer;
        ExplicitInvite {
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
