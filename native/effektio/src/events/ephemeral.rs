use futures::channel::mpsc::Sender;
use matrix_sdk::{
    ruma::{events::AnySyncEphemeralRoomEvent, OwnedRoomId},
    Client,
};

#[derive(Clone, Debug)]
pub struct EphemeralEvent {
    event_name: String,
    room_id: String,
}

impl EphemeralEvent {
    pub(crate) fn new(event_name: String, room_id: String) -> Self {
        Self {
            event_name,
            room_id,
        }
    }

    pub fn get_event_name(&self) -> String {
        self.event_name.clone()
    }

    pub fn get_room_id(&self) -> String {
        self.room_id.clone()
    }
}

// thread callback must be global function, not member function
pub async fn handle_ephemeral_event(
    room_id: &OwnedRoomId,
    event: &AnySyncEphemeralRoomEvent,
    client: &Client,
    tx: &mut Sender<EphemeralEvent>,
) {
    match event {
        AnySyncEphemeralRoomEvent::Receipt(ev) => {
            let evt = EphemeralEvent::new(
                "AnySyncEphemeralRoomEvent::Receipt".to_owned(),
                room_id.to_string(),
            );
            if let Err(e) = tx.try_send(evt) {
                log::warn!("Dropping ephemeral event for {}: {}", room_id, e);
            }
        }
        AnySyncEphemeralRoomEvent::Typing(ev) => {
            let evt = EphemeralEvent::new(
                "AnySyncEphemeralRoomEvent::Typing".to_owned(),
                room_id.to_string(),
            );
            if let Err(e) = tx.try_send(evt) {
                log::warn!("Dropping ephemeral event for {}: {}", room_id, e);
            }
        }
        _ => {}
    }
}
