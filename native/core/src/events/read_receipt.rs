use derive_builder::Builder;
use derive_getters::Getters;
use matrix_sdk_base::ruma::{events::macros::EventContent, OwnedEventId};
use serde::{Deserialize, Serialize};

use super::BelongsTo;

/// Subscribe Event
#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder, Getters)]
#[ruma_event(type = "global.acter.dev.read", kind = MessageLike)]
#[builder(name = "SubscribeBuilder", derive(Debug))]
pub struct ReadReceiptEventContent {
    #[builder(setter(into))]
    #[serde(rename = "m.relates_to")]
    pub on: BelongsTo,
}

impl ReadReceiptEventContent {
    pub fn new(object_id: OwnedEventId) -> ReadReceiptEventContent {
        ReadReceiptEventContent {
            on: BelongsTo::from(object_id),
        }
    }
}
