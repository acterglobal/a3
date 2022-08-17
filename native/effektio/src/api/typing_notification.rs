use futures::{
    channel::mpsc::{channel, Receiver, Sender},
    StreamExt,
};
use matrix_sdk::{
    deserialized_responses::Rooms,
    ruma::{events::AnySyncEphemeralRoomEvent, OwnedRoomId},
    Client,
};
use parking_lot::Mutex;
use std::sync::Arc;

#[derive(Clone, Debug)]
pub struct TypingNotificationEvent {
    room_id: String,
}

impl TypingNotificationEvent {
    pub(crate) fn new(room_id: String) -> Self {
        Self { room_id }
    }

    pub fn get_room_id(&self) -> String {
        self.room_id.clone()
    }
}

#[derive(Clone)]
pub struct TypingNotificationController {
    event_tx: Sender<TypingNotificationEvent>,
    event_rx: Arc<Mutex<Option<Receiver<TypingNotificationEvent>>>>,
}

impl TypingNotificationController {
    pub(crate) fn new() -> Self {
        let (tx, rx) = channel::<TypingNotificationEvent>(10); // dropping after more than 10 items queued
        TypingNotificationController {
            event_tx: tx,
            event_rx: Arc::new(Mutex::new(Some(rx))),
        }
    }

    pub fn get_event_rx(&self) -> Option<Receiver<TypingNotificationEvent>> {
        self.event_rx.lock().take()
    }

    pub(crate) fn process_ephemeral_events(&self, client: &Client, rooms: &Rooms) {
        let mut event_tx = self.event_tx.clone();
        for (room_id, room_info) in rooms.join.iter() {
            for event in room_info
                .ephemeral
                .events
                .iter()
                .filter_map(|ev| ev.deserialize().ok())
            {
                if let AnySyncEphemeralRoomEvent::Typing(ev) = event {
                    let evt = TypingNotificationEvent::new(room_id.to_string());
                    if let Err(e) = event_tx.try_send(evt) {
                        log::warn!("Dropping ephemeral event for {}: {}", room_id, e);
                    }
                }
            }
        }
    }
}
