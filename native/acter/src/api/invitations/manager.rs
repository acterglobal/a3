use std::collections::BTreeSet;

use crate::{Client, Room};
use anyhow::Result;
use futures::Stream;
use ruma::OwnedRoomId;
use tokio::sync::broadcast::Receiver;
use tokio_stream::{wrappers::BroadcastStream, StreamExt};

use super::RoomInvitation;

pub struct InvitationsManager {
    client: Client,
}

impl InvitationsManager {
    pub(crate) fn new(client: Client) -> Self {
        Self { client }
    }

    pub fn subscribe_stream(&self) -> impl Stream<Item = bool> {
        let mut prev_set: BTreeSet<OwnedRoomId> = Default::default();
        BroadcastStream::new(self.client.subscribe_to_all_room_updates()).filter_map(move |u| {
            let Ok(update) = u else { return None };
            let new_set: BTreeSet<OwnedRoomId> = update.invite.keys().map(Clone::clone).collect();
            if (new_set != prev_set) {
                prev_set = new_set;
                Some(true)
            } else {
                None
            }
        })
    }

    pub async fn room_invitations(&self) -> Result<Vec<RoomInvitation>> {
        let rooms = self.client.invited_rooms();
        let mut invites = vec![];

        for room in rooms {
            // Process each room invitation
            match RoomInvitation::parse(&self.client.core, room).await {
                Ok(invitation) => invites.push(invitation),
                Err(err) => log::error!("Failed to parse room invitation: {}", err),
            }
        }

        Ok(invites)
    }
}
