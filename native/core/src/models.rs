mod color;
mod comments;
mod faq;
mod news;
mod pins;
mod tag;
mod tasks;
#[cfg(test)]
mod test;

use crate::error::Error;
pub use crate::store::Store;
pub use color::Color;
pub use comments::{Comment, CommentUpdate, CommentsManager, CommentsStats};
pub use core::fmt::Debug;
pub use faq::Faq;
use matrix_sdk::ruma::{
    events::{AnySyncTimelineEvent, AnyTimelineEvent, MessageLikeEvent},
    serde::Raw,
    EventId, MilliSecondsSinceUnixEpoch, OwnedEventId, OwnedRoomId, OwnedUserId, RoomId,
};
pub use news::News;
pub use pins::Pin;
use serde::{Deserialize, Serialize};
pub use tag::Tag;
pub use tasks::{Task, TaskList, TaskListUpdate, TaskStats, TaskUpdate};

#[cfg(test)]
pub use test::{TestModel, TestModelBuilder, TestModelBuilderError};

use async_recursion::async_recursion;
use enum_dispatch::enum_dispatch;

use crate::events::{
    comments::{
        OriginalCommentEvent, OriginalCommentUpdateEvent, SyncCommentEvent, SyncCommentUpdateEvent,
    },
    pins::{OriginalPinEvent, SyncPinEvent},
    tasks::{
        OriginalTaskEvent, OriginalTaskListEvent, OriginalTaskUpdateEvent, SyncTaskEvent,
        SyncTaskListEvent, SyncTaskUpdateEvent,
    },
};

#[derive(Debug, Eq, PartialEq)]
pub enum Capability {
    // someone can comment on this
    Commentable,
    // another custom capability
    Custom(&'static str),
}

#[async_recursion]
pub async fn transition_tree(
    store: &Store,
    parents: Vec<String>,
    model: &AnyEffektioModel,
) -> crate::Result<Vec<AnyEffektioModel>> {
    let mut models = vec![];
    for p in parents {
        let mut parent = store.get(&p).await?;
        if parent.transition(model)? {
            if let Some(grandparents) = parent.belongs_to() {
                let mut parent_models = transition_tree(store, grandparents, &parent).await?;
                if !parent_models.is_empty() {
                    models.append(&mut parent_models);
                }
            }
            models.push(parent);
        }
    }
    Ok(models)
}

pub async fn default_model_execute(
    store: &Store,
    model: AnyEffektioModel,
) -> crate::Result<Vec<String>> {
    tracing::trace!(event_id=?model.event_id(), ?model, "handling");
    let Some(belongs_to) = model.belongs_to() else {
        let event_id = model.event_id().to_string();
        tracing::trace!(?event_id, "saving simple model");
        return store.save(model).await
    };

    tracing::trace!(event_id=?model.event_id(), ?belongs_to, "transitioning tree");
    let mut models = transition_tree(store, belongs_to, &model).await?;
    models.push(model);
    store.save_many(models).await
}

#[enum_dispatch(AnyEffektioModel)]
pub trait EffektioModel: Debug {
    fn indizes(&self) -> Vec<String>;
    /// The key to store this model under
    fn event_id(&self) -> &EventId;
    /// The models to inform about this model as it belongs to that
    fn belongs_to(&self) -> Option<Vec<String>> {
        None
    }

    /// activate to enable commenting support for this type of model
    fn capabilities(&self) -> &[Capability] {
        &[]
    }
    /// The execution to run when this model is found.
    async fn execute(self, store: &Store) -> crate::Result<Vec<String>>;

    /// handle transition from an external Item upon us
    fn transition(&mut self, model: &AnyEffektioModel) -> crate::Result<bool> {
        tracing::error!(?self, ?model, "Transition has not been implemented");
        Ok(false)
    }
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct EventMeta {
    /// The globally unique event identifier attached to this task
    pub event_id: OwnedEventId,

    /// The fully-qualified ID of the user who sent created this task
    pub sender: OwnedUserId,

    /// Timestamp in milliseconds on originating homeserver when the task was created
    pub origin_server_ts: MilliSecondsSinceUnixEpoch,

    /// The ID of the room of this task
    pub room_id: OwnedRoomId,
}

#[enum_dispatch]
#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum AnyEffektioModel {
    // -- Tasks
    TaskList,
    TaskListUpdate,
    Task,
    TaskUpdate,

    // -- Pins
    Pin,

    // -- more generics
    Comment,
    CommentUpdate,
    #[cfg(test)]
    TestModel,
}

impl AnyEffektioModel {
    pub fn from_raw_tlevent(raw: &Raw<AnyTimelineEvent>) -> Result<Self, Error> {
        let Ok(Some(m_type)) = raw.get_field("type") else {
            return Err(Error::UnknownModel(None));
        };

        match m_type {
            // -- TASKS
            "org.effektio.dev.tasklist" => Ok(AnyEffektioModel::TaskList(
                raw.deserialize_as::<OriginalTaskListEvent>()
                    .map_err(|error| {
                        tracing::error!(?error, ?raw, "parsing task list event failed");
                        Error::FailedToParse {
                            model_type: "org.effektio.dev.tasklist".to_string(),
                            msg: error.to_string(),
                        }
                    })?
                    .into(),
            )),
            "org.effektio.dev.task" => Ok(AnyEffektioModel::Task(
                raw.deserialize_as::<OriginalTaskEvent>()
                    .map_err(|error| {
                        tracing::error!(?error, ?raw, "parsing task event failed");
                        Error::FailedToParse {
                            model_type: "org.effektio.dev.task".to_string(),
                            msg: error.to_string(),
                        }
                    })?
                    .into(),
            )),
            "org.effektio.dev.task.update" => Ok(AnyEffektioModel::TaskUpdate(
                raw.deserialize_as::<OriginalTaskUpdateEvent>()
                    .map_err(|error| {
                        tracing::error!(?error, ?raw, "parsing task update event failed");
                        Error::FailedToParse {
                            model_type: "org.effektio.dev.task.update".to_string(),
                            msg: error.to_string(),
                        }
                    })?
                    .into(),
            )),

            // -- Pins
            "org.effektio.dev.pin" => Ok(AnyEffektioModel::Pin(
                raw.deserialize_as::<OriginalPinEvent>()
                    .map_err(|error| {
                        tracing::error!(?error, ?raw, "parsing pin event failed");
                        Error::FailedToParse {
                            model_type: "org.effektio.dev.pin".to_string(),
                            msg: error.to_string(),
                        }
                    })?
                    .into(),
            )),

            // -- generics

            // comments
            "org.effektio.dev.comment" => Ok(AnyEffektioModel::Comment(
                raw.deserialize_as::<OriginalCommentEvent>()
                    .map_err(|error| {
                        tracing::error!(?error, ?raw, "parsing task update event failed");
                        Error::FailedToParse {
                            model_type: "org.effektio.dev.comment".to_string(),
                            msg: error.to_string(),
                        }
                    })?
                    .into(),
            )),
            "org.effektio.dev.comment.update" => Ok(AnyEffektioModel::CommentUpdate(
                raw.deserialize_as::<OriginalCommentUpdateEvent>()
                    .map_err(|error| {
                        tracing::error!(?error, ?raw, "parsing task update event failed");
                        Error::FailedToParse {
                            model_type: "org.effektio.dev.comment.update".to_string(),
                            msg: error.to_string(),
                        }
                    })?
                    .into(),
            )),

            _ => {
                if m_type.starts_with("org.effektio.") {
                    tracing::error!(?raw, "{m_type} not implemented");
                }

                Err(Error::UnknownModel(Some(m_type.to_owned())))
            }
        }
    }
    pub fn from_raw_synctlevent(
        raw: &Raw<AnySyncTimelineEvent>,
        room_id: &RoomId,
    ) -> Result<Self, Error> {
        let Ok(Some(m_type)) = raw.get_field("type") else {
            return Err(Error::UnknownModel(None));
        };

        match m_type {
            // -- Tasks
            "org.effektio.dev.tasklist" => match raw
                .deserialize_as::<SyncTaskListEvent>()
                .map_err(|error| {
                    tracing::error!(?error, ?raw, "parsing task list event failed");
                    Error::FailedToParse {
                        model_type: "org.effektio.dev.tasklist".to_string(),
                        msg: error.to_string(),
                    }
                })?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Ok(AnyEffektioModel::TaskList(t.into())),
                _ => Err(Error::UnknownModel(None)),
            },
            "org.effektio.dev.task" => match raw
                .deserialize_as::<SyncTaskEvent>()
                .map_err(|error| {
                    tracing::error!(?error, ?raw, "parsing task event failed");
                    Error::FailedToParse {
                        model_type: "org.effektio.dev.task".to_string(),
                        msg: error.to_string(),
                    }
                })?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Ok(AnyEffektioModel::Task(t.into())),
                _ => Err(Error::UnknownModel(None)),
            },
            "org.effektio.dev.task.update" => match raw
                .deserialize_as::<SyncTaskUpdateEvent>()
                .map_err(|error| {
                    tracing::error!(?error, ?raw, "parsing task update event failed");
                    Error::FailedToParse {
                        model_type: "org.effektio.dev.task.update".to_string(),
                        msg: error.to_string(),
                    }
                })?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Ok(AnyEffektioModel::TaskUpdate(t.into())),
                _ => Err(Error::UnknownModel(None)),
            },

            // -- Pins
            "org.effektio.dev.pin" => match raw
                .deserialize_as::<SyncPinEvent>()
                .map_err(|error| {
                    tracing::error!(?error, ?raw, "parsing pin event failed");
                    Error::FailedToParse {
                        model_type: "org.effektio.dev.pin".to_string(),
                        msg: error.to_string(),
                    }
                })?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Ok(AnyEffektioModel::Pin(t.into())),
                _ => Err(Error::UnknownModel(None)),
            },

            // generic

            // comments
            "org.effektio.dev.comment" => match raw
                .deserialize_as::<SyncCommentEvent>()
                .map_err(|error| {
                    tracing::error!(?error, ?raw, "parsing task update event failed");
                    Error::FailedToParse {
                        model_type: "org.effektio.dev.comment".to_string(),
                        msg: error.to_string(),
                    }
                })?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Ok(AnyEffektioModel::Comment(t.into())),
                _ => Err(Error::UnknownModel(None)),
            },
            "org.effektio.dev.comment.update" => match raw
                .deserialize_as::<SyncCommentUpdateEvent>()
                .map_err(|error| {
                    tracing::error!(?error, ?raw, "parsing task update event failed");
                    Error::FailedToParse {
                        model_type: "org.effektio.dev.comment.update".to_string(),
                        msg: error.to_string(),
                    }
                })?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Ok(AnyEffektioModel::CommentUpdate(t.into())),
                _ => Err(Error::UnknownModel(None)),
            },

            // unimplemented cases
            _ => {
                if m_type.starts_with("org.effektio.") {
                    tracing::error!(?raw, "{m_type} not implemented");
                }

                Err(Error::UnknownModel(Some(m_type.to_owned())))
            }
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
mod tests {
    use super::*;
    use crate::Result;
    use serde_json;
    #[test]
    fn ensure_minimal_tasklist_parses() -> Result<()> {
        let json_raw = r#"{"type":"org.effektio.dev.tasklist",
            "room_id":"!euhIDqDVvVXulrhWgN:ds9.effektio.org","sender":"@odo:ds9.effektio.org",
            "content":{"name":"Daily Security Brief"},"origin_server_ts":1672407531453,
            "unsigned":{"age":11523850},
            "event_id":"$KwumA4L3M-duXu0I3UA886LvN-BDCKAyxR1skNfnh3c",
            "user_id":"@odo:ds9.effektio.org","age":11523850}"#;
        let event = serde_json::from_str::<Raw<AnyTimelineEvent>>(json_raw)?;
        let _effektio_ev = AnyEffektioModel::from_raw_tlevent(&event)?;
        // assert!(matches!(event, AnyCreation::TaskList(_)));
        Ok(())
    }
    #[test]
    fn ensure_minimal_pin_parses() -> Result<()> {
        let json_raw = r#"{"type":"org.effektio.dev.pin",
            "room_id":"!euhIDqDVvVXulrhWgN:ds9.effektio.org","sender":"@odo:ds9.effektio.org",
            "content":{"title":"Seat arrangement"},"origin_server_ts":1672407531453,
            "unsigned":{"age":11523850},
            "event_id":"$KwumA4L3M-duXu0I3UA886LvN-BDCKAyxR1skNfnh3c",
            "user_id":"@odo:ds9.effektio.org","age":11523850}"#;
        let event = serde_json::from_str::<Raw<AnyTimelineEvent>>(json_raw)?;
        let _effektio_ev = AnyEffektioModel::from_raw_tlevent(&event)?;
        // assert!(matches!(event, AnyCreation::TaskList(_)));
        Ok(())
    }
}
