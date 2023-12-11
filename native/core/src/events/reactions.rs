use derive_builder::Builder;
use ruma_events::macros::EventContent;
use serde::{Deserialize, Serialize};

use super::BelongsTo;

#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder)]
#[ruma_event(type = "global.acter.dev.reaction", kind = MessageLike)]
#[builder(name = "ReactionBuilder", derive(Debug))]

pub struct ReactionEventContent {
    #[builder(setter(into))]
    #[serde(rename = "m.relates_to")]
    pub to: BelongsTo,

    pub like_reaction: bool,
    // TODO: support for more reactions near future ??
}
