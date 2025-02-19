use derive_builder::Builder;
use derive_getters::Getters;
use matrix_sdk_base::ruma::events::macros::EventContent;
use serde::{Deserialize, Serialize};

use super::BelongsTo;

/// Subscribe Event
#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder, Getters)]
#[ruma_event(type = "global.acter.dev.subscribe", kind = MessageLike)]
#[builder(name = "SubscribeBuilder", derive(Debug))]
pub struct SubscribeEventContent {
    #[builder(setter(into))]
    #[serde(rename = "m.relates_to")]
    pub on: BelongsTo,
}

/// Unsubscribe Event
#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder, Getters)]
#[ruma_event(type = "global.acter.dev.unsubscribe", kind = MessageLike)]
#[builder(name = "UnsubscribBuilder", derive(Debug))]
pub struct UnsubscribeEventContent {
    #[builder(setter(into))]
    #[serde(rename = "m.relates_to")]
    pub on: BelongsTo,
}
