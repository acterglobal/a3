use async_broadcast::{broadcast, Receiver, Sender};
use futures::StreamExt;
use log::{info, warn};
use matrix_sdk::{
    room::Room,
    ruma::events::{typing::TypingEventContent, SyncEphemeralRoomEvent},
    Client,
};
use parking_lot::Mutex;
use std::sync::Arc;

#[derive(Clone, Debug)]
pub struct TypingNotificationEvent {
    room_id: String,
    user_ids: Vec<String>,
}

impl TypingNotificationEvent {
    pub(crate) fn new(room_id: String, user_ids: Vec<String>) -> Self {
        Self { room_id, user_ids }
    }

    pub fn get_room_id(&self) -> String {
        self.room_id.clone()
    }

    pub fn get_user_ids(&self) -> Vec<String> {
        self.user_ids.clone()
    }
}

#[derive(Clone)]
pub struct TypingNotificationController {
    event_tx: Sender<TypingNotificationEvent>,
    event_rx: Arc<Mutex<Option<Receiver<TypingNotificationEvent>>>>,
}

impl TypingNotificationController {
    pub(crate) fn new() -> Self {
        let (tx, rx) = broadcast::<TypingNotificationEvent>(10); // dropping after more than 10 items queued
        TypingNotificationController {
            event_tx: tx,
            event_rx: Arc::new(Mutex::new(Some(rx))),
        }
    }

    pub fn get_event_rx(&self) -> Option<Receiver<TypingNotificationEvent>> {
        self.event_rx.clone().lock().clone()
    }

    pub(crate) fn process_ephemeral_event(
        &self,
        ev: SyncEphemeralRoomEvent<TypingEventContent>,
        room: &Room,
    ) {
        info!("typing: {:?}", ev.content.user_ids);
        let room_id = room.room_id();
        let mut user_ids = vec![];
        for user_id in ev.content.user_ids {
            user_ids.push(user_id.to_string());
        }
        let msg = TypingNotificationEvent::new(room_id.to_string(), user_ids);
        let mut event_tx = self.event_tx.clone();
        if let Err(e) = event_tx.try_broadcast(msg) {
            warn!("Dropping ephemeral event for {}: {}", room_id, e);
        }
    }
}
