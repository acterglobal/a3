use super::TextMessageEventContent;
use crate::util::deserialize_some;
use derive_builder::Builder;
use matrix_sdk::ruma::{events::macros::EventContent, OwnedUserId};
use serde::{Deserialize, Serialize};
use serde_repr::{Deserialize_repr, Serialize_repr};

/// ToDo Lists and Task Items management
/// modeled after [JMAP Tasks](https://jmap.io/spec-tasks.html), extensions to
/// [ietf rfc8984](https://www.rfc-editor.org/rfc/rfc8984.html#name-task).
///
use super::{BelongsTo, Color, TimeZone, Update, UtcDateTime};

#[derive(Clone, Serialize, Deserialize, Debug)]
pub enum SpecialTaskListRole {
    Inbox,
    Trash,
}

#[derive(Clone, Serialize_repr, Deserialize_repr, PartialEq, Eq, Debug)]
#[repr(u8)]
/// Implementing Priority according to
/// <https://www.rfc-editor.org/rfc/rfc8984.html#section-4.4.1>
pub enum Priority {
    Undefined = 0,
    Highest = 1,
    SecondHighest = 2,
    Three = 3,
    Four = 4,
    Five = 5,
    Six = 6,
    Seven = 7,
    SecondLowest = 8,
    Lowest = 9,
}

impl Default for Priority {
    fn default() -> Self {
        Priority::Undefined
    }
}

/// The TaskList Event
///
/// modeled after [JMAP TaskList](https://jmap.io/spec-tasks.html#tasklists)
#[derive(Clone, Debug, Default, Deserialize, Serialize, EventContent, Builder)]
#[ruma_event(type = "org.effektio.dev.tasklist", kind = MessageLike)]
#[builder(name = "TaskListBuilder", derive(Debug))]
pub struct TaskListEventContent {
    pub name: String,
    #[builder(setter(into, strip_option), default)]
    pub role: Option<SpecialTaskListRole>,
    #[builder(setter(into, strip_option), default)]
    pub description: Option<TextMessageEventContent>,
    #[builder(setter(into, strip_option), default)]
    pub color: Option<Color>,
    #[builder(default)]
    pub sort_order: u32,
    #[builder(setter(into, strip_option), default)]
    pub time_zone: Option<TimeZone>,
    // FIXME: manage through `label` as in [MSC2326](https://github.com/matrix-org/matrix-doc/pull/2326)
    #[builder(setter(into, strip_option), default)]
    pub keywords: Option<Vec<String>>,
    #[builder(setter(into, strip_option), default)]
    pub categories: Option<Vec<String>>,
    #[builder(setter(into, strip_option), default)]
    pub subscribers: Option<Vec<OwnedUserId>>,
}

/// The Task Event
///
/// modeled after [JMAP Task](https://jmap.io/spec-tasks.html#tasks)
/// see also the [IETF Task](https://www.rfc-editor.org/rfc/rfc8984.html#name-task)
/// but all timezones have been dumbed down to UTC-only.
#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder)]
#[ruma_event(type = "org.effektio.dev.task", kind = MessageLike)]
#[builder(name = "TaskBuilder", derive(Debug))]
pub struct TaskEventContent {
    /// The title of the Task
    pub title: String,
    /// Every tasks belongs to a tasklist
    #[builder(setter(into))]
    #[serde(rename = "m.relates_to")]
    pub task_list_id: BelongsTo,
    /// Further information describing the task
    #[builder(setter(into, strip_option), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub description: Option<TextMessageEventContent>,
    /// The users this task is assigned to
    #[builder(default)]
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub assignees: Vec<OwnedUserId>,
    /// Other users subscribed to updates of this item
    #[builder(setter(into, strip_option), default)]
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub subscribers: Vec<OwnedUserId>,
    /// When is this task due
    #[builder(setter(into, strip_option), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub utc_due: Option<UtcDateTime>,
    /// When was this task started?
    #[builder(setter(into, strip_option), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub utc_start: Option<UtcDateTime>,
    /// How far along is this task in percent (everything > 100: = 100)
    #[builder(default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub progress_percent: Option<u8>,
    /// Sort order within the TaskList
    #[builder(default)]
    pub sort_order: u32,
    /// the priority of the Task
    #[builder(default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub priority: Option<Priority>,
    /// Color this task
    #[builder(setter(into, strip_option), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub color: Option<Color>,
    // FIXME: manage through `label` as in [MSC2326](https://github.com/matrix-org/matrix-doc/pull/2326)
    #[builder(setter(into, strip_option), default)]
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub keywords: Vec<String>,
    #[builder(setter(into, strip_option), default)]
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub categories: Vec<String>,
}

/// The Task Update Event
///
/// modeled after [JMAP Task](https://jmap.io/spec-tasks.html#tasks)
/// see also the [IETF Task](https://www.rfc-editor.org/rfc/rfc8984.html#name-task)
/// but all timezones have been dumbed down to UTC-only.
#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder)]
#[ruma_event(type = "org.effektio.dev.task.update", kind = MessageLike)]
#[builder(name = "TaskUpdateBuilder", derive(Debug))]
pub struct TaskUpdateEventContent {
    #[builder(setter(into))]
    #[serde(rename = "m.relates_to")]
    pub task: Update,
    /// The title of the Task
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub title: Option<String>,
    /// Every tasks belongs to a tasklist
    /// Further information describing the task
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub description: Option<Option<TextMessageEventContent>>,
    /// The users this task is assigned to
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub assignees: Option<Vec<OwnedUserId>>,
    /// Other users subscribed to updates of this item
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub subscribers: Option<Vec<OwnedUserId>>,
    /// When is this task due
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub utc_due: Option<Option<UtcDateTime>>,
    /// When was this task started?
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub utc_start: Option<Option<UtcDateTime>>,
    /// How far along is this task in percent (everything > 100: = 100)
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub progress_percent: Option<Option<u8>>,
    /// Sort order within the TaskList
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub sort_order: Option<u32>,
    /// the priority of the Task
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub priority: Option<Option<Priority>>,
    /// Color this task
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub color: Option<Option<Color>>,
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

impl TaskUpdateEventContent {
    pub fn apply(&self, task: &mut TaskEventContent) -> crate::Result<bool> {
        let mut updated = false;
        if let Some(title) = &self.title {
            task.title = title.clone();
            updated = true;
        }

        if let Some(description) = &self.description {
            task.description = description.clone();
            updated = true;
        }

        if let Some(assignees) = &self.assignees {
            task.assignees = assignees.clone();
            updated = true;
        }

        if let Some(subscribers) = &self.subscribers {
            task.subscribers = subscribers.clone();
            updated = true;
        }

        if let Some(utc_due) = &self.utc_due {
            task.utc_due = utc_due.clone();
            updated = true;
        }

        if let Some(utc_start) = &self.utc_start {
            task.utc_start = utc_start.clone();
            updated = true;
        }

        if let Some(progress_percent) = &self.progress_percent {
            task.progress_percent = progress_percent.clone();
            updated = true;
        }

        if let Some(sort_order) = &self.sort_order {
            task.sort_order = sort_order.clone();
            updated = true;
        }

        if let Some(priority) = &self.priority {
            task.priority = priority.clone();
            updated = true;
        }

        if let Some(color) = &self.color {
            task.color = color.clone();
            updated = true;
        }

        if let Some(keywords) = &self.keywords {
            task.keywords = keywords.clone();
            updated = true;
        }

        if let Some(categories) = &self.categories {
            task.categories = categories.clone();
            updated = true;
        }

        tracing::trace!(update = ?self, ?updated, ?task, "Task updated");

        Ok(updated)
    }
}
