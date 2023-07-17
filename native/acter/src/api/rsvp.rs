use acter_core::{
    events::rsvp::{RsvpEntryBuilder, RsvpStatus},
    models::{self, ActerModel, AnyActerModel, Color},
};
use anyhow::{bail, Context, Result};
use core::time::Duration;
use matrix_sdk::{
    room::{Joined, Room},
    ruma::{events::room::message::TextMessageEventContent, OwnedEventId, OwnedUserId},
};
use std::ops::Deref;
use tokio::sync::broadcast::Receiver;

use super::{client::Client, RUNTIME};

impl Client {
    pub async fn wait_for_rsvp(
        &self,
        key: String,
        timeout: Option<Box<Duration>>,
    ) -> Result<RsvpEntry> {
        let client = self.clone();
        RUNTIME
            .spawn(async move {
                let AnyActerModel::RsvpEntry(rsvp) = client.wait_for(key.clone(), timeout).await? else {
                    bail!("{key} is not a rsvp");
                };
                let room = client
                    .core
                    .client()
                    .get_room(&rsvp.meta.room_id)
                    .context("Room not found")?;
                Ok(RsvpEntry {
                    client: client.clone(),
                    room,
                    inner: rsvp,
                })
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct RsvpEntry {
    client: Client,
    room: Room,
    inner: models::RsvpEntry,
}

impl Deref for RsvpEntry {
    type Target = models::RsvpEntry;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl RsvpEntry {
    pub fn reply_draft(&self) -> Result<RsvpEntryDraft> {
        let Room::Joined(joined) = &self.room else {
            bail!("Can do RSVP in only joined rooms");
        };
        Ok(RsvpEntryDraft {
            client: self.client.clone(),
            room: joined.clone(),
            inner: self.inner.reply_builder(),
        })
    }

    pub fn sender(&self) -> OwnedUserId {
        self.inner.meta.sender.clone()
    }

    pub fn origin_server_ts(&self) -> u64 {
        self.inner.meta.origin_server_ts.get().into()
    }

    pub fn status(&self) -> String {
        match self.inner.status {
            RsvpStatus::Yes => "Yes".to_string(),
            RsvpStatus::No => "No".to_string(),
            RsvpStatus::Maybe => "Maybe".to_string(),
        }
    }
}

pub struct RsvpEntryDraft {
    client: Client,
    room: Joined,
    inner: RsvpEntryBuilder,
}

impl RsvpEntryDraft {
    pub fn status(&mut self, status: String) -> &mut Self {
        let s = match status.as_str() {
            "Yes" => RsvpStatus::Yes,
            "Maybe" => RsvpStatus::Maybe,
            "No" => RsvpStatus::No,
            _ => unreachable!("Wrong status about RSVP"),
        };
        self.inner.status(s);
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

    pub async fn entries(&self) -> Result<Vec<RsvpEntry>> {
        let manager = self.inner.clone();
        let client = self.client.clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let res = manager
                    .entries()
                    .await?
                    .into_iter()
                    .map(|entry| RsvpEntry {
                        client: client.clone(),
                        room: room.clone(),
                        inner: entry,
                    })
                    .collect();
                Ok(res)
            })
            .await?
    }

    pub fn rsvp_draft(&self) -> Result<RsvpEntryDraft> {
        let Room::Joined(joined) = &self.room else {
            bail!("Can do RSVP in only joined rooms");
        };
        Ok(RsvpEntryDraft {
            client: self.client.clone(),
            room: joined.clone(),
            inner: self.inner.draft_builder(),
        })
    }

    pub fn subscribe(&self) -> Receiver<()> {
        let key = self.inner.event_id().to_string();
        self.client.executor().subscribe(key)
    }
}
