use matrix_sdk::ruma::OwnedEventId;
use urlencoding::encode;

use crate::models::{ActerModel, AnyActerModel};

#[derive(Clone, Debug)]
pub enum ActivityObject {
    News {
        object_id: OwnedEventId,
    },
    Pin {
        object_id: OwnedEventId,
        title: String,
    },
    CalendarEvent {
        object_id: OwnedEventId,
        title: String,
    },
    TaskList {
        object_id: OwnedEventId,
        title: String,
    },
    Task {
        tl_id: OwnedEventId,
        object_id: OwnedEventId,
        title: String,
    },
    Unknown {
        object_id: OwnedEventId,
    },
}

impl ActivityObject {
    pub fn type_str(&self) -> String {
        match self {
            ActivityObject::News { .. } => "news",
            ActivityObject::Pin { .. } => "pin",
            ActivityObject::CalendarEvent { .. } => "event",
            ActivityObject::TaskList { .. } => "task-list",
            ActivityObject::Task { .. } => "task",
            ActivityObject::Unknown { .. } => "unknown",
        }
        .to_owned()
    }
    pub fn object_id_str(&self) -> String {
        match self {
            ActivityObject::News { object_id }
            | ActivityObject::Pin { object_id, .. }
            | ActivityObject::TaskList { object_id, .. }
            | ActivityObject::Task { object_id, .. }
            | ActivityObject::Unknown { object_id, .. }
            | ActivityObject::CalendarEvent { object_id, .. } => object_id.to_string(),
        }
    }
    pub fn title(&self) -> Option<String> {
        match self {
            ActivityObject::News { .. } | ActivityObject::Unknown { .. } => None,
            ActivityObject::Pin { title, .. }
            | ActivityObject::TaskList { title, .. }
            | ActivityObject::Task { title, .. }
            | ActivityObject::CalendarEvent { title, .. } => Some(title.clone()),
        }
    }

    pub fn target_url(&self) -> String {
        match self {
            ActivityObject::News { object_id } => format!("/updates/{}", object_id),
            ActivityObject::Pin { object_id, .. } => format!("/pins/{}", object_id),
            ActivityObject::TaskList { object_id, .. } => format!("/tasks/{}", object_id),
            ActivityObject::Task {
                object_id, tl_id, ..
            } => format!("/tasks/{tl_id}/{object_id}"),
            ActivityObject::CalendarEvent { object_id, .. } => {
                format!("/events/{}", object_id)
            }
            ActivityObject::Unknown { object_id } => {
                format!("/forward?eventId={}", encode(object_id.as_str()),)
            }
        }
    }

    pub fn emoji(&self) -> String {
        match self {
            ActivityObject::News { .. } => "🚀",          // boost rocket
            ActivityObject::Pin { .. } => "📌",           // pin
            ActivityObject::TaskList { .. } => "📋",      // tasklist-> clipboard
            ActivityObject::CalendarEvent { .. } => "🗓️", // calendar
            ActivityObject::Task { .. } => "☑️",          // task -> checkoff
            ActivityObject::Unknown { .. } => "🧩",       // puzzle piece if unknown
        }
        .to_owned()
    }
}

impl TryFrom<&AnyActerModel> for ActivityObject {
    type Error = ();

    fn try_from(value: &AnyActerModel) -> std::result::Result<Self, Self::Error> {
        match value {
            AnyActerModel::NewsEntry(e) => Ok(ActivityObject::News {
                object_id: e.event_id().to_owned(),
            }),
            AnyActerModel::CalendarEvent(e) => Ok(ActivityObject::CalendarEvent {
                object_id: e.event_id().to_owned(),
                title: e.title().clone(),
            }),
            AnyActerModel::Pin(e) => Ok(ActivityObject::Pin {
                object_id: e.event_id().to_owned(),
                title: e.title().clone(),
            }),
            AnyActerModel::TaskList(e) => Ok(ActivityObject::TaskList {
                object_id: e.event_id().to_owned(),
                title: e.name().clone(),
            }),
            AnyActerModel::Task(e) => Ok(ActivityObject::Task {
                object_id: e.event_id().to_owned(),
                tl_id: e.task_list_id.event_id.clone(),
                title: e.title().clone(),
            }),
            AnyActerModel::RedactedActerModel(_)
            | AnyActerModel::CalendarEventUpdate(_)
            | AnyActerModel::TaskListUpdate(_)
            | AnyActerModel::TaskUpdate(_)
            | AnyActerModel::TaskSelfAssign(_)
            | AnyActerModel::TaskSelfUnassign(_)
            | AnyActerModel::PinUpdate(_)
            | AnyActerModel::NewsEntryUpdate(_)
            | AnyActerModel::Story(_)
            | AnyActerModel::StoryUpdate(_)
            | AnyActerModel::Comment(_)
            | AnyActerModel::CommentUpdate(_)
            | AnyActerModel::Attachment(_)
            | AnyActerModel::AttachmentUpdate(_)
            | AnyActerModel::Rsvp(_)
            | AnyActerModel::Reaction(_)
            | AnyActerModel::RoomStatus(_)
            | AnyActerModel::ReadReceipt(_) => {
                tracing::trace!("Received Notification on an unsupported parent");
                Err(())
            }
            #[cfg(any(test, feature = "testing"))]
            AnyActerModel::TestModel(_test_model) => todo!(),
        }
    }
}
