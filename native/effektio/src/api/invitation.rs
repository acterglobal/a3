use anyhow::{bail, Context, Result};
use futures_signals::signal::{
    Mutable, MutableSignal, MutableSignalCloned, SignalExt, SignalStream,
};
use log::{error, info, warn};
use matrix_sdk::{
    event_handler::{Ctx, EventHandlerHandle},
    room::Room as MatrixRoom,
    ruma::{
        events::room::member::{MembershipState, StrippedRoomMemberEvent, SyncRoomMemberEvent},
        RoomId, UserId,
    },
    Client as MatrixClient,
};
use std::time::{SystemTime, UNIX_EPOCH};
use tokio::time::{sleep, Duration};

use super::{
    client::{divide_rooms_from_common, Client},
    profile::UserProfile,
    RUNTIME,
};

#[derive(Default, Clone, Debug)]
pub struct Invitation {
    client: Option<MatrixClient>,
    origin_server_ts: Option<u64>,
    room_id: String,
    room_name: String,
    sender: String,
}

impl Invitation {
    pub fn origin_server_ts(&self) -> Option<u64> {
        self.origin_server_ts
    }

    pub fn room_id(&self) -> String {
        self.room_id.clone()
    }

    pub fn room_name(&self) -> String {
        self.room_name.clone()
    }

    pub fn sender(&self) -> String {
        self.sender.clone()
    }

    pub async fn get_sender_profile(&self) -> Result<UserProfile> {
        let client = self.client.clone().unwrap();
        let user_id = UserId::parse(self.sender.clone())?;
        RUNTIME
            .spawn(async move {
                let mut user_profile = UserProfile::new(client, user_id, None, None);
                user_profile.fetch().await;
                Ok(user_profile)
            })
            .await?
    }

    pub async fn accept(&self) -> Result<bool> {
        let client = self.client.clone().unwrap();
        let room_id = RoomId::parse(self.room_id.clone())?;
        let room = client
            .get_invited_room(&room_id)
            .context("Can't accept a room we are not invited")?;
        // any variable in self can't be called directly in spawn
        RUNTIME
            .spawn(async move {
                let mut delay = 2;
                while let Err(err) = room.accept_invitation().await {
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
        let client = self.client.clone().unwrap();
        let room_id = RoomId::parse(self.room_id.clone())?;
        let room = client
            .get_invited_room(&room_id)
            .context("Can't accept a room we are not invited")?;
        // any variable in self can't be called directly in spawn
        RUNTIME
            .spawn(async move {
                let mut delay = 2;
                while let Err(err) = room.reject_invitation().await {
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

#[derive(Clone)]
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

    pub fn add_event_handler(&mut self, client: &MatrixClient) {
        let me = self.clone();

        client.add_event_handler_context(me.clone());
        let handle = client.add_event_handler(
            |ev: StrippedRoomMemberEvent,
             room: MatrixRoom,
             c: MatrixClient,
             Ctx(me): Ctx<InvitationController>| async move {
                // user got invitation
                me.clone().process_stripped_event(ev, room, &c).await;
            },
        );
        self.stripped_event_handle = Some(handle);

        client.add_event_handler_context(me);
        let handle = client.add_event_handler(
            |ev: SyncRoomMemberEvent,
             room: MatrixRoom,
             c: MatrixClient,
             Ctx(me): Ctx<InvitationController>| async move {
                // user accepted or rejected invitation
                me.clone().process_sync_event(ev, room, &c);
            },
        );
        self.sync_event_handle = Some(handle);
    }

    pub fn remove_event_handler(&mut self, client: &MatrixClient) {
        if let Some(handle) = self.stripped_event_handle.clone() {
            client.remove_event_handler(handle);
            self.stripped_event_handle = None;
        }
        if let Some(handle) = self.sync_event_handle.clone() {
            client.remove_event_handler(handle);
            self.sync_event_handle = None;
        }
    }

    pub async fn load_invitations(&self, client: &MatrixClient) -> Result<()> {
        let mut invitations: Vec<Invitation> = vec![];
        for room in client.invited_rooms().iter() {
            let details = room.invite_details().await?;
            if let Some(inviter) = details.inviter {
                let invitation = Invitation {
                    client: Some(client.clone()),
                    origin_server_ts: None,
                    room_id: room.room_id().to_string(),
                    room_name: room.display_name().await?.to_string(),
                    sender: inviter.user_id().to_string(),
                };
                invitations.push(invitation);
            }
        }
        self.invitations.lock_mut().clone_from(&invitations);
        Ok(())
    }

    async fn process_stripped_event(
        &mut self,
        ev: StrippedRoomMemberEvent,
        room: MatrixRoom,
        client: &MatrixClient,
    ) -> Result<()> {
        // filter only event for me
        let user_id = client.user_id().expect("You seem to be not logged in");
        if ev.state_key != *user_id {
            return Ok(());
        }

        info!("stripped room member event: {:?}", ev);
        let start = SystemTime::now();
        let since_the_epoch = start
            .duration_since(UNIX_EPOCH)
            .expect("Time went backwards");

        info!("event type: StrippedRoomMemberEvent");
        info!("membership: {:?}", ev.content.membership);

        if ev.content.membership == MembershipState::Invite {
            let room_id = room.room_id();
            let sender = ev.sender;
            let invitation = Invitation {
                client: Some(client.clone()),
                origin_server_ts: Some(since_the_epoch.as_millis() as u64),
                room_id: room_id.to_string(),
                room_name: room.display_name().await?.to_string(),
                sender: sender.to_string(),
            };
            let mut invitations = self.invitations.lock_mut();
            if !invitations
                .iter()
                .any(|x| x.room_id == *room_id && x.sender == *sender)
            {
                invitations.insert(0, invitation);
            }
        }
        Ok(())
    }

    fn process_sync_event(
        &mut self,
        ev: SyncRoomMemberEvent,
        room: MatrixRoom,
        client: &MatrixClient,
    ) {
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
                        if let Some(idx) = invitations.iter().position(|x| x.room_id == room_id) {
                            invitations.remove(idx);
                        }
                    }
                    (MembershipState::Invite, MembershipState::Leave) => {
                        // remove this invitation from list
                        let room_id = room.room_id().to_string();
                        if let Some(idx) = invitations.iter().position(|x| x.room_id == room_id) {
                            invitations.remove(idx);
                        }
                    }
                    _ => {}
                }
            }
        }
    }
}

impl Client {
    pub fn invitations_rx(&self) -> SignalStream<MutableSignalCloned<Vec<Invitation>>> {
        self.invitation_controller
            .invitations
            .signal_cloned()
            .to_stream()
    }

    pub async fn suggested_users_to_invite(&self, room_name: String) -> Result<Vec<UserProfile>> {
        let client = self.client.clone();
        let room_id = RoomId::parse(room_name)?;
        let res = self.client.get_room(&room_id);
        if res.is_none() {
            return Ok(vec![]);
        }
        let room = res.unwrap();
        RUNTIME
            .spawn(async move {
                // get member list of target room
                let mut room_members = vec![];
                let members = room.members().await?;
                for member in members {
                    room_members.push(member.user_id().to_string());
                }
                // iterate my rooms to get user list
                let mut profiles: Vec<UserProfile> = vec![];
                let (_, convos) = divide_rooms_from_common(client.clone()).await;
                for convo in convos {
                    if convo.room_id() == room_id {
                        continue;
                    }
                    let members = convo.members().await?;
                    for member in members {
                        let user_id = member.user_id().to_string();
                        // exclude user that belongs to target room
                        if room_members.contains(&user_id) {
                            continue;
                        }
                        // exclude user that already selected
                        if profiles.iter().any(|x| x.user_id() == member.user_id()) {
                            continue;
                        }
                        let user_profile = UserProfile::new(
                            client.clone(),
                            member.user_id().to_owned(),
                            member.avatar_url().map(|x| x.to_owned()),
                            member.display_name().map(|x| x.to_string()),
                        );
                        profiles.push(user_profile);
                    }
                }
                Ok(profiles)
            })
            .await?
    }
}
