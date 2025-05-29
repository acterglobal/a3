use derive_builder::Builder;
use derive_getters::Getters;
use matrix_sdk_base::ruma::events::{macros::EventContent, room::message::TextMessageEventContent};
use serde::{Deserialize, Serialize};
use tracing::trace;

use crate::{models::TextMessageContent, util::deserialize_some, Result};

/// Calendar Events
/// modeled after [JMAP Calendar Events](https://jmap.io/spec-calendars.html#calendar-events), extensions to
/// [ietf rfc8984](https://www.rfc-editor.org/rfc/rfc8984.html#name-event).
///
use super::{Display, Icon, Update, UtcDateTime};

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

        /// A `geo:` URI RFC5870 for the location.
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

pub struct EventLocationInfo {
    pub inner: EventLocation,
}

impl EventLocationInfo {
    pub fn new(location: &EventLocation) -> Self {
        match location {
            EventLocation::Physical {
                name,
                description,
                icon,
                coordinates,
                uri,
            } => EventLocationInfo {
                inner: EventLocation::Physical {
                    name: name.clone(),
                    description: description.clone(),
                    icon: icon.clone(),
                    coordinates: coordinates.clone(),
                    uri: uri.clone(),
                },
            },
            EventLocation::Virtual {
                uri,
                name,
                description,
                icon,
            } => EventLocationInfo {
                inner: EventLocation::Virtual {
                    uri: uri.clone(),
                    name: name.clone(),
                    description: description.clone(),
                    icon: icon.clone(),
                },
            },
        }
    }

    pub fn location_type(&self) -> String {
        match &self.inner {
            EventLocation::Physical { .. } => "Physical".to_owned(),
            EventLocation::Virtual { .. } => "Virtual".to_owned(),
        }
    }

    pub fn name(&self) -> Option<String> {
        match &self.inner {
            EventLocation::Physical { name, .. } => name.clone(),
            EventLocation::Virtual { name, .. } => name.clone(),
        }
    }

    pub fn description(&self) -> Option<TextMessageContent> {
        match &self.inner {
            EventLocation::Physical { description, .. } => {
                description.clone().map(TextMessageContent::from)
            }
            EventLocation::Virtual { description, .. } => {
                description.clone().map(TextMessageContent::from)
            }
        }
    }

    pub fn icon(&self) -> Option<Icon> {
        match &self.inner {
            EventLocation::Physical { icon, .. } => icon.clone(),
            EventLocation::Virtual { icon, .. } => icon.clone(),
        }
    }

    pub fn coordinates(&self) -> Option<String> {
        match &self.inner {
            EventLocation::Physical { coordinates, .. } => coordinates.clone(),
            _ => None,
        }
    }

    /// always available for virtual location
    pub fn uri(&self) -> Option<String> {
        match &self.inner {
            EventLocation::Physical { uri, .. } => uri.clone(),
            EventLocation::Virtual { uri, .. } => Some(uri.clone()),
        }
    }
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

    /// Further information describing the calendar_event
    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub description: Option<TextMessageEventContent>,

    /// Further information describing the calendar_event
    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub display: Option<Display>,

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

impl CalendarEventBuilder {
    pub fn add_physical_location(
        &mut self,
        name: Option<String>,
        description: Option<TextMessageEventContent>,
        coordinates: Option<String>,
        uri: Option<String>,
    ) -> &mut Self {
        let mut locations = self.locations.clone().unwrap_or_default();
        locations.push(EventLocation::Physical {
            name,
            description,
            icon: None,
            coordinates,
            uri,
        });
        self.locations = Some(locations);
        self
    }

    pub fn add_virtual_location(
        &mut self,
        uri: String,
        name: Option<String>,
        description: Option<TextMessageEventContent>,
    ) -> &mut Self {
        let mut locations = self.locations.clone().unwrap_or_default();
        locations.push(EventLocation::Virtual {
            uri,
            name,
            description,
            icon: None,
        });
        self.locations = Some(locations);
        self
    }
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

    /// Optionally some displaying parameters
    #[builder(setter(into), default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub display: Option<Option<Display>>,
}

impl CalendarEventUpdateEventContent {
    pub fn apply(&self, calendar_event: &mut CalendarEventEventContent) -> Result<bool> {
        let mut updated = false;
        if let Some(title) = &self.title {
            calendar_event.title.clone_from(title);
            updated = true;
        }

        if let Some(description) = &self.description {
            calendar_event.description.clone_from(description);
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
            calendar_event.locations.clone_from(locations);
            updated = true;
        }

        if let Some(show_without_time) = &self.show_without_time {
            calendar_event.show_without_time = *show_without_time;
            updated = true;
        }

        if let Some(display) = &self.display {
            calendar_event.display.clone_from(display);
            updated = true;
        }

        if let Some(keywords) = &self.keywords {
            calendar_event.keywords.clone_from(keywords);
            updated = true;
        }

        if let Some(categories) = &self.categories {
            calendar_event.categories.clone_from(categories);
            updated = true;
        }

        trace!(update = ?self, ?updated, ?calendar_event, "CalendarEvent updated");

        Ok(updated)
    }
}
