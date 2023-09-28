use ruma_common::{events::OriginalMessageLikeEvent, EventId, RoomId, UserId};
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
        self.inner.description.clone().map(Into::into)
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

    pub fn key_from_event(event_id: &EventId) -> String {
        event_id.to_string()
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
}

impl ActerModel for CalendarEvent {
    fn indizes(&self) -> Vec<String> {
        vec![
            format!("{}::{}", self.meta.room_id, CALENDAR_KEY),
            CALENDAR_KEY.to_string(),
        ]
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }

    fn capabilities(&self) -> &[Capability] {
        &[Capability::Commentable]
    }

    async fn execute(self, store: &Store) -> Result<Vec<String>> {
        default_model_execute(store, self.into()).await
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        None
    }

    fn transition(&mut self, model: &AnyActerModel) -> Result<bool> {
        let AnyActerModel::CalendarEventUpdate(update) = model else {
            return Ok(false)
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
    fn indizes(&self) -> Vec<String> {
        vec![format!("{:}::history", self.inner.calendar_event.event_id)]
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }

    async fn execute(self, store: &Store) -> Result<Vec<String>> {
        default_model_execute(store, self.into()).await
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        None
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
            },
        }
    }
}
