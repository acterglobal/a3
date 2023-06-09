use futures::{
    channel::mpsc::{channel, Receiver, Sender},
    StreamExt,
};
use log::{info, warn};
use matrix_sdk::{
    event_handler::{Ctx, EventHandlerHandle},
    room::Room,
    ruma::{events::typing::SyncTypingEvent, OwnedRoomId, OwnedUserId},
    Client as SdkClient,
};
use std::sync::Arc;
use tokio::sync::Mutex;

use super::client::Client;

#[derive(Clone, Debug)]
pub struct TypingEvent {
    room_id: OwnedRoomId,
    user_ids: Vec<OwnedUserId>,
}

impl TypingEvent {
    pub(crate) fn new(room_id: OwnedRoomId, user_ids: Vec<OwnedUserId>) -> Self {
        Self { room_id, user_ids }
    }

    pub fn room_id(&self) -> OwnedRoomId {
        self.room_id.clone()
    }

    pub fn user_ids(&self) -> Vec<OwnedUserId> {
        self.user_ids.clone()
    }
}

#[derive(Clone, Debug)]
pub(crate) struct TypingController {
    event_tx: Sender<TypingEvent>,
    event_rx: Arc<Mutex<Option<Receiver<TypingEvent>>>>,
    event_handle: Option<EventHandlerHandle>,
}

impl TypingController {
    pub fn new() -> Self {
        let (tx, rx) = channel::<TypingEvent>(10); // dropping after more than 10 items queued
        TypingController {
            event_tx: tx,
            event_rx: Arc::new(Mutex::new(Some(rx))),
            event_handle: None,
        }
    }

    pub fn add_event_handler(&mut self, client: &SdkClient) {
        let me = self.clone();
        client.add_event_handler_context(me);
        let handle = client.add_event_handler(
            |ev: SyncTypingEvent, room: Room, Ctx(me): Ctx<TypingController>| async move {
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

    fn process_ephemeral_event(&mut self, ev: SyncTypingEvent, room: &Room) {
        info!("typing: {:?}", ev.content.user_ids);
        let room_id = room.room_id().to_owned();
        let msg = TypingEvent::new(room_id.clone(), ev.content.user_ids);
        if let Err(e) = self.event_tx.try_send(msg) {
            warn!("Dropping ephemeral event for {}: {}", room_id, e);
        }
    }
}

impl Client {
    pub fn typing_event_rx(&self) -> Option<Receiver<TypingEvent>> {
        match self.typing_controller.event_rx.try_lock() {
            Ok(mut r) => r.take(),
            Err(e) => None,
        }
    }
}
