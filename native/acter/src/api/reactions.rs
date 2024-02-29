use acter_core::models::{self, ActerModel, AnyActerModel};
use anyhow::{bail, Context, Result};
use futures::stream::StreamExt;
use matrix_sdk::room::Room;
use ruma_common::{EventId, OwnedEventId, OwnedTransactionId, OwnedUserId};
use ruma_events::{reaction::ReactionEventContent, relation::Annotation, MessageLikeEventType};
use std::ops::Deref;
use tokio::sync::broadcast::Receiver;
use tokio_stream::{wrappers::BroadcastStream, Stream};
use tracing::{info, trace};

use super::{client::Client, RUNTIME};

impl Client {
    pub async fn wait_for_reaction(&self, key: String, timeout: Option<u8>) -> Result<Reaction> {
        let client = self.clone();
        RUNTIME
            .spawn(async move {
                let AnyActerModel::Reaction(reaction) =
                    client.wait_for(key.clone(), timeout).await?
                else {
                    bail!("{key} is not a reaction");
                };
                let room = client
                    .core
                    .client()
                    .get_room(&reaction.meta.room_id)
                    .context("Room not found")?;
                Ok(Reaction {
                    client: client.clone(),
                    room,
                    inner: reaction,
                })
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct Reaction {
    client: Client,
    room: Room,
    inner: models::Reaction,
}

impl Deref for Reaction {
    type Target = models::Reaction;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl Reaction {
    pub fn event_id_str(&self) -> String {
        self.inner.event_id().to_string()
    }

    pub fn sender(&self) -> OwnedUserId {
        self.inner.meta.sender.clone()
    }

    pub fn origin_server_ts(&self) -> u64 {
        self.inner.meta.origin_server_ts.get().into()
    }

    pub fn relates_to(&self) -> String {
        self.inner.relates_to.event_id.to_string()
    }
}

#[derive(Clone, Debug)]
pub struct ReactionManager {
    client: Client,
    room: Room,
    inner: models::ReactionManager,
}

impl Deref for ReactionManager {
    type Target = models::ReactionManager;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl ReactionManager {
    pub(crate) async fn new(
        client: Client,
        room: Room,
        event_id: OwnedEventId,
    ) -> Result<ReactionManager> {
        RUNTIME
            .spawn(async move {
                let inner =
                    models::ReactionManager::from_store_and_event_id(client.store(), &event_id)
                        .await;
                Ok(ReactionManager {
                    client,
                    room,
                    inner,
                })
            })
            .await?
    }

    pub async fn reload(&self) -> Result<ReactionManager> {
        ReactionManager::new(
            self.client.clone(),
            self.room.clone(),
            self.inner.event_id(),
        )
        .await
    }

    pub async fn send_like(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let client = room.client();
        let my_id = client.user_id().context("User not found")?.to_owned();
        let event = self.inner.construct_like_event();

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::Reaction) {
                    bail!("No permission to send reaction in this room");
                }

                trace!("before sending like");
                let response = room.send(event).await?;

                trace!("after sending like");
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn send_reaction(&self, key: String) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let client = room.client();
        let my_id = client.user_id().context("User not found")?.to_owned();
        let event = self.inner.construct_reaction_event(key);

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::Reaction) {
                    bail!("No permission to send message in this room");
                }

                trace!("before sending reaction");
                let response = room.send(event).await?;

                trace!("after sending reaction");
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn redact_like(
        &self,
        reason: Option<String>,
        txn_id: Option<String>,
    ) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let stats = self.inner.stats();
        let Some(event_id) = stats.user_likes.last().cloned() else {
            bail!("User hasn't liked");
        };

        let txn_id = txn_id.map(OwnedTransactionId::from);

        RUNTIME
            .spawn(async move {
                trace!("before redacting like");
                let response = room.redact(&event_id, reason.as_deref(), txn_id).await?;
                trace!("after redacting like");
                Ok(response.event_id)
            })
            .await?
    }

    pub fn stats(&self) -> models::ReactionStats {
        self.inner.stats().clone()
    }

    pub fn likes_count(&self) -> u32 {
        self.inner.stats().total_like_reactions
    }

    pub fn liked_by_me(&self) -> bool {
        self.inner.stats().user_has_liked
    }

    pub fn reacted_by_me(&self) -> bool {
        self.inner.stats().user_has_reacted
    }

    pub fn has_reaction_entries(&self) -> bool {
        self.stats().has_reaction_entries
    }

    pub fn total_reaction_count(&self) -> u32 {
        self.stats().total_reaction_count
    }

    pub async fn reaction_entries(&self) -> Result<Vec<Reaction>> {
        let manager = self.inner.clone();
        let client = self.client.clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let res = manager
                    .reaction_entries()
                    .await?
                    .into_iter()
                    .map(|(user_id, inner)| Reaction {
                        client: client.clone(),
                        room: room.clone(),
                        inner,
                    })
                    .collect();
                Ok(res)
            })
            .await?
    }

    pub fn subscribe_stream(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.subscribe()).map(|f| true)
    }

    pub fn subscribe(&self) -> Receiver<()> {
        self.client.subscribe(self.inner.update_key())
    }
}
