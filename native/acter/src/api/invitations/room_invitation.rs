use acter_core::client::CoreClient;
use anyhow::{bail, Context, Result};
use futures_signals::signal::{Mutable, MutableSignalCloned, SignalExt, SignalStream};
use matrix_sdk::{
    event_handler::{Ctx, EventHandlerHandle},
    room::{Room, RoomMember},
};
use matrix_sdk_base::{
    ruma::{
        api::client::user_directory::search_users,
        events::room::member::{MembershipState, StrippedRoomMemberEvent, SyncRoomMemberEvent},
        OwnedRoomId, OwnedUserId, RoomId,
    },
    RoomMemberships, RoomState,
};
use std::{
    collections::BTreeMap,
    ops::Deref,
    time::{SystemTime, UNIX_EPOCH},
};
use tokio::time::{sleep, Duration};
use tokio_retry::{strategy::FixedInterval, Retry};
use tracing::{error, info};

use super::super::{
    client::{Client, SyncController},
    profile::{PublicProfile, UserProfile},
};
use crate::RUNTIME;

#[derive(Clone, Debug)]
enum Sender {
    IdOnly(OwnedUserId),
    Member(RoomMember),
}

#[derive(Clone, Debug)]
pub struct RoomInvitation {
    core: CoreClient,
    is_dm: bool,
    room: Room,
    sender: Sender,
    sync_controller: SyncController,
}

impl Deref for RoomInvitation {
    type Target = Room;

    fn deref(&self) -> &Self::Target {
        &self.room
    }
}

impl RoomInvitation {
    pub async fn parse(
        core: &CoreClient,
        room: Room,
        sync_controller: SyncController,
    ) -> Result<Self> {
        let Some(invitee) = room.get_member_no_sync(room.own_user_id()).await? else {
            bail!("Failed to get own member event");
        };
        let event = invitee.event();
        let inviter_id = event.sender();
        let sender = match room.get_member_no_sync(inviter_id).await {
            Ok(Some(info)) => Sender::Member(info),
            _ => Sender::IdOnly(inviter_id.to_owned()),
        };
        Ok(Self {
            core: core.clone(),
            is_dm: room.is_direct().await.unwrap_or_default(),
            room,
            sender,
            sync_controller,
        })
    }

    pub fn room(&self) -> crate::Room {
        crate::Room::new(
            self.core.clone(),
            self.room.clone(),
            self.sync_controller.clone(),
        )
    }

    pub fn is_dm(&self) -> bool {
        self.is_dm
    }

    pub fn room_id_str(&self) -> String {
        self.room.room_id().to_string()
    }

    pub fn sender_id(&self) -> OwnedUserId {
        match &self.sender {
            Sender::IdOnly(i) => i.clone(),
            Sender::Member(m) => m.user_id().to_owned(),
        }
    }

    pub fn sender_id_str(&self) -> String {
        match &self.sender {
            Sender::IdOnly(i) => i.to_string(),
            Sender::Member(m) => m.user_id().to_string(),
        }
    }

    pub fn sender_profile(&self) -> Option<UserProfile> {
        match &self.sender {
            Sender::IdOnly(i) => None,
            Sender::Member(m) => Some(UserProfile::from_member(m.clone())),
        }
    }

    pub async fn accept(&self) -> Result<bool> {
        let room = self.room.clone();
        if !matches!(room.state(), RoomState::Invited) {
            bail!("Unable to join a room we are not invited to");
        }
        // any variable in self can’t be called directly in spawn
        RUNTIME
            .spawn(async move {
                let strategy = FixedInterval::from_millis(2000).take(5);
                Retry::spawn(strategy, move || {
                    let room = room.clone();
                    async move { room.join().await }
                })
                .await?;
                Ok(true)
            })
            .await?
    }

    pub async fn reject(&self) -> Result<bool> {
        let room_id = self.room.room_id().to_owned();
        let room = self
            .core
            .client()
            .get_room(&room_id)
            .context("Room not found")?;
        if !matches!(room.state(), RoomState::Invited) {
            bail!("Unable to get a room we are not invited");
        }
        // any variable in self can’t be called directly in spawn
        RUNTIME
            .spawn(async move {
                let mut delay = 2;
                while let Err(err) = room.leave().await {
                    // retry autojoin due to synapse sending invites, before the
                    // invited user can join for more information see
                    // https://github.com/matrix-org/synapse/issues/4345
                    error!(
                        "Failed to reject room {} ({:?}), retrying in {}s",
                        room.room_id(),
                        err,
                        delay,
                    );

                    sleep(Duration::from_secs(delay)).await;
                    delay *= 2;

                    if delay > 3600 {
                        error!("Unable to reject room {} ({:?})", room.room_id(), err);
                        break;
                    }
                }
                info!("Successfully rejected room {}", room.room_id());
                Ok(delay <= 3600)
            })
            .await?
    }
}
