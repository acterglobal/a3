use derive_builder::Builder;
use derive_getters::Getters;
use matrix_sdk::ruma::events::{macros::EventContent, room::message::TextMessageEventContent};
use serde::{Deserialize, Serialize};
use tracing::trace;

use crate::util::deserialize_some;

/// Calendar Events
/// modeled after [JMAP Calendar Events](https://jmap.io/spec-calendars.html#calendar-events), extensions to
/// [ietf rfc8984](https://www.rfc-editor.org/rfc/rfc8984.html#name-event).
///
use super::{BelongsTo, Color, Icon, Update, UtcDateTime};

/// Event Location
#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum RsvpState {
    Yes,
    Maybe,
    No,
}

/// Event Location
#[derive(Clone, Debug, Serialize, Deserialize)]
#[serde(tag = "type")]
pub enum EventLocation {
    Physical {
        /// Optional name of this location
        #[serde(default, skip_serializing_if = "Option::is_none")]
        name: Option<String>,

        /// further description to this location
        #[serde(default, skip_serializing_if = "Option::is_none")]
        description: Option<TextMessageEventContent>,

        /// Alternative Icon to show with this location
        #[serde(default, skip_serializing_if = "Option::is_none")]
        icon: Option<Icon>,

        /// A `geo:` URI [RFC5870] for the location.
        #[serde(default, skip_serializing_if = "Option::is_none")]
        coordinates: Option<String>,

        /// further Link
        #[serde(default, skip_serializing_if = "Option::is_none")]
        uri: Option<String>,
    },
    Virtual {
        /// URI to this virtual location
        uri: String,

        /// Optional name of this virtual location
        #[serde(default, skip_serializing_if = "Option::is_none")]
        name: Option<String>,

        /// further description for virtual location
        #[serde(default, skip_serializing_if = "Option::is_none")]
        description: Option<TextMessageEventContent>,

        /// Alternative Icon to show with this location
        #[serde(default, skip_serializing_if = "Option::is_none")]
        icon: Option<Icon>,
    },
}

/// The Calendar Event
///
/// modeled after [JMAP Calendar Events](https://jmap.io/spec-calendars.html#calendar-events)
/// see also the [IETF CalendarEvent](https://www.rfc-editor.org/rfc/rfc8984.html#name-event)
/// but all timezones have been dumbed down to UTC-only.
#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder, Getters)]
#[ruma_event(type = "global.acter.dev.calendar_event", kind = MessageLike)]
#[builder(name = "CalendarEventBuilder", derive(Debug))]
pub struct CalendarEventEventContent {
    /// The title of the CalendarEvent
    pub title: String,

    /// an Icon to show with with this event
    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub icon: Option<Icon>,

    /// colorizing this event
    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub color: Option<Color>,

    /// Further information describing the calendar_event
    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub description: Option<TextMessageEventContent>,

    /// When will this event start?
    #[builder(setter(into))]
    pub utc_start: UtcDateTime,

    /// When will this event end?
    #[builder(setter(into))]
    pub utc_end: UtcDateTime,

    /// Should this event been shown without the time?
    #[builder(default)]
    #[serde(default)]
    pub show_without_time: bool,

    /// Where is this event happening?
    #[builder(default)]
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub locations: Vec<EventLocation>,

    // FIXME: manage through `label` as in [MSC2326](https://github.com/matrix-org/matrix-doc/pull/2326)
    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub keywords: Vec<String>,

    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub categories: Vec<String>,
}

/// The CalendarEvent Update Event
#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder)]
#[ruma_event(type = "global.acter.dev.calendar_event.update", kind = MessageLike)]
#[builder(name = "CalendarEventUpdateBuilder", derive(Debug))]
pub struct CalendarEventUpdateEventContent {
    #[builder(setter(into))]
    #[serde(rename = "m.relates_to")]
    pub calendar_event: Update,

    /// The title of the CalendarEvent
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub title: Option<String>,

    /// Every calendar_events belongs to a calendar_eventlist
    /// Further information describing the calendar_event
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub description: Option<Option<TextMessageEventContent>>,

    /// When was this calendar_event started?
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub utc_start: Option<UtcDateTime>,

    /// When was this calendar_event started?
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub utc_end: Option<UtcDateTime>,

    /// Color this calendar_event
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub color: Option<Option<Color>>,

    /// Icon this calendar_event
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub icon: Option<Option<Icon>>,

    /// Should this event been shown without the time?
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub show_without_time: Option<bool>,

    /// Where is this event happening?
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub locations: Option<Vec<EventLocation>>,

    // FIXME: manage through `label` as in [MSC2326](https://github.com/matrix-org/matrix-doc/pull/2326)
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub keywords: Option<Vec<String>>,

    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub categories: Option<Vec<String>>,
}

impl CalendarEventUpdateEventContent {
    pub fn apply(&self, calendar_event: &mut CalendarEventEventContent) -> crate::Result<bool> {
        let mut updated = false;
        if let Some(title) = &self.title {
            calendar_event.title = title.clone();
            updated = true;
        }

        if let Some(description) = &self.description {
            calendar_event.description = description.clone();
            updated = true;
        }

        if let Some(utc_start) = &self.utc_start {
            calendar_event.utc_start = *utc_start;
            updated = true;
        }

        if let Some(utc_end) = &self.utc_end {
            calendar_event.utc_end = *utc_end;
            updated = true;
        }

        if let Some(locations) = &self.locations {
            calendar_event.locations = locations.clone();
            updated = true;
        }

        if let Some(show_without_time) = &self.show_without_time {
            calendar_event.show_without_time = *show_without_time;
            updated = true;
        }

        if let Some(color) = &self.color {
            calendar_event.color = color.clone();
            updated = true;
        }

        if let Some(icon) = &self.icon {
            calendar_event.icon = icon.clone();
            updated = true;
        }

        if let Some(keywords) = &self.keywords {
            calendar_event.keywords = keywords.clone();
            updated = true;
        }

        if let Some(categories) = &self.categories {
            calendar_event.categories = categories.clone();
            updated = true;
        }

        trace!(update = ?self, ?updated, ?calendar_event, "CalendarEvent updated");

        Ok(updated)
    }
}

/// The RSVP Event
#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder)]
#[ruma_event(type = "global.acter.dev.rsvp", kind = MessageLike)]
#[builder(name = "RsvpBuilder", derive(Debug))]
pub struct RsvpEventContent {
    #[builder(setter(into))]
    #[serde(rename = "m.relates_to")]
    pub calendar_event: BelongsTo,

    /// The the response by this user
    pub rsvp: RsvpState,
}
