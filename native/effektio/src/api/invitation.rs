use anyhow::{bail, Result};
use futures::{
    channel::mpsc::{channel, Receiver, Sender},
    StreamExt,
};
use log::{error, info, warn};
use matrix_sdk::{
    event_handler::Ctx,
    room::Room as MatrixRoom,
    ruma::{
        api::client::room::create_room::v3::Request as CreateRoomRequest,
        events::room::member::{StrippedRoomMemberEvent, SyncRoomMemberEvent},
        RoomId,
    },
    Client as MatrixClient,
};
use parking_lot::Mutex;
use std::{
    sync::Arc,
    time::{SystemTime, UNIX_EPOCH},
};
use tokio::time::{sleep, Duration};

use super::{client::Client, RUNTIME};

#[derive(Default, Clone, Debug)]
pub struct InvitationEvent {
    origin_server_ts: u64,
    room_id: String,
    room_name: String,
    sender: String,
}

impl InvitationEvent {
    pub fn origin_server_ts(&self) -> u64 {
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
}

#[derive(Clone)]
pub(crate) struct InvitationController {
    event_tx: Sender<InvitationEvent>,
    event_rx: Arc<Mutex<Option<Receiver<InvitationEvent>>>>,
}

impl InvitationController {
    pub fn new() -> Self {
        let (tx, rx) = channel::<InvitationEvent>(10); // dropping after more than 10 items queued
        InvitationController {
            event_tx: tx,
            event_rx: Arc::new(Mutex::new(Some(rx))),
        }
    }

    pub fn setup(&self, client: &MatrixClient) -> Result<()> {
        let me = self.clone();
        client.add_event_handler_context(me.clone());
        client.add_event_handler(
            |ev: SyncRoomMemberEvent,
             room: MatrixRoom,
             Ctx(me): Ctx<InvitationController>| async move {
                me.clone().process_sync_event(ev, room).await;
            },
        );
        client.add_event_handler_context(me);
        client.add_event_handler(
            |ev: StrippedRoomMemberEvent,
             room: MatrixRoom,
             Ctx(me): Ctx<InvitationController>| async move {
                me.clone().process_stripped_event(ev, room);
            },
        );
        Ok(())
    }

    async fn process_sync_event(&mut self, ev: SyncRoomMemberEvent, room: MatrixRoom) {
        let msg = InvitationEvent {
            origin_server_ts: ev.origin_server_ts().as_secs().into(),
            room_id: room.room_id().to_string(),
            room_name: room.display_name().await.unwrap().to_string(),
            sender: ev.sender().to_string(),
        };

        info!("event type: {:?}", ev.event_type());
        info!("membership: {:?}", ev.membership());
        info!("invitation: {:?}", msg);

        if let Err(e) = self.event_tx.try_send(msg) {
            warn!("Dropping invitation event: {:?}", e);
        }
    }

    async fn process_stripped_event(&mut self, ev: StrippedRoomMemberEvent, room: MatrixRoom) {
        let start = SystemTime::now();
        let since_the_epoch = start
            .duration_since(UNIX_EPOCH)
            .expect("Time went backwards");

        let msg = InvitationEvent {
            origin_server_ts: since_the_epoch.as_secs(),
            room_id: room.room_id().to_string(),
            room_name: room.display_name().await.unwrap().to_string(),
            sender: ev.sender.to_string(),
        };

        info!("event type: StrippedRoomMemberEvent");
        info!("membership: {:?}", ev.content.membership);
        info!("invitation: {:?}", msg);

        if let Err(e) = self.event_tx.try_send(msg) {
            warn!("Dropping invitation event: {:?}", e);
        }
    }
}

impl Client {
    pub(crate) async fn create_room(&self) -> Result<String> {
        let req = CreateRoomRequest::new();
        let res = self.client.create_room(req).await?;
        Ok(res.room_id().to_string())
    }

    pub fn invitation_event_rx(&self) -> Option<Receiver<InvitationEvent>> {
        self.invitation_controller.event_rx.lock().take()
    }

    pub async fn get_invited_rooms(&self) -> Result<Vec<InvitationEvent>> {
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let mut events: Vec<InvitationEvent> = vec![];
                for room in client.invited_rooms().iter() {
                    let invite = room.invite_details().await?;
                    let event = InvitationEvent {
                        origin_server_ts: 0,
                        room_id: room.room_id().to_string(),
                        room_name: room.display_name().await.unwrap().to_string(),
                        sender: invite.inviter.unwrap().user_id().to_string(),
                    };
                    events.push(event);
                }
                Ok(events)
            })
            .await?
    }

    pub async fn accept_invitation(&self, room_id: String) -> Result<bool> {
        let room_id = RoomId::parse(room_id)?;
        match self.client.get_invited_room(&room_id) {
            Some(room) => {
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
            None => {
                bail!("Can't accept a room we are not invited")
            }
        }
    }

    pub async fn reject_invitation(&self, room_id: String) -> Result<bool> {
        let room_id = RoomId::parse(room_id)?;
        match self.client.get_invited_room(&room_id) {
            Some(room) => {
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
            None => {
                bail!("Can't reject a room we are not invited")
            }
        }
    }
}
