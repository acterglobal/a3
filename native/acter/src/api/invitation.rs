use acter_core::client::CoreClient;
use anyhow::{bail, Context, Result};
use futures_signals::signal::{Mutable, MutableSignalCloned, SignalExt, SignalStream};
use matrix_sdk::{
    event_handler::{Ctx, EventHandlerHandle},
    room::{Room as SdkRoom, RoomMember},
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
    time::{SystemTime, UNIX_EPOCH},
};
use tokio::time::{sleep, Duration};
use tokio_retry::{strategy::FixedInterval, Retry};
use tracing::{error, info};

use super::{
    client::{Client, SyncController},
    profile::{PublicProfile, UserProfile},
    room::Room,
    RUNTIME,
};

#[derive(Clone, Debug)]
enum Sender {
    IdOnly(OwnedUserId),
    Member(RoomMember),
}

#[derive(Clone, Debug)]
pub struct Invitation {
    core: CoreClient,
    origin_server_ts: Option<u64>,
    is_dm: bool,
    room: SdkRoom,
    sender: Sender,
    sync_controller: SyncController,
}

impl Invitation {
    pub fn origin_server_ts(&self) -> Option<u64> {
        self.origin_server_ts
    }

    pub fn room(&self) -> Room {
        Room::new(
            self.core.clone(),
            self.room.clone(),
            self.sync_controller.clone(),
        )
    }

    pub fn is_dm(&self) -> bool {
        self.is_dm
    }

    pub fn room_id(&self) -> OwnedRoomId {
        self.room.room_id().to_owned()
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

#[derive(Clone, Debug)]
pub(crate) struct InvitationController {
    core: CoreClient,
    invitations: Mutable<Vec<Invitation>>,
    stripped_event_handle: Option<EventHandlerHandle>,
    sync_event_handle: Option<EventHandlerHandle>,
    sync_controller: SyncController,
}

impl InvitationController {
    pub fn new(core: CoreClient, sync_controller: SyncController) -> Self {
        InvitationController {
            core,
            invitations: Default::default(),
            stripped_event_handle: None,
            sync_event_handle: None,
            sync_controller,
        }
    }

    pub fn add_event_handler(&mut self) {
        let client = self.core.client();

        client.add_event_handler_context(self.clone());
        let handle = client.add_event_handler(
            |ev: StrippedRoomMemberEvent,
             room: SdkRoom,
             Ctx(me): Ctx<InvitationController>| async move {
                // user got invitation
                me.clone().process_stripped_event(ev, room);
            },
        );
        self.stripped_event_handle = Some(handle);

        client.add_event_handler_context(self.clone());
        let handle = client.add_event_handler(
            |ev: SyncRoomMemberEvent, room: SdkRoom, Ctx(me): Ctx<InvitationController>| async move {
                // user accepted or rejected invitation
                me.clone().process_sync_event(ev, room);
            },
        );
        self.sync_event_handle = Some(handle);
    }

    pub fn remove_event_handler(&mut self) {
        let client = self.core.client();
        if let Some(handle) = self.stripped_event_handle.clone() {
            client.remove_event_handler(handle);
            self.stripped_event_handle = None;
        }
        if let Some(handle) = self.sync_event_handle.clone() {
            client.remove_event_handler(handle);
            self.sync_event_handle = None;
        }
    }

    pub async fn load_invitations(&self) -> Result<()> {
        let mut invitations = vec![];
        for room in self.core.client().invited_rooms().iter() {
            let details = room.invite_details().await?;
            if let Some(inviter) = details.inviter {
                let is_dm = details
                    .invitee
                    .event()
                    .as_stripped()
                    .and_then(|e| e.content.is_direct)
                    .unwrap_or_default();
                let invitation = Invitation {
                    is_dm,
                    core: self.core.clone(),
                    origin_server_ts: None,
                    room: room.clone(),
                    sender: Sender::Member(inviter),
                    sync_controller: self.sync_controller.clone(),
                };
                invitations.push(invitation);
            }
        }
        self.invitations.lock_mut().clone_from(&invitations);
        Ok(())
    }

    fn process_stripped_event(&mut self, ev: StrippedRoomMemberEvent, room: SdkRoom) -> Result<()> {
        // filter only event for me
        let user_id = self
            .core
            .client()
            .user_id()
            .context("You must be logged in to do that")?;
        if ev.state_key != *user_id {
            return Ok(());
        }

        info!("stripped room member event: {:?}", ev);
        let since_the_epoch = SystemTime::now().duration_since(UNIX_EPOCH)?;

        info!("event type: StrippedRoomMemberEvent");
        info!("membership: {:?}", ev.content.membership);

        if ev.content.membership == MembershipState::Invite {
            let room_id = room.room_id();
            let sender = ev.sender;

            let is_dm = ev.content.is_direct.unwrap_or_default();
            let invitation = Invitation {
                core: self.core.clone(),
                is_dm,
                origin_server_ts: Some(since_the_epoch.as_millis() as u64),
                room: room.clone(),
                sender: Sender::IdOnly(sender.to_owned()),
                sync_controller: self.sync_controller.clone(),
            };
            let mut invitations = self.invitations.lock_mut();
            if !invitations
                .iter()
                .any(|x| x.room_id() == *room_id && x.sender_id() == *sender)
            {
                invitations.insert(0, invitation);
            }
        }
        Ok(())
    }

    fn process_sync_event(&mut self, ev: SyncRoomMemberEvent, room: SdkRoom) {
        if let Some(evt) = ev.as_original() {
            // filter only event for me
            let user_id = self.core.client().user_id().expect("UserId needed");
            if evt.clone().state_key != *user_id {
                return;
            }

            if let Some(prev_content) = evt.clone().unsigned.prev_content {
                let mut invitations = self.invitations.lock_mut();
                match (prev_content.membership, evt.clone().content.membership) {
                    (MembershipState::Invite, MembershipState::Join) => {
                        // remove this invitation from list
                        let room_id = room.room_id().to_string();
                        if let Some(idx) = invitations.iter().position(|x| x.room_id() == room_id) {
                            invitations.remove(idx);
                        }
                    }
                    (MembershipState::Invite, MembershipState::Leave) => {
                        // remove this invitation from list
                        let room_id = room.room_id().to_string();
                        if let Some(idx) = invitations.iter().position(|x| x.room_id() == room_id) {
                            invitations.remove(idx);
                        }
                    }
                    _ => {}
                }
            }
        }
    }
}

struct SearchedUser {
    inner: search_users::v3::User,
}

impl SearchedUser {
    pub fn user_id_str(&self) -> String {
        self.inner.user_id.to_string()
    }
}

impl Client {
    pub fn invitations_rx(&self) -> SignalStream<MutableSignalCloned<Vec<Invitation>>> {
        self.invitation_controller
            .invitations
            .signal_cloned()
            .to_stream()
    }

    pub async fn search_users(&self, search_term: String) -> Result<Vec<UserProfile>> {
        let client = self.core.client().clone();
        RUNTIME
            .spawn(async move {
                let resp = client.search_users(&search_term, 30).await?;
                let user_profiles = resp
                    .results
                    .into_iter()
                    .map(|inner| {
                        UserProfile::from_search(PublicProfile::new(inner, client.clone()))
                    })
                    .collect();
                Ok(user_profiles)
            })
            .await?
    }

    pub async fn suggested_users(&self, room_name: Option<String>) -> Result<Vec<UserProfile>> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                // get member list of target room
                let local_members = if let Some(room_name) = room_name {
                    if let Some(room) = me.core.client().get_room(&RoomId::parse(room_name)?) {
                        room.members(RoomMemberships::all())
                            .await?
                            .iter()
                            .map(|x| x.user_id().to_owned())
                            .collect::<Vec<OwnedUserId>>()
                    } else {
                        // but we always ignore ourselves
                        vec![me.user_id()?]
                    }
                } else {
                    // but we always ignore ourselves
                    vec![me.user_id()?]
                };
                // iterate my rooms to get user list
                let mut profiles: BTreeMap<OwnedUserId, (RoomMember, Vec<String>)> =
                    Default::default();
                for room in me.rooms().iter().filter(|r| r.are_members_synced()) {
                    let members = room.members(RoomMemberships::ACTIVE).await?;
                    let room_id = room.room_id().to_string();
                    for member in members.into_iter() {
                        let user_id = member.user_id().to_owned();
                        // exclude user that belongs to target room
                        if local_members.contains(&user_id) {
                            continue;
                        }
                        profiles
                            .entry(user_id)
                            .and_modify(|(m, rooms)| {
                                rooms.push(room_id.clone());
                            })
                            .or_insert_with(|| (member, vec![room_id.clone()]));
                    }
                }
                let mut found_profiles = profiles
                    .into_values()
                    .map(|(m, rooms)| UserProfile::with_shared_rooms(m, rooms))
                    .collect::<Vec<_>>();

                found_profiles.sort_by_cached_key(|a| -(a.shared_rooms().len() as i64)); // reverse sort

                Ok(found_profiles)
            })
            .await?
    }
}
