use acter_core::{events::explicit_invites::ExplicitInviteEventContent, models};
use futures::{Stream, StreamExt};
use matrix_sdk::ruma::{OwnedEventId, OwnedUserId};
use ruma::UserId;
use tokio::sync::broadcast::Receiver;
use tokio_stream::wrappers::BroadcastStream;

use crate::{Client, MsgContent, RUNTIME};
use anyhow::Result;
use matrix_sdk::Room;
use std::ops::Deref;

#[derive(Clone, Debug)]
pub struct ObjectInvitationsManager {
    client: Client,
    room: Room,
    inner: models::InvitationsManager,
}

impl Deref for ObjectInvitationsManager {
    type Target = models::InvitationsManager;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl ObjectInvitationsManager {
    pub fn is_invited(&self) -> bool {
        let Ok(user_id) = self.client.user_id() else {
            return false;
        };
        self.inner.invited().contains(&user_id)
    }

    /// whether
    pub fn can_invite(&self, user_id: String) -> Result<bool> {
        let user_id = UserId::parse(user_id)?;
        Ok(!self.inner.accepted().contains(&user_id)
            && !self.inner.declined().contains(&user_id)
            && !self.inner.accepted().contains(&user_id))
    }
    pub fn has_accepted(&self) -> bool {
        let Ok(user_id) = self.client.user_id() else {
            return false;
        };
        self.inner.accepted().contains(&user_id)
    }

    pub fn has_declined(&self) -> bool {
        let Ok(user_id) = self.client.user_id() else {
            return false;
        };
        self.inner.declined().contains(&user_id)
    }
    pub fn invited(&self) -> Vec<String> {
        self.inner
            .invited()
            .iter()
            .map(ToString::to_string)
            .collect()
    }

    pub fn accepted(&self) -> Vec<String> {
        self.inner
            .accepted()
            .iter()
            .map(ToString::to_string)
            .collect()
    }

    pub fn declined(&self) -> Vec<String> {
        self.inner
            .declined()
            .iter()
            .map(ToString::to_string)
            .collect()
    }

    pub fn has_invitations(&self) -> bool {
        !self.inner.invited().is_empty()
    }

    pub async fn invite(&self, user_id: String) -> Result<String> {
        let user_id = UserId::parse(user_id)?;
        let msg = ExplicitInviteEventContent::new(self.inner.event_id(), user_id);
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                let event_id = room.send(msg).await?.event_id;
                Ok(event_id.to_string())
            })
            .await?
    }

    pub fn subscribe_stream(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.subscribe()).map(|_| true)
    }

    pub fn subscribe(&self) -> Receiver<()> {
        self.client.subscribe(self.inner.update_key())
    }

    pub async fn reload(&self) -> Result<Self> {
        let client = self.client.clone();
        let room = self.room.clone();
        let event_id = self.inner.event_id().to_owned();
        RUNTIME
            .spawn(async move { ObjectInvitationsManager::new(client, room, event_id).await })
            .await?
    }
}

impl ObjectInvitationsManager {
    pub async fn new(client: Client, room: Room, event_id: OwnedEventId) -> Result<Self> {
        let inner =
            models::InvitationsManager::from_store_and_event_id(client.store(), event_id.as_ref())
                .await;
        Ok(ObjectInvitationsManager {
            client,
            room,
            inner,
        })
    }
}
