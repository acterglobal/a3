use matrix_sdk_base::ruma::{events::OriginalMessageLikeEvent, RoomId, UserId};
use serde::{Deserialize, Serialize};
use std::ops::Deref;

use super::{default_model_execute, ActerModel, AnyActerModel, Capability, EventMeta};
use crate::{
    events::pins::{PinEventContent, PinUpdateBuilder, PinUpdateEventContent},
    statics::KEYS,
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
}

impl ActerModel for Pin {
    fn indizes(&self, _user_id: &UserId) -> Vec<String> {
        vec![
            format!("{}::{}", self.meta.room_id, KEYS::PINS),
            KEYS::PINS.to_owned(),
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

    async fn execute(self, store: &Store) -> Result<Vec<String>> {
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
    inner: PinUpdateEventContent,
    meta: EventMeta,
}

impl ActerModel for PinUpdate {
    fn indizes(&self, _user_id: &UserId) -> Vec<String> {
        vec![format!("{:}::history", self.inner.pin.event_id)]
    }

    fn event_meta(&self) -> &EventMeta {
        &self.meta
    }

    async fn execute(self, store: &Store) -> Result<Vec<String>> {
        default_model_execute(store, self.into()).await
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(vec![self.inner.pin.event_id.to_string()])
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
