use crate::{Client, Room};
use anyhow::Result;

use super::RoomInvitation;

pub struct InvitationsManager {
    client: Client,
}

impl InvitationsManager {
    pub(crate) fn new(client: Client) -> Self {
        Self { client }
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
