use derive_builder::Builder;
use derive_getters::Getters;
use matrix_sdk_base::ruma::events::{macros::EventContent, room::message::TextMessageEventContent};
use serde::{Deserialize, Serialize};
use tracing::trace;

use super::{Display, Update};
use crate::{util::deserialize_some, Result};

/// The Pin Event
#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder, Getters)]
#[ruma_event(type = "global.acter.dev.pin", kind = MessageLike)]
#[builder(name = "PinBuilder", derive(Debug))]
pub struct PinEventContent {
    /// Every Pin has a title or question
    pub title: String,

    /// Optionally the Pin has some further content
    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub content: Option<TextMessageEventContent>,

    /// Optionally the Pin has some external URL
    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub url: Option<String>,

    /// Optionally, a pin can be colored
    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub display: Option<Display>,
}

/// The Pin Event
#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder, Getters)]
#[ruma_event(type = "global.acter.dev.pin.update", kind = MessageLike)]
#[builder(name = "PinUpdateBuilder", derive(Debug))]
pub struct PinUpdateEventContent {
    #[builder(setter(into))]
    #[serde(rename = "m.relates_to")]
    pub pin: Update,

    /// If you want to update the pin title
    #[builder(setter(into), default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub title: Option<String>,

    /// Optionally the Pin has some further content
    #[builder(setter(into), default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub content: Option<Option<TextMessageEventContent>>,

    /// Optionally the Pin has some external URL
    #[builder(setter(into), default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub url: Option<Option<String>>,

    /// Optionally some displaying parameters
    #[builder(setter(into), default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub display: Option<Option<Display>>,
}

impl PinUpdateEventContent {
    pub fn apply(&self, pin: &mut PinEventContent) -> Result<bool> {
        let mut updated = false;
        if let Some(title) = &self.title {
            pin.title.clone_from(title);
            updated = true;
        }
        if let Some(content) = &self.content {
            pin.content.clone_from(content);
            updated = true;
        }
        if let Some(url) = &self.url {
            pin.url.clone_from(url);
            updated = true;
        }
        if let Some(display) = &self.display {
            pin.display.clone_from(display);
            updated = true;
        }

        trace!(update = ?self, ?updated, ?pin, "Pin updated");

        Ok(updated)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn ensure_minimal_pin_parses() -> Result<()> {
        let json_raw = r#"{"type":"global.acter.dev.pin",
            "room_id":"!euhIDqDVvVXulrhWgN:ds9.acter.global","sender":"@odo:ds9.acter.global",
            "content":{"title":"Seat arrangement"},"origin_server_ts":1672407531453,
            "unsigned":{"age":11523850},
            "event_id":"$KwumA4L3M-duXu0I3UA886LvN-BDCKAyxR1skNfnh3c",
            "user_id":"@odo:ds9.acter.global","age":11523850}"#;
        let event = serde_json::from_str::<OriginalPinEvent>(json_raw)?;
        assert_eq!(event.content.title, "Seat arrangement");
        Ok(())
    }

    #[test]
    fn ensure_pin_with_text_parses() -> Result<()> {
        let json_raw = r#"{"type":"global.acter.dev.pin",
            "room_id":"!euhIDqDVvVXulrhWgN:ds9.acter.global","sender":"@odo:ds9.acter.global",
            "content":{"title":"Seat arrangement", "content": { "body": "my response"}},"origin_server_ts":1672407531453,
            "unsigned":{"age":11523850},
            "event_id":"$KwumA4L3M-duXu0I3UA886LvN-BDCKAyxR1skNfnh3c",
            "user_id":"@odo:ds9.acter.global","age":11523850}"#;
        let event = serde_json::from_str::<OriginalPinEvent>(json_raw)?;
        assert_eq!(event.content.title, "Seat arrangement");
        Ok(())
    }
}
