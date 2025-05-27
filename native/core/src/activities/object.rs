use matrix_sdk_base::ruma::{events::room::message::TextMessageEventContent, OwnedEventId};
use urlencoding::encode;

use crate::{
    events::{Date, UtcDateTime},
    models::{ActerModel, AnyActerModel},
};

#[derive(Clone, Debug)]
pub enum ActivityObject {
    News {
        object_id: OwnedEventId,
    },
    Story {
        object_id: OwnedEventId,
    },
    Pin {
        object_id: OwnedEventId,
        title: String,
        description: Option<TextMessageEventContent>,
    },
    CalendarEvent {
        object_id: OwnedEventId,
        title: String,
        description: Option<TextMessageEventContent>,
        utc_start: UtcDateTime,
        utc_end: UtcDateTime,
    },
    TaskList {
        object_id: OwnedEventId,
        title: String,
    },
    Task {
        tl_id: OwnedEventId,
        object_id: OwnedEventId,
        title: String,
        due_date: Option<Date>,
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
            ActivityObject::Story { .. } => "story",
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
            | ActivityObject::CalendarEvent { object_id, .. }
            | ActivityObject::Story { object_id, .. } => object_id.to_string(),
        }
    }
    pub fn title(&self) -> Option<String> {
        match self {
            ActivityObject::News { .. }
            | ActivityObject::Unknown { .. }
            | ActivityObject::Story { .. } => None,
            ActivityObject::Pin { title, .. }
            | ActivityObject::TaskList { title, .. }
            | ActivityObject::Task { title, .. }
            | ActivityObject::CalendarEvent { title, .. } => Some(title.clone()),
        }
    }

    pub fn target_url(&self) -> String {
        match self {
            ActivityObject::News { object_id } => format!("/updates/{}", object_id),
            ActivityObject::Story { object_id } => format!("/updates/{}", object_id),
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

    pub fn task_list_id_str(&self) -> Option<String> {
        match self {
            ActivityObject::Task { tl_id, .. } => Some(tl_id.to_string()),
            _ => None,
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
            ActivityObject::Story { .. } => "📰",         //  for story
        }
        .to_owned()
    }

    pub fn description(&self) -> Option<TextMessageEventContent> {
        match self {
            ActivityObject::Pin { description, .. } => description.clone(),
            ActivityObject::CalendarEvent { description, .. } => description.clone(),
            _ => None,
        }
    }

    pub fn utc_start(&self) -> Option<UtcDateTime> {
        match self {
            ActivityObject::CalendarEvent { utc_start, .. } => Some(*utc_start),
            _ => None,
        }
    }

    pub fn utc_end(&self) -> Option<UtcDateTime> {
        match self {
            ActivityObject::CalendarEvent { utc_end, .. } => Some(*utc_end),
            _ => None,
        }
    }

    pub fn due_date(&self) -> Option<Date> {
        match self {
            ActivityObject::Task { due_date, .. } => *due_date,
            _ => None,
        }
    }
}

impl TryFrom<&AnyActerModel> for ActivityObject {
    type Error = ();

    fn try_from(value: &AnyActerModel) -> std::result::Result<Self, Self::Error> {
        match value {
            AnyActerModel::NewsEntry(e) => Ok(ActivityObject::News {
                object_id: e.event_id().to_owned(),
            }),
            AnyActerModel::Story(e) => Ok(ActivityObject::Story {
                object_id: e.event_id().to_owned(),
            }),
            AnyActerModel::CalendarEvent(e) => Ok(ActivityObject::CalendarEvent {
                object_id: e.event_id().to_owned(),
                title: e.title(),
                description: e.description.clone(),
                utc_start: e.utc_start(),
                utc_end: e.utc_end(),
            }),
            AnyActerModel::Pin(e) => Ok(ActivityObject::Pin {
                object_id: e.event_id().to_owned(),
                title: e.title(),
                description: e.description(),
            }),
            AnyActerModel::TaskList(e) => Ok(ActivityObject::TaskList {
                object_id: e.event_id().to_owned(),
                title: e.name().clone(),
            }),
            AnyActerModel::Task(e) => Ok(ActivityObject::Task {
                object_id: e.event_id().to_owned(),
                tl_id: e.task_list_id.event_id.clone(),
                title: e.title(),
                due_date: e.due_date,
            }),
            AnyActerModel::RedactedActerModel(_)
            | AnyActerModel::ExplicitInvite(_)
            | AnyActerModel::CalendarEventUpdate(_)
            | AnyActerModel::TaskListUpdate(_)
            | AnyActerModel::TaskUpdate(_)
            | AnyActerModel::TaskSelfAssign(_)
            | AnyActerModel::TaskSelfUnassign(_)
            | AnyActerModel::PinUpdate(_)
            | AnyActerModel::NewsEntryUpdate(_)
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
            AnyActerModel::TestModel(_test_model) => {
                tracing::warn!("Converting a a test model failed");
                Err(())
            }
        }
    }
}
