use acter_core::{
    events::rsvp::{RsvpBuilder, RsvpStatus},
    models::{self, ActerModel, AnyActerModel, Color},
};
use anyhow::{bail, Context, Result};
use core::time::Duration;
use futures::stream::StreamExt;
use matrix_sdk::{
    room::{Joined, Room},
    ruma::{events::room::message::TextMessageEventContent, OwnedEventId, OwnedUserId},
};
use std::{ops::Deref, str::FromStr};
use tokio::sync::broadcast::Receiver;
use tokio_stream::{wrappers::BroadcastStream, Stream};
use tracing::warn;

use super::{client::Client, RUNTIME};

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
    room: Joined,
    inner: RsvpBuilder,
}

impl RsvpDraft {
    pub fn status(&mut self, status: String) -> &mut Self {
        let Ok(s) = RsvpStatus::from_str(&status) else {
            unreachable!("Wrong status about RSVP")
        };
        self.inner.status(s);
        self
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let inner = self.inner.build()?;
        warn!("rsvp draft spawn");
        RUNTIME
            .spawn(async move {
                warn!("before sending rsvp");
                let resp = room.send(inner, None).await?;
                warn!("after sending rsvp");
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
                    .map(|entry| Rsvp {
                        client: client.clone(),
                        room: room.clone(),
                        inner: entry,
                    })
                    .collect();
                Ok(res)
            })
            .await?
    }

    pub fn rsvp_draft(&self) -> Result<RsvpDraft> {
        let Room::Joined(joined) = &self.room else {
            bail!("Can do RSVP in only joined rooms");
        };
        Ok(RsvpDraft {
            client: self.client.clone(),
            room: joined.clone(),
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
