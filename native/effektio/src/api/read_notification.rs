use futures::{
    channel::mpsc::{channel, Receiver, Sender},
    StreamExt,
};
use log::{info, warn};
use matrix_sdk::{
    room::Room,
    ruma::{
        events::{receipt::ReceiptEventContent, SyncEphemeralRoomEvent},
        receipt::ReceiptType,
    },
    Client,
};
use parking_lot::Mutex;
use std::sync::Arc;

#[derive(Clone, Debug)]
pub struct ReadRecord {
    event_id: String,
    user_id: String,
    timestamp: u64,
}

impl ReadRecord {
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
pub struct ReadNotificationEvent {
    room_id: String,
    read_records: Vec<ReadRecord>,
}

impl ReadNotificationEvent {
    pub(crate) fn new(room_id: String) -> Self {
        Self {
            room_id,
            read_records: vec![],
        }
    }

    pub fn get_room_id(&self) -> String {
        self.room_id.clone()
    }

    pub(crate) fn add_read_record(&mut self, event_id: String, user_id: String, timestamp: u64) {
        self.read_records.push(ReadRecord {
            event_id,
            user_id,
            timestamp,
        });
    }

    pub fn get_read_records(&self) -> Vec<ReadRecord> {
        self.read_records.clone()
    }
}

#[derive(Clone)]
pub struct ReadNotificationController {
    event_tx: Sender<ReadNotificationEvent>,
    event_rx: Arc<Mutex<Option<Receiver<ReadNotificationEvent>>>>,
}

impl ReadNotificationController {
    pub(crate) fn new() -> Self {
        let (tx, rx) = channel::<ReadNotificationEvent>(10); // dropping after more than 10 items queued
        ReadNotificationController {
            event_tx: tx,
            event_rx: Arc::new(Mutex::new(Some(rx))),
        }
    }

    pub fn get_event_rx(&self) -> Option<Receiver<ReadNotificationEvent>> {
        self.event_rx.lock().take()
    }

    pub(crate) fn process_ephemeral_event(
        &self,
        ev: SyncEphemeralRoomEvent<ReceiptEventContent>,
        room: &Room,
    ) {
        info!("receipt: {:?}", ev.content);
        let room_id = room.room_id();
        let mut msg = ReadNotificationEvent::new(room_id.to_string());
        for (event_id, event_info) in ev.content.iter() {
            info!("receipt iter: {:?}", event_id);
            for (user_id, receipt) in event_info[&ReceiptType::Read].iter() {
                info!("user receipt: {:?}", receipt);
                let timestamp = u64::try_from(receipt.ts.unwrap().get()).unwrap();
                msg.add_read_record(
                    event_id.to_string(),
                    user_id.to_string(),
                    timestamp,
                );
            }
        }
        let mut event_tx = self.event_tx.clone();
        if let Err(e) = event_tx.try_send(msg) {
            log::warn!("Dropping ephemeral event for {}: {}", room_id, e);
        }
    }
}
