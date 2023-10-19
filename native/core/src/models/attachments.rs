use derive_getters::Getters;
use ruma_common::{EventId, OwnedEventId};
use ruma_events::OriginalMessageLikeEvent;
use serde::{Deserialize, Serialize};
use std::ops::Deref;
use tracing::{error, trace};

use super::{AnyActerModel, EventMeta};
use crate::{
    events::attachments::{
        AttachmentBuilder, AttachmentEventContent, AttachmentUpdateBuilder,
        AttachmentUpdateEventContent,
    },
    store::Store,
    Result,
};

static ATTACHMENTS_FIELD: &str = "attachments";
static ATTACHMENTS_STATS_FIELD: &str = "attachments_stats";

#[derive(Clone, Debug, Default, Deserialize, Serialize, Getters)]
pub struct AttachmentsStats {
    has_attachments: bool,
    total_attachments_count: u32,
}

#[derive(Clone, Debug)]
pub struct AttachmentsManager {
    stats: AttachmentsStats,
    event_id: OwnedEventId,
    store: Store,
}

impl AttachmentsManager {
    fn stats_field_for<T: AsRef<str>>(parent: &T) -> String {
        let r = parent.as_ref();
        format!("{r}::{ATTACHMENTS_STATS_FIELD}")
    }

    pub async fn from_store_and_event_id(store: &Store, event_id: &EventId) -> AttachmentsManager {
        let store = store.clone();
        let stats = store
            .get_raw(&Self::stats_field_for(&event_id))
            .await
            .unwrap_or_default();
        AttachmentsManager {
            store,
            stats,
            event_id: event_id.to_owned(),
        }
    }

    pub async fn attachments(&self) -> Result<Vec<Attachment>> {
        let attachments = self
            .store
            .get_list(&Attachment::index_for(&self.event_id))
            .await?
            .filter_map(|e| match e {
                AnyActerModel::Attachment(c) => Some(c),
                _ => None,
            })
            .collect();
        Ok(attachments)
    }

    pub(crate) async fn add_attachment(&mut self, _attachment: &Attachment) -> Result<bool> {
        self.stats.has_attachments = true;
        self.stats.total_attachments_count += 1;
        Ok(true)
    }

    pub fn stats(&self) -> &AttachmentsStats {
        &self.stats
    }

    pub fn draft_builder(&self) -> AttachmentBuilder {
        AttachmentBuilder::default()
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
}

impl Deref for AttachmentsManager {
    type Target = AttachmentsStats;
    fn deref(&self) -> &Self::Target {
        &self.stats
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Attachment {
    pub(crate) inner: AttachmentEventContent,
    pub meta: EventMeta,
}

impl Deref for Attachment {
    type Target = AttachmentEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl Attachment {
    pub fn index_for<T: AsRef<str>>(parent: &T) -> String {
        let r = parent.as_ref();
        format!("{r}::{ATTACHMENTS_FIELD}")
    }

    pub fn updater(&self) -> AttachmentUpdateBuilder {
        AttachmentUpdateBuilder::default()
            .attachment(self.meta.event_id.to_owned())
            .to_owned()
    }
}

impl super::ActerModel for Attachment {
    fn indizes(&self) -> Vec<String> {
        self.belongs_to()
            .unwrap() // we always have some as attachments
            .into_iter()
            .map(|v| Attachment::index_for(&v))
            .collect()
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }

    fn capabilities(&self) -> &[super::Capability] {
        &[]
    }

    async fn execute(self, store: &Store) -> Result<Vec<String>> {
        let belongs_to = self.belongs_to().unwrap();
        trace!(event_id=?self.event_id(), ?belongs_to, "applying attachment");

        let mut managers = vec![];
        for p in belongs_to {
            let parent = store.get(&p).await?;
            if !parent
                .capabilities()
                .contains(&super::Capability::HasAttachments)
            {
                error!(?parent, attachment = ?self, "doesn't support attachments. can't apply");
                continue;
            }

            // FIXME: what if we have this twice in the same loop?
            let mut manager =
                AttachmentsManager::from_store_and_event_id(store, parent.event_id()).await;
            if manager.add_attachment(&self).await? {
                managers.push(manager);
            }
        }
        let mut updates = store.save(self.into()).await?;
        for manager in managers {
            updates.push(manager.save().await?);
        }
        Ok(updates)
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(vec![self.inner.on.event_id.to_string()])
    }

    fn transition(&mut self, model: &super::AnyActerModel) -> Result<bool> {
        let AnyActerModel::AttachmentUpdate(update) = model else {
            return Ok(false)
        };

        update.apply(&mut self.inner)
    }
}

impl From<OriginalMessageLikeEvent<AttachmentEventContent>> for Attachment {
    fn from(outer: OriginalMessageLikeEvent<AttachmentEventContent>) -> Self {
        let OriginalMessageLikeEvent {
            content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = outer;
        Attachment {
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
pub struct AttachmentUpdate {
    inner: AttachmentUpdateEventContent,
    meta: EventMeta,
}

impl super::ActerModel for AttachmentUpdate {
    fn indizes(&self) -> Vec<String> {
        vec![format!("{:}::history", self.inner.attachment.event_id)]
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(vec![self.inner.attachment.event_id.to_string()])
    }

    async fn execute(self, store: &super::Store) -> Result<Vec<String>> {
        super::default_model_execute(store, self.into()).await
    }
}

impl Deref for AttachmentUpdate {
    type Target = AttachmentUpdateEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl From<OriginalMessageLikeEvent<AttachmentUpdateEventContent>> for AttachmentUpdate {
    fn from(outer: OriginalMessageLikeEvent<AttachmentUpdateEventContent>) -> Self {
        let OriginalMessageLikeEvent {
            content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = outer;
        AttachmentUpdate {
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
