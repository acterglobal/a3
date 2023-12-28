mod task;
mod task_list;

pub use task::{Task, TaskSelfAssign, TaskSelfUnassign, TaskUpdate};
pub use task_list::{TaskList, TaskListUpdate, TaskStats};

use crate::statics::KEYS;

static TASKS_KEY: &str = KEYS::TASKS;
