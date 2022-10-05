use anyhow::Result;
use futures::{
    channel::mpsc::{channel, Receiver, Sender},
    StreamExt,
};
use log::{info, warn};
use matrix_sdk::{
    event_handler::Ctx,
    room::Room as MatrixRoom,
    ruma::{
        api::client::room::create_room::v3::Request as CreateRoomRequest,
        events::room::member::{StrippedRoomMemberEvent, SyncRoomMemberEvent},
    },
    Client as MatrixClient,
};
use parking_lot::Mutex;
use std::{
    sync::Arc,
    time::{SystemTime, UNIX_EPOCH},
};

use super::Client;

#[derive(Default, Clone, Debug)]
pub struct MembershipEvent {
    origin_server_ts: u64,
    room_id: String,
    room_name: String,
    sender: String,
}

impl MembershipEvent {
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
pub(crate) struct MembershipController {
    event_tx: Sender<MembershipEvent>,
    event_rx: Arc<Mutex<Option<Receiver<MembershipEvent>>>>,
}

impl MembershipController {
    pub fn new() -> Self {
        let (tx, rx) = channel::<MembershipEvent>(10); // dropping after more than 10 items queued
        MembershipController {
            event_tx: tx,
            event_rx: Arc::new(Mutex::new(Some(rx))),
        }
    }

    pub fn get_event_rx(&self) -> Option<Receiver<MembershipEvent>> {
        self.event_rx.lock().take()
    }

    pub fn setup(&self, client: &MatrixClient) -> Result<()> {
        let me = self.clone();
        // past event
        client.add_event_handler_context(me.clone());
        client.add_event_handler(
            |ev: SyncRoomMemberEvent,
             room: MatrixRoom,
             Ctx(me): Ctx<MembershipController>| async move {
                me.clone().process_sync_event(ev, room).await;
            },
        );
        // incoming event
        client.add_event_handler_context(me);
        client.add_event_handler(
            |ev: StrippedRoomMemberEvent,
             room: MatrixRoom,
             Ctx(me): Ctx<MembershipController>| async move {
                me.clone().process_stripped_event(ev, room);
            },
        );
        Ok(())
    }

    async fn process_sync_event(&mut self, ev: SyncRoomMemberEvent, room: MatrixRoom) {
        let msg = MembershipEvent {
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

        let msg = MembershipEvent {
            origin_server_ts: since_the_epoch.as_secs().into(),
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

    pub fn membership_event_rx(&self) -> Option<Receiver<MembershipEvent>> {
        self.membership_controller.event_rx.lock().take()
    }
}
