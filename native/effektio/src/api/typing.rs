use futures::{
    channel::mpsc::{channel, Receiver, Sender},
    StreamExt,
};
use log::{info, warn};
use matrix_sdk::{
    event_handler::Ctx,
    room::Room as MatrixRoom,
    ruma::{
        events::{typing::TypingEventContent, SyncEphemeralRoomEvent},
        OwnedRoomId, OwnedUserId,
    },
    Client as MatrixClient,
};
use parking_lot::Mutex;
use std::sync::Arc;

use super::{client::Client, RUNTIME};

#[derive(Clone, Debug)]
pub struct TypingEvent {
    room_id: OwnedRoomId,
    user_ids: Vec<OwnedUserId>,
}

impl TypingEvent {
    pub(crate) fn new(room_id: OwnedRoomId, user_ids: Vec<OwnedUserId>) -> Self {
        Self { room_id, user_ids }
    }

    pub fn room_id(&self) -> String {
        self.room_id.to_string()
    }

    pub fn user_ids(&self) -> Vec<String> {
        let mut res: Vec<String> = vec![];
        for user_id in self.user_ids.iter() {
            res.push(user_id.to_string());
        }
        res
    }
}

#[derive(Clone)]
pub(crate) struct TypingController {
    event_tx: Sender<TypingEvent>,
    event_rx: Arc<Mutex<Option<Receiver<TypingEvent>>>>,
}

impl TypingController {
    pub fn new() -> Self {
        let (tx, rx) = channel::<TypingEvent>(10); // dropping after more than 10 items queued
        TypingController {
            event_tx: tx,
            event_rx: Arc::new(Mutex::new(Some(rx))),
        }
    }

    pub fn setup(&self, client: &MatrixClient) {
        let me = self.clone();
        client.add_event_handler_context(me);
        client.add_event_handler(
            |ev: SyncEphemeralRoomEvent<TypingEventContent>,
             room: MatrixRoom,
             Ctx(me): Ctx<TypingController>| async move {
                me.clone().process_ephemeral_event(ev, &room);
            },
        );
    }

    fn process_ephemeral_event(
        &self,
        ev: SyncEphemeralRoomEvent<TypingEventContent>,
        room: &MatrixRoom,
    ) {
        info!("typing: {:?}", ev.content.user_ids);
        let room_id = room.room_id().to_owned();
        let msg = TypingEvent::new(room_id.clone(), ev.content.user_ids);
        let mut event_tx = self.event_tx.clone();
        if let Err(e) = event_tx.try_send(msg) {
            warn!("Dropping ephemeral event for {}: {}", room_id, e);
        }
    }
}

impl Client {
    pub fn typing_event_rx(&self) -> Option<Receiver<TypingEvent>> {
        self.typing_controller.event_rx.lock().take()
    }
}
