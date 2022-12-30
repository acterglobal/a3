mod color;
mod faq;
mod news;
mod tag;
mod tasks;

pub use color::Color;
pub use faq::Faq;
use matrix_sdk::ruma::{events::AnyTimelineEvent, serde::Raw};
pub use news::News;
use serde::{Deserialize, Serialize};
pub use tag::Tag;
pub use tasks::{Task, TaskList};

use enum_dispatch::enum_dispatch;

use crate::events::tasks::{OriginalTaskEvent, OriginalTaskListEvent};

#[enum_dispatch(AnyEffektioModel)]
pub trait EffektioModel {
    /// The indizes this model should be added to
    fn indizes(&self) -> Vec<String>;
    /// The key to store this model under
    fn key(&self) -> String;
    /// The models to inform about this model as it belongs to that
    fn belongs_to(&self) -> Option<Vec<String>> {
        None
    }
    /// handle transition
    fn transition(&mut self, model: &AnyEffektioModel) -> crate::Result<bool>;
}

#[enum_dispatch]
#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum AnyEffektioModel {
    TaskList,
    Task,
}

impl TryFrom<&Raw<AnyTimelineEvent>> for AnyEffektioModel {
    type Error = crate::Error;
    fn try_from(raw: &Raw<AnyTimelineEvent>) -> Result<Self, Self::Error> {
        let Ok(Some(m_type)) = raw.get_field("type") else {
            return Err(crate::Error::UnknownEvent);
        };

        match m_type {
            "org.effektio.dev.tasklist" => Ok(AnyEffektioModel::TaskList(
                raw.deserialize_as::<OriginalTaskListEvent>()?.into(),
            )),
            "org.effektio.dev.task" => Ok(AnyEffektioModel::Task(
                raw.deserialize_as::<OriginalTaskEvent>()?.into(),
            )),
            _ => Err(crate::Error::UnknownEvent),
        }
    }
}

#[cfg(feature = "with-mocks")]
pub mod mocks {
    pub use super::color::mocks::ColorFaker;
    pub use super::faq::gen_mocks as gen_mock_faqs;
    pub use super::news::gen_mocks as gen_mock_news;
}

#[cfg(test)]
mod test {
    use super::*;
    use crate::Result;
    use serde_json;
    #[test]
    fn ensure_tasklist_parses() -> Result<()> {
        let json_raw = r#"{"type":"org.effektio.dev.tasklist",
            "room_id":"!euhIDqDVvVXulrhWgN:ds9.effektio.org","sender":"@odo:ds9.effektio.org",
            "content":{"categories":null,"color":null,"description":
            {"body":"The tops of the daily security briefing with kyra","msgtype":"m.text"},
            "keywords":null,"name":"Daily Security Brief","role":null,"sort_order":0,
            "subscribers":null,"time_zone":null},"origin_server_ts":1672407531453,
            "unsigned":{"age":11523850},
            "event_id":"$KwumA4L3M-duXu0I3UA886LvN-BDCKAyxR1skNfnh3c",
            "user_id":"@odo:ds9.effektio.org","age":11523850}"#;
        let event = serde_json::from_str::<Raw<AnyTimelineEvent>>(json_raw)?;
        let effektio_ev = AnyEffektioModel::try_from(&event)?;
        // assert!(matches!(event, AnyCreation::TaskList(_)));
        Ok(())
    }
}
