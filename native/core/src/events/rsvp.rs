use derive_builder::Builder;
use ruma_macros::EventContent;
use serde::{Deserialize, Serialize};
use std::str::FromStr;
use strum::Display;

use super::BelongsTo;

/// RSVP status
// previolusly accepted only camel-case
// now accept not only serialization in kebab-case but also alias in camel-case
// because a lot of RsvpStatus in camel-case were uploaded and if parsing under only kebab-case failed at RsvpStatus in camel-case
#[derive(Clone, Debug, Serialize, Deserialize, Display, Eq, PartialEq)]
#[serde(rename_all = "kebab-case", tag = "type")]
#[strum(serialize_all = "kebab-case")]
pub enum RsvpStatus {
    #[serde(alias = "Yes")]
    Yes,
    #[serde(alias = "Maybe")]
    Maybe,
    #[serde(alias = "No")]
    No,
}

impl FromStr for RsvpStatus {
    type Err = ();

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "yes" => Ok(RsvpStatus::Yes),
            "no" => Ok(RsvpStatus::No),
            "maybe" => Ok(RsvpStatus::Maybe),
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
