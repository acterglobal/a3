use derive_getters::Getters;
use matrix_sdk_base::ruma::{events::OriginalMessageLikeEvent, EventId, OwnedEventId, UserId};
use serde::{Deserialize, Serialize};
use std::ops::Deref;
use tracing::{error, trace};

use super::{
    default_model_execute, ActerModel, AnyActerModel, Capability, EventMeta, RedactedActerModel,
};
use crate::{
    events::attachments::{
        AttachmentBuilder, AttachmentEventContent, AttachmentUpdateBuilder,
        AttachmentUpdateEventContent,
    },
    referencing::{ExecuteReference, IndexKey, ModelParam, ObjectListIndex},
    store::Store,
    Result,
};

#[derive(Clone, Debug, Default, Deserialize, Serialize, Getters)]
pub struct AttachmentsStats {
    has_attachments: bool,
    #[serde(default, skip_serializing_if = "is_zero")]
    total_attachments_count: u32,
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub user_attachments: Vec<OwnedEventId>,
}
/// This is only used for serialize
#[allow(clippy::trivially_copy_pass_by_ref)]
fn is_zero(num: &u32) -> bool {
    *num == 0
}
#[derive(Clone, Debug)]
pub struct AttachmentsManager {
    stats: AttachmentsStats,
    event_id: OwnedEventId,
    store: Store,
}

impl AttachmentsManager {
    fn stats_field_for(parent: OwnedEventId) -> ExecuteReference {
        ExecuteReference::ModelParam(parent, ModelParam::AttachmentsStats)
    }

    pub async fn from_store_and_event_id(store: &Store, event_id: &EventId) -> AttachmentsManager {
        let store = store.clone();
        let stats = store
            .get_raw(&Self::stats_field_for(event_id.to_owned()).as_storage_key())
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
            .get_list(&Attachment::index_for(self.event_id.clone()))
            .await?
            .filter_map(|e| match e {
                AnyActerModel::Attachment(c) => Some(c),
                _ => None,
            })
            .collect();
        Ok(attachments)
    }

    pub(crate) fn add_attachment(&mut self, _attachment: &Attachment) -> Result<bool> {
        self.stats.has_attachments = true;
        let is_my_attachment = self.store.user_id() == _attachment.meta.sender;
        if is_my_attachment {
            self.stats
                .user_attachments
                .push(_attachment.meta.event_id.clone())
        }
        self.stats.total_attachments_count += 1;
        Ok(true)
    }

    pub(crate) fn redact_attachment(
        &mut self,
        attachment: &Attachment,
        _redaction: &RedactedActerModel,
    ) -> Result<bool> {
        let was_my_attachment = self.store.user_id() == attachment.meta.sender;
        self.stats.total_attachments_count = self
            .stats
            .total_attachments_count
            .checked_sub(1)
            .unwrap_or_default();
        if was_my_attachment {
            self.stats
                .user_attachments
                .retain(|e| e != &attachment.meta.event_id);
        }

        Ok(true)
    }

    pub fn stats(&self) -> &AttachmentsStats {
        &self.stats
    }

    pub fn draft_builder(&self) -> AttachmentBuilder {
        AttachmentBuilder::default()
            .on(self.event_id.clone())
            .to_owned()
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
    pub fn index_for(parent: OwnedEventId) -> IndexKey {
        IndexKey::ObjectList(parent, ObjectListIndex::Attachments)
    }

    pub fn updater(&self) -> AttachmentUpdateBuilder {
        AttachmentUpdateBuilder::default()
            .attachment(self.meta.event_id.clone())
            .to_owned()
    }

    async fn apply(
        &self,
        store: &Store,
        redaction_model: Option<RedactedActerModel>,
    ) -> Result<Vec<ExecuteReference>> {
        let belongs_to = self.inner.on.event_id.clone();
        trace!(event_id=?self.event_id(), ?belongs_to, "applying attachment");

        let manager = {
            let parent = store.get(&belongs_to).await?;
            if !parent.capabilities().contains(&Capability::Attachmentable) {
                error!(?parent, attachment = ?self, "doesn’t support attachments. can’t apply");
                None
            } else {
                // FIXME: what if we have this twice in the same loop?
                let mut manager =
                    AttachmentsManager::from_store_and_event_id(store, parent.event_id()).await;
                if let Some(redacted) = redaction_model.as_ref() {
                    if manager.redact_attachment(self, redacted)? {
                        trace!(event_id=?self.event_id(), "redacted attachment");
                        Some(manager)
                    } else {
                        None
                    }
                } else if manager.add_attachment(self)? {
                    trace!(event_id=?self.event_id(), "added attachment");
                    Some(manager)
                } else {
                    None
                }
            }
        };

        let mut redacted_model = self.clone();
        if let Some(redaction_model_inner) = redaction_model {
            redacted_model.meta.redacted = Some(redaction_model_inner.meta.event_id.clone());
        }
        let mut updates = store.save(redacted_model.into()).await?;
        if let Some(manager) = manager {
            updates.push(manager.save().await?);
        }
        Ok(updates)
    }
}

impl ActerModel for Attachment {
    fn indizes(&self, _user_id: &UserId) -> Vec<IndexKey> {
        vec![
            Attachment::index_for(self.inner.on.event_id.clone()),
            IndexKey::ObjectHistory(self.inner.on.event_id.clone()),
            IndexKey::RoomHistory(self.meta.room_id.clone()),
            IndexKey::AllHistory,
        ]
    }
    fn event_meta(&self) -> &EventMeta {
        &self.meta
    }

    fn capabilities(&self) -> &[Capability] {
        &[Capability::Commentable, Capability::Reactable]
    }

    async fn execute(self, store: &Store) -> Result<Vec<ExecuteReference>> {
        self.apply(store, None).await
    }

    fn belongs_to(&self) -> Option<Vec<OwnedEventId>> {
        // Do not trigger the parent to update, we have a manager
        None
    }

    fn transition(&mut self, model: &AnyActerModel) -> Result<bool> {
        let AnyActerModel::AttachmentUpdate(update) = model else {
            return Ok(false);
        };

        update.apply(&mut self.inner)
    }
    // custom redaction code
    async fn redact(
        &self,
        store: &Store,
        redaction_model: RedactedActerModel,
    ) -> crate::Result<Vec<ExecuteReference>> {
        self.apply(store, Some(redaction_model)).await
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
                timestamp: origin_server_ts,
                redacted: None,
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
    fn indizes(&self, _user_id: &UserId) -> Vec<IndexKey> {
        vec![
            IndexKey::ObjectHistory(self.inner.attachment.event_id.clone()),
            IndexKey::RoomHistory(self.meta.room_id.clone()),
            IndexKey::AllHistory,
        ]
    }

    fn event_meta(&self) -> &EventMeta {
        &self.meta
    }

    fn belongs_to(&self) -> Option<Vec<OwnedEventId>> {
        Some(vec![self.inner.attachment.event_id.clone()])
    }

    async fn execute(self, store: &Store) -> Result<Vec<ExecuteReference>> {
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
                timestamp: origin_server_ts,
                redacted: None,
            },
        }
    }
}
