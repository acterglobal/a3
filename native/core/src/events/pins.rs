use derive_builder::Builder;
use derive_getters::Getters;
use matrix_sdk::ruma::events::macros::EventContent;
use serde::{Deserialize, Serialize};

use super::{Color, Icon, TextMessageEventContent, Update};
use crate::util::deserialize_some;

#[derive(Clone, Debug, Deserialize, Serialize, Builder)]
#[builder(name = "PinDisplayInfoBuilder", derive(Debug))]
pub struct PinDisplayInfo {
    /// Colorize the item
    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub color: Option<Color>,
    /// Show this icon
    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub icon: Option<Icon>,
    /// show it in particular sections only
    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub section: Option<String>,
}

#[derive(Clone, Debug, Deserialize, Serialize, Builder)]
#[builder(name = "PinDisplayInfoUpdateBuilder", derive(Debug))]
pub struct PinDisplayInfoUpdate {
    /// Colorize the item
    #[builder(setter(into), default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    color: Option<Option<Color>>,
    /// Show this icon
    #[builder(setter(into), default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    icon: Option<Option<Icon>>,
    /// show it in particular sections only
    #[builder(setter(into), default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    section: Option<Option<String>>,
}

impl PinDisplayInfoUpdate {
    pub fn apply(&self, info: &mut PinDisplayInfo) -> crate::Result<bool> {
        let mut updated = false;
        if let Some(color) = &self.color {
            info.color = color.clone();
            updated = true;
        }
        if let Some(icon) = &self.icon {
            info.icon = icon.clone();
            updated = true;
        }
        if let Some(section) = &self.section {
            info.section = section.clone();
            updated = true;
        }

        tracing::trace!(update = ?self, ?updated, ?info, "Info updated");

        Ok(updated)
    }
}

impl From<&PinDisplayInfoUpdate> for PinDisplayInfo {
    fn from(val: &PinDisplayInfoUpdate) -> Self {
        PinDisplayInfo {
            color: val.color.clone().unwrap_or_default(),
            icon: val.icon.clone().unwrap_or_default(),
            section: val.section.clone().unwrap_or_default(),
        }
    }
}

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
    pub display: Option<PinDisplayInfo>,
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

    /// Optionally, a pin can be colored
    #[builder(setter(into), default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub display: Option<Option<PinDisplayInfoUpdate>>,
}

impl PinUpdateEventContent {
    pub fn apply(&self, pin: &mut PinEventContent) -> crate::Result<bool> {
        let mut updated = false;
        if let Some(title) = &self.title {
            pin.title = title.clone();
            updated = true;
        }
        if let Some(content) = &self.content {
            pin.content = content.clone();
            updated = true;
        }
        if let Some(url) = &self.url {
            pin.url = url.clone();
            updated = true;
        }

        if let Some(display) = &self.display {
            match (&mut pin.display, display) {
                (Some(_), None) => {
                    pin.display = None;
                    updated = true;
                }
                (None, Some(new)) => {
                    pin.display = Some(new.into());
                    updated = true;
                }
                (Some(current), Some(new)) => {
                    new.apply(current)?;
                    updated = true;
                }
                _ => {}
            }
        }

        tracing::trace!(update = ?self, ?updated, ?pin, "Pin updated");

        Ok(updated)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::Result;
    use serde_json;
    #[test]
    fn ensure_minimal_pin_parses() -> Result<()> {
        let json_raw = r#"{"type":"global.acter.dev.pin",
            "room_id":"!euhIDqDVvVXulrhWgN:ds9.acter.global","sender":"@odo:ds9.acter.global",
            "content":{"title":"Seat arrangement"},"origin_server_ts":1672407531453,
            "unsigned":{"age":11523850},
            "event_id":"$KwumA4L3M-duXu0I3UA886LvN-BDCKAyxR1skNfnh3c",
            "user_id":"@odo:ds9.acter.global","age":11523850}"#;
        let event = serde_json::from_str::<OriginalPinEvent>(json_raw)?;
        assert_eq!(event.content.title, "Seat arrangement".to_string());
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
        assert_eq!(event.content.title, "Seat arrangement".to_string());
        Ok(())
    }
}
