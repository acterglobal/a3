use std::sync::Arc;

use matrix_sdk::{
    deserialized_responses::SyncRoomEvent,
    ruma::{
        events::{
            room::message::{MessageType, RoomMessageEventContent},
            AnySyncMessageLikeEvent, AnySyncRoomEvent, SyncMessageLikeEvent, OriginalSyncMessageLikeEvent
        },
        MxcUri,
    },
};

pub struct RoomMessage {
    inner: OriginalSyncMessageLikeEvent<RoomMessageEventContent>,
    fallback: String,
}

impl RoomMessage {
    pub fn event_id(&self) -> String {
        self.inner.event_id.to_string()
    }

    pub fn body(&self) -> String {
        self.fallback.clone()
    }

    pub fn sender(&self) -> String {
        self.inner.sender.to_string()
    }

    pub fn origin_server_ts(&self) -> u64 {
        self.inner.origin_server_ts.as_secs().into()
    }
}

pub fn sync_event_to_message(sync_event: SyncRoomEvent) -> Option<RoomMessage> {
    match sync_event.event.deserialize() {
        Ok(AnySyncRoomEvent::MessageLike(AnySyncMessageLikeEvent::RoomMessage(
            SyncMessageLikeEvent::Original(m),
        ))) => {
            Some(RoomMessage {
                fallback: m.content.body().to_string(),
                inner: m,
            })
        }
        _ => None,
    }
}
