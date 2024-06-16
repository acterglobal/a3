use ruma::OwnedRoomId;
use ruma_events::{
    space::child::SpaceChildEventContent, EventContent, PossiblyRedactedStateEventContent,
    StateEventType,
};
use ruma_macros::EventContent;
use serde::{Deserialize, Serialize};

use super::Labels;

/// The possibly redacted form of [`ActerSpaceChildEventContent`].
///
/// This type is used when it's not obvious whether the content is redacted or not.
#[derive(Clone, Debug, Deserialize, Serialize)]
#[allow(clippy::exhaustive_structs)]
pub struct PossiblyRedactedActerSpaceChildEventContent();

impl EventContent for PossiblyRedactedActerSpaceChildEventContent {
    type EventType = StateEventType;

    fn event_type(&self) -> Self::EventType {
        "m.space.child".into()
    }
}

impl PossiblyRedactedStateEventContent for PossiblyRedactedActerSpaceChildEventContent {
    type StateKey = OwnedRoomId;
}

#[derive(Debug, Serialize, Deserialize, Clone, EventContent)]
#[ruma_event(type = "m.space.child", kind = State, state_key_type = OwnedRoomId, custom_possibly_redacted)]
pub struct ActerSpaceChildEventContent {
    #[serde(flatten)]
    pub space_child_event_content: SpaceChildEventContent,
    pub labels: Labels,
}
