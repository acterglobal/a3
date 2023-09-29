use acter_core::{
    events::rsvp::{RsvpBuilder, RsvpStatus},
    models::{self, ActerModel, AnyActerModel, Color},
    statics::KEYS,
};
use anyhow::{bail, Context, Result};
use core::time::Duration;
use futures::stream::StreamExt;
use matrix_sdk::{room::Room, RoomState};
use ruma_common::{
    events::{room::message::TextMessageEventContent, MessageLikeEventType},
    OwnedEventId, OwnedUserId,
};
use std::{ops::Deref, str::FromStr};
use tokio::sync::broadcast::Receiver;
use tokio_stream::{wrappers::BroadcastStream, Stream};
use tracing::{error, trace, warn};

use super::{calendar_events::CalendarEvent, client::Client, common::OptionString, RUNTIME};

impl Client {
    pub async fn wait_for_rsvp(&self, key: String, timeout: Option<Box<Duration>>) -> Result<Rsvp> {
        let client = self.clone();
        RUNTIME
            .spawn(async move {
                let AnyActerModel::Rsvp(rsvp) = client.wait_for(key.clone(), timeout).await? else {
                    bail!("{key} is not a rsvp");
                };
                let room = client
                    .core
                    .client()
                    .get_room(&rsvp.meta.room_id)
                    .context("Room not found")?;
                Ok(Rsvp {
                    client: client.clone(),
                    room,
                    inner: rsvp,
                })
            })
            .await?
    }

    pub async fn all_upcoming_events(
        &self,
        secs_from_now: Option<u32>,
    ) -> Result<Vec<CalendarEvent>> {
        let client = self.clone();
        RUNTIME
            .spawn(async move {
                let mut cal_events = vec![];
                for mdl in client.store().get_list(KEYS::CALENDAR).await? {
                    if let AnyActerModel::CalendarEvent(inner) = mdl {
                        let now = chrono::Utc::now();
                        let start_time = inner.utc_start();
                        if now > start_time {
                            // skip past events
                            continue;
                        }
                        if let Some(secs) = secs_from_now {
                            if start_time > now + chrono::Duration::seconds(secs as i64) {
                                // skip too far events
                                continue;
                            }
                        }
                        let room = client
                            .get_room(inner.room_id())
                            .context("Room of calendar event not found")?;
                        let cal_event = CalendarEvent::new(client.clone(), room, inner);
                        cal_events.push(cal_event);
                    } else {
                        warn!(
                            "Non calendar_event model found in `calendar_events` index: {:?}",
                            mdl
                        );
                    }
                }
                Ok(cal_events)
            })
            .await?
    }

    pub async fn my_upcoming_events(
        &self,
        secs_from_now: Option<u32>,
    ) -> Result<Vec<CalendarEvent>> {
        let client = self.clone();
        RUNTIME
            .spawn(async move {
                let mut cal_events = vec![];
                for mdl in client.store().get_list(KEYS::CALENDAR).await? {
                    if let AnyActerModel::CalendarEvent(inner) = mdl {
                        let now = chrono::Utc::now();
                        let start_time = inner.utc_start();
                        if now > start_time {
                            // skip past events
                            continue;
                        }
                        if let Some(secs) = secs_from_now {
                            if start_time > now + chrono::Duration::seconds(secs as i64) {
                                // skip too far events
                                continue;
                            }
                        }
                        let room = client
                            .get_room(inner.room_id())
                            .context("Room of calendar event not found")?;
                        let cal_event = CalendarEvent::new(client.clone(), room, inner);
                        // fliter only events that i sent rsvp
                        let rsvp_manager = cal_event.rsvp_manager().await?;
                        let status = rsvp_manager.my_status().await?;
                        if let Some(status) = status.text() {
                            match status.as_str() {
                                "Yes" | "Maybe" => {
                                    cal_events.push(cal_event);
                                }
                                _ => {}
                            }
                        }
                    } else {
                        warn!(
                            "Non calendar_event model found in `calendar_events` index: {:?}",
                            mdl
                        );
                    }
                }
                Ok(cal_events)
            })
            .await?
    }

    pub async fn my_past_events(&self, secs_from_now: Option<u32>) -> Result<Vec<CalendarEvent>> {
        let client = self.clone();
        RUNTIME
            .spawn(async move {
                let mut cal_events = vec![];
                for mdl in client.store().get_list(KEYS::CALENDAR).await? {
                    if let AnyActerModel::CalendarEvent(inner) = mdl {
                        let now = chrono::Utc::now();
                        let start_time = inner.utc_start();
                        if start_time > now {
                            // skip upcoming events
                            continue;
                        }
                        if let Some(secs) = secs_from_now {
                            if start_time < now - chrono::Duration::seconds(secs as i64) {
                                // skip too far events
                                continue;
                            }
                        }
                        let room = client
                            .get_room(inner.room_id())
                            .context("Room of calendar event not found")?;
                        let cal_event = CalendarEvent::new(client.clone(), room, inner);
                        // fliter only events that i sent rsvp
                        let rsvp_manager = cal_event.rsvp_manager().await?;
                        let status = rsvp_manager.my_status().await?;
                        if let Some(status) = status.text() {
                            match status.as_str() {
                                "Yes" | "Maybe" => {
                                    cal_events.push(cal_event);
                                }
                                _ => {}
                            }
                        }
                    } else {
                        warn!(
                            "Non calendar_event model found in `calendar_events` index: {:?}",
                            mdl
                        );
                    }
                }
                Ok(cal_events)
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct Rsvp {
    client: Client,
    room: Room,
    inner: models::Rsvp,
}

impl Deref for Rsvp {
    type Target = models::Rsvp;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl Rsvp {
    pub fn sender(&self) -> OwnedUserId {
        self.inner.meta.sender.clone()
    }

    pub fn origin_server_ts(&self) -> u64 {
        self.inner.meta.origin_server_ts.get().into()
    }

    pub fn status(&self) -> String {
        self.inner.status.to_string()
    }
}

pub struct RsvpDraft {
    client: Client,
    room: Room,
    inner: RsvpBuilder,
}

impl RsvpDraft {
    pub fn status(&mut self, status: String) -> &mut Self {
        if let Ok(s) = RsvpStatus::from_str(&status) {
            self.inner.status(s);
        } else {
            error!("Wrong status about RSVP");
        }
        self
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let inner = self.inner.build()?;
        trace!("rsvp draft spawn");

        let client = room.client();
        let my_id = client.user_id().context("User not found")?.to_owned();

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }

                trace!("before sending rsvp");
                let resp = room.send(inner, None).await?;
                trace!("after sending rsvp");
                Ok(resp.event_id)
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct RsvpManager {
    client: Client,
    room: Room,
    inner: models::RsvpManager,
}

impl Deref for RsvpManager {
    type Target = models::RsvpManager;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl RsvpManager {
    pub(crate) fn new(client: Client, room: Room, inner: models::RsvpManager) -> RsvpManager {
        RsvpManager {
            client,
            room,
            inner,
        }
    }

    pub fn stats(&self) -> models::RsvpStats {
        self.inner.stats().clone()
    }

    pub fn has_rsvp_entries(&self) -> bool {
        *self.stats().has_rsvp_entries()
    }

    pub fn total_rsvp_count(&self) -> u32 {
        *self.stats().total_rsvp_count()
    }

    pub async fn rsvp_entries(&self) -> Result<Vec<Rsvp>> {
        let manager = self.inner.clone();
        let client = self.client.clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let res = manager
                    .rsvp_entries()
                    .await?
                    .into_iter()
                    .map(|(user_id, inner)| Rsvp {
                        client: client.clone(),
                        room: room.clone(),
                        inner,
                    })
                    .collect();
                Ok(res)
            })
            .await?
    }

    pub async fn my_status(&self) -> Result<OptionString> {
        let manager = self.inner.clone();
        let my_id = self.client.user_id().context("User not found")?;
        RUNTIME
            .spawn(async move {
                let entries = manager.rsvp_entries().await?;
                if let Some(entry) = entries.get(&my_id) {
                    let status = entry.status.to_string();
                    return Ok(OptionString::new(Some(status)));
                }
                Ok(OptionString::new(None))
            })
            .await?
    }

    pub async fn count_at_status(&self, status: String) -> Result<u32> {
        let manager = self.inner.clone();
        RUNTIME
            .spawn(async move {
                let mut count = 0;
                let entries = manager.rsvp_entries().await?;
                for (user_id, entry) in entries {
                    if entry.status.to_string() == status {
                        count += 1;
                    }
                }
                Ok(count)
            })
            .await?
    }

    pub async fn users_at_status(&self, status: String) -> Result<Vec<OwnedUserId>> {
        let manager = self.inner.clone();
        RUNTIME
            .spawn(async move {
                let mut senders = vec![];
                let entries = manager.rsvp_entries().await?;
                for (user_id, entry) in entries {
                    if entry.status.to_string() == status {
                        senders.push(user_id);
                    }
                }
                Ok(senders)
            })
            .await?
    }

    fn is_joined(&self) -> bool {
        matches!(self.room.state(), RoomState::Joined)
    }

    pub fn rsvp_draft(&self) -> Result<RsvpDraft> {
        if !self.is_joined() {
            bail!("Can do RSVP in only joined rooms");
        }
        Ok(RsvpDraft {
            client: self.client.clone(),
            room: self.room.clone(),
            inner: self.inner.draft_builder(),
        })
    }

    pub fn subscribe_stream(&self) -> impl Stream<Item = ()> {
        BroadcastStream::new(self.subscribe()).map(|f| f.unwrap_or_default())
    }

    pub fn subscribe(&self) -> Receiver<()> {
        let key = models::Rsvp::index_for(&self.inner.event_id());
        self.client.subscribe(key)
    }
}
