pub use acter_core::events::rsvp::RsvpStatus;
use acter_core::{
    events::rsvp::RsvpBuilder,
    models::{self, ActerModel, AnyActerModel},
    referencing::{IndexKey, SectionIndex},
};
use anyhow::{bail, Result};
use core::time::Duration;
use futures::stream::StreamExt;
use matrix_sdk::room::Room;
use matrix_sdk_base::{
    ruma::{events::MessageLikeEventType, OwnedEventId, OwnedUserId},
    RoomState,
};
use std::{ops::Deref, str::FromStr};
use tokio::sync::broadcast::Receiver;
use tokio_stream::{wrappers::BroadcastStream, Stream};
use tracing::{error, warn};

use super::{calendar_events::CalendarEvent, client::Client, common::OptionRsvpStatus, RUNTIME};

impl Client {
    pub async fn wait_for_rsvp(&self, key: String, timeout: Option<u8>) -> Result<Rsvp> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let AnyActerModel::Rsvp(rsvp) = me.wait_for(key.clone(), timeout).await? else {
                    bail!("{key} is not a rsvp");
                };
                let room = me.room_by_id_typed(&rsvp.meta.room_id)?;
                Ok(Rsvp {
                    client: me.clone(),
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
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let mut cal_events = vec![];
                for mdl in me
                    .store()
                    .get_list(&IndexKey::Section(SectionIndex::Calendar))
                    .await?
                {
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
                        let room = me.room_by_id_typed(inner.room_id())?;
                        let cal_event = CalendarEvent::new(me.clone(), room, inner);
                        cal_events.push(cal_event);
                    } else {
                        warn!(
                            "Non calendar_event model found in `calendar_events` index: {:?}",
                            mdl
                        );
                    }
                }
                cal_events.sort();
                Ok(cal_events)
            })
            .await?
    }

    pub async fn my_upcoming_events(
        &self,
        secs_from_now: Option<u32>,
    ) -> Result<Vec<CalendarEvent>> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let mut cal_events = vec![];
                for mdl in me
                    .store()
                    .get_list(&IndexKey::Section(SectionIndex::Calendar))
                    .await?
                {
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
                        let room = me.room_by_id_typed(inner.room_id())?;
                        let cal_event = CalendarEvent::new(me.clone(), room, inner);
                        // fliter only events that i sent rsvp
                        let rsvp_manager = cal_event.rsvps().await?;
                        let status = rsvp_manager.responded_by_me().await?;
                        match status.status() {
                            Some(RsvpStatus::Yes) | Some(RsvpStatus::Maybe) => {
                                cal_events.push(cal_event);
                            }
                            _ => {}
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
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let mut cal_events = vec![];
                for mdl in me
                    .store()
                    .get_list(&IndexKey::Section(SectionIndex::Calendar))
                    .await?
                {
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
                        let room = me.room_by_id_typed(inner.room_id())?;
                        let cal_event = CalendarEvent::new(me.clone(), room, inner);
                        // fliter only events that i sent rsvp
                        let rsvp_manager = cal_event.rsvps().await?;
                        let status = rsvp_manager.responded_by_me().await?;
                        match status.status() {
                            Some(RsvpStatus::Yes) | Some(RsvpStatus::Maybe) => {
                                cal_events.push(cal_event);
                            }
                            _ => {}
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
        let my_id = self.client.user_id()?;
        let inner = self.inner.build()?;

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::RoomMessage)
                    .await?;
                if !permitted {
                    bail!("No permissions to send message in this room");
                }
                let response = room.send(inner).await?;
                Ok(response.event_id)
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
    pub(crate) async fn new(
        client: Client,
        room: Room,
        event_id: OwnedEventId,
    ) -> Result<RsvpManager> {
        RUNTIME
            .spawn(async move {
                let inner =
                    models::RsvpManager::from_store_and_event_id(client.store(), &event_id).await;
                Ok(RsvpManager {
                    client,
                    room,
                    inner,
                })
            })
            .await?
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

    pub async fn responded_by_me(&self) -> Result<OptionRsvpStatus> {
        let manager = self.inner.clone();
        let my_id = self.client.user_id()?;
        RUNTIME
            .spawn(async move {
                let entries = manager.rsvp_entries().await?;
                let status = entries.get(&my_id).map(|x| x.status.clone());
                Ok(OptionRsvpStatus::new(status))
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
        self.users_at_status_typed(RsvpStatus::from_str(&status)?)
            .await
    }

    // ***_typed fn accepts rust-typed input, not string-based one
    pub(crate) async fn users_at_status_typed(
        &self,
        status: RsvpStatus,
    ) -> Result<Vec<OwnedUserId>> {
        let manager = self.inner.clone();
        RUNTIME
            .spawn(async move {
                let mut senders = vec![];
                let entries = manager.rsvp_entries().await?;
                for (user_id, entry) in entries {
                    if entry.status == status {
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

    pub fn subscribe_stream(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.subscribe()).map(|f| true)
    }

    pub fn subscribe(&self) -> Receiver<()> {
        let key = models::Rsvp::index_for(self.inner.event_id().to_owned());
        self.client.subscribe(key)
    }
}
