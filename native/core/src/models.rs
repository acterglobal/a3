mod attachments;
mod calendar;
mod color;
mod comments;
mod common;
mod news;
mod pins;
mod rsvp;
mod tag;
mod tasks;
#[cfg(test)]
mod test;

use async_recursion::async_recursion;
pub use attachments::{Attachment, AttachmentUpdate, AttachmentsManager, AttachmentsStats};
pub use calendar::{CalendarEvent, CalendarEventUpdate};
pub use color::Color;
pub use comments::{Comment, CommentUpdate, CommentsManager, CommentsStats};
pub use common::*;
pub use core::fmt::Debug;
use enum_dispatch::enum_dispatch;
use matrix_sdk::ruma::{
    events::{AnySyncTimelineEvent, AnyTimelineEvent, MessageLikeEvent},
    serde::Raw,
    EventId, MilliSecondsSinceUnixEpoch, OwnedEventId, OwnedRoomId, OwnedUserId, RoomId,
};
pub use news::{NewsEntry, NewsEntryUpdate};
pub use pins::{Pin, PinUpdate};
pub use rsvp::{RsvpEntry, RsvpManager, RsvpStats};
use serde::{Deserialize, Serialize};
pub use tag::Tag;
pub use tasks::{Task, TaskList, TaskListUpdate, TaskStats, TaskUpdate};
use tracing::{error, trace};

#[cfg(test)]
pub use test::{TestModel, TestModelBuilder, TestModelBuilderError};

pub use crate::store::Store;
use crate::{
    error::Error,
    events::{
        attachments::{
            OriginalAttachmentEvent, OriginalAttachmentUpdateEvent, SyncAttachmentEvent,
            SyncAttachmentUpdateEvent,
        },
        calendar::{
            OriginalCalendarEventEvent, OriginalCalendarEventUpdateEvent, SyncCalendarEventEvent,
            SyncCalendarEventUpdateEvent,
        },
        comments::{
            OriginalCommentEvent, OriginalCommentUpdateEvent, SyncCommentEvent,
            SyncCommentUpdateEvent,
        },
        news::{
            OriginalNewsEntryEvent, OriginalNewsEntryUpdateEvent, SyncNewsEntryEvent,
            SyncNewsEntryUpdateEvent,
        },
        pins::{OriginalPinEvent, OriginalPinUpdateEvent, SyncPinEvent, SyncPinUpdateEvent},
        rsvp::{OriginalRsvpEntryEvent, SyncRsvpEntryEvent},
        tasks::{
            OriginalTaskEvent, OriginalTaskListEvent, OriginalTaskListUpdateEvent,
            OriginalTaskUpdateEvent, SyncTaskEvent, SyncTaskListEvent, SyncTaskListUpdateEvent,
            SyncTaskUpdateEvent,
        },
    },
};

#[derive(Debug, Eq, PartialEq)]
pub enum Capability {
    // someone can comment on this
    Commentable,
    // someone can add attchments on this
    HasAttachments,
    // another custom capability
    Custom(&'static str),
}

#[async_recursion]
pub async fn transition_tree(
    store: &Store,
    parents: Vec<String>,
    model: &AnyActerModel,
) -> crate::Result<Vec<AnyActerModel>> {
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
    model: AnyActerModel,
) -> crate::Result<Vec<String>> {
    trace!(event_id=?model.event_id(), ?model, "handling");
    let Some(belongs_to) = model.belongs_to() else {
        let event_id = model.event_id().to_string();
        trace!(?event_id, "saving simple model");
        return store.save(model).await
    };

    trace!(event_id=?model.event_id(), ?belongs_to, "transitioning tree");
    let mut models = transition_tree(store, belongs_to, &model).await?;
    models.push(model);
    store.save_many(models).await
}

#[enum_dispatch(AnyActerModel)]
pub trait ActerModel: Debug {
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
    fn transition(&mut self, model: &AnyActerModel) -> crate::Result<bool> {
        error!(?self, ?model, "Transition has not been implemented");
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
pub enum AnyActerModel {
    // -- Calendar
    CalendarEvent,
    CalendarEventUpdate,

    // -- Tasks
    TaskList,
    TaskListUpdate,
    Task,
    TaskUpdate,

    // -- Pins
    Pin,
    PinUpdate,

    // -- News
    NewsEntry,
    NewsEntryUpdate,

    // -- more generics
    Comment,
    CommentUpdate,

    Attachment,
    AttachmentUpdate,

    RsvpEntry,

    #[cfg(test)]
    TestModel,
}

impl AnyActerModel {
    pub fn from_raw_tlevent(raw: &Raw<AnyTimelineEvent>) -> Result<Self, Error> {
        let Ok(Some(model_type)) = raw.get_field("type") else {
            return Err(Error::UnknownModel(None));
        };

        match model_type {
            // -- CALENDAR
            "global.acter.dev.calendar_event" => Ok(AnyActerModel::CalendarEvent(
                raw.deserialize_as::<OriginalCalendarEventEvent>()
                    .map_err(|error| {
                        error!(?error, ?raw, "parsing calendar_event event failed");
                        Error::FailedToParse {
                            model_type: "global.acter.dev.calendar_event".to_string(),
                            msg: error.to_string(),
                        }
                    })?
                    .into(),
            )),
            "global.acter.dev.calendar_event.update" => Ok(AnyActerModel::CalendarEventUpdate(
                raw.deserialize_as::<OriginalCalendarEventUpdateEvent>()
                    .map_err(|error| {
                        error!(?error, ?raw, "parsing calendar_event update event failed");
                        Error::FailedToParse {
                            model_type: "global.acter.dev.calendar_event.update".to_string(),
                            msg: error.to_string(),
                        }
                    })?
                    .into(),
            )),

            // -- TASKS
            "global.acter.dev.tasklist" => Ok(AnyActerModel::TaskList(
                raw.deserialize_as::<OriginalTaskListEvent>()
                    .map_err(|error| {
                        error!(?error, ?raw, "parsing task list event failed");
                        Error::FailedToParse {
                            model_type: "global.acter.dev.tasklist".to_string(),
                            msg: error.to_string(),
                        }
                    })?
                    .into(),
            )),
            "global.acter.dev.tasklist.update" => Ok(AnyActerModel::TaskListUpdate(
                raw.deserialize_as::<OriginalTaskListUpdateEvent>()
                    .map_err(|error| {
                        error!(?error, ?raw, "parsing task list update event failed");
                        Error::FailedToParse {
                            model_type: "global.acter.dev.tasklist.update".to_string(),
                            msg: error.to_string(),
                        }
                    })?
                    .into(),
            )),
            "global.acter.dev.task" => Ok(AnyActerModel::Task(
                raw.deserialize_as::<OriginalTaskEvent>()
                    .map_err(|error| {
                        error!(?error, ?raw, "parsing task event failed");
                        Error::FailedToParse {
                            model_type: "global.acter.dev.task".to_string(),
                            msg: error.to_string(),
                        }
                    })?
                    .into(),
            )),
            "global.acter.dev.task.update" => Ok(AnyActerModel::TaskUpdate(
                raw.deserialize_as::<OriginalTaskUpdateEvent>()
                    .map_err(|error| {
                        error!(?error, ?raw, "parsing task update event failed");
                        Error::FailedToParse {
                            model_type: "global.acter.dev.task.update".to_string(),
                            msg: error.to_string(),
                        }
                    })?
                    .into(),
            )),

            // -- Pins
            "global.acter.dev.pin" => Ok(AnyActerModel::Pin(
                raw.deserialize_as::<OriginalPinEvent>()
                    .map_err(|error| {
                        error!(?error, ?raw, "parsing pin event failed");
                        Error::FailedToParse {
                            model_type: "global.acter.dev.pin".to_string(),
                            msg: error.to_string(),
                        }
                    })?
                    .into(),
            )),
            "global.acter.dev.pin.update" => Ok(AnyActerModel::PinUpdate(
                raw.deserialize_as::<OriginalPinUpdateEvent>()
                    .map_err(|error| {
                        error!(?error, ?raw, "parsing pin update event failed");
                        Error::FailedToParse {
                            model_type: "global.acter.dev.pin.update".to_string(),
                            msg: error.to_string(),
                        }
                    })?
                    .into(),
            )),

            // -- News
            "global.acter.dev.news" => Ok(AnyActerModel::NewsEntry(
                raw.deserialize_as::<OriginalNewsEntryEvent>()
                    .map_err(|error| {
                        error!(?error, ?raw, "parsing news event failed");
                        Error::FailedToParse {
                            model_type: "global.acter.dev.news".to_string(),
                            msg: error.to_string(),
                        }
                    })?
                    .into(),
            )),
            "global.acter.dev.news.update" => Ok(AnyActerModel::NewsEntryUpdate(
                raw.deserialize_as::<OriginalNewsEntryUpdateEvent>()
                    .map_err(|error| {
                        error!(?error, ?raw, "parsing news update event failed");
                        Error::FailedToParse {
                            model_type: "global.acter.dev.news.update".to_string(),
                            msg: error.to_string(),
                        }
                    })?
                    .into(),
            )),

            // -- generics

            // comments
            "global.acter.dev.comment" => Ok(AnyActerModel::Comment(
                raw.deserialize_as::<OriginalCommentEvent>()
                    .map_err(|error| {
                        error!(?error, ?raw, "parsing comment event failed");
                        Error::FailedToParse {
                            model_type: "global.acter.dev.comment".to_string(),
                            msg: error.to_string(),
                        }
                    })?
                    .into(),
            )),
            "global.acter.dev.comment.update" => Ok(AnyActerModel::CommentUpdate(
                raw.deserialize_as::<OriginalCommentUpdateEvent>()
                    .map_err(|error| {
                        error!(?error, ?raw, "parsing comment update event failed");
                        Error::FailedToParse {
                            model_type: "global.acter.dev.comment.update".to_string(),
                            msg: error.to_string(),
                        }
                    })?
                    .into(),
            )),

            // attachments
            "global.acter.dev.attachment" => Ok(AnyActerModel::Attachment(
                raw.deserialize_as::<OriginalAttachmentEvent>()
                    .map_err(|error| {
                        error!(?error, ?raw, "parsing attachment event failed");
                        Error::FailedToParse {
                            model_type: "global.acter.dev.attachment".to_string(),
                            msg: error.to_string(),
                        }
                    })?
                    .into(),
            )),
            "global.acter.dev.attachment.update" => Ok(AnyActerModel::AttachmentUpdate(
                raw.deserialize_as::<OriginalAttachmentUpdateEvent>()
                    .map_err(|error| {
                        error!(?error, ?raw, "parsing attachment update event failed");
                        Error::FailedToParse {
                            model_type: "global.acter.dev.attachment.update".to_string(),
                            msg: error.to_string(),
                        }
                    })?
                    .into(),
            )),

            // rsvp
            "global.acter.dev.rsvp" => Ok(AnyActerModel::RsvpEntry(
                raw.deserialize_as::<OriginalRsvpEntryEvent>()
                    .map_err(|error| {
                        error!(?error, ?raw, "parsing rsvp event failed");
                        Error::FailedToParse {
                            model_type: "global.acter.dev.rsvp".to_string(),
                            msg: error.to_string(),
                        }
                    })?
                    .into(),
            )),

            _ => {
                if model_type.starts_with("global.acter.") {
                    error!(?raw, "{model_type} not implemented");
                }

                Err(Error::UnknownModel(Some(model_type.to_owned())))
            }
        }
    }

    pub fn from_raw_synctlevent(
        raw: &Raw<AnySyncTimelineEvent>,
        room_id: &RoomId,
    ) -> Result<Self, Error> {
        let Ok(Some(model_type)) = raw.get_field("type") else {
            return Err(Error::UnknownModel(None));
        };

        match model_type {
            // -- Calendar
            "global.acter.dev.calendar_event" => match raw
                .deserialize_as::<SyncCalendarEventEvent>()
                .map_err(|error| {
                    error!(?error, ?raw, "parsing calendar_event event failed");
                    Error::FailedToParse {
                        model_type: "global.acter.dev.calendar_event".to_string(),
                        msg: error.to_string(),
                    }
                })?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Ok(AnyActerModel::CalendarEvent(t.into())),
                _ => Err(Error::UnknownModel(None)),
            },
            "global.acter.dev.calendar_event.update" => match raw
                .deserialize_as::<SyncCalendarEventUpdateEvent>()
                .map_err(|error| {
                    error!(?error, ?raw, "parsing calendar_event update event failed");
                    Error::FailedToParse {
                        model_type: "global.acter.dev.calendar_event.update".to_string(),
                        msg: error.to_string(),
                    }
                })?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Ok(AnyActerModel::CalendarEventUpdate(t.into())),
                _ => Err(Error::UnknownModel(None)),
            },

            // -- Tasks
            "global.acter.dev.tasklist" => match raw
                .deserialize_as::<SyncTaskListEvent>()
                .map_err(|error| {
                    error!(?error, ?raw, "parsing task list event failed");
                    Error::FailedToParse {
                        model_type: "global.acter.dev.tasklist".to_string(),
                        msg: error.to_string(),
                    }
                })?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Ok(AnyActerModel::TaskList(t.into())),
                _ => Err(Error::UnknownModel(None)),
            },
            "global.acter.dev.tasklist.update" => match raw
                .deserialize_as::<SyncTaskListUpdateEvent>()
                .map_err(|error| {
                    error!(?error, ?raw, "parsing task list update event failed");
                    Error::FailedToParse {
                        model_type: "global.acter.dev.tasklist.update".to_string(),
                        msg: error.to_string(),
                    }
                })?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Ok(AnyActerModel::TaskListUpdate(t.into())),
                _ => Err(Error::UnknownModel(None)),
            },
            "global.acter.dev.task" => match raw
                .deserialize_as::<SyncTaskEvent>()
                .map_err(|error| {
                    error!(?error, ?raw, "parsing task event failed");
                    Error::FailedToParse {
                        model_type: "global.acter.dev.task".to_string(),
                        msg: error.to_string(),
                    }
                })?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Ok(AnyActerModel::Task(t.into())),
                _ => Err(Error::UnknownModel(None)),
            },
            "global.acter.dev.task.update" => match raw
                .deserialize_as::<SyncTaskUpdateEvent>()
                .map_err(|error| {
                    error!(?error, ?raw, "parsing task update event failed");
                    Error::FailedToParse {
                        model_type: "global.acter.dev.task.update".to_string(),
                        msg: error.to_string(),
                    }
                })?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Ok(AnyActerModel::TaskUpdate(t.into())),
                _ => Err(Error::UnknownModel(None)),
            },

            // -- Pins
            "global.acter.dev.pin" => match raw
                .deserialize_as::<SyncPinEvent>()
                .map_err(|error| {
                    error!(?error, ?raw, "parsing pin event failed");
                    Error::FailedToParse {
                        model_type: "global.acter.dev.pin".to_string(),
                        msg: error.to_string(),
                    }
                })?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Ok(AnyActerModel::Pin(t.into())),
                _ => Err(Error::UnknownModel(None)),
            },
            "global.acter.dev.pin.update" => match raw
                .deserialize_as::<SyncPinUpdateEvent>()
                .map_err(|error| {
                    error!(?error, ?raw, "parsing pin update event failed");
                    Error::FailedToParse {
                        model_type: "global.acter.dev.pin.update".to_string(),
                        msg: error.to_string(),
                    }
                })?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Ok(AnyActerModel::PinUpdate(t.into())),
                _ => Err(Error::UnknownModel(None)),
            },

            // -- NewsEntrys
            "global.acter.dev.news" => match raw
                .deserialize_as::<SyncNewsEntryEvent>()
                .map_err(|error| {
                    error!(?error, ?raw, "parsing news event failed");
                    Error::FailedToParse {
                        model_type: "global.acter.dev.news".to_string(),
                        msg: error.to_string(),
                    }
                })?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Ok(AnyActerModel::NewsEntry(t.into())),
                _ => Err(Error::UnknownModel(None)),
            },
            "global.acter.dev.news.update" => match raw
                .deserialize_as::<SyncNewsEntryUpdateEvent>()
                .map_err(|error| {
                    error!(?error, ?raw, "parsing news update event failed");
                    Error::FailedToParse {
                        model_type: "global.acter.dev.news.update".to_string(),
                        msg: error.to_string(),
                    }
                })?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Ok(AnyActerModel::NewsEntryUpdate(t.into())),
                _ => Err(Error::UnknownModel(None)),
            },

            // generic

            // comments
            "global.acter.dev.comment" => match raw
                .deserialize_as::<SyncCommentEvent>()
                .map_err(|error| {
                    error!(?error, ?raw, "parsing comment event failed");
                    Error::FailedToParse {
                        model_type: "global.acter.dev.comment".to_string(),
                        msg: error.to_string(),
                    }
                })?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Ok(AnyActerModel::Comment(t.into())),
                _ => Err(Error::UnknownModel(None)),
            },
            "global.acter.dev.comment.update" => match raw
                .deserialize_as::<SyncCommentUpdateEvent>()
                .map_err(|error| {
                    error!(?error, ?raw, "parsing comment update event failed");
                    Error::FailedToParse {
                        model_type: "global.acter.dev.comment.update".to_string(),
                        msg: error.to_string(),
                    }
                })?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Ok(AnyActerModel::CommentUpdate(t.into())),
                _ => Err(Error::UnknownModel(None)),
            },

            // attachments
            "global.acter.dev.attachment" => match raw
                .deserialize_as::<SyncAttachmentEvent>()
                .map_err(|error| {
                    error!(?error, ?raw, "parsing attachment event failed");
                    Error::FailedToParse {
                        model_type: "global.acter.dev.attachment".to_string(),
                        msg: error.to_string(),
                    }
                })?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Ok(AnyActerModel::Attachment(t.into())),
                _ => Err(Error::UnknownModel(None)),
            },
            "global.acter.dev.attachment.update" => match raw
                .deserialize_as::<SyncAttachmentUpdateEvent>()
                .map_err(|error| {
                    error!(?error, ?raw, "parsing attachment update event failed");
                    Error::FailedToParse {
                        model_type: "global.acter.dev.attachment.update".to_string(),
                        msg: error.to_string(),
                    }
                })?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Ok(AnyActerModel::AttachmentUpdate(t.into())),
                _ => Err(Error::UnknownModel(None)),
            },

            // RSVP events
            "global.acter.dev.rsvp" => match raw
                .deserialize_as::<SyncRsvpEntryEvent>()
                .map_err(|error| {
                    error!(?error, ?raw, "parsing RSVP event failed");
                    Error::FailedToParse {
                        model_type: "global.acter.dev.rsvp".to_string(),
                        msg: error.to_string(),
                    }
                })?
                .into_full_event(room_id.to_owned())
            {
                MessageLikeEvent::Original(t) => Ok(AnyActerModel::RsvpEntry(t.into())),
                _ => Err(Error::UnknownModel(None)),
            },

            // unimplemented cases
            _ => {
                if model_type.starts_with("global.acter.") {
                    error!(?raw, "{model_type} not implemented");
                }

                Err(Error::UnknownModel(Some(model_type.to_owned())))
            }
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::Result;
    use serde_json;
    #[test]
    fn ensure_minimal_tasklist_parses() -> Result<()> {
        let json_raw = r#"{"type":"global.acter.dev.tasklist",
            "room_id":"!euhIDqDVvVXulrhWgN:ds9.acter.global","sender":"@odo:ds9.acter.global",
            "content":{"name":"Daily Security Brief"},"origin_server_ts":1672407531453,
            "unsigned":{"age":11523850},
            "event_id":"$KwumA4L3M-duXu0I3UA886LvN-BDCKAyxR1skNfnh3c",
            "user_id":"@odo:ds9.acter.global","age":11523850}"#;
        let event = serde_json::from_str::<Raw<AnyTimelineEvent>>(json_raw)?;
        let _acter_ev = AnyActerModel::from_raw_tlevent(&event)?;
        // assert!(matches!(event, AnyCreation::TaskList(_)));
        Ok(())
    }
    #[test]
    fn ensure_minimal_pin_parses() -> Result<()> {
        let json_raw = r#"{"type":"global.acter.dev.pin",
            "room_id":"!euhIDqDVvVXulrhWgN:ds9.acter.global","sender":"@odo:ds9.acter.global",
            "content":{"title":"Seat arrangement"},"origin_server_ts":1672407531453,
            "unsigned":{"age":11523850},
            "event_id":"$KwumA4L3M-duXu0I3UA886LvN-BDCKAyxR1skNfnh3c",
            "user_id":"@odo:ds9.acter.global","age":11523850}"#;
        let event = serde_json::from_str::<Raw<AnyTimelineEvent>>(json_raw)?;
        let _acter_ev = AnyActerModel::from_raw_tlevent(&event)?;
        // assert!(matches!(event, AnyCreation::TaskList(_)));
        Ok(())
    }
}
