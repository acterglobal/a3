use acter_core::{
    events::{
        calendar::{self as calendar_events, CalendarEventBuilder},
        Icon, UtcDateTime,
    },
    models::{self, ActerModel, AnyActerModel, Color},
    statics::KEYS,
};
use anyhow::{bail, Context, Result};
use chrono::DateTime;
use core::time::Duration;
use futures::stream::StreamExt;
use matrix_sdk::{
    room::{Joined, Room},
    ruma::{events::room::message::TextMessageEventContent, OwnedEventId, OwnedRoomId},
};
use std::{
    collections::{hash_map::Entry, HashMap},
    ops::Deref,
};
use tokio::sync::broadcast::Receiver;
use tracing::warn;

use super::{client::Client, spaces::Space, RUNTIME};

impl Client {
    pub async fn wait_for_calendar_event(
        &self,
        key: String,
        timeout: Option<Box<Duration>>,
    ) -> Result<CalendarEvent> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let AnyActerModel::CalendarEvent(inner) = me.wait_for(key.clone(), timeout).await? else {
                    bail!("{key} is not a calendar_event");
                };
                let room = me
                    .core
                    .client()
                    .get_room(inner.room_id())
                    .context("Room not found")?;
                Ok(CalendarEvent {
                    client: me.clone(),
                    room,
                    inner,
                })
            })
            .await?
    }

    pub async fn calendar_event(&self, calendar_id: String) -> Result<CalendarEvent> {
        let client = self.clone();
        RUNTIME
            .spawn(async move {
                let AnyActerModel::CalendarEvent(inner) = client.store().get(&calendar_id).await? else {
                    bail!("Calendar event not found");
                };
                let room = client
                    .get_room(inner.room_id())
                    .context("Room of calendar event not found")?;
                Ok(CalendarEvent {
                    client,
                    room,
                    inner,
                })
            })
            .await?
    }

    pub async fn calendar_events(&self) -> Result<Vec<CalendarEvent>> {
        let mut calendar_events = Vec::new();
        let mut rooms_map: HashMap<OwnedRoomId, Room> = HashMap::new();
        let client = self.clone();
        RUNTIME
            .spawn(async move {
                for mdl in client.store().get_list(KEYS::CALENDAR).await? {
                    if let AnyActerModel::CalendarEvent(t) = mdl {
                        let room_id = t.room_id().to_owned();
                        let room = match rooms_map.entry(room_id) {
                            Entry::Occupied(t) => t.get().clone(),
                            Entry::Vacant(e) => {
                                if let Some(room) = client.get_room(e.key()) {
                                    e.insert(room.clone());
                                    room
                                } else {
                                    /// User not part of the room anymore, ignore
                                    continue;
                                }
                            }
                        };
                        calendar_events.push(CalendarEvent {
                            client: client.clone(),
                            room,
                            inner: t,
                        })
                    } else {
                        warn!(
                            "Non calendar_event model found in `calendar_events` index: {:?}",
                            mdl
                        );
                    }
                }
                Ok(calendar_events)
            })
            .await?
    }
}

impl Space {
    pub async fn calendar_events(&self) -> Result<Vec<CalendarEvent>> {
        let client = self.client.clone();
        let mut calendar_events = Vec::new();
        let room = self.room.clone();
        let room_id = self.room_id().to_owned();
        RUNTIME
            .spawn(async move {
                let k = format!("{room_id}::{}", KEYS::CALENDAR);
                for mdl in client.store().get_list(&k).await? {
                    if let AnyActerModel::CalendarEvent(inner) = mdl {
                        calendar_events.push(CalendarEvent {
                            client: client.clone(),
                            room: room.clone(),
                            inner,
                        })
                    } else {
                        warn!(
                            "Non calendar_event model found in `calendar_events` index: {:?}",
                            mdl
                        );
                    }
                }
                Ok(calendar_events)
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct CalendarEvent {
    client: Client,
    room: Room,
    inner: models::CalendarEvent,
}

impl Deref for CalendarEvent {
    type Target = models::CalendarEvent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

/// helpers for inner
impl CalendarEvent {
    pub fn event_id(&self) -> OwnedEventId {
        self.inner.event_id().to_owned()
    }
}

/// Custom functions
impl CalendarEvent {
    pub async fn refresh(&self) -> Result<CalendarEvent> {
        let key = self.inner.event_id().to_string();
        let client = self.client.clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let AnyActerModel::CalendarEvent(inner) = client.store().get(&key).await? else {
                    bail!("Refreshing failed. {key} not a calendar_event")
                };
                Ok(CalendarEvent {
                    client,
                    room,
                    inner,
                })
            })
            .await?
    }

    pub fn update_builder(&self) -> Result<CalendarEventUpdateBuilder> {
        let Room::Joined(joined) = &self.room else {
            bail!("Can only update calendar_events in joined rooms");
        };
        Ok(CalendarEventUpdateBuilder {
            client: self.client.clone(),
            room: joined.clone(),
            inner: self.inner.updater(),
        })
    }

    pub fn subscribe_stream(&self) -> impl tokio_stream::Stream<Item = ()> {
        tokio_stream::wrappers::BroadcastStream::new(self.subscribe())
            .map(|f| f.unwrap_or_default())
    }

    pub fn subscribe(&self) -> tokio::sync::broadcast::Receiver<()> {
        let key = self.inner.event_id().to_string();
        self.client.subscribe(key)
    }

    pub async fn comments(&self) -> Result<crate::CommentsManager> {
        let client = self.client.clone();
        let room = self.room.clone();
        let event_id = self.inner.event_id().to_owned();

        RUNTIME
            .spawn(async move {
                let inner =
                    models::CommentsManager::from_store_and_event_id(client.store(), &event_id)
                        .await;
                Ok(crate::CommentsManager::new(client, room, inner))
            })
            .await?
    }

    pub async fn rsvp_manager(&self) -> Result<crate::RsvpManager> {
        let client = self.client.clone();
        let room = self.room.clone();
        let event_id = self.inner.event_id().to_owned();

        RUNTIME
            .spawn(async move {
                let inner =
                    models::RsvpManager::from_store_and_event_id(client.store(), &event_id).await;
                Ok(crate::RsvpManager::new(client, room, inner))
            })
            .await?
    }
}

#[derive(Clone)]
pub struct CalendarEventDraft {
    client: Client,
    room: Joined,
    inner: CalendarEventBuilder,
}

impl CalendarEventDraft {
    pub fn title(&mut self, title: String) -> &mut Self {
        self.inner.title(title);
        self
    }

    pub fn description_text(&mut self, body: String) -> &mut Self {
        let desc = TextMessageEventContent::plain(body);
        self.inner.description(Some(desc));
        self
    }

    pub fn unset_description(&mut self) -> &mut Self {
        self.inner.description(None);
        self
    }

    pub fn utc_start_from_rfc3339(&mut self, utc_start: String) -> Result<()> {
        let dt: UtcDateTime = DateTime::parse_from_rfc3339(&utc_start)?.into();
        self.inner.utc_start(dt);
        Ok(())
    }

    pub fn utc_start_from_rfc2822(&mut self, utc_start: String) -> Result<()> {
        let dt: UtcDateTime = DateTime::parse_from_rfc2822(&utc_start)?.into();
        self.inner.utc_start(dt);
        Ok(())
    }

    pub fn utc_start_from_format(&mut self, utc_start: String, format: String) -> Result<()> {
        let dt: UtcDateTime = DateTime::parse_from_str(&utc_start, &format)?.into();
        self.inner.utc_start(dt);
        Ok(())
    }

    pub fn utc_end_from_rfc3339(&mut self, utc_end: String) -> Result<()> {
        let dt: UtcDateTime = DateTime::parse_from_rfc3339(&utc_end)?.into();
        self.inner.utc_end(dt);
        Ok(())
    }

    pub fn utc_end_from_rfc2822(&mut self, utc_end: String) -> Result<()> {
        let dt: UtcDateTime = DateTime::parse_from_rfc2822(&utc_end)?.into();
        self.inner.utc_end(dt);
        Ok(())
    }

    pub fn utc_end_from_format(&mut self, utc_end: String, format: String) -> Result<()> {
        let dt: UtcDateTime = DateTime::parse_from_str(&utc_end, &format)?.into();
        self.inner.utc_end(dt);
        Ok(())
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let inner = self.inner.build()?;
        RUNTIME
            .spawn(async move {
                let resp = room.send(inner, None).await?;
                Ok(resp.event_id)
            })
            .await?
    }
}

#[derive(Clone)]
pub struct CalendarEventUpdateBuilder {
    client: Client,
    room: Joined,
    inner: calendar_events::CalendarEventUpdateBuilder,
}

impl CalendarEventUpdateBuilder {
    pub fn title(&mut self, title: String) -> &mut Self {
        self.inner.title(Some(title));
        self
    }

    pub fn unset_title_update(&mut self) -> &mut Self {
        self.inner.title(None);
        self
    }

    pub fn description_text(&mut self, body: String) -> &mut Self {
        let desc = TextMessageEventContent::plain(body);
        self.inner.description(Some(Some(desc)));
        self
    }

    pub fn unset_description(&mut self) -> &mut Self {
        self.inner.description(Some(None));
        self
    }

    pub fn unset_description_update(&mut self) -> &mut Self {
        self.inner
            .description(None::<Option<TextMessageEventContent>>);
        self
    }

    pub fn utc_start_from_rfc3339(&mut self, utc_start: String) -> Result<()> {
        let dt = DateTime::parse_from_rfc3339(&utc_start)?.into();
        self.inner.utc_start(Some(dt));
        Ok(())
    }

    pub fn utc_start_from_rfc2822(&mut self, utc_start: String) -> Result<()> {
        let dt = DateTime::parse_from_rfc2822(&utc_start)?.into();
        self.inner.utc_start(Some(dt));
        Ok(())
    }

    pub fn utc_start_from_format(&mut self, utc_start: String, format: String) -> Result<()> {
        let dt = DateTime::parse_from_str(&utc_start, &format)?.into();
        self.inner.utc_start(Some(dt));
        Ok(())
    }

    pub fn unset_utc_start_update(&mut self) -> &mut Self {
        self.inner.utc_start(None);
        self
    }

    pub fn utc_end_from_rfc3339(&mut self, utc_end: String) -> Result<()> {
        let dt = DateTime::parse_from_rfc3339(&utc_end)?.into();
        self.inner.utc_end(Some(dt));
        Ok(())
    }

    pub fn utc_end_from_rfc2822(&mut self, utc_end: String) -> Result<()> {
        let dt = DateTime::parse_from_rfc2822(&utc_end)?.into();
        self.inner.utc_end(Some(dt));
        Ok(())
    }

    pub fn utc_end_from_format(&mut self, utc_end: String, format: String) -> Result<()> {
        let dt = DateTime::parse_from_str(&utc_end, &format)?.into();
        self.inner.utc_end(Some(dt));
        Ok(())
    }

    pub fn unset_utc_end_update(&mut self) -> &mut Self {
        self.inner.utc_end(None);
        self
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let inner = self.inner.build()?;
        RUNTIME
            .spawn(async move {
                let resp = room.send(inner, None).await?;
                Ok(resp.event_id)
            })
            .await?
    }
}

impl Space {
    pub fn calendar_event_draft(&self) -> Result<CalendarEventDraft> {
        let Room::Joined(joined) = &self.inner.room else {
            bail!("You can't create calendar_events for spaces we are not part on")
        };
        Ok(CalendarEventDraft {
            client: self.client.clone(),
            room: joined.clone(),
            inner: Default::default(),
        })
    }

    pub fn calendar_event_draft_with_builder(
        &self,
        inner: CalendarEventBuilder,
    ) -> Result<CalendarEventDraft> {
        let Room::Joined(joined) = &self.inner.room else {
            bail!("You can't create calendar_events for spaces we are not part on")
        };
        Ok(CalendarEventDraft {
            client: self.client.clone(),
            room: joined.clone(),
            inner,
        })
    }
}
