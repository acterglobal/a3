mod color;
mod faq;
mod news;
mod tag;
mod tasks;

pub use color::Color;
pub use core::fmt::Debug;
pub use faq::Faq;
use matrix_sdk::ruma::{
    events::{AnySyncTimelineEvent, AnyTimelineEvent, MessageLikeEvent},
    serde::Raw,
    RoomId,
};
pub use news::News;
use serde::{Deserialize, Serialize};
pub use tag::Tag;
pub use tasks::{Task, TaskList, TaskUpdate};

use enum_dispatch::enum_dispatch;

use crate::events::tasks::{
    OriginalTaskEvent, OriginalTaskListEvent, OriginalTaskUpdateEvent, SyncTaskEvent,
    SyncTaskListEvent, SyncTaskUpdateEvent,
};

#[enum_dispatch(AnyEffektioModel)]
pub trait EffektioModel: Debug {
    /// The indizes this model should be added to
    fn indizes(&self) -> Vec<String>;
    /// The key to store this model under
    fn key(&self) -> String;
    /// The models to inform about this model as it belongs to that
    fn belongs_to(&self) -> Option<Vec<String>> {
        None
    }
    /// handle transition
    fn transition(&mut self, model: &AnyEffektioModel) -> crate::Result<bool> {
        tracing::error!(?self, ?model, "Transition has not been implemented");
        Ok(false)
    }
}

#[enum_dispatch]
#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum AnyEffektioModel {
    TaskList,
    Task,
    TaskUpdate,
}

impl AnyEffektioModel {
    pub fn from_raw_tlevent(raw: &Raw<AnyTimelineEvent>) -> Option<Self> {
        let Ok(Some(m_type)) = raw.get_field("type") else {
            return None;
        };

        match m_type {
            "org.effektio.dev.tasklist" => Some(AnyEffektioModel::TaskList(
                raw.deserialize_as::<OriginalTaskListEvent>()
                    .map_err(|error| {
                        tracing::error!(?error, ?raw, "parsing task list event failed")
                    })
                    .ok()?
                    .into(),
            )),
            "org.effektio.dev.task" => Some(AnyEffektioModel::Task(
                raw.deserialize_as::<OriginalTaskEvent>()
                    .map_err(|error| tracing::error!(?error, ?raw, "parsing task event failed"))
                    .ok()?
                    .into(),
            )),
            "org.effektio.dev.task.update" => Some(AnyEffektioModel::TaskUpdate(
                raw.deserialize_as::<OriginalTaskUpdateEvent>()
                    .map_err(|error| {
                        tracing::error!(?error, ?raw, "parsing task update event failed")
                    })
                    .ok()?
                    .into(),
            )),
            _ => None,
        }
    }
    pub fn from_raw_synctlevent(raw: &Raw<AnySyncTimelineEvent>, room_id: &RoomId) -> Option<Self> {
        let Ok(Some(m_type)) = raw.get_field("type") else {
            return None;
        };

        match m_type {
            "org.effektio.dev.tasklist" => match raw
                .deserialize_as::<SyncTaskListEvent>()
                .map_err(|error| tracing::error!(?error, ?raw, "parsing task list event failed"))
                .ok()?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Some(AnyEffektioModel::TaskList(t.into())),
                _ => None,
            },
            "org.effektio.dev.task" => match raw
                .deserialize_as::<SyncTaskEvent>()
                .map_err(|error| tracing::error!(?error, ?raw, "parsing task event failed"))
                .ok()?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Some(AnyEffektioModel::Task(t.into())),
                _ => None,
            },
            "org.effektio.dev.task.update" => match raw
                .deserialize_as::<SyncTaskUpdateEvent>()
                .map_err(|error| tracing::error!(?error, ?raw, "parsing task update event failed"))
                .ok()?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Some(AnyEffektioModel::TaskUpdate(t.into())),
                _ => None,
            },
            _ => None,
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
        let _effektio_ev = AnyEffektioModel::from_raw_tlevent(&event).unwrap();
        // assert!(matches!(event, AnyCreation::TaskList(_)));
        Ok(())
    }
}
