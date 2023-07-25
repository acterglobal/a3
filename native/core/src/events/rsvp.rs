use derive_builder::Builder;
use matrix_sdk::ruma::events::macros::EventContent;
use serde::{Deserialize, Serialize};
use std::str::FromStr;
use strum::Display;

use super::BelongsTo;

/// RSVP status
#[derive(Clone, Debug, Serialize, Deserialize, Display)]
#[serde(tag = "type")]
pub enum RsvpStatus {
    Yes,
    Maybe,
    No,
}

impl FromStr for RsvpStatus {
    type Err = ();

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "Yes" => Ok(RsvpStatus::Yes),
            "No" => Ok(RsvpStatus::No),
            "Maybe" => Ok(RsvpStatus::Maybe),
            _ => Err(()),
        }
    }
}

/// The RSVP Event
#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder)]
#[ruma_event(type = "global.acter.dev.rsvp", kind = MessageLike)]
#[builder(name = "RsvpBuilder", derive(Debug))]
pub struct RsvpEventContent {
    #[builder(setter(into))]
    #[serde(rename = "m.relates_to")]
    pub to: BelongsTo,

    /// The status responded by this user
    pub status: RsvpStatus,
}
