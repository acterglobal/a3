use acter_matrix::models::{self, ActerModel, AnyActerModel};
use anyhow::{bail, Result};
use futures::stream::StreamExt;
use matrix_sdk::room::Room;
use matrix_sdk_base::ruma::{
    events::MessageLikeEventType, OwnedEventId, OwnedTransactionId, OwnedUserId, UserId,
};
use std::ops::Deref;
use tokio::sync::broadcast::Receiver;
use tokio_stream::{wrappers::BroadcastStream, Stream};

use super::{client::Client, RUNTIME};

impl Client {
    pub async fn wait_for_reaction(&self, key: String, timeout: Option<u8>) -> Result<Reaction> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let AnyActerModel::Reaction(reaction) = me.wait_for(key.clone(), timeout).await?
                else {
                    bail!("{key} is not a reaction");
                };
                let room = me.room_by_id_typed(&reaction.meta.room_id)?;
                Ok(Reaction {
                    client: me.clone(),
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
        let my_id = self.client.user_id()?;
        let event = self.inner.construct_like_event();

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::Reaction)
                    .await?;
                if !permitted {
                    bail!("No permission to send reaction in this room");
                }
                let response = room.send(event).await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn send_reaction(&self, key: String) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let my_id = self.client.user_id()?;
        let event = self.inner.construct_reaction_event(key);

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::Reaction)
                    .await?;
                if !permitted {
                    bail!("No permission to send reaction in this room");
                }
                let response = room.send(event).await?;
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
        let my_id = self.client.user_id()?;
        let stats = self.inner.stats();
        let Some(event_id) = stats.user_likes.last().cloned() else {
            bail!("User hasn’t liked")
        };
        let txn_id = txn_id.map(OwnedTransactionId::from);

        RUNTIME
            .spawn(async move {
                let evt = room.event(&event_id, None).await?;
                let Some(sender) = evt.kind.raw().get_field::<OwnedUserId>("sender")? else {
                    bail!("Could not determine the sender of the previous event");
                };
                let permitted = if sender == my_id {
                    room.can_user_redact_own(&my_id).await?
                } else {
                    room.can_user_redact_other(&my_id).await?
                };
                if !permitted {
                    bail!("No permission to redact this reaction");
                }
                let response = room.redact(&event_id, reason.as_deref(), txn_id).await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn redact_reaction(
        &self,
        sender_id: String,
        key: String,
        reason: Option<String>,
        txn_id: Option<String>,
    ) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let my_id = self.client.user_id()?;
        let sender_id = UserId::parse(sender_id)?;
        let inner = self.inner.clone();
        let txn_id = txn_id.map(OwnedTransactionId::from);

        RUNTIME
            .spawn(async move {
                let permitted = if sender_id == my_id {
                    room.can_user_redact_own(&my_id).await?
                } else {
                    room.can_user_redact_other(&my_id).await?
                };
                if !permitted {
                    bail!("No permission to redact this reaction");
                }
                for (user_id, reaction) in inner.reaction_entries().await? {
                    if user_id == sender_id && reaction.relates_to.key == key {
                        let response = room
                            .redact(reaction.event_id(), reason.as_deref(), txn_id)
                            .await?;
                        return Ok(response.event_id);
                    }
                }
                bail!("User hasn’t reacted")
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
