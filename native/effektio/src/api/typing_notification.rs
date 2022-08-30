use super::Client;
use anyhow::Result;
use async_stream::stream;
use futures::{pin_mut, stream::Stream, StreamExt};
use futures_signals::signal::{
    channel, Broadcaster, BroadcasterSignalCloned, Receiver, Sender, SignalExt, SignalStream,
};
use log::{info, warn};
use matrix_sdk::{
    event_handler::Ctx,
    room::Room,
    ruma::events::{typing::TypingEventContent, SyncEphemeralRoomEvent},
    Client as MatrixClient,
};
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

impl std::ops::Drop for TypingNotificationEvent {
    fn drop(&mut self) {
        println!("Dropping evt {:?}@{:?}", self, &self as *const _);
    }
}

#[derive(Clone)]
pub struct TypingNotificationController {
    event_tx: Sender<TypingNotificationEvent>,
    event_rx: Broadcaster<Receiver<TypingNotificationEvent>>,
}

impl TypingNotificationController {
    pub(crate) fn new() -> Self {
        let initial_value = TypingNotificationEvent::new("".to_owned(), vec![]);
        let (tx, rx) = channel(initial_value); // dropping after more than 10 items queued
        TypingNotificationController {
            event_tx: tx,
            event_rx: rx.broadcast(),
        }
    }

    pub async fn setup(&self, client: &MatrixClient) -> Result<()> {
        let me = self.clone();
        client
            .register_event_handler_context(me)
            .register_event_handler(
                |ev: SyncEphemeralRoomEvent<TypingEventContent>,
                 room: Room,
                 Ctx(me): Ctx<TypingNotificationController>| async move {
                    me.clone().process_ephemeral_event(ev, room);
                },
            )
            .await;
        Ok(())
    }

    pub(crate) fn get_event_rx(
        &self,
    ) -> SignalStream<BroadcasterSignalCloned<Receiver<TypingNotificationEvent>>> {
        self.event_rx.signal_cloned().to_stream()
    }

    fn process_ephemeral_event(&self, ev: SyncEphemeralRoomEvent<TypingEventContent>, room: Room) {
        println!("typing: {:?}", ev.content.user_ids);
        let room_id = room.room_id();
        let mut user_ids = vec![];
        for user_id in ev.content.user_ids {
            user_ids.push(user_id.to_owned().to_string());
        }
        let msg = TypingNotificationEvent::new(room_id.to_owned().to_string(), user_ids);
        if let Err(e) = self.event_tx.send(msg) {
            println!("Dropping ephemeral event for {}: {:?}", room_id, e);
        }
    }
}

impl Client {
    pub fn get_typing_notifications(&self) -> Result<impl Stream<Item = TypingNotificationEvent>> {
        // if not exists, create new controller and return it.
        // thus Result is necessary but Option is not necessary.
        let receiver = self.typing_notification_controller.get_event_rx();
        Ok(stream! {
            pin_mut!(receiver);
            for x in receiver.next().await {
                // FIXME: FFI gen doesn't properly deal with singular events coming from different streams
                //        which causes memory corruption. clone the event here again before returning it
                //        prevents that problem.
                yield x.clone()
            }
        })
    }
}
