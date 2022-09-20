mod color;
mod faq;
mod news;
mod tag;
mod tasks;

use crate::statics::KEYS;
pub use color::Color;
pub use faq::Faq;
pub use news::News;
use serde::{Deserialize, Serialize};
pub use tag::Tag;
pub use tasks::{Task, TaskList};

use crate::events::{AnyBelongTo, AnyCreation};

#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum AnyEffektioModel {
    TaskList(TaskList),
}

impl AnyEffektioModel {
    pub fn indizes(&self) -> Vec<String> {
        match self {
            AnyEffektioModel::TaskList(_) => vec![KEYS::TASKS.to_owned()],
        }
    }
    pub fn key(&self) -> String {
        match self {
            AnyEffektioModel::TaskList(t) => t.event_id.to_string(),
        }
    }

    pub fn transition(&self, _e: &AnyBelongTo) {}
}

impl From<AnyCreation> for AnyEffektioModel {
    fn from(e: AnyCreation) -> Self {
        match e {
            AnyCreation::TaskList(t) => AnyEffektioModel::TaskList(t.into()),
        }
    }
}

#[cfg(feature = "with-mocks")]
pub mod mocks {
    pub use super::color::mocks::ColorFaker;
    pub use super::faq::gen_mocks as gen_mock_faqs;
    pub use super::news::gen_mocks as gen_mock_news;
}
