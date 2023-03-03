use super::TextMessageEventContent;
use super::{Color, Icon};
use derive_builder::Builder;
use derive_getters::Getters;
use matrix_sdk::ruma::events::macros::EventContent;
use serde::{Deserialize, Serialize};

/// The Pin Event
#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder, Getters)]
#[ruma_event(type = "org.effektio.dev.pin", kind = MessageLike)]
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
    pub color: Option<Color>,

    /// Optionally, a pin might have an icon attached
    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub icon: Option<Icon>,
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::Result;
    use serde_json;
    #[test]
    fn ensure_minimal_pin_parses() -> Result<()> {
        let json_raw = r#"{"type":"org.effektio.dev.pin",
            "room_id":"!euhIDqDVvVXulrhWgN:ds9.effektio.org","sender":"@odo:ds9.effektio.org",
            "content":{"title":"Seat arrangement"},"origin_server_ts":1672407531453,
            "unsigned":{"age":11523850},
            "event_id":"$KwumA4L3M-duXu0I3UA886LvN-BDCKAyxR1skNfnh3c",
            "user_id":"@odo:ds9.effektio.org","age":11523850}"#;
        let event = serde_json::from_str::<OriginalPinEvent>(json_raw)?;
        assert_eq!(event.content.title, "Seat arrangement".to_string());
        Ok(())
    }

    #[test]
    fn ensure_pin_with_text_parses() -> Result<()> {
        let json_raw = r#"{"type":"org.effektio.dev.pin",
            "room_id":"!euhIDqDVvVXulrhWgN:ds9.effektio.org","sender":"@odo:ds9.effektio.org",
            "content":{"title":"Seat arrangement", "content": { "body": "my response"}},"origin_server_ts":1672407531453,
            "unsigned":{"age":11523850},
            "event_id":"$KwumA4L3M-duXu0I3UA886LvN-BDCKAyxR1skNfnh3c",
            "user_id":"@odo:ds9.effektio.org","age":11523850}"#;
        let event = serde_json::from_str::<OriginalPinEvent>(json_raw)?;
        assert_eq!(event.content.title, "Seat arrangement".to_string());
        Ok(())
    }
}
