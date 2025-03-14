pub mod attachments;
pub mod bookmarks;
pub mod calendar;
pub mod comments;
mod common;
pub mod explicit_invites;
pub mod news;
pub mod pins;
pub mod read_receipt;
pub mod room;
pub mod rsvp;
pub mod settings;
pub mod stories;
pub mod tasks;
pub mod three_pid;

pub use common::*;
use matrix_sdk::{
    event_handler::{HandlerKind, SyncEvent},
    ruma::events::AnySyncTimelineEvent,
};
use matrix_sdk_base::ruma::{
    events::{reaction, AnyTimelineEvent, EventTypeDeHelper, StaticEventContent},
    exports::{serde::de::Error as SerdeDeError, serde_json as smart_serde_json},
    OwnedRoomId, RoomId,
};

#[derive(Clone, Debug)]
pub enum AnyActerEvent {
    CalendarEvent(calendar::CalendarEventEvent),
    CalendarEventUpdate(calendar::CalendarEventUpdateEvent),

    Pin(pins::PinEvent),
    PinUpdate(pins::PinUpdateEvent),

    NewsEntry(news::NewsEntryEvent),
    NewsEntryUpdate(news::NewsEntryUpdateEvent),

    Story(stories::StoryEvent),
    StoryUpdate(stories::StoryUpdateEvent),

    TaskList(tasks::TaskListEvent),
    TaskListUpdate(tasks::TaskListUpdateEvent),

    Task(tasks::TaskEvent),
    TaskUpdate(tasks::TaskUpdateEvent),
    TaskSelfAssign(tasks::TaskSelfAssignEvent),
    TaskSelfUnassign(tasks::TaskSelfUnassignEvent),

    // Generic Relative Features
    Comment(comments::CommentEvent),
    CommentUpdate(comments::CommentUpdateEvent),

    Attachment(attachments::AttachmentEvent),
    AttachmentUpdate(attachments::AttachmentUpdateEvent),

    Reaction(reaction::ReactionEvent),
    ReadReceipt(read_receipt::ReadReceiptEvent),
    ExplicitInvite(explicit_invites::ExplicitInviteEvent),
    Rsvp(rsvp::RsvpEvent),

    // Regular Matrix / Ruma Event
    RegularTimelineEvent(AnyTimelineEvent),
}

impl AnyActerEvent {
    pub fn room_id(&self) -> &RoomId {
        match &self {
            Self::Attachment(e) => e.room_id(),
            AnyActerEvent::CalendarEvent(e) => e.room_id(),
            AnyActerEvent::CalendarEventUpdate(e) => e.room_id(),
            AnyActerEvent::Pin(e) => e.room_id(),
            AnyActerEvent::PinUpdate(e) => e.room_id(),
            AnyActerEvent::NewsEntry(e) => e.room_id(),
            AnyActerEvent::NewsEntryUpdate(e) => e.room_id(),
            AnyActerEvent::Story(e) => e.room_id(),
            AnyActerEvent::StoryUpdate(e) => e.room_id(),
            AnyActerEvent::TaskList(e) => e.room_id(),
            AnyActerEvent::TaskListUpdate(e) => e.room_id(),
            AnyActerEvent::Task(e) => e.room_id(),
            AnyActerEvent::TaskUpdate(e) => e.room_id(),
            AnyActerEvent::TaskSelfAssign(e) => e.room_id(),
            AnyActerEvent::TaskSelfUnassign(e) => e.room_id(),
            AnyActerEvent::Comment(e) => e.room_id(),
            AnyActerEvent::CommentUpdate(e) => e.room_id(),
            AnyActerEvent::AttachmentUpdate(e) => e.room_id(),
            AnyActerEvent::Reaction(e) => e.room_id(),
            AnyActerEvent::ReadReceipt(e) => e.room_id(),
            AnyActerEvent::Rsvp(e) => e.room_id(),
            AnyActerEvent::ExplicitInvite(e) => e.room_id(),
            AnyActerEvent::RegularTimelineEvent(e) => e.room_id(),
        }
    }
}

impl<'de> serde::Deserialize<'de> for AnyActerEvent {
    fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        let json = Box::<smart_serde_json::value::RawValue>::deserialize(deserializer)?;
        let EventTypeDeHelper { ev_type, .. } =
            ::matrix_sdk_base::ruma::serde::from_raw_json_value(&json)?;
        match &*ev_type {
            calendar::CalendarEventEventContent::TYPE => {
                let event = smart_serde_json::from_str::<calendar::CalendarEventEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::CalendarEvent(event))
            }
            calendar::CalendarEventUpdateEventContent::TYPE => {
                let event =
                    smart_serde_json::from_str::<calendar::CalendarEventUpdateEvent>(json.get())
                        .map_err(D::Error::custom)?;
                Ok(Self::CalendarEventUpdate(event))
            }

            pins::PinEventContent::TYPE => {
                let event = smart_serde_json::from_str::<pins::PinEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::Pin(event))
            }
            pins::PinUpdateEventContent::TYPE => {
                let event = smart_serde_json::from_str::<pins::PinUpdateEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::PinUpdate(event))
            }

            news::NewsEntryEventContent::TYPE => {
                let event = smart_serde_json::from_str::<news::NewsEntryEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::NewsEntry(event))
            }
            news::NewsEntryUpdateEventContent::TYPE => {
                let event = smart_serde_json::from_str::<news::NewsEntryUpdateEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::NewsEntryUpdate(event))
            }

            stories::StoryEventContent::TYPE => {
                let event = smart_serde_json::from_str::<stories::StoryEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::Story(event))
            }
            stories::StoryUpdateEventContent::TYPE => {
                let event = smart_serde_json::from_str::<stories::StoryUpdateEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::StoryUpdate(event))
            }
            tasks::TaskListEventContent::TYPE => {
                let event = smart_serde_json::from_str::<tasks::TaskListEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::TaskList(event))
            }
            tasks::TaskListUpdateEventContent::TYPE => {
                let event = smart_serde_json::from_str::<tasks::TaskListUpdateEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::TaskListUpdate(event))
            }

            tasks::TaskEventContent::TYPE => {
                let event = smart_serde_json::from_str::<tasks::TaskEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::Task(event))
            }
            tasks::TaskUpdateEventContent::TYPE => {
                let event = smart_serde_json::from_str::<tasks::TaskUpdateEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::TaskUpdate(event))
            }

            tasks::TaskSelfAssignEventContent::TYPE => {
                let event = smart_serde_json::from_str::<tasks::TaskSelfAssignEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::TaskSelfAssign(event))
            }

            tasks::TaskSelfUnassignEventContent::TYPE => {
                let event = smart_serde_json::from_str::<tasks::TaskSelfUnassignEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::TaskSelfUnassign(event))
            }

            comments::CommentEventContent::TYPE => {
                let event = smart_serde_json::from_str::<comments::CommentEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::Comment(event))
            }
            comments::CommentUpdateEventContent::TYPE => {
                let event = smart_serde_json::from_str::<comments::CommentUpdateEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::CommentUpdate(event))
            }

            attachments::AttachmentEventContent::TYPE => {
                let event = smart_serde_json::from_str::<attachments::AttachmentEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::Attachment(event))
            }
            attachments::AttachmentUpdateEventContent::TYPE => {
                let event =
                    smart_serde_json::from_str::<attachments::AttachmentUpdateEvent>(json.get())
                        .map_err(D::Error::custom)?;
                Ok(Self::AttachmentUpdate(event))
            }

            rsvp::RsvpEventContent::TYPE => {
                let event = smart_serde_json::from_str::<rsvp::RsvpEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::Rsvp(event))
            }

            read_receipt::ReadReceiptEventContent::TYPE => {
                let event = ::matrix_sdk_base::ruma::exports::serde_json::from_str::<
                    read_receipt::ReadReceiptEvent,
                >(json.get())
                .map_err(D::Error::custom)?;
                Ok(Self::ReadReceipt(event))
            }

            explicit_invites::ExplicitInviteEventContent::TYPE => {
                let event =
                    smart_serde_json::from_str::<explicit_invites::ExplicitInviteEvent>(json.get())
                        .map_err(D::Error::custom)?;
                Ok(Self::ExplicitInvite(event))
            }

            reaction::ReactionEventContent::TYPE => {
                let event = ::matrix_sdk_base::ruma::exports::serde_json::from_str::<
                    reaction::ReactionEvent,
                >(json.get())
                .map_err(D::Error::custom)?;
                Ok(Self::Reaction(event))
            }

            _ => {
                if let Ok(event) = ::matrix_sdk_base::ruma::exports::serde_json::from_str::<
                    AnyTimelineEvent,
                >(json.get())
                {
                    Ok(Self::RegularTimelineEvent(event))
                } else {
                    Err(SerdeDeError::unknown_variant(
                        &ev_type,
                        &[
                            calendar::CalendarEventEventContent::TYPE,
                            calendar::CalendarEventUpdateEventContent::TYPE,
                            pins::PinEventContent::TYPE,
                            pins::PinUpdateEventContent::TYPE,
                            news::NewsEntryEventContent::TYPE,
                            news::NewsEntryUpdateEventContent::TYPE,
                            stories::StoryEventContent::TYPE,
                            stories::StoryUpdateEventContent::TYPE,
                            tasks::TaskListEventContent::TYPE,
                            tasks::TaskListUpdateEventContent::TYPE,
                            tasks::TaskEventContent::TYPE,
                            tasks::TaskUpdateEventContent::TYPE,
                            tasks::TaskSelfAssignEventContent::TYPE,
                            tasks::TaskSelfUnassignEventContent::TYPE,
                            comments::CommentEventContent::TYPE,
                            comments::CommentUpdateEventContent::TYPE,
                            attachments::AttachmentEventContent::TYPE,
                            attachments::AttachmentUpdateEventContent::TYPE,
                            rsvp::RsvpEventContent::TYPE,
                            read_receipt::ReadReceiptEventContent::TYPE,
                            reaction::ReactionEventContent::TYPE,
                        ],
                    ))
                }
            }
        }
    }
}

#[derive(Clone, Debug)]
pub enum SyncAnyActerEvent {
    CalendarEvent(calendar::SyncCalendarEventEvent),
    CalendarEventUpdate(calendar::SyncCalendarEventUpdateEvent),

    Pin(pins::SyncPinEvent),
    PinUpdate(pins::SyncPinUpdateEvent),

    NewsEntry(news::SyncNewsEntryEvent),
    NewsEntryUpdate(news::SyncNewsEntryUpdateEvent),

    Story(stories::SyncStoryEvent),
    StoryUpdate(stories::SyncStoryUpdateEvent),

    TaskList(tasks::SyncTaskListEvent),
    TaskListUpdate(tasks::SyncTaskListUpdateEvent),

    Task(tasks::SyncTaskEvent),
    TaskUpdate(tasks::SyncTaskUpdateEvent),
    TaskSelfAssign(tasks::SyncTaskSelfAssignEvent),
    TaskSelfUnassign(tasks::SyncTaskSelfUnassignEvent),

    // Generic Relative Features
    Comment(comments::SyncCommentEvent),
    CommentUpdate(comments::SyncCommentUpdateEvent),

    Attachment(attachments::SyncAttachmentEvent),
    AttachmentUpdate(attachments::SyncAttachmentUpdateEvent),

    Reaction(reaction::SyncReactionEvent),
    ReadReceipt(read_receipt::SyncReadReceiptEvent),
    ExplicitInvite(explicit_invites::SyncExplicitInviteEvent),
    Rsvp(rsvp::SyncRsvpEvent),
    // Regular Matrix / Ruma Event
    RegularTimelineEvent(AnySyncTimelineEvent),
}

impl SyncAnyActerEvent {
    /// Convert this sync event into a full event (one with a `room_id` field).
    pub fn into_full_any_acter_event(self, room_id: OwnedRoomId) -> AnyActerEvent {
        match self {
            Self::CalendarEvent(e) => AnyActerEvent::CalendarEvent(e.into_full_event(room_id)),
            Self::CalendarEventUpdate(e) => {
                AnyActerEvent::CalendarEventUpdate(e.into_full_event(room_id))
            }
            Self::Pin(e) => AnyActerEvent::Pin(e.into_full_event(room_id)),
            Self::PinUpdate(e) => AnyActerEvent::PinUpdate(e.into_full_event(room_id)),
            Self::NewsEntry(e) => AnyActerEvent::NewsEntry(e.into_full_event(room_id)),
            Self::NewsEntryUpdate(e) => AnyActerEvent::NewsEntryUpdate(e.into_full_event(room_id)),
            Self::Story(e) => AnyActerEvent::Story(e.into_full_event(room_id)),
            Self::StoryUpdate(e) => AnyActerEvent::StoryUpdate(e.into_full_event(room_id)),
            Self::TaskList(e) => AnyActerEvent::TaskList(e.into_full_event(room_id)),
            Self::TaskListUpdate(e) => AnyActerEvent::TaskListUpdate(e.into_full_event(room_id)),
            Self::Task(e) => AnyActerEvent::Task(e.into_full_event(room_id)),
            Self::TaskUpdate(e) => AnyActerEvent::TaskUpdate(e.into_full_event(room_id)),
            Self::TaskSelfAssign(e) => AnyActerEvent::TaskSelfAssign(e.into_full_event(room_id)),
            Self::TaskSelfUnassign(e) => {
                AnyActerEvent::TaskSelfUnassign(e.into_full_event(room_id))
            }
            Self::Comment(e) => AnyActerEvent::Comment(e.into_full_event(room_id)),
            Self::CommentUpdate(e) => AnyActerEvent::CommentUpdate(e.into_full_event(room_id)),
            Self::Attachment(e) => AnyActerEvent::Attachment(e.into_full_event(room_id)),
            Self::AttachmentUpdate(e) => {
                AnyActerEvent::AttachmentUpdate(e.into_full_event(room_id))
            }
            Self::Reaction(e) => AnyActerEvent::Reaction(e.into_full_event(room_id)),
            Self::ReadReceipt(e) => AnyActerEvent::ReadReceipt(e.into_full_event(room_id)),
            Self::Rsvp(e) => AnyActerEvent::Rsvp(e.into_full_event(room_id)),
            Self::ExplicitInvite(e) => AnyActerEvent::ExplicitInvite(e.into_full_event(room_id)),
            Self::RegularTimelineEvent(e) => {
                AnyActerEvent::RegularTimelineEvent(e.into_full_event(room_id))
            }
        }
    }
}

impl<'de> serde::Deserialize<'de> for SyncAnyActerEvent {
    fn deserialize<D>(deserializer: D) -> ::std::result::Result<Self, D::Error>
    where
        D: serde::Deserializer<'de>,
    {
        let json = Box::<smart_serde_json::value::RawValue>::deserialize(deserializer)?;
        let EventTypeDeHelper { ev_type, .. } =
            ::matrix_sdk_base::ruma::serde::from_raw_json_value(&json)?;
        match &*ev_type {
            calendar::CalendarEventEventContent::TYPE => {
                let event =
                    smart_serde_json::from_str::<calendar::SyncCalendarEventEvent>(json.get())
                        .map_err(D::Error::custom)?;
                Ok(Self::CalendarEvent(event))
            }
            calendar::CalendarEventUpdateEventContent::TYPE => {
                let event = smart_serde_json::from_str::<calendar::SyncCalendarEventUpdateEvent>(
                    json.get(),
                )
                .map_err(D::Error::custom)?;
                Ok(Self::CalendarEventUpdate(event))
            }

            pins::PinEventContent::TYPE => {
                let event = smart_serde_json::from_str::<pins::SyncPinEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::Pin(event))
            }
            pins::PinUpdateEventContent::TYPE => {
                let event = smart_serde_json::from_str::<pins::SyncPinUpdateEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::PinUpdate(event))
            }

            news::NewsEntryEventContent::TYPE => {
                let event = smart_serde_json::from_str::<news::SyncNewsEntryEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::NewsEntry(event))
            }
            news::NewsEntryUpdateEventContent::TYPE => {
                let event =
                    smart_serde_json::from_str::<news::SyncNewsEntryUpdateEvent>(json.get())
                        .map_err(D::Error::custom)?;
                Ok(Self::NewsEntryUpdate(event))
            }

            stories::StoryEventContent::TYPE => {
                let event = smart_serde_json::from_str::<stories::SyncStoryEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::Story(event))
            }
            stories::StoryUpdateEventContent::TYPE => {
                let event = smart_serde_json::from_str::<stories::SyncStoryUpdateEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::StoryUpdate(event))
            }

            tasks::TaskListEventContent::TYPE => {
                let event = smart_serde_json::from_str::<tasks::SyncTaskListEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::TaskList(event))
            }
            tasks::TaskListUpdateEventContent::TYPE => {
                let event =
                    smart_serde_json::from_str::<tasks::SyncTaskListUpdateEvent>(json.get())
                        .map_err(D::Error::custom)?;
                Ok(Self::TaskListUpdate(event))
            }

            tasks::TaskEventContent::TYPE => {
                let event = smart_serde_json::from_str::<tasks::SyncTaskEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::Task(event))
            }
            tasks::TaskUpdateEventContent::TYPE => {
                let event = smart_serde_json::from_str::<tasks::SyncTaskUpdateEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::TaskUpdate(event))
            }

            tasks::TaskSelfAssignEventContent::TYPE => {
                let event =
                    smart_serde_json::from_str::<tasks::SyncTaskSelfAssignEvent>(json.get())
                        .map_err(D::Error::custom)?;
                Ok(Self::TaskSelfAssign(event))
            }

            tasks::TaskSelfUnassignEventContent::TYPE => {
                let event =
                    smart_serde_json::from_str::<tasks::SyncTaskSelfUnassignEvent>(json.get())
                        .map_err(D::Error::custom)?;
                Ok(Self::TaskSelfUnassign(event))
            }

            comments::CommentEventContent::TYPE => {
                let event = smart_serde_json::from_str::<comments::SyncCommentEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::Comment(event))
            }
            comments::CommentUpdateEventContent::TYPE => {
                let event =
                    smart_serde_json::from_str::<comments::SyncCommentUpdateEvent>(json.get())
                        .map_err(D::Error::custom)?;
                Ok(Self::CommentUpdate(event))
            }

            attachments::AttachmentEventContent::TYPE => {
                let event =
                    smart_serde_json::from_str::<attachments::SyncAttachmentEvent>(json.get())
                        .map_err(D::Error::custom)?;
                Ok(Self::Attachment(event))
            }
            attachments::AttachmentUpdateEventContent::TYPE => {
                let event = smart_serde_json::from_str::<attachments::SyncAttachmentUpdateEvent>(
                    json.get(),
                )
                .map_err(D::Error::custom)?;
                Ok(Self::AttachmentUpdate(event))
            }

            rsvp::RsvpEventContent::TYPE => {
                let event = smart_serde_json::from_str::<rsvp::SyncRsvpEvent>(json.get())
                    .map_err(D::Error::custom)?;
                Ok(Self::Rsvp(event))
            }

            read_receipt::ReadReceiptEventContent::TYPE => {
                let event = ::matrix_sdk_base::ruma::exports::serde_json::from_str::<
                    read_receipt::SyncReadReceiptEvent,
                >(json.get())
                .map_err(D::Error::custom)?;
                Ok(Self::ReadReceipt(event))
            }

            explicit_invites::ExplicitInviteEventContent::TYPE => {
                let event =
                    smart_serde_json::from_str::<explicit_invites::SyncExplicitInviteEvent>(
                        json.get(),
                    )
                    .map_err(D::Error::custom)?;
                Ok(Self::ExplicitInvite(event))
            }

            reaction::ReactionEventContent::TYPE => {
                let event = ::matrix_sdk_base::ruma::exports::serde_json::from_str::<
                    reaction::SyncReactionEvent,
                >(json.get())
                .map_err(D::Error::custom)?;
                Ok(Self::Reaction(event))
            }

            _ => {
                if let Ok(event) = ::matrix_sdk_base::ruma::exports::serde_json::from_str::<
                    AnySyncTimelineEvent,
                >(json.get())
                {
                    Ok(Self::RegularTimelineEvent(event))
                } else {
                    Err(SerdeDeError::unknown_variant(
                        &ev_type,
                        &[
                            calendar::CalendarEventEventContent::TYPE,
                            calendar::CalendarEventUpdateEventContent::TYPE,
                            pins::PinEventContent::TYPE,
                            pins::PinUpdateEventContent::TYPE,
                            news::NewsEntryEventContent::TYPE,
                            news::NewsEntryUpdateEventContent::TYPE,
                            stories::StoryEventContent::TYPE,
                            stories::StoryUpdateEventContent::TYPE,
                            tasks::TaskListEventContent::TYPE,
                            tasks::TaskListUpdateEventContent::TYPE,
                            tasks::TaskEventContent::TYPE,
                            tasks::TaskUpdateEventContent::TYPE,
                            tasks::TaskSelfAssignEventContent::TYPE,
                            tasks::TaskSelfUnassignEventContent::TYPE,
                            comments::CommentEventContent::TYPE,
                            comments::CommentUpdateEventContent::TYPE,
                            attachments::AttachmentEventContent::TYPE,
                            attachments::AttachmentUpdateEventContent::TYPE,
                            rsvp::RsvpEventContent::TYPE,
                            read_receipt::ReadReceiptEventContent::TYPE,
                            reaction::ReactionEventContent::TYPE,
                            explicit_invites::ExplicitInviteEventContent::TYPE,
                        ],
                    ))
                }
            }
        }
    }
}

impl SyncEvent for SyncAnyActerEvent {
    const KIND: HandlerKind = HandlerKind::Timeline;
    const TYPE: Option<&'static str> = None;
}
