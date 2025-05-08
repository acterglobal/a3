use matrix_sdk_base::ruma::{
    events::{room::message::TextMessageEventContent, OriginalMessageLikeEvent},
    OwnedEventId, RoomId, UserId,
};
use serde::{Deserialize, Serialize};
use std::ops::Deref;

use super::{default_model_execute, ActerModel, AnyActerModel, Capability, EventMeta};
use crate::{
    events::pins::{PinEventContent, PinUpdateBuilder, PinUpdateEventContent},
    referencing::{ExecuteReference, IndexKey, SectionIndex},
    store::Store,
    Result,
};

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Pin {
    inner: PinEventContent,
    meta: EventMeta,
}
impl Deref for Pin {
    type Target = PinEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl Pin {
    pub fn title(&self) -> String {
        self.inner.title.clone()
    }

    pub fn description(&self) -> Option<TextMessageEventContent> {
        self.inner.content.clone()
    }

    pub fn room_id(&self) -> &RoomId {
        &self.meta.room_id
    }

    pub fn sender(&self) -> &UserId {
        &self.meta.sender
    }

    pub fn is_link(&self) -> bool {
        self.inner.url.is_some()
    }

    pub fn updater(&self) -> PinUpdateBuilder {
        PinUpdateBuilder::default()
            .pin(self.meta.event_id.clone())
            .to_owned()
    }
}

impl ActerModel for Pin {
    fn indizes(&self, _user_id: &UserId) -> Vec<IndexKey> {
        vec![
            IndexKey::RoomSection(self.meta.room_id.clone(), SectionIndex::Pins),
            IndexKey::Section(SectionIndex::Pins),
            IndexKey::ObjectHistory(self.meta.event_id.to_owned()),
            IndexKey::RoomHistory(self.meta.room_id.clone()),
        ]
    }

    fn event_meta(&self) -> &EventMeta {
        &self.meta
    }

    fn capabilities(&self) -> &[Capability] {
        &[
            Capability::Commentable,
            Capability::Attachmentable,
            Capability::Reactable,
        ]
    }

    async fn execute(self, store: &Store) -> Result<Vec<ExecuteReference>> {
        default_model_execute(store, self.into()).await
    }

    fn transition(&mut self, model: &AnyActerModel) -> Result<bool> {
        let AnyActerModel::PinUpdate(update) = model else {
            return Ok(false);
        };

        update.apply(&mut self.inner)
    }
}

impl From<OriginalMessageLikeEvent<PinEventContent>> for Pin {
    fn from(outer: OriginalMessageLikeEvent<PinEventContent>) -> Self {
        let OriginalMessageLikeEvent {
            content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = outer;
        Pin {
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
pub struct PinUpdate {
    pub(crate) inner: PinUpdateEventContent,
    meta: EventMeta,
}

impl ActerModel for PinUpdate {
    fn indizes(&self, _user_id: &UserId) -> Vec<IndexKey> {
        vec![
            IndexKey::ObjectHistory(self.inner.pin.event_id.to_owned()),
            IndexKey::RoomHistory(self.meta.room_id.to_owned()),
        ]
    }

    fn event_meta(&self) -> &EventMeta {
        &self.meta
    }

    async fn execute(self, store: &Store) -> Result<Vec<ExecuteReference>> {
        default_model_execute(store, self.into()).await
    }

    fn belongs_to(&self) -> Option<Vec<OwnedEventId>> {
        Some(vec![self.inner.pin.event_id.to_owned()])
    }
}

impl Deref for PinUpdate {
    type Target = PinUpdateEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl From<OriginalMessageLikeEvent<PinUpdateEventContent>> for PinUpdate {
    fn from(outer: OriginalMessageLikeEvent<PinUpdateEventContent>) -> Self {
        let OriginalMessageLikeEvent {
            content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = outer;
        PinUpdate {
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
