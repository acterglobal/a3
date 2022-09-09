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
    },
    Client as MatrixClient,
};
use parking_lot::Mutex;
use std::sync::Arc;

use super::{client::Client, RUNTIME};

#[derive(Clone, Debug)]
pub struct ReceiptRecord {
    event_id: String,
    user_id: String,
    timestamp: u64,
}

impl ReceiptRecord {
    pub fn get_event_id(&self) -> String {
        self.event_id.clone()
    }

    pub fn get_user_id(&self) -> String {
        self.user_id.clone()
    }

    pub fn get_timestamp(&self) -> u64 {
        self.timestamp
    }
}

#[derive(Clone, Debug)]
pub struct ReceiptNotificationEvent {
    room_id: String,
    receipt_records: Vec<ReceiptRecord>,
}

impl ReceiptNotificationEvent {
    pub(crate) fn new(room_id: String) -> Self {
        Self {
            room_id,
            receipt_records: vec![],
        }
    }

    pub fn get_room_id(&self) -> String {
        self.room_id.clone()
    }

    pub(crate) fn add_receipt_record(&mut self, event_id: String, user_id: String, timestamp: u64) {
        self.receipt_records.push(ReceiptRecord {
            event_id,
            user_id,
            timestamp,
        });
    }

    pub fn get_receipt_records(&self) -> Vec<ReceiptRecord> {
        self.receipt_records.clone()
    }
}

#[derive(Clone)]
pub struct ReceiptNotificationController {
    event_tx: Sender<ReceiptNotificationEvent>,
    event_rx: Arc<Mutex<Option<Receiver<ReceiptNotificationEvent>>>>,
}

impl ReceiptNotificationController {
    pub(crate) fn new() -> Self {
        let (tx, rx) = channel::<ReceiptNotificationEvent>(10); // dropping after more than 10 items queued
        ReceiptNotificationController {
            event_tx: tx,
            event_rx: Arc::new(Mutex::new(Some(rx))),
        }
    }

    pub(crate) async fn setup(&self, client: &MatrixClient) {
        let me = self.clone();
        client
            .register_event_handler_context(me)
            .register_event_handler(
                |ev: SyncEphemeralRoomEvent<ReceiptEventContent>,
                 room: MatrixRoom,
                 Ctx(me): Ctx<ReceiptNotificationController>| async move {
                    me.clone().process_ephemeral_event(ev, &room);
                },
            )
            .await;
    }

    fn process_ephemeral_event(
        &self,
        ev: SyncEphemeralRoomEvent<ReceiptEventContent>,
        room: &MatrixRoom,
    ) {
        info!("receipt: {:?}", ev.content);
        let room_id = room.room_id();
        let mut msg = ReceiptNotificationEvent::new(room_id.to_string());
        for (event_id, event_info) in ev.content.iter() {
            info!("receipt iter: {:?}", event_id);
            for (user_id, receipt) in event_info[&ReceiptType::Read].iter() {
                info!("user receipt: {:?}", receipt);
                let timestamp = u64::try_from(receipt.ts.unwrap().get()).unwrap();
                msg.add_receipt_record(event_id.to_string(), user_id.to_string(), timestamp);
            }
        }
        let mut event_tx = self.event_tx.clone();
        if let Err(e) = event_tx.try_send(msg) {
            log::warn!("Dropping ephemeral event for {}: {}", room_id, e);
        }
    }
}

impl Client {
    pub fn receipt_notification_event_rx(&self) -> Option<Receiver<ReceiptNotificationEvent>> {
        self.receipt_notification_controller.event_rx.lock().take()
    }
}
