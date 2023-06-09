use acter_core::{
    events::{
        calendar::{self as calendar_events, CalendarEventBuilder},
        Icon,
    },
    models::{self, ActerModel, AnyActerModel, Color},
    statics::KEYS,
};
use anyhow::{bail, Context, Result};
use async_broadcast::Receiver;
use core::time::Duration;
use matrix_sdk::{
    room::{Joined, Room},
    ruma::{events::room::message::TextMessageEventContent, OwnedEventId, OwnedRoomId},
};
use std::collections::{hash_map::Entry, HashMap};

use super::{client::Client, spaces::Space, RUNTIME};

impl Client {
    pub async fn wait_for_calendar_event(
        &self,
        key: String,
        timeout: Option<Box<Duration>>,
    ) -> Result<CalendarEvent> {
        let AnyActerModel::CalendarEvent(inner) = self.wait_for(key.clone(), timeout).await.context("Couldn't wait calendar event")? else {
            bail!("{key} is not a calendar_event");
        };
        let room = self
            .core
            .client()
            .get_room(inner.room_id())
            .context("Room not found")?;
        Ok(CalendarEvent {
            client: self.clone(),
            room,
            inner,
        })
    }

    pub async fn calendar_events(&self) -> Result<Vec<CalendarEvent>> {
        let mut calendar_events = Vec::new();
        let mut rooms_map: HashMap<OwnedRoomId, Room> = HashMap::new();
        let client = self.clone();
        for mdl in self
            .store()
            .get_list(KEYS::CALENDAR)
            .await
            .context("Couldn't get list from store")?
        {
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
                tracing::warn!(
                    "Non calendar_event model found in `calendar_events` index: {:?}",
                    mdl
                );
            }
        }
        Ok(calendar_events)
    }
}

impl Space {
    pub async fn calendar_events(&self) -> Result<Vec<CalendarEvent>> {
        let mut calendar_events = Vec::new();
        let room_id = self.room_id();
        for mdl in self
            .client
            .store()
            .get_list(&format!("{room_id}::{}", KEYS::CALENDAR))
            .await
            .context("Couldn't get list from store")?
        {
            if let AnyActerModel::CalendarEvent(t) = mdl {
                calendar_events.push(CalendarEvent {
                    client: self.client.clone(),
                    room: self.room.clone(),
                    inner: t,
                })
            } else {
                tracing::warn!(
                    "Non calendar_event model found in `calendar_events` index: {:?}",
                    mdl
                );
            }
        }
        Ok(calendar_events)
    }
}

#[derive(Clone, Debug)]
pub struct CalendarEvent {
    client: Client,
    room: Room,
    inner: models::CalendarEvent,
}

impl std::ops::Deref for CalendarEvent {
    type Target = models::CalendarEvent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

/// helpers for inner
impl CalendarEvent {
    pub fn title(&self) -> String {
        self.inner.title.clone()
    }

    pub fn description_text(&self) -> Option<String> {
        self.inner.description.as_ref().map(|t| t.body.clone())
    }

    pub fn color(&self) -> Option<Color> {
        self.inner.color.clone()
    }

    pub fn icon(&self) -> Option<Icon> {
        self.inner.icon.clone()
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
                let AnyActerModel::CalendarEvent(inner) = client.store().get(&key).await.context("Couldn't get calendar event from store")? else {
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

    pub fn subscribe(&self) -> Receiver<()> {
        let key = self.inner.event_id().to_string();
        self.client.executor().subscribe(key)
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
        self.inner
            .description(Some(TextMessageEventContent::plain(body)));
        self
    }

    pub fn unset_description(&mut self) -> &mut Self {
        self.inner.description(None);
        self
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let inner = self
            .inner
            .build()
            .context("building failed in event content of calendar event")?;
        RUNTIME
            .spawn(async move {
                let resp = room
                    .send(inner, None)
                    .await
                    .context("Couldn't send calendart event draft")?;
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
        self.inner
            .description(Some(Some(TextMessageEventContent::plain(body))));
        self
    }

    pub fn unset_description(&mut self) -> &mut Self {
        self.inner.description(Some(None));
        self
    }

    pub fn description_update(&mut self) -> &mut Self {
        self.inner
            .description(None::<Option<TextMessageEventContent>>);
        self
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let inner = self
            .inner
            .build()
            .context("building failed in event content of calendar event update")?;
        RUNTIME
            .spawn(async move {
                let resp = room
                    .send(inner, None)
                    .await
                    .context("Couldn't send calendar event update")?;
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
