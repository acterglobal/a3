mod attachments;
mod calendar;
mod comments;
mod common;
mod news;
mod pins;
mod reactions;
mod read_receipts;
mod rsvp;
mod stories;
mod tag;
mod tasks;
#[cfg(any(test, feature = "testing"))]
mod test;

use async_recursion::async_recursion;
pub use attachments::{Attachment, AttachmentUpdate, AttachmentsManager, AttachmentsStats};
pub use calendar::{CalendarEvent, CalendarEventUpdate};
pub use comments::{Comment, CommentUpdate, CommentsManager, CommentsStats};
pub use common::*;
pub use core::fmt::Debug;
use enum_dispatch::enum_dispatch;
use matrix_sdk::room::Room;
use matrix_sdk_base::ruma::{
    events::{
        reaction::ReactionEventContent,
        room::redaction::{OriginalRoomRedactionEvent, RoomRedactionEventContent},
        MessageLikeEvent, StaticEventContent, UnsignedRoomRedactionEvent,
    },
    EventId, MilliSecondsSinceUnixEpoch, OwnedEventId, OwnedRoomId, OwnedUserId, RoomId, UserId,
};
pub use news::{NewsEntry, NewsEntryUpdate};
pub use pins::{Pin, PinUpdate};
pub use reactions::{Reaction, ReactionManager, ReactionStats};
pub use read_receipts::{ReadReceipt, ReadReceiptStats, ReadReceiptsManager};
pub use rsvp::{Rsvp, RsvpManager, RsvpStats};
use serde::{Deserialize, Serialize};
pub use stories::{Story, StoryUpdate};
pub use tag::Tag;
pub use tasks::{
    Task, TaskList, TaskListUpdate, TaskSelfAssign, TaskSelfUnassign, TaskStats, TaskUpdate,
};
use tracing::{error, info, trace, warn};

#[cfg(any(test, feature = "testing"))]
pub use test::{TestModel, TestModelBuilder, TestModelBuilderError};

pub use crate::store::Store;
use crate::{
    events::{
        attachments::{AttachmentEventContent, AttachmentUpdateEventContent},
        calendar::{CalendarEventEventContent, CalendarEventUpdateEventContent},
        comments::{CommentEventContent, CommentUpdateEventContent},
        news::{NewsEntryEventContent, NewsEntryUpdateEventContent},
        pins::{PinEventContent, PinUpdateEventContent},
        read_receipt::ReadReceiptEventContent,
        rsvp::RsvpEventContent,
        stories::{StoryEventContent, StoryUpdateEventContent},
        tasks::{
            TaskEventContent, TaskListEventContent, TaskListUpdateEventContent,
            TaskSelfAssignEventContent, TaskSelfUnassignEventContent, TaskUpdateEventContent,
        },
        AnyActerEvent,
    },
    executor::Executor,
    referencing::{ExecuteReference, IndexKey},
};

#[derive(Debug, Eq, PartialEq)]
pub enum Capability {
    // someone can add reaction on this
    Reactable,
    // someone can add comment on this
    Commentable,
    // someone can add attachment on this
    Attachmentable,
    // users reads/views are being tracked
    ReadTracking,
    // another custom capability
    Custom(&'static str),
}

#[async_recursion]
pub async fn transition_tree(
    store: &Store,
    parents: Vec<OwnedEventId>,
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
) -> crate::Result<Vec<ExecuteReference>> {
    trace!(event_id=?model.event_id(), ?model, "handling");
    let Some(belongs_to) = model.belongs_to() else {
        trace!(event_id=?model.event_id(), "saving simple model");
        return store.save(model).await;
    };

    trace!(event_id=?model.event_id(), ?belongs_to, "transitioning tree");
    let mut models = transition_tree(store, belongs_to, &model).await?;
    models.push(model);
    store.save_many(models).await
}

#[enum_dispatch(AnyActerModel)]
pub trait ActerModel: Debug {
    /// the event metadata for this model
    fn event_meta(&self) -> &EventMeta;

    fn indizes(&self, user_id: &UserId) -> Vec<IndexKey>;

    /// The key to store this model under
    fn event_id(&self) -> &EventId {
        &self.event_meta().event_id
    }

    /// The room id this model belongs to
    fn room_id(&self) -> &RoomId {
        &self.event_meta().room_id
    }

    /// The models to inform about this model as it belongs to that
    fn belongs_to(&self) -> Option<Vec<OwnedEventId>> {
        None
    }

    /// activate to enable commenting support for this type of model
    fn capabilities(&self) -> &[Capability] {
        &[]
    }
    /// The execution to run when this model is found.
    async fn execute(self, store: &Store) -> crate::Result<Vec<ExecuteReference>>;

    /// handle transition from an external Item upon us
    fn transition(&mut self, model: &AnyActerModel) -> crate::Result<bool> {
        warn!(?self, ?model, "Transition has not been implemented");
        Ok(false)
    }
    /// The execution to run when this model is found.
    async fn redact(
        &self,
        store: &Store,
        redaction_model: RedactedActerModel,
    ) -> crate::Result<Vec<ExecuteReference>> {
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
    meta: EventMeta,
    content: RedactionContent,
    // legacy support
    #[serde(skip, default)]
    #[allow(dead_code)]
    indizes: Option<Vec<IndexKey>>,
}

impl RedactedActerModel {
    pub fn origin_type(&self) -> &str {
        &self.orig_type
    }
}

impl RedactedActerModel {
    pub fn new(orig_type: String, meta: EventMeta, content: RedactionContent) -> Self {
        RedactedActerModel {
            meta,
            orig_type,
            content,
            indizes: None,
        }
    }
}

impl ActerModel for RedactedActerModel {
    fn indizes(&self, _user_id: &UserId) -> Vec<IndexKey> {
        let mut indizes = vec![IndexKey::RoomHistory(self.meta.room_id.clone())];
        if let Some(origin_event_id) = self.content.content.redacts.as_ref() {
            indizes.push(IndexKey::ObjectHistory(origin_event_id.clone()))
        }
        indizes
    }

    fn event_meta(&self) -> &EventMeta {
        &self.meta
    }

    async fn execute(self, store: &Store) -> crate::Result<Vec<ExecuteReference>> {
        default_model_execute(store, self.into()).await
    }

    fn transition(&mut self, model: &AnyActerModel) -> crate::Result<bool> {
        // Transitions aren’t possible anymore when the source has been redacted
        // so we eat up the content and just log that we had to do that.
        info!(?self, ?model, "Transition on Redaction Swallowed");
        Ok(false)
    }
}

#[derive(Serialize, Deserialize, Debug, Clone)]
#[cfg_attr(any(test, feature = "testing"), derive(PartialEq, Eq))]
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

pub async fn can_redact(room: &Room, sender_id: &UserId) -> crate::error::Result<bool> {
    let client = room.client();
    let Some(user_id) = client.user_id() else {
        // not logged in means we can’t redact
        return Ok(false);
    };
    Ok(if sender_id == user_id {
        room.can_user_redact_own(user_id).await?
    } else {
        room.can_user_redact_other(user_id).await?
    })
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

    // -- News
    Story(Story),
    StoryUpdate(StoryUpdate),

    // -- more generics
    Comment(Comment),
    CommentUpdate(CommentUpdate),

    Attachment(Attachment),
    AttachmentUpdate(AttachmentUpdate),

    Rsvp(Rsvp),
    Reaction(Reaction),
    ReadReceipt(ReadReceipt),

    #[cfg(any(test, feature = "testing"))]
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
            AnyActerModel::Story(_) => StoryEventContent::TYPE,
            AnyActerModel::StoryUpdate(_) => StoryUpdateEventContent::TYPE,
            AnyActerModel::Comment(_) => CommentEventContent::TYPE,
            AnyActerModel::CommentUpdate(_) => CommentUpdateEventContent::TYPE,
            AnyActerModel::Attachment(_) => AttachmentEventContent::TYPE,
            AnyActerModel::AttachmentUpdate(_) => AttachmentUpdateEventContent::TYPE,
            AnyActerModel::Rsvp(_) => RsvpEventContent::TYPE,
            AnyActerModel::Reaction(_) => ReactionEventContent::TYPE,
            AnyActerModel::ReadReceipt(_) => ReadReceiptEventContent::TYPE,
            AnyActerModel::RedactedActerModel(..) => "unknown_redacted_model",
            #[cfg(any(test, feature = "testing"))]
            AnyActerModel::TestModel(_) => "test_model",
        }
    }

    pub async fn execute(executor: &Executor, event: AnyActerEvent) {
        let room_id = event.room_id().to_owned();
        match AnyActerModel::try_from(event) {
            Ok(model) => {
                trace!(?room_id, ?model, "handling timeline event");
                if let Err(e) = executor.handle(model).await {
                    error!("Failure handling event: {:}", e);
                }
            }
            Err(ParseError::ModelRedacted {
                model_type,
                meta,
                reason,
            }) => {
                trace!(?meta.room_id, model_type, ?meta.event_id, "redacted event");
                if let Err(e) = executor.redact(model_type, meta, reason).await {
                    error!("Failure redacting {:}", e);
                }
            }
            Err(ParseError::UnsupportedEvent(AnyActerEvent::RegularTimelineEvent(_))) => {
                // save to hard ignore
                trace!(?room_id, "ignoring timeline event");
            }
            Err(ParseError::UnsupportedEvent(inner)) => {
                // sae to hard ignore
                error!(?room_id, ?inner, "seems like the dev failed to add parsing");
            }
        };
    }
}

#[derive(thiserror::Error, Debug)]
pub enum ParseError {
    #[error("Model {meta:?} ({model_type}): {reason:?}")]
    ModelRedacted {
        model_type: String,
        meta: EventMeta,
        reason: UnsignedRoomRedactionEvent,
    },
    #[error("Not supported Acter Event")]
    UnsupportedEvent(AnyActerEvent),
}

impl TryFrom<AnyActerEvent> for AnyActerModel {
    type Error = ParseError;
    fn try_from(value: AnyActerEvent) -> Result<Self, Self::Error> {
        match value {
            // Originals
            AnyActerEvent::CalendarEvent(e) => match e {
                MessageLikeEvent::Original(m) => Ok(AnyActerModel::CalendarEvent(m.into())),
                MessageLikeEvent::Redacted(r) => Err(Self::Error::ModelRedacted {
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
                MessageLikeEvent::Redacted(r) => Err(Self::Error::ModelRedacted {
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
                MessageLikeEvent::Redacted(r) => Err(Self::Error::ModelRedacted {
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
                MessageLikeEvent::Redacted(r) => Err(Self::Error::ModelRedacted {
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
                MessageLikeEvent::Redacted(r) => Err(Self::Error::ModelRedacted {
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
                MessageLikeEvent::Redacted(r) => Err(Self::Error::ModelRedacted {
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

            AnyActerEvent::Story(e) => match e {
                MessageLikeEvent::Original(m) => Ok(AnyActerModel::Story(m.into())),
                MessageLikeEvent::Redacted(r) => Err(Self::Error::ModelRedacted {
                    model_type: StoryEventContent::TYPE.to_owned(),
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
            AnyActerEvent::StoryUpdate(e) => match e {
                MessageLikeEvent::Original(m) => Ok(AnyActerModel::StoryUpdate(m.into())),
                MessageLikeEvent::Redacted(r) => Err(Self::Error::ModelRedacted {
                    model_type: StoryUpdateEventContent::TYPE.to_owned(),
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
                MessageLikeEvent::Redacted(r) => Err(Self::Error::ModelRedacted {
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
                MessageLikeEvent::Redacted(r) => Err(Self::Error::ModelRedacted {
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
                MessageLikeEvent::Redacted(r) => Err(Self::Error::ModelRedacted {
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
                MessageLikeEvent::Redacted(r) => Err(Self::Error::ModelRedacted {
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
                MessageLikeEvent::Redacted(r) => Err(Self::Error::ModelRedacted {
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
                MessageLikeEvent::Redacted(r) => Err(Self::Error::ModelRedacted {
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
                MessageLikeEvent::Redacted(r) => Err(Self::Error::ModelRedacted {
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
                MessageLikeEvent::Redacted(r) => Err(Self::Error::ModelRedacted {
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
                MessageLikeEvent::Redacted(r) => Err(Self::Error::ModelRedacted {
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
                MessageLikeEvent::Redacted(r) => Err(Self::Error::ModelRedacted {
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
                MessageLikeEvent::Redacted(r) => Err(Self::Error::ModelRedacted {
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
                MessageLikeEvent::Redacted(r) => Err(Self::Error::ModelRedacted {
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

            AnyActerEvent::ReadReceipt(e) => match e {
                MessageLikeEvent::Original(m) => Ok(AnyActerModel::ReadReceipt(m.into())),
                MessageLikeEvent::Redacted(r) => Err(Self::Error::ModelRedacted {
                    model_type: ReadReceiptEventContent::TYPE.to_owned(),
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
            // should not really happen
            AnyActerEvent::RegularTimelineEvent(_) => Err(Self::Error::UnsupportedEvent(value)),
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::Result;

    use matrix_sdk_base::ruma::owned_event_id;
    #[test]
    fn ensure_minimal_tasklist_parses() -> Result<()> {
        let json_raw = r#"{"type":"global.acter.dev.tasklist",
            "room_id":"!euhIDqDVvVXulrhWgN:ds9.acter.global","sender":"@odo:ds9.acter.global",
            "content":{"name":"Daily Security Brief"},"origin_server_ts":1672407531453,
            "unsigned":{"age":11523850},
            "event_id":"$KwumA4L3M-duXu0I3UA886LvN-BDCKAyxR1skNfnh3c",
            "user_id":"@odo:ds9.acter.global","age":11523850}"#;
        let event = serde_json::from_str::<AnyActerEvent>(json_raw)?;
        AnyActerModel::try_from(event).unwrap();
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
        let event = serde_json::from_str::<AnyActerEvent>(json_raw)?;
        AnyActerModel::try_from(event).unwrap();
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
        let event = serde_json::from_str::<AnyActerEvent>(json_raw)?;
        let acter_ev_result = AnyActerModel::try_from(event.clone());
        let model_type = "global.acter.dev.news".to_owned();
        let event_id = owned_event_id!("$2_k7NsG2GOGfyeNOvV55OovysVl7WGKgGEY2hv6VosY");
        assert!(
            matches!(
                acter_ev_result,
                Err(ParseError::ModelRedacted {
                    ref model_type,
                    meta: EventMeta { ref event_id, .. },
                    ..
                })
            ),
            "Didn’t receive expected error: {acter_ev_result:?}"
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
        let event = serde_json::from_str::<AnyActerEvent>(json_raw)?;
        let acter_ev_result = AnyActerModel::try_from(event);
        let model_type = "global.acter.dev.pin".to_owned();
        let event_id = owned_event_id!("$KwumA4L3M-duXu0I3UA886LvN-BDCKAyxR1skNfnh3c");
        assert!(
            matches!(
                acter_ev_result,
                Err(ParseError::ModelRedacted {
                    ref model_type,
                    meta: EventMeta { ref event_id, .. },
                    ..
                })
            ),
            "Didn’t receive expected error: {acter_ev_result:?}"
        );
        // assert!(matches!(event, AnyCreation::TaskList(_)));
        Ok(())
    }
}
