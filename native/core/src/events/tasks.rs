use chrono_tz::Tz;
use core::result::Result as CoreResult;
use derive_builder::Builder;
use derive_getters::Getters;
use matrix_sdk_base::ruma::events::{macros::EventContent, room::message::TextMessageEventContent};
use serde::{Deserialize, Serialize};
use serde_repr::{Deserialize_repr, Serialize_repr};
use tracing::trace;

/// ToDo Lists and Task Items management
/// modeled after [JMAP Tasks](https://jmap.io/spec-tasks.html), extensions to
/// [ietf rfc8984](https://www.rfc-editor.org/rfc/rfc8984.html#name-task).
///
use super::{BelongsTo, Date, Display, Update, UtcDateTime};
use crate::{util::deserialize_some, Result as ActerResult};

#[derive(Clone, Serialize, Deserialize, Debug)]
pub enum SpecialTaskListRole {
    Inbox,
    Trash,
}

#[derive(Clone, Serialize_repr, Deserialize_repr, PartialEq, Eq, Debug)]
#[repr(u8)]
/// Implementing Priority according to
/// <https://www.rfc-editor.org/rfc/rfc8984.html#section-4.4.1>
#[derive(Default)]
pub enum Priority {
    #[default]
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

impl Priority {
    fn is_undefinied(&self) -> bool {
        matches!(self, Priority::Undefined)
    }
}

/// The TaskList Event
///
/// modeled after [JMAP TaskList](https://jmap.io/spec-tasks.html#tasklists)
#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder, Getters)]
#[ruma_event(type = "global.acter.dev.tasklist", kind = MessageLike)]
#[builder(name = "TaskListBuilder", derive(Debug))]
pub struct TaskListEventContent {
    pub name: String,

    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub role: Option<SpecialTaskListRole>,

    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub description: Option<TextMessageEventContent>,

    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub display: Option<Display>,

    #[builder(default)]
    #[serde(default)]
    pub sort_order: u32,

    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub time_zone: Option<Tz>,

    // FIXME: manage through `label` as in [MSC2326](https://github.com/matrix-org/matrix-doc/pull/2326)
    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub keywords: Vec<String>,

    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub categories: Vec<String>,
}

/// The TaskList Event
///
/// modeled after [JMAP TaskList](https://jmap.io/spec-tasks.html#tasklists)
#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder)]
#[ruma_event(type = "global.acter.dev.tasklist.update", kind = MessageLike)]
#[builder(name = "TaskListUpdateBuilder", derive(Debug))]
pub struct TaskListUpdateEventContent {
    #[builder(setter(into))]
    #[serde(rename = "m.relates_to")]
    pub task_list: Update,

    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub name: Option<String>,

    #[builder(setter(into), default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub role: Option<Option<SpecialTaskListRole>>,

    #[builder(setter(into), default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub description: Option<Option<TextMessageEventContent>>,

    #[builder(setter(into), default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub display: Option<Option<Display>>,

    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub sort_order: Option<u32>,

    #[builder(setter(into), default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub time_zone: Option<Option<Tz>>,

    // FIXME: manage through `label` as in [MSC2326](https://github.com/matrix-org/matrix-doc/pull/2326)
    #[builder(setter(into), default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub keywords: Option<Vec<String>>,

    #[builder(setter(into), default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub categories: Option<Vec<String>>,
}

impl TaskListUpdateEventContent {
    pub fn apply(&self, task_list: &mut TaskListEventContent) -> ActerResult<bool> {
        let mut updated = false;
        if let Some(name) = &self.name {
            task_list.name.clone_from(name);
            updated = true;
        }
        if let Some(role) = &self.role {
            task_list.role.clone_from(role);
            updated = true;
        }
        if let Some(description) = &self.description {
            task_list.description.clone_from(description);
            updated = true;
        }
        if let Some(display) = &self.display {
            task_list.display.clone_from(display);
            updated = true;
        }
        if let Some(sort_order) = &self.sort_order {
            task_list.sort_order = *sort_order;
            updated = true;
        }
        if let Some(time_zone) = &self.time_zone {
            task_list.time_zone = *time_zone;
            updated = true;
        }
        if let Some(keywords) = &self.keywords {
            task_list.keywords.clone_from(keywords);
            updated = true;
        }
        if let Some(categories) = &self.categories {
            task_list.categories.clone_from(categories);
            updated = true;
        }

        trace!(update = ?self, ?updated, ?task_list, "TaskList updated");

        Ok(updated)
    }
}

/// The Task Event
///
/// modeled after [JMAP Task](https://jmap.io/spec-tasks.html#tasks)
/// see also the [IETF Task](https://www.rfc-editor.org/rfc/rfc8984.html#name-task)
/// but all timezones have been dumbed down to UTC-only.
#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder, Getters)]
#[ruma_event(type = "global.acter.dev.task", kind = MessageLike)]
#[builder(
    name = "TaskBuilder",
    build_fn(validate = "Self::validate"),
    derive(Debug)
)]
pub struct TaskEventContent {
    /// The title of the Task
    pub title: String,

    /// Every tasks belongs to a tasklist
    #[builder(setter(into))]
    #[serde(rename = "m.relates_to")]
    pub task_list_id: BelongsTo,

    /// Further information describing the task
    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub description: Option<TextMessageEventContent>,

    /// Which day is this task due
    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub due_date: Option<Date>,

    /// Any particular time this task is due as seconds since/to midnight UTC
    /// make sure to include any
    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub utc_due_time_of_day: Option<i32>,

    /// When was this task started?
    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub utc_start: Option<UtcDateTime>,

    /// How far along is this task in percent (everything > 100: = 100)
    #[builder(default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub progress_percent: Option<u8>,

    /// Sort order within the TaskList
    #[builder(default)]
    #[serde(default)]
    pub sort_order: u32,

    /// the priority of the Task
    #[builder(default)]
    #[serde(default, skip_serializing_if = "Priority::is_undefinied")]
    pub priority: Priority,

    /// Display this task
    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub display: Option<Display>,

    // FIXME: manage through `label` as in [MSC2326](https://github.com/matrix-org/matrix-doc/pull/2326)
    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub keywords: Vec<String>,

    #[builder(setter(into), default)]
    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    pub categories: Vec<String>,
}

impl TaskBuilder {
    fn validate(&self) -> CoreResult<(), String> {
        if let Some(Some(percent)) = &self.progress_percent {
            if *percent > 100 {
                return Err("Progress percent can’t be higher than 100".to_string());
            }
        }
        Ok(())
    }
}

/// The Task Update Event
///
/// modeled after [JMAP Task](https://jmap.io/spec-tasks.html#tasks)
/// see also the [IETF Task](https://www.rfc-editor.org/rfc/rfc8984.html#name-task)
/// but all timezones have been dumbed down to UTC-only.
#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder)]
#[ruma_event(type = "global.acter.dev.task.update", kind = MessageLike)]
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

    /// Day when is this task due
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub due_date: Option<Option<Date>>,

    /// Specific time on the day is this task due
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub utc_due_time_of_day: Option<Option<i32>>,

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
    pub priority: Option<Priority>,

    /// Display this task
    #[builder(default)]
    #[serde(
        default,
        skip_serializing_if = "Option::is_none",
        deserialize_with = "deserialize_some"
    )]
    pub display: Option<Option<Display>>,

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
    pub fn apply(&self, task: &mut TaskEventContent) -> ActerResult<bool> {
        let mut updated = false;
        if let Some(title) = &self.title {
            task.title.clone_from(title);
            updated = true;
        }
        if let Some(description) = &self.description {
            task.description.clone_from(description);
            updated = true;
        }
        if let Some(due_date) = &self.due_date {
            task.due_date = *due_date;
            updated = true;
        }
        if let Some(utc_due_time_of_day) = &self.utc_due_time_of_day {
            task.utc_due_time_of_day = *utc_due_time_of_day;
            updated = true;
        }
        if let Some(utc_start) = &self.utc_start {
            task.utc_start = *utc_start;
            updated = true;
        }
        if let Some(progress_percent) = &self.progress_percent {
            task.progress_percent = *progress_percent;
            updated = true;
        }
        if let Some(sort_order) = &self.sort_order {
            task.sort_order = *sort_order;
            updated = true;
        }
        if let Some(priority) = &self.priority {
            task.priority = priority.clone();
            updated = true;
        }
        if let Some(display) = &self.display {
            task.display.clone_from(display);
            updated = true;
        }
        if let Some(keywords) = &self.keywords {
            task.keywords.clone_from(keywords);
            updated = true;
        }
        if let Some(categories) = &self.categories {
            task.categories.clone_from(categories);
            updated = true;
        }

        trace!(update = ?self, ?updated, ?task, "Task updated");

        Ok(updated)
    }
}

/// TaskSelfAssign Event
#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder, Getters)]
#[ruma_event(type = "global.acter.dev.task.self_assign", kind = MessageLike)]
#[builder(name = "TaskSelfAssignBuilder", derive(Debug))]
pub struct TaskSelfAssignEventContent {
    #[builder(setter(into))]
    #[serde(rename = "m.relates_to")]
    pub task: BelongsTo,
}

/// TaskSelfUnassign Event
#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder, Getters)]
#[ruma_event(type = "global.acter.dev.task.self_unassign", kind = MessageLike)]
#[builder(name = "TaskSelfUnassignBuilder", derive(Debug))]
pub struct TaskSelfUnassignEventContent {
    #[builder(setter(into))]
    #[serde(rename = "m.relates_to")]
    pub task: BelongsTo,
}
