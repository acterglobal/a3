pub use matrix_sdk::ruma::events::room::ImageInfo;

use chrono::{DateTime, Utc};
use matrix_sdk::ruma::OwnedEventId;
use serde::{Deserialize, Serialize};

mod labels;
mod object_reference;
mod rendering;

pub use labels::Labels;
pub use object_reference::{CalendarEventAction, ObjRef, RefDetails, TaskAction, TaskListAction};
pub use rendering::{BrandIcon, Color, Colorize, Icon, Position};

/// Default UTC Datetime Object
pub type UtcDateTime = DateTime<Utc>;

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
    /// The event this event references.
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
    /// The event this event references.
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
