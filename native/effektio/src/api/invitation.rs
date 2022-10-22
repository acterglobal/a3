use anyhow::{bail, Context, Result};
use futures_signals::signal::{
    Mutable, MutableSignal, MutableSignalCloned, SignalExt, SignalStream,
};
use log::{error, info, warn};
use matrix_sdk::{
    event_handler::Ctx,
    room::Room as MatrixRoom,
    ruma::{
        api::client::room::create_room::v3::Request as CreateRoomRequest,
        events::room::member::{
            MembershipState, OriginalSyncRoomMemberEvent, StrippedRoomMemberEvent,
        },
        RoomId, UserId,
    },
    Client as MatrixClient,
};
use std::time::{SystemTime, UNIX_EPOCH};
use tokio::time::{sleep, Duration};

use super::{client::Client, profile::UserProfile, RUNTIME};

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
                let mut user_profile = UserProfile::new(client, user_id);
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
}

impl InvitationController {
    pub fn new() -> Self {
        InvitationController {
            invitations: Default::default(),
        }
    }

    pub async fn setup(&self, client: &MatrixClient) {
        let invitations = self.get_invitations(client).await;
        self.invitations.lock_mut().clone_from(&invitations);

        let me = self.clone();
        client.add_event_handler_context(client.clone());
        client.add_event_handler_context(me.clone());
        client.add_event_handler(
            |ev: StrippedRoomMemberEvent,
             room: MatrixRoom,
             Ctx(client): Ctx<MatrixClient>,
             Ctx(me): Ctx<InvitationController>| async move {
                // user got invitation
                me.clone().process_stripped_event(ev, room, &client).await;
            },
        );
        client.add_event_handler_context(client.clone());
        client.add_event_handler_context(me);
        client.add_event_handler(
            |ev: OriginalSyncRoomMemberEvent,
             room: MatrixRoom,
             Ctx(client): Ctx<MatrixClient>,
             Ctx(me): Ctx<InvitationController>| async move {
                // user accepted or rejected invitation
                me.clone().process_sync_event(ev, room, &client);
            },
        );
    }

    async fn get_invitations(&self, client: &MatrixClient) -> Vec<Invitation> {
        let mut invitations: Vec<Invitation> = vec![];
        for room in client.invited_rooms().iter() {
            let details = room.invite_details().await.unwrap();
            let invitation = Invitation {
                client: Some(client.clone()),
                origin_server_ts: None,
                room_id: room.room_id().to_string(),
                room_name: room.display_name().await.unwrap().to_string(),
                sender: details.inviter.unwrap().user_id().to_string(),
            };
            invitations.push(invitation);
        }
        invitations
    }

    async fn process_stripped_event(
        &mut self,
        ev: StrippedRoomMemberEvent,
        room: MatrixRoom,
        client: &MatrixClient,
    ) {
        // filter only event for me
        let user_id = client.user_id().expect("You seem to be not logged in");
        if ev.state_key != *user_id {
            return;
        }

        info!("invitation - stripped room member event: {:?}", ev);
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
                origin_server_ts: Some(since_the_epoch.as_secs()),
                room_id: room_id.to_string(),
                room_name: room.display_name().await.unwrap().to_string(),
                sender: sender.to_string(),
            };
            let mut invitations = self.invitations.lock_mut();
            let idx = invitations
                .iter()
                .position(|x| x.room_id == *room_id && x.sender == *sender);
            if idx.is_none() {
                invitations.insert(0, invitation);
            }
        }
    }

    fn process_sync_event(
        &mut self,
        ev: OriginalSyncRoomMemberEvent,
        room: MatrixRoom,
        client: &MatrixClient,
    ) {
        // filter only event for me
        let user_id = client.user_id().expect("You seem to be not logged in");
        if ev.state_key != *user_id {
            return;
        }

        let evt = ev.clone();
        // info!("invitation - original sync room member event: {:?}", ev);
        if let Some(prev_content) = ev.unsigned.prev_content {
            let mut invitations = self.invitations.lock_mut();
            match (prev_content.membership, ev.content.membership) {
                (MembershipState::Invite, MembershipState::Join) => {
                    info!("invitation - original sync room member event: {:?}", evt);
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

impl Client {
    pub(crate) async fn create_room(&self) -> Result<String> {
        let req = CreateRoomRequest::new();
        let res = self.client.create_room(req).await?;
        Ok(res.room_id().to_string())
    }

    pub fn invitations_rx(&self) -> SignalStream<MutableSignalCloned<Vec<Invitation>>> {
        self.invitation_controller
            .invitations
            .signal_cloned()
            .to_stream()
    }
}
