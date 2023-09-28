use futures::{
    channel::mpsc::{channel, Receiver, Sender},
    stream::StreamExt,
};
use matrix_sdk::{
    event_handler::{Ctx, EventHandlerHandle},
    room::Room,
    Client as SdkClient,
};
use ruma_common::{
    MilliSecondsSinceUnixEpoch, OwnedEventId, OwnedRoomId, OwnedUserId,
};
use ruma_events::receipt::{ReceiptType, SyncReceiptEvent};
use std::sync::Arc;
use tokio::sync::Mutex;
use tracing::{error, info};

use super::client::Client;

#[derive(Clone, Debug)]
pub struct ReceiptRecord {
    event_id: OwnedEventId,
    seen_by: OwnedUserId,
    ts: Option<MilliSecondsSinceUnixEpoch>,
}

impl ReceiptRecord {
    pub(crate) fn new(
        event_id: OwnedEventId,
        seen_by: OwnedUserId,
        ts: Option<MilliSecondsSinceUnixEpoch>,
    ) -> Self {
        ReceiptRecord {
            event_id,
            seen_by,
            ts,
        }
    }

    pub fn event_id(&self) -> String {
        self.event_id.to_string()
    }

    pub fn seen_by(&self) -> String {
        self.seen_by.to_string()
    }

    pub fn ts(&self) -> Option<u64> {
        self.ts.map(|x| x.get().into())
    }
}

#[derive(Clone, Debug)]
pub struct ReceiptEvent {
    room_id: OwnedRoomId,
    receipt_records: Vec<ReceiptRecord>,
}

impl ReceiptEvent {
    pub(crate) fn new(room_id: OwnedRoomId) -> Self {
        Self {
            room_id,
            receipt_records: vec![],
        }
    }

    pub fn room_id(&self) -> OwnedRoomId {
        self.room_id.clone()
    }

    pub fn is_empty(&self) -> bool {
        self.receipt_records.is_empty()
    }

    pub(crate) fn add_receipt_record(
        &mut self,
        event_id: &OwnedEventId,
        seen_by: &OwnedUserId,
        ts: Option<MilliSecondsSinceUnixEpoch>,
    ) {
        let record = ReceiptRecord::new(event_id.clone(), seen_by.clone(), ts);
        self.receipt_records.push(record);
    }

    pub fn receipt_records(&self) -> Vec<ReceiptRecord> {
        self.receipt_records.clone()
    }
}

#[derive(Clone, Debug)]
pub(crate) struct ReceiptController {
    event_tx: Sender<ReceiptEvent>,
    event_rx: Arc<Mutex<Option<Receiver<ReceiptEvent>>>>,
    event_handle: Option<EventHandlerHandle>,
}

impl ReceiptController {
    pub fn new() -> Self {
        let (tx, rx) = channel::<ReceiptEvent>(10); // dropping after more than 10 items queued
        ReceiptController {
            event_tx: tx,
            event_rx: Arc::new(Mutex::new(Some(rx))),
            event_handle: None,
        }
    }

    pub fn add_event_handler(&mut self, client: &SdkClient) {
        let me = self.clone();
        client.add_event_handler_context(me);
        let handle = client.add_event_handler(
            |ev: SyncReceiptEvent, room: Room, Ctx(me): Ctx<ReceiptController>| async move {
                me.clone().process_ephemeral_event(ev, &room);
            },
        );
        self.event_handle = Some(handle);
    }

    pub fn remove_event_handler(&mut self, client: &SdkClient) {
        if let Some(handle) = self.event_handle.clone() {
            client.remove_event_handler(handle);
            self.event_handle = None;
        }
    }

    fn process_ephemeral_event(&mut self, ev: SyncReceiptEvent, room: &Room) {
        info!("receipt: {:?}", ev.content);
        let room_id = room.room_id();
        let mut msg = ReceiptEvent::new(room_id.to_owned());
        for (event_id, event_info) in ev.content.iter() {
            info!("receipt iter: {:?}", event_id);
            if event_info.contains_key(&ReceiptType::Read) {
                for (seen_by, receipt) in event_info[&ReceiptType::Read].iter() {
                    info!("user receipt: {:?}", receipt);
                    msg.add_receipt_record(event_id, seen_by, receipt.ts);
                }
            }
        }
        if !msg.is_empty() {
            if let Err(e) = self.event_tx.try_send(msg) {
                error!("Dropping ephemeral event for {}: {}", room_id, e);
            }
        }
    }
}

impl Client {
    pub fn receipt_event_rx(&self) -> Option<Receiver<ReceiptEvent>> {
        match self.receipt_controller.event_rx.try_lock() {
            Ok(mut rx) => rx.take(),
            Err(e) => None,
        }
    }
}
