use super::{AnyActerModel, EventMeta};
use crate::events::{
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
};
use core::fmt::Debug;
use matrix_sdk_base::ruma::events::{
    reaction::ReactionEventContent, MessageLikeEvent, StaticEventContent,
    UnsignedRoomRedactionEvent,
};

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
