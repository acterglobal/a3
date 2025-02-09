pub use core::fmt::Debug;
use matrix_sdk_base::ruma::{
    events::{
        room::redaction::{OriginalRoomRedactionEvent, RoomRedactionEventContent},
        UnsignedRoomRedactionEvent,
    },
    MilliSecondsSinceUnixEpoch, OwnedEventId, OwnedUserId, UserId,
};
use serde::{Deserialize, Serialize};
use tracing::info;

use super::{any::ActerModel, default_model_execute, AnyActerModel, EventMeta};

use crate::referencing::{ExecuteReference, IndexKey};
pub use crate::store::Store;

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct RedactionContent {
    /// Data specific to the event type.
    pub content: RoomRedactionEventContent,

    /// The globally unique event identifier for the event.
    pub event_id: OwnedEventId,

    /// The fully-qualified ID of the user who sent this event.
    pub sender: OwnedUserId,

    /// Timestamp in milliseconds on originating homeserver when this event was sent.
    pub origin_server_ts: MilliSecondsSinceUnixEpoch,
}

impl From<UnsignedRoomRedactionEvent> for RedactionContent {
    fn from(value: UnsignedRoomRedactionEvent) -> Self {
        let UnsignedRoomRedactionEvent {
            content,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = value;
        RedactionContent {
            content,
            event_id,
            sender,
            origin_server_ts,
        }
    }
}

impl From<OriginalRoomRedactionEvent> for RedactionContent {
    fn from(value: OriginalRoomRedactionEvent) -> Self {
        let OriginalRoomRedactionEvent {
            content,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = value;
        RedactionContent {
            content,
            event_id,
            sender,
            origin_server_ts,
        }
    }
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct RedactedActerModel {
    orig_type: String,
    pub(crate) meta: EventMeta,
    content: RedactionContent,
    // legacy support
    #[serde(skip, default)]
    #[allow(dead_code)]
    indizes: Option<Vec<IndexKey>>,
}

impl RedactedActerModel {
    pub fn origin_type(&self) -> &str {
        &self.orig_type
    }
}

impl RedactedActerModel {
    pub fn new(orig_type: String, meta: EventMeta, content: RedactionContent) -> Self {
        RedactedActerModel {
            meta,
            orig_type,
            content,
            indizes: None,
        }
    }
}

impl ActerModel for RedactedActerModel {
    fn indizes(&self, _user_id: &UserId) -> Vec<IndexKey> {
        let mut indizes = vec![IndexKey::RoomHistory(self.meta.room_id.clone())];
        if let Some(origin_event_id) = self.content.content.redacts.as_ref() {
            indizes.push(IndexKey::ObjectHistory(origin_event_id.clone()))
        }
        indizes
    }

    fn event_meta(&self) -> &EventMeta {
        &self.meta
    }

    async fn execute(self, store: &Store) -> crate::Result<Vec<ExecuteReference>> {
        default_model_execute(store, self.into()).await
    }

    fn transition(&mut self, model: &AnyActerModel) -> crate::Result<bool> {
        // Transitions aren’t possible anymore when the source has been redacted
        // so we eat up the content and just log that we had to do that.
        info!(?self, ?model, "Transition on Redaction Swallowed");
        Ok(false)
    }
}
