mod attachments;
mod calendar;
mod comments;
mod common;
mod news;
mod pins;
mod reactions;
mod rsvp;
mod tag;
mod tasks;
#[cfg(test)]
mod test;

use async_recursion::async_recursion;
pub use attachments::{Attachment, AttachmentUpdate, AttachmentsManager, AttachmentsStats};
pub use calendar::{CalendarEvent, CalendarEventUpdate};
pub use comments::{Comment, CommentUpdate, CommentsManager, CommentsStats};
pub use common::*;
pub use core::fmt::Debug;
use enum_dispatch::enum_dispatch;
pub use news::{NewsEntry, NewsEntryUpdate};
pub use pins::{Pin, PinUpdate};
pub use reactions::{Reaction, ReactionManager, ReactionStats};
pub use rsvp::{Rsvp, RsvpManager, RsvpStats};
use ruma::RoomId;
use ruma_common::{
    serde::Raw, EventId, MilliSecondsSinceUnixEpoch, OwnedEventId, OwnedRoomId, OwnedUserId, UserId,
};
use ruma_events::{
    reaction::ReactionEventContent,
    room::redaction::{OriginalRoomRedactionEvent, RoomRedactionEventContent},
    AnySyncTimelineEvent, AnyTimelineEvent, MessageLikeEvent, StaticEventContent,
    UnsignedRoomRedactionEvent,
};
use serde::{Deserialize, Serialize};
pub use tag::Tag;
pub use tasks::{
    Task, TaskList, TaskListUpdate, TaskSelfAssign, TaskSelfUnassign, TaskStats, TaskUpdate,
};
use tracing::{error, trace};

#[cfg(test)]
pub use test::{TestModel, TestModelBuilder, TestModelBuilderError};

pub use crate::store::Store;
use crate::{
    error::Error,
    events::{
        attachments::{AttachmentEventContent, AttachmentUpdateEventContent},
        calendar::{CalendarEventEventContent, CalendarEventUpdateEventContent},
        comments::{CommentEventContent, CommentUpdateEventContent},
        news::{NewsEntryEventContent, NewsEntryUpdateEventContent},
        pins::{PinEventContent, PinUpdateEventContent},
        rsvp::RsvpEventContent,
        tasks::{
            TaskEventContent, TaskListEventContent, TaskListUpdateEventContent,
            TaskSelfAssignEventContent, TaskSelfUnassignEventContent, TaskUpdateEventContent,
        },
        AnyActerEvent,
    },
};

#[derive(Debug, Eq, PartialEq)]
pub enum Capability {
    // someone can add reaction on this
    Reactable,
    // someone can add comment on this
    Commentable,
    // someone can add attachment on this
    Attachmentable,
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
        return store.save(model).await;
    };

    trace!(event_id=?model.event_id(), ?belongs_to, "transitioning tree");
    let mut models = transition_tree(store, belongs_to, &model).await?;
    models.push(model);
    store.save_many(models).await
}

#[enum_dispatch(AnyActerModel)]
pub trait ActerModel: Debug {
    fn indizes(&self, user_id: &UserId) -> Vec<String>;
    /// The key to store this model under
    fn event_id(&self) -> &EventId;

    /// The room id this model belongs to
    fn room_id(&self) -> &RoomId;

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
    /// The execution to run when this model is found.
    async fn redact(
        &self,
        store: &Store,
        redaction_model: RedactedActerModel,
    ) -> crate::Result<Vec<String>> {
        trace!(event_id=?redaction_model.event_id(), ?redaction_model, "handling");
        let Some(belongs_to) = self.belongs_to() else {
            let event_id = redaction_model.event_id();
            trace!(?event_id, "saving simple model");
            return store.save(redaction_model.into()).await;
        };
        let model: AnyActerModel = redaction_model.into();
        trace!(event_id=?model.event_id(), ?belongs_to, "transitioning tree");
        let mut models = transition_tree(store, belongs_to, &model).await?;
        models.push(model);
        store.save_many(models).await
    }
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct RedactionContent {
    /// Data specific to the event type.
    pub content: RoomRedactionEventContent,

    /// The globally unique event identifier for the event.
    pub event_id: OwnedEventId,

    /// The fully-qualified ID of the user who sent this event.
    pub sender: OwnedUserId,

    /// Timestamp in milliseconds on originating homeserver when this event was sent.
    pub origin_server_ts: MilliSecondsSinceUnixEpoch,
}

impl From<UnsignedRoomRedactionEvent> for RedactionContent {
    fn from(value: UnsignedRoomRedactionEvent) -> Self {
        let UnsignedRoomRedactionEvent {
            content,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = value;
        RedactionContent {
            content,
            event_id,
            sender,
            origin_server_ts,
        }
    }
}

impl From<OriginalRoomRedactionEvent> for RedactionContent {
    fn from(value: OriginalRoomRedactionEvent) -> Self {
        let OriginalRoomRedactionEvent {
            content,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = value;
        RedactionContent {
            content,
            event_id,
            sender,
            origin_server_ts,
        }
    }
}

#[derive(Serialize, Deserialize, Clone, Debug)]
pub struct RedactedActerModel {
    orig_type: String,
    indizes: Vec<String>,
    meta: EventMeta,
    content: RedactionContent,
}

impl RedactedActerModel {
    pub fn new(
        orig_type: String,
        orig_indizes: Vec<String>,
        meta: EventMeta,
        content: RedactionContent,
    ) -> Self {
        RedactedActerModel {
            meta,
            orig_type,
            content,
            indizes: orig_indizes
                .into_iter()
                .map(|s| format!("{s}::redacted"))
                .collect(),
        }
    }
}

impl ActerModel for RedactedActerModel {
    fn room_id(&self) -> &RoomId {
        &self.meta.room_id
    }
    fn indizes(&self, _user_id: &UserId) -> Vec<String> {
        self.indizes.clone()
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }

    async fn execute(self, store: &Store) -> crate::Result<Vec<String>> {
        default_model_execute(store, self.into()).await
    }
}

#[derive(Serialize, Deserialize, Debug, Clone)]
pub struct EventMeta {
    /// The globally unique event identifier attached to this event
    pub event_id: OwnedEventId,

    /// The fully-qualified ID of the user who sent created this event
    pub sender: OwnedUserId,

    /// Timestamp in milliseconds on originating homeserver when the event was created
    pub origin_server_ts: MilliSecondsSinceUnixEpoch,

    /// The ID of the room of this event
    pub room_id: OwnedRoomId,

    /// Optional redacted event identifier
    #[serde(default)]
    redacted: Option<OwnedEventId>,
}

impl EventMeta {
    pub fn for_redacted_source(value: &OriginalRoomRedactionEvent) -> Option<Self> {
        let target_event_id = value.redacts.clone()?;

        Some(EventMeta {
            event_id: target_event_id,
            sender: value.sender.clone(),
            room_id: value.room_id.clone(),
            origin_server_ts: value.origin_server_ts,
            redacted: None,
        })
    }
}

#[enum_dispatch]
#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum AnyActerModel {
    RedactedActerModel,

    // -- Calendar
    CalendarEvent(CalendarEvent),
    CalendarEventUpdate(CalendarEventUpdate),

    // -- Tasks
    TaskList(TaskList),
    TaskListUpdate(TaskListUpdate),
    Task(Task),
    TaskUpdate(TaskUpdate),
    TaskSelfAssign(TaskSelfAssign),
    TaskSelfUnassign(TaskSelfUnassign),

    // -- Pins
    Pin(Pin),
    PinUpdate(PinUpdate),

    // -- News
    NewsEntry(NewsEntry),
    NewsEntryUpdate(NewsEntryUpdate),

    // -- more generics
    Comment(Comment),
    CommentUpdate(CommentUpdate),

    Attachment(Attachment),
    AttachmentUpdate(AttachmentUpdate),

    Rsvp(Rsvp),
    Reaction(Reaction),

    #[cfg(test)]
    TestModel(TestModel),
}

impl AnyActerModel {
    pub fn model_type(&self) -> &str {
        match self {
            AnyActerModel::CalendarEvent(_) => CalendarEventEventContent::TYPE,
            AnyActerModel::CalendarEventUpdate(_) => CalendarEventUpdateEventContent::TYPE,
            AnyActerModel::TaskList(_) => TaskListEventContent::TYPE,
            AnyActerModel::TaskListUpdate(_) => TaskListUpdateEventContent::TYPE,
            AnyActerModel::Task(_) => TaskEventContent::TYPE,
            AnyActerModel::TaskUpdate(_) => TaskUpdateEventContent::TYPE,
            AnyActerModel::TaskSelfAssign(_) => TaskSelfAssignEventContent::TYPE,
            AnyActerModel::TaskSelfUnassign(_) => TaskSelfUnassignEventContent::TYPE,
            AnyActerModel::Pin(_) => PinEventContent::TYPE,
            AnyActerModel::PinUpdate(_) => PinUpdateEventContent::TYPE,
            AnyActerModel::NewsEntry(_) => NewsEntryEventContent::TYPE,
            AnyActerModel::NewsEntryUpdate(_) => NewsEntryUpdateEventContent::TYPE,
            AnyActerModel::Comment(_) => CommentEventContent::TYPE,
            AnyActerModel::CommentUpdate(_) => CommentUpdateEventContent::TYPE,
            AnyActerModel::Attachment(_) => AttachmentEventContent::TYPE,
            AnyActerModel::AttachmentUpdate(_) => AttachmentUpdateEventContent::TYPE,
            AnyActerModel::Rsvp(_) => RsvpEventContent::TYPE,
            AnyActerModel::Reaction(_) => ReactionEventContent::TYPE,
            AnyActerModel::RedactedActerModel(..) => "unknown_redacted_model",
            #[cfg(test)]
            AnyActerModel::TestModel(_) => "test_model",
        }
    }
}

impl TryFrom<AnyActerEvent> for AnyActerModel {
    type Error = Error;
    fn try_from(value: AnyActerEvent) -> Result<Self, Self::Error> {
        match value {
            // Originals
            AnyActerEvent::CalendarEvent(e) => match e {
                MessageLikeEvent::Original(m) => Ok(AnyActerModel::CalendarEvent(m.into())),
                MessageLikeEvent::Redacted(r) => Err(Error::ModelRedacted {
                    model_type: CalendarEventEventContent::TYPE.to_owned(),
                    meta: EventMeta {
                        room_id: r.room_id,
                        event_id: r.event_id,
                        sender: r.sender,
                        origin_server_ts: r.origin_server_ts,
                        redacted: None,
                    },
                    reason: r.unsigned.redacted_because,
                }),
            },
            AnyActerEvent::CalendarEventUpdate(e) => match e {
                MessageLikeEvent::Original(m) => Ok(AnyActerModel::CalendarEventUpdate(m.into())),
                MessageLikeEvent::Redacted(r) => Err(Error::ModelRedacted {
                    model_type: CalendarEventUpdateEventContent::TYPE.to_owned(),
                    meta: EventMeta {
                        room_id: r.room_id,
                        event_id: r.event_id,
                        sender: r.sender,
                        origin_server_ts: r.origin_server_ts,
                        redacted: None,
                    },
                    reason: r.unsigned.redacted_because,
                }),
            },
            AnyActerEvent::Pin(e) => match e {
                MessageLikeEvent::Original(m) => Ok(AnyActerModel::Pin(m.into())),
                MessageLikeEvent::Redacted(r) => Err(Error::ModelRedacted {
                    model_type: PinEventContent::TYPE.to_owned(),
                    meta: EventMeta {
                        room_id: r.room_id,
                        event_id: r.event_id,
                        sender: r.sender,
                        origin_server_ts: r.origin_server_ts,
                        redacted: None,
                    },
                    reason: r.unsigned.redacted_because,
                }),
            },
            AnyActerEvent::PinUpdate(e) => match e {
                MessageLikeEvent::Original(m) => Ok(AnyActerModel::PinUpdate(m.into())),
                MessageLikeEvent::Redacted(r) => Err(Error::ModelRedacted {
                    model_type: PinUpdateEventContent::TYPE.to_owned(),
                    meta: EventMeta {
                        room_id: r.room_id,
                        event_id: r.event_id,
                        sender: r.sender,
                        origin_server_ts: r.origin_server_ts,
                        redacted: None,
                    },
                    reason: r.unsigned.redacted_because,
                }),
            },
            AnyActerEvent::NewsEntry(e) => match e {
                MessageLikeEvent::Original(m) => Ok(AnyActerModel::NewsEntry(m.into())),
                MessageLikeEvent::Redacted(r) => Err(Error::ModelRedacted {
                    model_type: NewsEntryEventContent::TYPE.to_owned(),
                    meta: EventMeta {
                        room_id: r.room_id,
                        event_id: r.event_id,
                        sender: r.sender,
                        origin_server_ts: r.origin_server_ts,
                        redacted: None,
                    },
                    reason: r.unsigned.redacted_because,
                }),
            },
            AnyActerEvent::NewsEntryUpdate(e) => match e {
                MessageLikeEvent::Original(m) => Ok(AnyActerModel::NewsEntryUpdate(m.into())),
                MessageLikeEvent::Redacted(r) => Err(Error::ModelRedacted {
                    model_type: NewsEntryUpdateEventContent::TYPE.to_owned(),
                    meta: EventMeta {
                        room_id: r.room_id,
                        event_id: r.event_id,
                        sender: r.sender,
                        origin_server_ts: r.origin_server_ts,
                        redacted: None,
                    },
                    reason: r.unsigned.redacted_because,
                }),
            },
            AnyActerEvent::TaskList(e) => match e {
                MessageLikeEvent::Original(m) => Ok(AnyActerModel::TaskList(m.into())),
                MessageLikeEvent::Redacted(r) => Err(Error::ModelRedacted {
                    model_type: TaskListEventContent::TYPE.to_owned(),
                    meta: EventMeta {
                        room_id: r.room_id,
                        event_id: r.event_id,
                        sender: r.sender,
                        origin_server_ts: r.origin_server_ts,
                        redacted: None,
                    },
                    reason: r.unsigned.redacted_because,
                }),
            },
            AnyActerEvent::TaskListUpdate(e) => match e {
                MessageLikeEvent::Original(m) => Ok(AnyActerModel::TaskListUpdate(m.into())),
                MessageLikeEvent::Redacted(r) => Err(Error::ModelRedacted {
                    model_type: TaskListUpdateEventContent::TYPE.to_owned(),
                    meta: EventMeta {
                        room_id: r.room_id,
                        event_id: r.event_id,
                        sender: r.sender,
                        origin_server_ts: r.origin_server_ts,
                        redacted: None,
                    },
                    reason: r.unsigned.redacted_because,
                }),
            },
            AnyActerEvent::Task(e) => match e {
                MessageLikeEvent::Original(m) => Ok(AnyActerModel::Task(m.into())),
                MessageLikeEvent::Redacted(r) => Err(Error::ModelRedacted {
                    model_type: TaskEventContent::TYPE.to_owned(),
                    meta: EventMeta {
                        room_id: r.room_id,
                        event_id: r.event_id,
                        sender: r.sender,
                        origin_server_ts: r.origin_server_ts,
                        redacted: None,
                    },
                    reason: r.unsigned.redacted_because,
                }),
            },
            AnyActerEvent::TaskUpdate(e) => match e {
                MessageLikeEvent::Original(m) => Ok(AnyActerModel::TaskUpdate(m.into())),
                MessageLikeEvent::Redacted(r) => Err(Error::ModelRedacted {
                    model_type: TaskUpdateEventContent::TYPE.to_owned(),
                    meta: EventMeta {
                        room_id: r.room_id,
                        event_id: r.event_id,
                        sender: r.sender,
                        origin_server_ts: r.origin_server_ts,
                        redacted: None,
                    },
                    reason: r.unsigned.redacted_because,
                }),
            },
            AnyActerEvent::TaskSelfAssign(e) => match e {
                MessageLikeEvent::Original(m) => Ok(AnyActerModel::TaskSelfAssign(m.into())),
                MessageLikeEvent::Redacted(r) => Err(Error::ModelRedacted {
                    model_type: TaskSelfAssignEventContent::TYPE.to_owned(),
                    meta: EventMeta {
                        room_id: r.room_id,
                        event_id: r.event_id,
                        sender: r.sender,
                        origin_server_ts: r.origin_server_ts,
                        redacted: None,
                    },
                    reason: r.unsigned.redacted_because,
                }),
            },
            AnyActerEvent::TaskSelfUnassign(e) => match e {
                MessageLikeEvent::Original(m) => Ok(AnyActerModel::TaskSelfUnassign(m.into())),
                MessageLikeEvent::Redacted(r) => Err(Error::ModelRedacted {
                    model_type: TaskSelfUnassignEventContent::TYPE.to_owned(),
                    meta: EventMeta {
                        room_id: r.room_id,
                        event_id: r.event_id,
                        sender: r.sender,
                        origin_server_ts: r.origin_server_ts,
                        redacted: None,
                    },
                    reason: r.unsigned.redacted_because,
                }),
            },
            AnyActerEvent::Comment(e) => match e {
                MessageLikeEvent::Original(m) => Ok(AnyActerModel::Comment(m.into())),
                MessageLikeEvent::Redacted(r) => Err(Error::ModelRedacted {
                    model_type: CommentEventContent::TYPE.to_owned(),
                    meta: EventMeta {
                        room_id: r.room_id,
                        event_id: r.event_id,
                        sender: r.sender,
                        origin_server_ts: r.origin_server_ts,
                        redacted: None,
                    },
                    reason: r.unsigned.redacted_because,
                }),
            },
            AnyActerEvent::CommentUpdate(e) => match e {
                MessageLikeEvent::Original(m) => Ok(AnyActerModel::CommentUpdate(m.into())),
                MessageLikeEvent::Redacted(r) => Err(Error::ModelRedacted {
                    model_type: CommentUpdateEventContent::TYPE.to_owned(),
                    meta: EventMeta {
                        room_id: r.room_id,
                        event_id: r.event_id,
                        sender: r.sender,
                        origin_server_ts: r.origin_server_ts,
                        redacted: None,
                    },
                    reason: r.unsigned.redacted_because,
                }),
            },
            AnyActerEvent::Attachment(e) => match e {
                MessageLikeEvent::Original(m) => Ok(AnyActerModel::Attachment(m.into())),
                MessageLikeEvent::Redacted(r) => Err(Error::ModelRedacted {
                    model_type: AttachmentEventContent::TYPE.to_owned(),
                    meta: EventMeta {
                        room_id: r.room_id,
                        event_id: r.event_id,
                        sender: r.sender,
                        origin_server_ts: r.origin_server_ts,
                        redacted: None,
                    },
                    reason: r.unsigned.redacted_because,
                }),
            },
            AnyActerEvent::AttachmentUpdate(e) => match e {
                MessageLikeEvent::Original(m) => Ok(AnyActerModel::AttachmentUpdate(m.into())),
                MessageLikeEvent::Redacted(r) => Err(Error::ModelRedacted {
                    model_type: AttachmentUpdateEventContent::TYPE.to_owned(),
                    meta: EventMeta {
                        room_id: r.room_id,
                        event_id: r.event_id,
                        sender: r.sender,
                        origin_server_ts: r.origin_server_ts,
                        redacted: None,
                    },
                    reason: r.unsigned.redacted_because,
                }),
            },
            AnyActerEvent::Rsvp(e) => match e {
                MessageLikeEvent::Original(m) => Ok(AnyActerModel::Rsvp(m.into())),
                MessageLikeEvent::Redacted(r) => Err(Error::ModelRedacted {
                    model_type: RsvpEventContent::TYPE.to_owned(),
                    meta: EventMeta {
                        room_id: r.room_id,
                        event_id: r.event_id,
                        sender: r.sender,
                        origin_server_ts: r.origin_server_ts,
                        redacted: None,
                    },
                    reason: r.unsigned.redacted_because,
                }),
            },

            AnyActerEvent::Reaction(e) => match e {
                MessageLikeEvent::Original(m) => Ok(AnyActerModel::Reaction(m.into())),
                MessageLikeEvent::Redacted(r) => Err(Error::ModelRedacted {
                    model_type: ReactionEventContent::TYPE.to_owned(),
                    meta: EventMeta {
                        room_id: r.room_id,
                        event_id: r.event_id,
                        sender: r.sender,
                        origin_server_ts: r.origin_server_ts,
                        redacted: None,
                    },
                    reason: r.unsigned.redacted_because,
                }),
            },
        }
    }
}

impl TryFrom<&Raw<AnyTimelineEvent>> for AnyActerModel {
    type Error = Error;
    fn try_from(raw: &Raw<AnyTimelineEvent>) -> Result<Self, Self::Error> {
        let Ok(Some(model_type)) = raw.get_field::<String>("type") else {
            return Err(Error::UnknownModel(None));
        };

        if !model_type.starts_with("global.acter") || model_type == "global.acter.app_settings" {
            return Err(Error::UnknownModel(Some(model_type)));
        }

        Self::try_from(raw.deserialize_as::<AnyActerEvent>().map_err(|error| {
            trace!(?error, ?raw, "parsing acter event failed");
            Error::FailedToParse {
                model_type,
                msg: error.to_string(),
            }
        })?)
    }
}

impl TryFrom<&Raw<AnySyncTimelineEvent>> for AnyActerModel {
    type Error = Error;
    fn try_from(raw: &Raw<AnySyncTimelineEvent>) -> Result<Self, Self::Error> {
        let Ok(Some(model_type)) = raw.get_field::<String>("type") else {
            return Err(Error::UnknownModel(None));
        };

        if !model_type.starts_with("global.acter") || model_type == "global.acter.app_settings" {
            return Err(Error::UnknownModel(Some(model_type)));
        }

        Self::try_from(raw.deserialize_as::<AnyActerEvent>().map_err(|error| {
            trace!(?error, ?raw, "parsing acter event failed");
            Error::FailedToParse {
                model_type,
                msg: error.to_string(),
            }
        })?)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::Result;
    use ruma_common::owned_event_id;
    #[test]
    fn ensure_minimal_tasklist_parses() -> Result<()> {
        let json_raw = r#"{"type":"global.acter.dev.tasklist",
            "room_id":"!euhIDqDVvVXulrhWgN:ds9.acter.global","sender":"@odo:ds9.acter.global",
            "content":{"name":"Daily Security Brief"},"origin_server_ts":1672407531453,
            "unsigned":{"age":11523850},
            "event_id":"$KwumA4L3M-duXu0I3UA886LvN-BDCKAyxR1skNfnh3c",
            "user_id":"@odo:ds9.acter.global","age":11523850}"#;
        let event = serde_json::from_str::<Raw<AnyTimelineEvent>>(json_raw)?;
        let _acter_ev = AnyActerModel::try_from(&event)?;
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
        let _acter_ev = AnyActerModel::try_from(&event)?;
        // assert!(matches!(event, AnyCreation::TaskList(_)));
        Ok(())
    }

    #[test]
    #[allow(unused_variables)]
    fn ensure_redacted_news_parses() -> Result<()> {
        let json_raw = r#"{
            "content": {},
            "origin_server_ts": 1689158713657,
            "room_id": "!uUufOaBOZwafrtxhoO:effektio.org",
            "sender": "@emilvincentz:effektio.org",
            "type": "global.acter.dev.news",
            "unsigned": {
              "redacted_by": "$2_k7NsG2GOGfyeNOvV55OovysVl7WGKgGEY2hv6VosY",
              "redacted_because": {
                "type": "m.room.redaction",
                "room_id": "!uUufOaBOZwafrtxhoO:effektio.org",
                "sender": "@ben:acter.global",
                "content": {
                  "reason": "",
                  "redacts": "$WAfv0heG198eXRIRPVVuli2Guc9pI2PB_spOcS8NXco"
                },
                "redacts": "$WAfv0heG198eXRIRPVVuli2Guc9pI2PB_spOcS8NXco",
                "origin_server_ts": 1694550003475,
                "unsigned": {
                  "age": 56316493,
                  "transaction_id": "1c85807d10074b17941f84ac02f168ee"
                },
                "event_id": "$2_k7NsG2GOGfyeNOvV55OovysVl7WGKgGEY2hv6VosY",
                "user_id": "@ben:acter.global",
                "age": 56316493
              }
            },
            "event_id": "$WAfv0heG198eXRIRPVVuli2Guc9pI2PB_spOcS8NXco",
            "user_id": "@emilvincentz:effektio.org",
            "redacted_because": {
              "type": "m.room.redaction",
              "room_id": "!uUufOaBOZwafrtxhoO:effektio.org",
              "sender": "@ben:acter.global",
              "content": {
                "reason": "",
                "redacts": "$WAfv0heG198eXRIRPVVuli2Guc9pI2PB_spOcS8NXco"
              },
              "redacts": "$WAfv0heG198eXRIRPVVuli2Guc9pI2PB_spOcS8NXco",
              "origin_server_ts": 1694550003475,
              "unsigned": {
                "age": 56316493,
                "transaction_id": "1c85807d10074b17941f84ac02f168ee"
              },
              "event_id": "$2_k7NsG2GOGfyeNOvV55OovysVl7WGKgGEY2hv6VosY",
              "user_id": "@ben:acter.global",
              "age": 56316493
            }
          }"#;
        let event = serde_json::from_str::<Raw<AnyTimelineEvent>>(json_raw)?;
        let acter_ev_result = AnyActerModel::try_from(&event);
        let model_type = "global.acter.dev.news".to_owned();
        let event_id = owned_event_id!("$2_k7NsG2GOGfyeNOvV55OovysVl7WGKgGEY2hv6VosY");
        assert!(
            matches!(
                acter_ev_result,
                Err(Error::ModelRedacted {
                    ref model_type,
                    meta: EventMeta { ref event_id, .. },
                    ..
                })
            ),
            "Didn't receive expected error: {acter_ev_result:?}"
        );
        // assert!(matches!(event, AnyCreation::TaskList(_)));
        Ok(())
    }

    #[test]
    #[allow(unused_variables)]
    fn ensure_redacted_pin_parses() -> Result<()> {
        let json_raw = r#"{
            "content": {},
            "origin_server_ts": 1689158713657,
            "room_id": "!uUufOaBOZwafrtxhoO:effektio.org",
            "sender": "@emilvincentz:effektio.org",
            "type": "global.acter.dev.pin",
            "unsigned": {
              "redacted_by": "$2_k7NsG2GOGfyeNOvV55OovysVl7WGKgGEY2hv6VosY",
              "redacted_because": {
                "type": "m.room.redaction",
                "room_id": "!uUufOaBOZwafrtxhoO:effektio.org",
                "sender": "@ben:acter.global",
                "content": {
                  "reason": "",
                  "redacts": "$WAfv0heG198eXRIRPVVuli2Guc9pI2PB_spOcS8NXco"
                },
                "redacts": "$WAfv0heG198eXRIRPVVuli2Guc9pI2PB_spOcS8NXco",
                "origin_server_ts": 1694550003475,
                "unsigned": {
                  "age": 56316493,
                  "transaction_id": "1c85807d10074b17941f84ac02f168ee"
                },
                "event_id": "$2_k7NsG2GOGfyeNOvV55OovysVl7WGKgGEY2hv6VosY",
                "user_id": "@ben:acter.global",
                "age": 56316493
              }
            },
            "event_id": "$WAfv0heG198eXRIRPVVuli2Guc9pI2PB_spOcS8NXco",
            "user_id": "@emilvincentz:effektio.org",
            "redacted_because": {
              "type": "m.room.redaction",
              "room_id": "!uUufOaBOZwafrtxhoO:effektio.org",
              "sender": "@ben:acter.global",
              "content": {
                "reason": "",
                "redacts": "$WAfv0heG198eXRIRPVVuli2Guc9pI2PB_spOcS8NXco"
              },
              "redacts": "$WAfv0heG198eXRIRPVVuli2Guc9pI2PB_spOcS8NXco",
              "origin_server_ts": 1694550003475,
              "unsigned": {
                "age": 56316493,
                "transaction_id": "1c85807d10074b17941f84ac02f168ee"
              },
              "event_id": "$2_k7NsG2GOGfyeNOvV55OovysVl7WGKgGEY2hv6VosY",
              "user_id": "@ben:acter.global",
              "age": 56316493
            }
          }"#;
        let event = serde_json::from_str::<Raw<AnyTimelineEvent>>(json_raw)?;
        let acter_ev_result = AnyActerModel::try_from(&event);
        let model_type = "global.acter.dev.pin".to_owned();
        let event_id = owned_event_id!("$KwumA4L3M-duXu0I3UA886LvN-BDCKAyxR1skNfnh3c");
        assert!(
            matches!(
                acter_ev_result,
                Err(Error::ModelRedacted {
                    ref model_type,
                    meta: EventMeta { ref event_id, .. },
                    ..
                })
            ),
            "Didn't receive expected error: {acter_ev_result:?}"
        );
        // assert!(matches!(event, AnyCreation::TaskList(_)));
        Ok(())
    }
}
