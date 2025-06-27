use matrix_sdk::room::Room;
use matrix_sdk_base::ruma::{
    events::room::redaction::OriginalRoomRedactionEvent, MilliSecondsSinceUnixEpoch, OwnedEventId,
    OwnedRoomId, OwnedUserId, UserId,
};

use serde::{Deserialize, Serialize};

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(any(test, feature = "testing"), derive(PartialEq, Eq))]
pub struct EventMeta {
    /// The globally unique event identifier attached to this event
    pub event_id: OwnedEventId,

    /// The fully-qualified ID of the user who sent created this event
    pub sender: OwnedUserId,

    /// Timestamp in milliseconds on originating homeserver when the event was created
    pub origin_server_ts: MilliSecondsSinceUnixEpoch,

    /// The ID of the room of this event
    pub room_id: OwnedRoomId,

    /// Optional redacted event identifier
    #[serde(default)]
    pub(crate) redacted: Option<OwnedEventId>,
}

impl EventMeta {
    pub fn for_redacted_source(value: &OriginalRoomRedactionEvent) -> Option<Self> {
        let target_event_id = value.redacts.clone()?;

        Some(EventMeta {
            event_id: target_event_id,
            sender: value.sender.clone(),
            room_id: value.room_id.clone(),
            origin_server_ts: value.origin_server_ts,
            redacted: None,
        })
    }
}

pub async fn can_redact(room: &Room, sender_id: &UserId) -> crate::error::Result<bool> {
    let client = room.client();
    let Some(user_id) = client.user_id() else {
        // not logged in means we can’t redact
        return Ok(false);
    };
    Ok(if sender_id == user_id {
        room.can_user_redact_own(user_id).await?
    } else {
        room.can_user_redact_other(user_id).await?
    })
}
