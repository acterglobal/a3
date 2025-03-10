use derive_builder::Builder;
use derive_getters::Getters;
use matrix_sdk::ruma::{events::Mentions, OwnedUserId};
use matrix_sdk_base::ruma::{events::macros::EventContent, OwnedEventId};
use serde::{Deserialize, Serialize};

use super::BelongsTo;

/// Subscribe Event
#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder, Getters)]
#[ruma_event(type = "global.acter.dev.invite", kind = MessageLike)]
#[builder(name = "SubscribeBuilder", derive(Debug))]
pub struct ExplicitInviteEventContent {
    #[builder(setter(into))]
    #[serde(rename = "m.relates_to")]
    pub to: BelongsTo,

    /// The actual user being invited    
    #[builder(setter(into))]
    #[serde(rename = "m.mention")]
    // We model this after a mention to use the existing notification setup
    pub mention: Mentions,
}

impl ExplicitInviteEventContent {
    pub fn new(object_id: OwnedEventId, user_id: OwnedUserId) -> ExplicitInviteEventContent {
        ExplicitInviteEventContent {
            to: BelongsTo::from(object_id),
            mention: Mentions::with_user_ids([user_id]),
        }
    }
}
