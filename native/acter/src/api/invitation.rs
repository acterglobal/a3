use anyhow::{bail, Context, Result};
use futures_signals::signal::{Mutable, MutableSignalCloned, SignalExt, SignalStream};
use matrix_sdk::{
    event_handler::{Ctx, EventHandlerHandle},
    room::{Room, RoomMember},
    ruma::api::client::user_directory::search_users::v3::User,
    Client as SdkClient, RoomMemberships, RoomState,
};
use ruma_common::{
    events::room::member::{MembershipState, StrippedRoomMemberEvent, SyncRoomMemberEvent},
    OwnedRoomId, OwnedUserId, RoomId,
};
use std::time::{SystemTime, UNIX_EPOCH};
use tokio::time::{sleep, Duration};
use tracing::{error, info};

use super::{
    client::Client,
    profile::{PublicProfile, UserProfile},
    RUNTIME,
};

#[derive(Clone, Debug)]
pub struct Invitation {
    client: SdkClient,
    origin_server_ts: Option<u64>,
    room: Room,
    sender: OwnedUserId,
}

impl Invitation {
    pub fn origin_server_ts(&self) -> Option<u64> {
        self.origin_server_ts
    }

    pub fn room_id(&self) -> OwnedRoomId {
        self.room.room_id().to_owned()
    }

    pub async fn room_name(&self) -> Result<String> {
        let client = self.client.clone();
        let room_id = self.room.room_id().to_owned();
        let room = client.get_room(&room_id).context("Not found a room")?;
        if !matches!(room.state(), RoomState::Invited) {
            bail!("Can't get a room we are not invited");
        }
        RUNTIME
            .spawn(async move {
                let name = room.display_name().await?;
                Ok(name.to_string())
            })
            .await?
    }

    pub fn sender(&self) -> OwnedUserId {
        self.sender.clone()
    }

    pub async fn get_sender_profile(&self) -> Result<UserProfile> {
        let room = self.room.clone();
        let sender = self.sender.clone();
        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&sender)
                    .await?
                    .context("Couldn't get room member")?;
                Ok(UserProfile::from_member(member))
            })
            .await?
    }

    pub async fn accept(&self) -> Result<bool> {
        let client = self.client.clone();
        let room_id = self.room.room_id().to_owned();
        let room = client.get_room(&room_id).context("Not found a room")?;
        if !matches!(room.state(), RoomState::Invited) {
            bail!("Can't get a room we are not invited");
        }
        // any variable in self can't be called directly in spawn
        RUNTIME
            .spawn(async move {
                let mut delay = 2;
                while let Err(err) = room.join().await {
                    // retry autojoin due to synapse sending invites, before the
                    // invited user can join for more information see
                    // https://github.com/matrix-org/synapse/issues/4345
                    error!(
                        "Failed to accept room {} ({:?}), retrying in {}s",
                        room.room_id(),
                        err,
                        delay,
                    );

                    sleep(Duration::from_secs(delay)).await;
                    delay *= 2;

                    if delay > 3600 {
                        error!("Can't accept room {} ({:?})", room.room_id(), err);
                        break;
                    }
                }
                info!("Successfully accepted room {}", room.room_id());
                Ok(delay <= 3600)
            })
            .await?
    }

    pub async fn reject(&self) -> Result<bool> {
        let client = self.client.clone();
        let room_id = self.room.room_id().to_owned();
        let room = client.get_room(&room_id).context("Not found a room")?;
        if !matches!(room.state(), RoomState::Invited) {
            bail!("Can't get a room we are not invited");
        }
        // any variable in self can't be called directly in spawn
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
                        error!("Can't reject room {} ({:?})", room.room_id(), err);
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
    invitations: Mutable<Vec<Invitation>>,
    stripped_event_handle: Option<EventHandlerHandle>,
    sync_event_handle: Option<EventHandlerHandle>,
}

impl InvitationController {
    pub fn new() -> Self {
        InvitationController {
            invitations: Default::default(),
            stripped_event_handle: None,
            sync_event_handle: None,
        }
    }

    pub fn add_event_handler(&mut self, client: &SdkClient) {
        let me = self.clone();

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: StrippedRoomMemberEvent,
             room: Room,
             c: SdkClient,
             Ctx(me): Ctx<InvitationController>| async move {
                // user got invitation
                me.clone().process_stripped_event(ev, room, &c);
            },
        );
        self.stripped_event_handle = Some(handle);

        client.add_event_handler_context(me);
        let handle = client.add_event_handler(
            |ev: SyncRoomMemberEvent,
             room: Room,
             c: SdkClient,
             Ctx(me): Ctx<InvitationController>| async move {
                // user accepted or rejected invitation
                me.clone().process_sync_event(ev, room, &c);
            },
        );
        self.sync_event_handle = Some(handle);
    }

    pub fn remove_event_handler(&mut self, client: &SdkClient) {
        if let Some(handle) = self.stripped_event_handle.clone() {
            client.remove_event_handler(handle);
            self.stripped_event_handle = None;
        }
        if let Some(handle) = self.sync_event_handle.clone() {
            client.remove_event_handler(handle);
            self.sync_event_handle = None;
        }
    }

    pub async fn load_invitations(&self, client: &SdkClient) -> Result<()> {
        let mut invitations = vec![];
        for room in client.invited_rooms().iter() {
            let details = room.invite_details().await?;
            if let Some(inviter) = details.inviter {
                let invitation = Invitation {
                    client: client.clone(),
                    origin_server_ts: None,
                    room: room.clone(),
                    sender: inviter.user_id().to_owned(),
                };
                invitations.push(invitation);
            }
        }
        self.invitations.lock_mut().clone_from(&invitations);
        Ok(())
    }

    fn process_stripped_event(
        &mut self,
        ev: StrippedRoomMemberEvent,
        room: Room,
        client: &SdkClient,
    ) -> Result<()> {
        // filter only event for me
        let user_id = client.user_id().context("You seem to be not logged in")?;
        if ev.state_key != *user_id {
            return Ok(());
        }

        info!("stripped room member event: {:?}", ev);
        let start = SystemTime::now();
        let since_the_epoch = start.duration_since(UNIX_EPOCH)?;

        info!("event type: StrippedRoomMemberEvent");
        info!("membership: {:?}", ev.content.membership);

        if ev.content.membership == MembershipState::Invite {
            let room_id = room.room_id();
            let sender = ev.sender;
            let invitation = Invitation {
                client: client.clone(),
                origin_server_ts: Some(since_the_epoch.as_millis() as u64),
                room: room.clone(),
                sender: sender.to_owned(),
            };
            let mut invitations = self.invitations.lock_mut();
            if !invitations
                .iter()
                .any(|x| x.room_id() == *room_id && x.sender == *sender)
            {
                invitations.insert(0, invitation);
            }
        }
        Ok(())
    }

    fn process_sync_event(&mut self, ev: SyncRoomMemberEvent, room: Room, client: &SdkClient) {
        if let Some(evt) = ev.as_original() {
            // filter only event for me
            let user_id = client.user_id().expect("You seem to be not logged in");
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
    inner: User,
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
                Ok(resp
                    .results
                    .into_iter()
                    .map(|inner| {
                        UserProfile::from_search(PublicProfile::new(inner, client.clone()))
                    })
                    .collect())
            })
            .await?
    }

    pub async fn suggested_users_to_invite(&self, room_name: String) -> Result<Vec<UserProfile>> {
        let client = self.clone();
        let room_id = RoomId::parse(room_name)?;
        let result = self.core.client().get_room(&room_id);
        if result.is_none() {
            return Ok(vec![]);
        }
        let room = result.unwrap();
        RUNTIME
            .spawn(async move {
                // get member list of target room
                let members = room.members(RoomMemberships::ACTIVE).await?;
                let room_members = members
                    .iter()
                    .map(|x| x.user_id().to_owned())
                    .collect::<Vec<OwnedUserId>>();
                // iterate my rooms to get user list
                let mut profiles: Vec<UserProfile> = vec![];
                if let Some(convo) = client.convo_typed(&room_id).await {
                    let members = convo.members(RoomMemberships::ACTIVE).await?;
                    for member in members {
                        let user_id = member.user_id().to_owned();
                        // exclude user that belongs to target room
                        if room_members.contains(&user_id) {
                            continue;
                        }
                        // exclude user that already selected
                        if profiles.iter().any(|x| x.user_id() == user_id) {
                            continue;
                        }
                        let user_profile = UserProfile::from_member(member);
                        profiles.push(user_profile);
                    }
                }
                Ok(profiles)
            })
            .await?
    }
}
