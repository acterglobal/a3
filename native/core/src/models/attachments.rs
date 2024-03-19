use derive_getters::Getters;
use ruma_common::{EventId, OwnedEventId, UserId};
use ruma_events::OriginalMessageLikeEvent;
use serde::{Deserialize, Serialize};
use std::ops::Deref;
use tracing::{error, trace};

use super::{default_model_execute, ActerModel, AnyActerModel, Capability, EventMeta};
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

    pub fn event_id(&self) -> OwnedEventId {
        self.event_id.clone()
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

impl ActerModel for Attachment {
    fn indizes(&self, _user_id: &UserId) -> Vec<String> {
        vec![Attachment::index_for(&self.inner.on.event_id)]
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }

    fn capabilities(&self) -> &[Capability] {
        &[Capability::Commentable, Capability::Reactable]
    }

    async fn execute(self, store: &Store) -> Result<Vec<String>> {
        let belongs_to = self.inner.on.event_id.to_string();
        trace!(event_id=?self.event_id(), ?belongs_to, "applying attachment");

        let manager = {
            let parent = store.get(&belongs_to).await?;
            if !parent.capabilities().contains(&Capability::Attachmentable) {
                error!(?parent, attachment = ?self, "doesn't support attachments. can't apply");
                None
            } else {
                // FIXME: what if we have this twice in the same loop?
                let mut manager =
                    AttachmentsManager::from_store_and_event_id(store, parent.event_id()).await;
                if manager.add_attachment(&self).await? {
                    Some(manager)
                } else {
                    None
                }
            }
        };
        let mut updates = store.save(self.into()).await?;
        if let Some(manager) = manager {
            updates.push(manager.save().await?);
        }
        Ok(updates)
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        // Do not trigger the parent to update, we have a manager
        None
    }

    fn transition(&mut self, model: &AnyActerModel) -> Result<bool> {
        let AnyActerModel::AttachmentUpdate(update) = model else {
            return Ok(false);
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

impl ActerModel for AttachmentUpdate {
    fn indizes(&self, _user_id: &UserId) -> Vec<String> {
        vec![format!("{:}::history", self.inner.attachment.event_id)]
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(vec![self.inner.attachment.event_id.to_string()])
    }

    async fn execute(self, store: &Store) -> Result<Vec<String>> {
        default_model_execute(store, self.into()).await
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
