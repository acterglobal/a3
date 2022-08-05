use futures::channel::mpsc::Sender;
use matrix_sdk::{
    ruma::{events::AnySyncEphemeralRoomEvent, serde::Raw, OwnedRoomId},
    Client,
};
use serde_json::Value;

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
pub struct ReadNotification {
    room_id: String,
    read_records: Vec<ReadRecord>,
}

impl ReadNotification {
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

// thread callback must be global function, not member function
pub async fn handle_read_notification(
    room_id: &OwnedRoomId,
    event: &Raw<AnySyncEphemeralRoomEvent>,
    client: &Client,
    tx: &mut Sender<ReadNotification>,
) {
    if let Some(AnySyncEphemeralRoomEvent::Receipt(ev)) = event.deserialize().ok() {
        let mut evt = ReadNotification::new(room_id.to_string());
        let v: Value = serde_json::from_str(event.json().get()).unwrap();
        for (event_id, event_info) in v["content"].as_object().unwrap().iter() {
            for (user_id, user_info) in event_info["m.read"].as_object().unwrap().iter() {
                let timestamp = user_info["ts"].as_u64().unwrap();
                evt.add_read_record(event_id.to_string(), user_id.to_string(), timestamp);
            }
        }
        if let Err(e) = tx.try_send(evt) {
            log::warn!("Dropping ephemeral event for {}: {}", room_id, e);
        }
    }
}
