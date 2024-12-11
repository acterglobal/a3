use chrono::{DateTime, Utc};
use matrix_sdk_base::ruma::OwnedEventId;
use serde::{Deserialize, Serialize};

mod categories;
mod color;
mod display;
mod labels;
mod object_reference;
mod rendering;

pub use categories::{
    CategoriesStateEvent, CategoriesStateEventContent, Category, CategoryBuilder,
};
pub use color::Color;
pub use labels::Labels;
pub use object_reference::{
    CalendarEventAction, CalendarEventRefPreview, ObjRef, ObjRefBuilder, RefDetails,
    RefDetailsBuilder, RefPreview, TaskAction, TaskListAction,
};
pub use rendering::{ActerIcon, BrandLogo, Colorize, ColorizeBuilder, Icon, Position};

pub use display::{Display, DisplayBuilder};

/// Default UTC DateTime Object
pub type UtcDateTime = DateTime<Utc>;

pub type Date = chrono::NaiveDate;

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
