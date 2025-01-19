use icalendar::{Component, Event as iCalEvent, EventLike};
use matrix_sdk_base::ruma::{events::OriginalMessageLikeEvent, RoomId, UserId};
use serde::{Deserialize, Serialize};
use std::ops::Deref;

use super::{
    super::{
        default_model_execute, ActerModel, AnyActerModel, Capability, EventMeta, Store,
        TextMessageContent,
    },
    CALENDAR_KEY,
};
use crate::{
    events::{
        calendar::{
            CalendarEventEventContent, CalendarEventUpdateBuilder, CalendarEventUpdateEventContent,
        },
        UtcDateTime,
    },
    Result,
};

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct CalendarEvent {
    inner: CalendarEventEventContent,
    meta: EventMeta,
}
impl Deref for CalendarEvent {
    type Target = CalendarEventEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl CalendarEvent {
    pub fn title(&self) -> String {
        self.inner.title.clone()
    }

    pub fn description(&self) -> Option<TextMessageContent> {
        self.inner.description.clone().map(TextMessageContent::from)
    }

    pub fn room_id(&self) -> &RoomId {
        &self.meta.room_id
    }

    pub fn sender(&self) -> &UserId {
        &self.meta.sender
    }

    pub fn updater(&self) -> CalendarEventUpdateBuilder {
        CalendarEventUpdateBuilder::default()
            .calendar_event(self.meta.event_id.clone())
            .to_owned()
    }

    pub fn utc_end(&self) -> UtcDateTime {
        self.inner.utc_end
    }

    pub fn utc_start(&self) -> UtcDateTime {
        self.inner.utc_start
    }

    pub fn show_without_time(&self) -> bool {
        self.inner.show_without_time
    }

    pub fn as_ical_event(&self) -> iCalEvent {
        let mut cal_e_builder = iCalEvent::new();

        cal_e_builder
            .summary(&self.inner.title)
            .starts(self.inner.utc_start)
            .ends(self.inner.utc_end)
            .class(icalendar::Class::Private);
        if let Some(msg) = &self.inner.description {
            if let Some(formatted) = &msg.formatted {
                return cal_e_builder.description(&formatted.body).done();
            } else {
                return cal_e_builder.description(&msg.body).done();
            }
        }
        cal_e_builder.done()
    }
}

impl ActerModel for CalendarEvent {
    fn indizes(&self, _user_id: &UserId) -> Vec<String> {
        vec![
            format!("{}::{}", self.meta.room_id, CALENDAR_KEY),
            CALENDAR_KEY.to_string(),
        ]
    }

    fn event_meta(&self) -> &EventMeta {
        &self.meta
    }

    fn capabilities(&self) -> &[Capability] {
        &[
            Capability::Commentable,
            Capability::Reactable,
            Capability::Attachmentable,
        ]
    }

    async fn execute(self, store: &Store) -> Result<Vec<String>> {
        default_model_execute(store, self.into()).await
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        None
    }

    fn transition(&mut self, model: &AnyActerModel) -> Result<bool> {
        let AnyActerModel::CalendarEventUpdate(update) = model else {
            return Ok(false);
        };

        // FIXME: redacting a CalendarEventUpdate would mean reverting to the previous
        //        state. That is currently not that easy...

        update.apply(&mut self.inner)
    }
}

impl From<OriginalMessageLikeEvent<CalendarEventEventContent>> for CalendarEvent {
    fn from(outer: OriginalMessageLikeEvent<CalendarEventEventContent>) -> Self {
        let OriginalMessageLikeEvent {
            content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = outer;
        CalendarEvent {
            inner: content,
            meta: EventMeta {
                room_id,
                event_id,
                sender,
                origin_server_ts,
                redacted: None,
            },
        }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct CalendarEventUpdate {
    inner: CalendarEventUpdateEventContent,
    meta: EventMeta,
}

impl ActerModel for CalendarEventUpdate {
    fn indizes(&self, _user_id: &UserId) -> Vec<String> {
        vec![format!("{:}::history", self.inner.calendar_event.event_id)]
    }

    fn event_meta(&self) -> &EventMeta {
        &self.meta
    }

    async fn execute(self, store: &Store) -> Result<Vec<String>> {
        default_model_execute(store, self.into()).await
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(vec![self.inner.calendar_event.event_id.to_string()])
    }
}

impl Deref for CalendarEventUpdate {
    type Target = CalendarEventUpdateEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl From<OriginalMessageLikeEvent<CalendarEventUpdateEventContent>> for CalendarEventUpdate {
    fn from(outer: OriginalMessageLikeEvent<CalendarEventUpdateEventContent>) -> Self {
        let OriginalMessageLikeEvent {
            content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = outer;
        CalendarEventUpdate {
            inner: content,
            meta: EventMeta {
                room_id,
                event_id,
                sender,
                origin_server_ts,
                redacted: None,
            },
        }
    }
}
