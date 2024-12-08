use matrix_sdk::{OwnedServerName, RoomDisplayName};
use matrix_sdk_base::ruma::{EventId, OwnedEventId, OwnedRoomId, RoomId};
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

impl FromStr for TaskAction {
    type Err = crate::Error;

    fn from_str(s: &str) -> Result<Self, crate::Error> {
        match s {
            "link" => Ok(TaskAction::Link),
            "embed" => Ok(TaskAction::Embed),
            "embed-subscribe" => Ok(TaskAction::EmbedSubscribe),
            "embed-accept-assignment" => Ok(TaskAction::EmbedAcceptAssignment),
            "embed-mark-done" => Ok(TaskAction::EmbedMarkDone),
            _ => Err(crate::Error::FailedToParse {
                model_type: "TaskAction".to_owned(),
                msg: format!("{s} is not a valid TaskAction"),
            }),
        }
    }
}

impl TaskAction {
    fn is_default(&self) -> bool {
        matches!(self, TaskAction::Link)
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
    type Err = crate::Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "link" => Ok(TaskListAction::Link),
            "embed" => Ok(TaskListAction::Embed),
            "embed-subscribe" => Ok(TaskListAction::EmbedSubscribe),
            _ => Err(crate::Error::FailedToParse {
                model_type: "TaskListAction".to_owned(),
                msg: format!("{s} is not a valid TaskListAction"),
            }),
        }
    }
}

#[derive(Eq, PartialEq, Clone, Display, Debug, Deserialize, Serialize, Default)]
#[serde(rename_all = "kebab-case")]
#[strum(serialize_all = "kebab-case")]
pub enum PinAction {
    #[default]
    Link,
    Embed,
    EmbedSubscribe,
}

impl PinAction {
    fn is_default(&self) -> bool {
        matches!(self, PinAction::Link)
    }
}

impl FromStr for PinAction {
    type Err = crate::Error;

    fn from_str(s: &str) -> Result<Self, crate::Error> {
        match s {
            "link" => Ok(PinAction::Link),
            "embed" => Ok(PinAction::Embed),
            "embed-subscribe" => Ok(PinAction::EmbedSubscribe),
            _ => Err(crate::Error::FailedToParse {
                model_type: "PinAction".to_owned(),
                msg: format!("{s} is not a valid PinAction"),
            }),
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
    type Err = crate::Error;

    fn from_str(s: &str) -> Result<Self, Self::Err> {
        match s {
            "link" => Ok(CalendarEventAction::Link),
            "embed" => Ok(CalendarEventAction::Embed),
            "embed-rsvp" => Ok(CalendarEventAction::EmbedRsvp),
            _ => Err(crate::Error::FailedToParse {
                model_type: "CalendarEventAction".to_owned(),
                msg: format!("{s} is not a valid CalendarEventAction"),
            }),
        }
    }
}

#[derive(Eq, PartialEq, Clone, Default, Debug, Deserialize, Serialize)]
pub struct RefPreview {
    pub title: Option<String>,
    pub room_display_name: Option<String>,
}

impl RefPreview {
    pub fn new(title: Option<String>, room_display_name: Option<RoomDisplayName>) -> Self {
        RefPreview {
            title,
            room_display_name: room_display_name.and_then(|r| match r {
                RoomDisplayName::Named(name)
                | RoomDisplayName::Aliased(name)
                | RoomDisplayName::Calculated(name)
                | RoomDisplayName::EmptyWas(name) => Some(name),
                _ => None,
            }),
        }
    }
}

impl RefPreview {
    fn is_none(&self) -> bool {
        self.title.is_none() && self.room_display_name.is_none()
    }
}

#[derive(Eq, PartialEq, Clone, Default, Debug, Deserialize, Serialize)]
pub struct CalendarEventRefPreview {
    pub title: Option<String>,
    pub room_display_name: Option<String>,
    pub participants: Option<u32>,
    pub start_at_utc: Option<i64>,
}

impl CalendarEventRefPreview {
    pub fn new(
        title: Option<String>,
        room_display_name: Option<RoomDisplayName>,
        participants: Option<u32>,
        start_at_utc: Option<i64>,
    ) -> Self {
        CalendarEventRefPreview {
            title,
            participants,
            start_at_utc,
            room_display_name: room_display_name.and_then(|r| match r {
                RoomDisplayName::Named(name)
                | RoomDisplayName::Aliased(name)
                | RoomDisplayName::Calculated(name)
                | RoomDisplayName::EmptyWas(name) => Some(name),
                _ => None,
            }),
        }
    }
}

impl CalendarEventRefPreview {
    fn is_none(&self) -> bool {
        self.title.is_none() && self.room_display_name.is_none()
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
        #[serde(default, skip_serializing_if = "Vec::is_empty")]
        via: Vec<OwnedServerName>,
        #[serde(default, skip_serializing_if = "RefPreview::is_none")]
        preview: RefPreview,

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
        #[serde(default, skip_serializing_if = "Vec::is_empty")]
        via: Vec<OwnedServerName>,
        #[serde(default, skip_serializing_if = "RefPreview::is_none")]
        preview: RefPreview,

        #[serde(default, skip_serializing_if = "TaskListAction::is_default")]
        action: TaskListAction,
    },
    Pin {
        #[serde(alias = "event_id")]
        /// the target event id
        target_id: OwnedEventId,

        /// if this links to an object not part of this room, but a different room
        #[serde(default, skip_serializing_if = "Option::is_none")]
        room_id: Option<OwnedRoomId>,
        #[serde(default, skip_serializing_if = "Vec::is_empty")]
        via: Vec<OwnedServerName>,
        #[serde(default, skip_serializing_if = "RefPreview::is_none")]
        preview: RefPreview,

        #[serde(default, skip_serializing_if = "PinAction::is_default")]
        action: PinAction,
    },
    CalendarEvent {
        #[serde(alias = "event_id")]
        /// the target event id
        target_id: OwnedEventId,

        /// if this links to an object not part of this room, but a different room
        #[serde(default, skip_serializing_if = "Option::is_none")]
        room_id: Option<OwnedRoomId>,
        #[serde(default, skip_serializing_if = "Vec::is_empty")]
        via: Vec<OwnedServerName>,
        #[serde(default, skip_serializing_if = "CalendarEventRefPreview::is_none")]
        preview: CalendarEventRefPreview,

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
            RefDetails::Pin { .. } => "pin".to_string(),
        }
    }

    pub fn embed_action_str(&self) -> String {
        match self {
            RefDetails::Link { .. } => "link".to_string(),
            RefDetails::Pin { .. } => "pin".to_string(),
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
            | RefDetails::Pin { target_id, .. }
            | RefDetails::CalendarEvent { target_id, .. } => Some(target_id.to_string()),
        }
    }

    pub fn room_id_str(&self) -> Option<String> {
        match self {
            RefDetails::Link { .. } => None,
            RefDetails::Task { room_id, .. }
            | RefDetails::TaskList { room_id, .. }
            | RefDetails::Pin { room_id, .. }
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

#[derive(Debug, Clone)]
pub struct RefDetailsBuilder {
    ref_details: RefDetails,
}

impl RefDetailsBuilder {
    pub fn new_task_ref_builder(target_id: OwnedEventId, task_list: OwnedEventId) -> Self {
        let ref_details = RefDetails::Task {
            target_id,
            room_id: None,
            task_list,
            action: TaskAction::default(),
            via: Default::default(),
            preview: Default::default(),
        };
        RefDetailsBuilder { ref_details }
    }

    pub fn new_task_list_ref_builder(target_id: OwnedEventId) -> Self {
        let ref_details = RefDetails::TaskList {
            target_id,
            room_id: None,
            action: TaskListAction::default(),
            via: Default::default(),
            preview: Default::default(),
        };
        RefDetailsBuilder { ref_details }
    }

    pub fn new_pin_ref_builder(target_id: OwnedEventId) -> Self {
        let ref_details = RefDetails::Pin {
            target_id,
            room_id: None,
            action: PinAction::default(),
            via: Default::default(),
            preview: Default::default(),
        };
        RefDetailsBuilder { ref_details }
    }

    pub fn new_calendar_event_ref_builder(target_id: OwnedEventId) -> Self {
        let ref_details = RefDetails::CalendarEvent {
            target_id,
            room_id: None,
            action: CalendarEventAction::default(),
            via: Default::default(),
            preview: Default::default(),
        };
        RefDetailsBuilder { ref_details }
    }

    pub fn new_link_ref_builder(title: String, uri: String) -> Self {
        let ref_details = RefDetails::Link { title, uri };
        RefDetailsBuilder { ref_details }
    }

    pub fn target_id(&mut self, target_id: String) -> crate::Result<()> {
        match self.ref_details.clone() {
            RefDetails::Task {
                room_id,
                task_list,
                action,
                ..
            } => {
                let target_id = EventId::parse(target_id)?;
                self.ref_details = RefDetails::Task {
                    target_id,
                    room_id,
                    task_list,
                    action,
                    via: Default::default(),
                    preview: Default::default(),
                };
            }
            RefDetails::TaskList {
                room_id, action, ..
            } => {
                let target_id = EventId::parse(target_id)?;
                self.ref_details = RefDetails::TaskList {
                    target_id,
                    room_id,
                    action,
                    via: Default::default(),
                    preview: Default::default(),
                };
            }
            RefDetails::CalendarEvent {
                room_id, action, ..
            } => {
                let target_id = EventId::parse(target_id)?;
                self.ref_details = RefDetails::CalendarEvent {
                    target_id,
                    room_id,
                    action,
                    via: Default::default(),
                    preview: Default::default(),
                };
            }
            _ => {
                return Err(crate::Error::FailedToParse {
                    model_type: "RefDetails".to_owned(),
                    msg: "target_id is available for only Task/TaskList/CalendarEvent ref"
                        .to_owned(),
                });
            }
        }
        Ok(())
    }

    pub fn room_id(&mut self, room_id: String) -> crate::Result<()> {
        match self.ref_details.clone() {
            RefDetails::Task {
                target_id,
                task_list,
                action,
                ..
            } => {
                let room_id = RoomId::parse(room_id)?;
                self.ref_details = RefDetails::Task {
                    target_id,
                    room_id: Some(room_id),
                    task_list,
                    action,
                    via: Default::default(),
                    preview: Default::default(),
                };
            }
            RefDetails::TaskList {
                target_id, action, ..
            } => {
                let room_id = RoomId::parse(room_id)?;
                self.ref_details = RefDetails::TaskList {
                    target_id,
                    room_id: Some(room_id),
                    action,
                    via: Default::default(),
                    preview: Default::default(),
                };
            }
            RefDetails::CalendarEvent {
                target_id, action, ..
            } => {
                let room_id = RoomId::parse(room_id)?;
                self.ref_details = RefDetails::CalendarEvent {
                    target_id,
                    room_id: Some(room_id),
                    action,
                    via: Default::default(),
                    preview: Default::default(),
                };
            }
            _ => {
                return Err(crate::Error::FailedToParse {
                    model_type: "RefDetails".to_owned(),
                    msg: "room_id is available for only Task/TaskList/CalendarEvent ref".to_owned(),
                });
            }
        }
        Ok(())
    }

    pub fn unset_room_id(&mut self) -> crate::Result<()> {
        match self.ref_details.clone() {
            RefDetails::Task {
                target_id,
                task_list,
                action,
                ..
            } => {
                self.ref_details = RefDetails::Task {
                    target_id,
                    room_id: None,
                    task_list,
                    action,
                    via: Default::default(),
                    preview: Default::default(),
                };
            }
            RefDetails::TaskList {
                target_id, action, ..
            } => {
                self.ref_details = RefDetails::TaskList {
                    target_id,
                    room_id: None,
                    action,
                    via: Default::default(),
                    preview: Default::default(),
                };
            }
            RefDetails::CalendarEvent {
                target_id, action, ..
            } => {
                self.ref_details = RefDetails::CalendarEvent {
                    target_id,
                    room_id: None,
                    action,
                    via: Default::default(),
                    preview: Default::default(),
                };
            }
            _ => {
                return Err(crate::Error::FailedToParse {
                    model_type: "RefDetails".to_owned(),
                    msg: "room_id is available for only Task/TaskList/CalendarEvent ref".to_owned(),
                });
            }
        }
        Ok(())
    }

    pub fn task_list(&mut self, task_list: String) -> crate::Result<()> {
        match self.ref_details.clone() {
            RefDetails::Task {
                target_id,
                room_id,
                action,
                ..
            } => {
                let task_list = EventId::parse(task_list)?;
                self.ref_details = RefDetails::Task {
                    target_id,
                    room_id,
                    task_list,
                    action,
                    via: Default::default(),
                    preview: Default::default(),
                };
            }
            _ => {
                return Err(crate::Error::FailedToParse {
                    model_type: "RefDetails".to_owned(),
                    msg: "task_list is available for only Task ref".to_owned(),
                });
            }
        }
        Ok(())
    }

    pub fn action(&mut self, action: String) -> crate::Result<()> {
        match self.ref_details.clone() {
            RefDetails::Task {
                target_id,
                room_id,
                task_list,
                ..
            } => {
                let action = TaskAction::from_str(&action)?;
                self.ref_details = RefDetails::Task {
                    target_id,
                    room_id,
                    task_list,
                    action,
                    via: Default::default(),
                    preview: Default::default(),
                };
            }
            RefDetails::TaskList {
                target_id, room_id, ..
            } => {
                let action = TaskListAction::from_str(&action)?;
                self.ref_details = RefDetails::TaskList {
                    target_id,
                    room_id,
                    action,
                    via: Default::default(),
                    preview: Default::default(),
                };
            }
            RefDetails::CalendarEvent {
                target_id, room_id, ..
            } => {
                let action = CalendarEventAction::from_str(&action)?;
                self.ref_details = RefDetails::CalendarEvent {
                    target_id,
                    room_id,
                    action,
                    via: Default::default(),
                    preview: Default::default(),
                };
            }
            _ => {
                return Err(crate::Error::FailedToParse {
                    model_type: "RefDetails".to_owned(),
                    msg: "action is available for only Task/TaskList/CalendarEvent ref".to_owned(),
                });
            }
        }
        Ok(())
    }

    pub fn unset_action(&mut self) -> crate::Result<()> {
        match self.ref_details.clone() {
            RefDetails::Task {
                target_id,
                room_id,
                task_list,
                ..
            } => {
                self.ref_details = RefDetails::Task {
                    target_id,
                    room_id,
                    task_list,
                    action: TaskAction::default(),
                    via: Default::default(),
                    preview: Default::default(),
                };
            }
            RefDetails::TaskList {
                target_id, room_id, ..
            } => {
                self.ref_details = RefDetails::TaskList {
                    target_id,
                    room_id,
                    action: TaskListAction::default(),
                    via: Default::default(),
                    preview: Default::default(),
                };
            }
            RefDetails::CalendarEvent {
                target_id, room_id, ..
            } => {
                self.ref_details = RefDetails::CalendarEvent {
                    target_id,
                    room_id,
                    action: CalendarEventAction::default(),
                    via: Default::default(),
                    preview: Default::default(),
                };
            }
            _ => {
                return Err(crate::Error::FailedToParse {
                    model_type: "RefDetails".to_owned(),
                    msg: "action is available for only Task/TaskList/CalendarEvent ref".to_owned(),
                });
            }
        }
        Ok(())
    }

    pub fn title(&mut self, title: String) -> crate::Result<()> {
        match self.ref_details.clone() {
            RefDetails::Link { uri, .. } => {
                self.ref_details = RefDetails::Link { title, uri };
            }
            _ => {
                return Err(crate::Error::FailedToParse {
                    model_type: "RefDetails".to_owned(),
                    msg: "title is available for only Link ref".to_owned(),
                });
            }
        }
        Ok(())
    }

    pub fn uri(&mut self, uri: String) -> crate::Result<()> {
        match self.ref_details.clone() {
            RefDetails::Link { title, .. } => {
                self.ref_details = RefDetails::Link { title, uri };
            }
            _ => {
                return Err(crate::Error::FailedToParse {
                    model_type: "RefDetails".to_owned(),
                    msg: "uri is available for only Link ref".to_owned(),
                });
            }
        }
        Ok(())
    }

    pub fn build(&self) -> RefDetails {
        self.ref_details.clone()
    }
}

/// An object reference is a link within the application
/// to a specific object with an optional flag to explain
/// how to embed said object. These may be interactive
/// elements when rendered on the view.
#[derive(Clone, Debug, Deserialize, Serialize)]
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

    pub fn ref_details(&self) -> RefDetails {
        self.reference.clone()
    }
}

#[derive(Debug, Clone)]
pub struct ObjRefBuilder {
    obj_ref: ObjRef,
}

impl ObjRefBuilder {
    pub fn new(position: Option<Position>, reference: RefDetails) -> Self {
        let obj_ref = ObjRef::new(position, reference);
        ObjRefBuilder { obj_ref }
    }

    pub fn position(&mut self, position: String) -> crate::Result<()> {
        let ObjRef { reference, .. } = self.obj_ref.clone();
        let position = Position::from_str(&position)?;
        self.obj_ref = ObjRef::new(Some(position), reference);
        Ok(())
    }

    pub fn unset_position(&mut self) -> &mut Self {
        let ObjRef { reference, .. } = self.obj_ref.clone();
        self.obj_ref = ObjRef::new(None, reference);
        self
    }

    #[allow(clippy::boxed_local)]
    pub fn reference(&mut self, reference: Box<RefDetails>) -> &mut Self {
        let ObjRef { position, .. } = self.obj_ref.clone();
        self.obj_ref = ObjRef::new(position, *reference);
        self
    }

    pub fn build(&self) -> ObjRef {
        self.obj_ref.clone()
    }
}
