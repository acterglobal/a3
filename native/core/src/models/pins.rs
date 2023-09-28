use ruma_common::{events::OriginalMessageLikeEvent, EventId, RoomId, UserId};
use serde::{Deserialize, Serialize};
use std::ops::Deref;

use super::{AnyActerModel, EventMeta};
use crate::{
    events::pins::{PinEventContent, PinUpdateBuilder, PinUpdateEventContent},
    statics::KEYS,
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
    pub fn title(&self) -> &String {
        &self.inner.title
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

    pub fn key_from_event(event_id: &EventId) -> String {
        event_id.to_string()
    }
}

impl super::ActerModel for Pin {
    fn indizes(&self) -> Vec<String> {
        vec![
            format!("{}::{}", self.meta.room_id, KEYS::PINS),
            KEYS::PINS.to_owned(),
        ]
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }

    fn capabilities(&self) -> &[super::Capability] {
        &[
            super::Capability::Commentable,
            super::Capability::HasAttachments,
        ]
    }

    async fn execute(self, store: &super::Store) -> Result<Vec<String>> {
        super::default_model_execute(store, self.into()).await
    }

    fn transition(&mut self, model: &super::AnyActerModel) -> Result<bool> {
        let AnyActerModel::PinUpdate(update) = model else {
            return Ok(false)
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
            },
        }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct PinUpdate {
    inner: PinUpdateEventContent,
    meta: EventMeta,
}

impl super::ActerModel for PinUpdate {
    fn indizes(&self) -> Vec<String> {
        vec![format!("{:}::history", self.inner.pin.event_id)]
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }

    async fn execute(self, store: &super::Store) -> Result<Vec<String>> {
        super::default_model_execute(store, self.into()).await
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(vec![Pin::key_from_event(&self.inner.pin.event_id)])
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
            },
        }
    }
}
