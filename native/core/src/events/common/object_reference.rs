use derive_getters::Getters;
use ruma_common::{OwnedEventId, OwnedRoomId};
use serde::{Deserialize, Serialize};
use std::str::FromStr;
use strum::Display;

use super::Position;

#[derive(Eq, PartialEq, Clone, Display, Debug, Deserialize, Serialize, Default)]
#[serde(rename_all = "kebab-case")]
#[strum(serialize_all = "kebab-case")]
pub enum TaskAction {
    #[default]
    Link,
    Embed,
    EmbedSubscribe,
    EmbedAcceptAssignment,
    EmbedMarkDone,
}

impl TaskAction {
    fn is_default(&self) -> bool {
        matches!(self, TaskAction::Link)
    }
}

impl FromStr for TaskAction {
    type Err = ();

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "link" => Ok(TaskAction::Link),
            "embed" => Ok(TaskAction::Embed),
            "embed-subscribe" => Ok(TaskAction::EmbedSubscribe),
            "embed-accept-assignment" => Ok(TaskAction::EmbedAcceptAssignment),
            "embed-mark-done" => Ok(TaskAction::EmbedMarkDone),
            _ => Err(()),
        }
    }
}

#[derive(Eq, PartialEq, Display, Clone, Debug, Deserialize, Serialize, Default)]
#[serde(rename_all = "kebab-case")]
#[strum(serialize_all = "kebab-case")]
pub enum TaskListAction {
    #[default]
    Link,
    Embed,
    EmbedSubscribe,
}

impl TaskListAction {
    fn is_default(&self) -> bool {
        matches!(self, TaskListAction::Link)
    }
}

impl FromStr for TaskListAction {
    type Err = ();

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "link" => Ok(TaskListAction::Link),
            "embed" => Ok(TaskListAction::Embed),
            "embed-subscribe" => Ok(TaskListAction::EmbedSubscribe),
            _ => Err(()),
        }
    }
}

#[derive(Eq, PartialEq, Display, Clone, Debug, Deserialize, Serialize, Default)]
#[serde(rename_all = "kebab-case")]
#[strum(serialize_all = "kebab-case")]
pub enum CalendarEventAction {
    #[default]
    Link,
    Embed,
    EmbedRsvp,
}

impl CalendarEventAction {
    fn is_default(&self) -> bool {
        matches!(self, CalendarEventAction::Link)
    }
}

impl FromStr for CalendarEventAction {
    type Err = ();

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "link" => Ok(CalendarEventAction::Link),
            "embed" => Ok(CalendarEventAction::Embed),
            "embed-rsvp" => Ok(CalendarEventAction::EmbedRsvp),
            _ => Err(()),
        }
    }
}

#[derive(Eq, PartialEq, Clone, Debug, Deserialize, Serialize)]
#[serde(rename_all = "kebab-case", tag = "ref")]
pub enum RefDetails {
    Task {
        #[serde(alias = "event_id")]
        /// the target event id
        target_id: OwnedEventId,

        /// if this links to an object not part of this room, but a different room
        #[serde(default, skip_serializing_if = "Option::is_none")]
        room_id: Option<OwnedRoomId>,

        task_list: OwnedEventId,

        #[serde(default, skip_serializing_if = "TaskAction::is_default")]
        action: TaskAction,
    },
    TaskList {
        #[serde(alias = "event_id")]
        /// the target event id
        target_id: OwnedEventId,

        /// if this links to an object not part of this room, but a different room
        #[serde(default, skip_serializing_if = "Option::is_none")]
        room_id: Option<OwnedRoomId>,

        #[serde(default, skip_serializing_if = "TaskListAction::is_default")]
        action: TaskListAction,
    },
    CalendarEvent {
        #[serde(alias = "event_id")]
        /// the target event id
        target_id: OwnedEventId,

        /// if this links to an object not part of this room, but a different room
        #[serde(default, skip_serializing_if = "Option::is_none")]
        room_id: Option<OwnedRoomId>,

        #[serde(default, skip_serializing_if = "CalendarEventAction::is_default")]
        action: CalendarEventAction,
    },
    Link {
        /// The title to show for this link
        title: String,

        /// The URI to open upon click
        uri: String,
    },
}

impl RefDetails {
    pub fn type_str(&self) -> String {
        match self {
            RefDetails::Task { .. } => "task".to_string(),
            RefDetails::TaskList { .. } => "task-list".to_string(),
            RefDetails::CalendarEvent { .. } => "calendar-event".to_string(),
            RefDetails::Link { .. } => "link".to_string(),
        }
    }

    pub fn embed_action_str(&self) -> String {
        match self {
            RefDetails::Link { .. } => "link".to_string(),
            RefDetails::Task { action, .. } => action.to_string(),
            RefDetails::TaskList { action, .. } => action.to_string(),
            RefDetails::CalendarEvent { action, .. } => action.to_string(),
        }
    }

    pub fn target_id_str(&self) -> Option<String> {
        match self {
            RefDetails::Link { .. } => None,
            RefDetails::Task { target_id, .. }
            | RefDetails::TaskList { target_id, .. }
            | RefDetails::CalendarEvent { target_id, .. } => Some(target_id.to_string()),
        }
    }

    pub fn room_id_str(&self) -> Option<String> {
        match self {
            RefDetails::Link { .. } => None,
            RefDetails::Task { room_id, .. }
            | RefDetails::TaskList { room_id, .. }
            | RefDetails::CalendarEvent { room_id, .. } => room_id.as_ref().map(|p| p.to_string()),
        }
    }

    pub fn task_list_id_str(&self) -> Option<String> {
        match self {
            RefDetails::Task { task_list, .. } => Some(task_list.to_string()),
            _ => None,
        }
    }

    pub fn title(&self) -> Option<String> {
        match self {
            RefDetails::Link { title, .. } => Some(title.clone()),
            _ => None,
        }
    }

    pub fn uri(&self) -> Option<String> {
        match self {
            RefDetails::Link { uri, .. } => Some(uri.clone()),
            _ => None,
        }
    }
}

/// An object reference is a link within the application
/// to a specific object with an optional flag to explain
/// how to embed said object. These may be interactive
/// elements when rendered on the view.
#[derive(Clone, Debug, Getters, Deserialize, Serialize)]
#[serde(tag = "rel_type", rename = "global.acter.dev.object_ref")]
pub struct ObjRef {
    /// an object reference might be overlayed on another items, if so
    /// this may contain the recommended position where to place it
    position: Option<Position>,

    #[serde(flatten)]
    reference: RefDetails,
}

impl ObjRef {
    pub fn new(position: Option<Position>, reference: RefDetails) -> Self {
        ObjRef {
            position,
            reference,
        }
    }

    pub fn position_str(&self) -> Option<String> {
        self.position.as_ref().map(|p| p.to_string())
    }
}
