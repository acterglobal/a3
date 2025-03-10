use acter_core::{events::explicit_invites::ExplicitInviteEventContent, models};
use matrix_sdk::ruma::{OwnedEventId, OwnedUserId};

use crate::{Client,  MsgContent};
use matrix_sdk::Room;
use anyhow::Result;
use std::ops::Deref;

use super::RUNTIME;

#[derive(Clone, Debug)]
pub struct InvitationsManager {
    client: Client,
    room: Room,
    inner: models::InvitationsManager,
}

impl Deref for InvitationsManager {
    type Target = models::InvitationsManager;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl InvitationsManager {
    fn is_invited(&self) -> Result<bool> {
        Ok(self.inner.invited().contains(&self.client.user_id()?))
    }
    fn invited(&self) -> Vec<OwnedUserId> {
        self.inner.invited().clone()
    }
    fn has_invitations(&self) -> bool {
        !self.inner.invited().is_empty()
    }

    pub async fn invite(&self, user_id: OwnedUserId) -> Result<OwnedEventId> {
        let msg = ExplicitInviteEventContent::new(self.inner.event_id(), user_id);
        let room = self.room.clone();
        RUNTIME.spawn(  async move {
        let event_id = room.send(msg).await?.event_id;
        Ok(event_id)
        }).await?
    }
}

impl InvitationsManager {
    pub async fn new(client: Client, room: Room, event_id: OwnedEventId) -> Result<InvitationsManager> {
        let inner = models::InvitationsManager::from_store_and_event_id(
            client.store(),  event_id.as_ref()
        ).await;
        Ok(InvitationsManager { client, room, inner })
    }
}