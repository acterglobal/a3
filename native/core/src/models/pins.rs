use matrix_sdk::ruma::{events::OriginalMessageLikeEvent, EventId, RoomId};
use serde::{Deserialize, Serialize};
use std::ops::Deref;

use super::EventMeta;

use crate::{events::pins::PinEventContent, statics::KEYS};

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

    // pub fn updater(&self) -> PinUpdateBuilder {
    //     PinUpdateBuilder::default()
    //         .Pin(self.meta.event_id.clone())
    //         .to_owned()
    // }

    pub fn key_from_event(event_id: &EventId) -> String {
        event_id.to_string()
    }
}

impl super::EffektioModel for Pin {
    fn indizes(&self) -> Vec<String> {
        vec![KEYS::PINS.to_owned()]
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }

    fn capabilities(&self) -> &[super::Capability] {
        &[super::Capability::Commentable]
    }

    async fn execute(self, store: &super::Store) -> crate::Result<Vec<String>> {
        super::default_model_execute(store, self.into()).await
    }

    // fn transition(&mut self, model: &super::AnyEffektioModel) -> crate::Result<bool> {
    //     let AnyEffektioModel::PinUpdate(update) = model else {
    //         return Ok(false)
    //     };

    //     update.apply(&mut self.inner)
    // }
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
