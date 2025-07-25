use std::collections::BTreeSet;

use crate::{Client, Room, RUNTIME};
use acter_matrix::{
    models::MyInvitesManager,
    referencing::{ExecuteReference, IndexKey, SpecialListsIndex},
};
use anyhow::Result;
use futures::{stream::select, Stream};
use log::{trace, warn};
use ruma::OwnedRoomId;
use tokio::sync::broadcast::Receiver;
use tokio_stream::{wrappers::BroadcastStream, StreamExt};

use super::RoomInvitation;

#[derive(Debug, Clone)]
pub struct InvitationsManager {
    client: Client,
}

impl InvitationsManager {
    pub(crate) fn new(client: Client) -> Self {
        Self { client }
    }

    pub fn subscribe_stream(&self) -> impl Stream<Item = bool> {
        let mut prev_set: BTreeSet<OwnedRoomId> = Default::default();
        let core = self.client.core.clone();
        let room_stream = BroadcastStream::new(self.client.subscribe_to_all_room_updates())
            .filter_map(move |u| {
                // an update was seen, check if the set of rooms we are invited to has changed
                let new_set: BTreeSet<OwnedRoomId> = core
                    .client()
                    .invited_rooms()
                    .iter()
                    .map(|r| r.room_id().to_owned())
                    .collect();
                if (new_set != prev_set) {
                    prev_set = new_set;
                    Some(true)
                } else {
                    None
                }
            });

        let object_invites = tokio_stream::wrappers::BroadcastStream::new(self.client.subscribe(
            ExecuteReference::Index(IndexKey::Special(SpecialListsIndex::InvitedTo)),
        ))
        .map(|_| true);

        select(room_stream, object_invites)
    }

    pub async fn room_invitations(&self) -> Result<Vec<RoomInvitation>> {
        let rooms = self.client.invited_rooms();
        let core = self.client.core.clone();
        Ok(RUNTIME
            .spawn(async move {
                let mut invites = vec![];
                for room in rooms {
                    // Process each room invitation
                    match RoomInvitation::parse(&core, room).await {
                        Ok(invitation) => invites.push(invitation),
                        Err(err) => log::error!("Failed to parse room invitation: {}", err),
                    }
                }
                invites
            })
            .await?)
    }

    pub async fn object_invitations(&self) -> Result<Vec<String>> {
        // the current list of open invitations to this use
        let core = self.client.core.clone();
        Ok(RUNTIME
            .spawn(async move {
                let manager = MyInvitesManager::load(core.store()).await;
                manager
                    .invited_to()
                    .iter()
                    .map(ToString::to_string)
                    .collect()
            })
            .await?)
    }
}
