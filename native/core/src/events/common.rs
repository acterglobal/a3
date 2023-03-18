pub use chrono_tz::Tz as TimeZone;
pub use csscolorparser::Color;
pub use matrix_sdk::ruma::events::room::ImageInfo;

use chrono::{DateTime, Utc};
use matrix_sdk::ruma::OwnedEventId;
use serde::{Deserialize, Serialize};

/// Default UTC Datetime Object
pub type UtcDateTime = DateTime<Utc>;

/// Customize the color scheme
#[derive(Clone, Debug, Deserialize, Serialize)]
// #[ruma_event(type = "global.acter.dev.colors")]
pub struct Colorize {
    /// The foreground color to be used, as HEX
    pub color: Option<Color>,
    /// The background color to be used, as HEX
    pub background: Option<Color>,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(rename_all = "lowercase")]
pub enum BrandIcon {
    Matrix,
    Twitter,
    Facebook,
    Email,
    Youtube,
    Whatsapp,
    Reddit,
    Skype,
    Zoom,
    Jitsi,
    Telegram,
    GoogleDrive,
    // FIXME: support for others?
}

/// Customize the color scheme
#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(tag = "type")]
pub enum Icon {
    Emoji { key: String },
    BrandIcon { icon: BrandIcon },
    Image(ImageInfo),
}

#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(tag = "rel_type", rename = "m.thread")]
pub struct InThread {
    /// The event this event archives.
    pub event_id: OwnedEventId,
}

impl From<OwnedEventId> for InThread {
    fn from(event_id: OwnedEventId) -> InThread {
        InThread { event_id }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(tag = "rel_type", rename = "m.reference")]
pub struct Reference {
    /// The event this event archives.
    pub event_id: OwnedEventId,
}

impl From<OwnedEventId> for Reference {
    fn from(event_id: OwnedEventId) -> Reference {
        Reference { event_id }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(tag = "rel_type", rename = "m.references")]
pub struct References {
    /// The event this event archives.
    pub event_ids: Vec<OwnedEventId>,
}

impl From<OwnedEventId> for References {
    fn from(event_id: OwnedEventId) -> References {
        vec![event_id].into()
    }
}

impl From<Vec<OwnedEventId>> for References {
    fn from(event_ids: Vec<OwnedEventId>) -> References {
        References { event_ids }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(tag = "rel_type", rename = "global.acter.dev.update")]
pub struct Update {
    /// The event this event archives.
    pub event_id: OwnedEventId,
}

impl From<OwnedEventId> for Update {
    fn from(event_id: OwnedEventId) -> Update {
        Update { event_id }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
#[serde(tag = "rel_type", rename = "global.acter.dev.belongs_to")]
pub struct BelongsTo {
    /// The event this event archives.
    pub event_id: OwnedEventId,
}

impl From<OwnedEventId> for BelongsTo {
    fn from(event_id: OwnedEventId) -> BelongsTo {
        BelongsTo { event_id }
    }
}
