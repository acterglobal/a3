use futures::{
    channel::mpsc::{channel, Receiver, Sender},
    StreamExt,
};
use log::{info, warn};
use matrix_sdk::{
    event_handler::Ctx,
    room::Room as MatrixRoom,
    ruma::{
        events::{receipt::ReceiptEventContent, SyncEphemeralRoomEvent},
        receipt::ReceiptType,
        MilliSecondsSinceUnixEpoch, OwnedEventId, OwnedRoomId, OwnedUserId,
    },
    Client as MatrixClient,
};
use parking_lot::Mutex;
use std::sync::Arc;

use super::{client::Client, RUNTIME};

#[derive(Clone, Debug)]
pub struct UserReceipt {
    event_id: OwnedEventId,
    user_id: OwnedUserId,
    ts: Option<MilliSecondsSinceUnixEpoch>,
}

impl UserReceipt {
    pub(crate) fn new(
        event_id: OwnedEventId,
        user_id: OwnedUserId,
        ts: Option<MilliSecondsSinceUnixEpoch>,
    ) -> Self {
        UserReceipt {
            event_id,
            user_id,
            ts,
        }
    }

    pub fn event_id(&self) -> String {
        self.event_id.to_string()
    }

    pub fn user_id(&self) -> String {
        self.user_id.to_string()
    }

    pub fn ts(&self) -> Option<u64> {
        self.ts.map(|x| x.as_secs().into())
    }
}

#[derive(Clone, Debug)]
pub struct ReceiptEvent {
    room_id: OwnedRoomId,
    user_receipts: Vec<UserReceipt>,
}

impl ReceiptEvent {
    pub(crate) fn new(room_id: OwnedRoomId) -> Self {
        Self {
            room_id,
            user_receipts: vec![],
        }
    }

    pub fn room_id(&self) -> String {
        self.room_id.to_string()
    }

    pub(crate) fn add_user_receipt(
        &mut self,
        event_id: OwnedEventId,
        user_id: OwnedUserId,
        ts: Option<MilliSecondsSinceUnixEpoch>,
    ) {
        let record = UserReceipt::new(event_id, user_id, ts);
        self.user_receipts.push(record);
    }

    pub fn user_receipts(&self) -> Vec<UserReceipt> {
        self.user_receipts.clone()
    }
}

#[derive(Clone)]
pub(crate) struct ReceiptController {
    event_tx: Sender<ReceiptEvent>,
    event_rx: Arc<Mutex<Option<Receiver<ReceiptEvent>>>>,
}

impl ReceiptController {
    pub fn new() -> Self {
        let (tx, rx) = channel::<ReceiptEvent>(10); // dropping after more than 10 items queued
        ReceiptController {
            event_tx: tx,
            event_rx: Arc::new(Mutex::new(Some(rx))),
        }
    }

    pub fn setup(&self, client: &MatrixClient) {
        let me = self.clone();
        client.add_event_handler_context(me);
        client.add_event_handler(
            |ev: SyncEphemeralRoomEvent<ReceiptEventContent>,
             room: MatrixRoom,
             Ctx(me): Ctx<ReceiptController>| async move {
                me.clone().process_ephemeral_event(ev, &room);
            },
        );
    }

    fn process_ephemeral_event(
        &self,
        ev: SyncEphemeralRoomEvent<ReceiptEventContent>,
        room: &MatrixRoom,
    ) {
        info!("receipt: {:?}", ev.content);
        let room_id = room.room_id();
        let mut msg = ReceiptEvent::new(room_id.to_owned());
        for (event_id, event_info) in ev.content.iter() {
            info!("receipt iter: {:?}", event_id);
            for (user_id, receipt) in event_info[&ReceiptType::Read].iter() {
                info!("user receipt: {:?}", receipt);
                msg.add_user_receipt(event_id.clone(), user_id.clone(), receipt.ts);
            }
        }
        let mut event_tx = self.event_tx.clone();
        if let Err(e) = event_tx.try_send(msg) {
            log::warn!("Dropping ephemeral event for {}: {}", room_id, e);
        }
    }
}

impl Client {
    pub fn receipt_event_rx(&self) -> Option<Receiver<ReceiptEvent>> {
        self.receipt_controller.event_rx.lock().take()
    }
}
