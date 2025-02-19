use matrix_sdk::{
    event_handler::{Ctx, EventHandlerHandle},
    room::Room,
    Client as SdkClient,
};
use matrix_sdk_base::ruma::{events::typing::SyncTypingEvent, OwnedUserId};
use scc::hash_map::{Entry, HashMap};
use std::sync::Arc;
use tokio::sync::broadcast::{channel, Receiver, Sender};
use tokio_stream::{wrappers::BroadcastStream, Stream, StreamExt};
use tracing::{error, trace};

use super::client::Client;

#[derive(Clone, Debug)]
pub struct TypingEvent {
    user_ids: Vec<OwnedUserId>,
}

impl TypingEvent {
    pub(crate) fn new(user_ids: Vec<OwnedUserId>) -> Self {
        Self { user_ids }
    }

    pub fn user_ids(&self) -> Vec<OwnedUserId> {
        self.user_ids.clone()
    }
}

#[derive(Clone, Debug)]
pub(crate) struct TypingController {
    notifiers: Arc<HashMap<String, Sender<TypingEvent>>>,
    event_handle: Option<EventHandlerHandle>,
}

impl TypingController {
    pub fn new() -> Self {
        TypingController {
            notifiers: Default::default(),
            event_handle: None,
        }
    }

    pub fn add_event_handler(&mut self, client: &SdkClient) {
        client.add_event_handler_context(self.clone());
        let handle = client.add_event_handler(
            |ev: SyncTypingEvent, room: Room, Ctx(me): Ctx<TypingController>| async move {
                me.issue_typing_event(ev, room.room_id().to_string());
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

    fn issue_typing_event(&self, ev: SyncTypingEvent, room_id: String) {
        if let Entry::Occupied(o) = self.notifiers.entry(room_id) {
            let v = o.get();
            if v.receiver_count() == 0 {
                trace!("No listeners. removing");
                let _ = o.remove();
                return;
            }
            if let Err(error) = v.send(TypingEvent::new(ev.content.user_ids)) {
                trace!(?error, "Notifying failed. No receivers. Clearing");
                // we have overflow activated, this only fails because it has been closed
                let _ = o.remove();
            }
        }
    }
}

impl Client {
    pub fn subscribe_to_typing_event_stream(&self, key: String) -> impl Stream<Item = TypingEvent> {
        BroadcastStream::new(self.subscribe_to_typing_event(key)).filter_map(|f| f.ok())
    }

    pub fn subscribe_to_typing_event(&self, key: String) -> Receiver<TypingEvent> {
        match self.typing_controller.notifiers.entry(key) {
            Entry::Occupied(mut o) => {
                let sender = o.get_mut();
                if sender.receiver_count() == 0 {
                    // replace the existing channel to reopen
                    let (sender, receiver) = channel(1);
                    o.insert(sender);
                    receiver
                } else {
                    sender.subscribe()
                }
            }
            Entry::Vacant(v) => {
                let (sender, receiver) = channel(1);
                v.insert_entry(sender);
                receiver
            }
        }
    }
}
