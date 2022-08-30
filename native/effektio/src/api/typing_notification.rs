use super::Client;
use anyhow::Result;
use async_broadcast::{broadcast, Receiver, Sender};
use async_stream::stream;
use futures::{pin_mut, stream::Stream, StreamExt};
use futures_signals::signal::{
    channel, Broadcaster, BroadcasterSignalCloned, SignalExt, SignalStream,
};
use log::{info, warn};
use matrix_sdk::{
    event_handler::Ctx,
    room::Room,
    ruma::{
        events::{typing::TypingEventContent, SyncEphemeralRoomEvent},
        OwnedRoomId, OwnedUserId,
    },
    Client as MatrixClient,
};
use std::sync::Arc;

pub type TypingNotificationEvent = (OwnedRoomId, Vec<OwnedUserId>);

#[derive(Clone)]
pub struct TypingNotificationController {
    sender: Sender<TypingNotificationEvent>,
}

impl TypingNotificationController {
    pub(crate) fn new() -> Self {
        let (mut sender, _) = broadcast(10); // dropping after more than 10 items queued
        sender.set_overflow(true); // if more than 10 items, remove the oldest
        TypingNotificationController { sender }
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

    pub(crate) fn new_receiver(&self) -> Receiver<TypingNotificationEvent> {
        self.sender.new_receiver()
    }

    fn process_ephemeral_event(&self, ev: SyncEphemeralRoomEvent<TypingEventContent>, room: Room) {
        println!("typing: {:?}", ev.content.user_ids);
        let room_id = room.room_id();
        let msg = (
            room_id.to_owned(),
            ev.content
                .user_ids
                .into_iter()
                .map(|u| u.to_owned())
                .collect(),
        );
        match self.sender.try_broadcast(msg) {
            Ok(Some(_)) => warn!("Oldest event had to be dropped to queue typing event"),
            Err(e) => warn!("Dropping ephemeral event for {}: {:?}", room_id, e),
            _ => {
                info!("Typing Event broadcasted for room {:}", room_id);
                // all good
            }
        }
    }
}
