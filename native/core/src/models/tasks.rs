
mod task;
mod task_list;

pub use task::{Task, TaskUpdate};
pub use task_list::{TaskStats, TaskListUpdate, TaskList};

use crate::{
    statics::KEYS,
};

static TASKS_KEY: &str = KEYS::TASKS;
