use futures::channel::mpsc::Sender;
use matrix_sdk::{
    ruma::{
        events::{
            room::message::MessageType, AnySyncMessageLikeEvent, AnyToDeviceEvent,
            SyncMessageLikeEvent,
        },
        OwnedRoomId,
    },
    Client,
};

#[derive(Clone)]
pub struct EmojiVerificationEvent {
    event_name: String,
    event_id: String,
    sender: String,
}

impl EmojiVerificationEvent {
    pub(crate) fn new(event_name: String, event_id: String, sender: String) -> Self {
        Self {
            event_name,
            event_id,
            sender,
        }
    }

    pub fn get_event_name(&self) -> String {
        self.event_name.clone()
    }

    pub fn get_event_id(&self) -> String {
        self.event_id.clone()
    }

    pub fn get_sender(&self) -> String {
        self.sender.clone()
    }
}

// thread callback must be global function, not member function
pub async fn handle_emoji_sync_msg_event(
    room_id: &OwnedRoomId,
    event: &AnySyncMessageLikeEvent,
    client: &Client,
    tx: &mut Sender<EmojiVerificationEvent>,
) {
    match event {
        AnySyncMessageLikeEvent::RoomMessage(SyncMessageLikeEvent::Original(m)) => {
            if let MessageType::VerificationRequest(_) = &m.content.msgtype {
                let sender = m.sender.to_string();
                let evt_id = m.event_id.to_string();
                let evt = EmojiVerificationEvent::new(
                    "AnySyncMessageLikeEvent::RoomMessage".to_owned(),
                    evt_id.clone(),
                    sender,
                );
                if let Err(e) = tx.try_send(evt) {
                    log::warn!("Dropping event for {}: {}", evt_id, e);
                }
            }
        }
        AnySyncMessageLikeEvent::KeyVerificationReady(SyncMessageLikeEvent::Original(ev)) => {
            let sender = ev.sender.to_string();
            let evt_id = ev.event_id.to_string();
            let evt = EmojiVerificationEvent::new(
                "AnySyncMessageLikeEvent::KeyVerificationReady".to_owned(),
                evt_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                log::warn!("Dropping event for {}: {}", evt_id, e);
            }
        }
        AnySyncMessageLikeEvent::KeyVerificationStart(SyncMessageLikeEvent::Original(ev)) => {
            let sender = ev.sender.to_string();
            let evt_id = ev.event_id.to_string();
            let evt = EmojiVerificationEvent::new(
                "AnySyncMessageLikeEvent::KeyVerificationReady".to_owned(),
                evt_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                log::warn!("Dropping event for {}: {}", evt_id, e);
            }
        }
        AnySyncMessageLikeEvent::KeyVerificationCancel(SyncMessageLikeEvent::Original(ev)) => {
            let sender = ev.sender.to_string();
            let evt_id = ev.event_id.to_string();
            let evt = EmojiVerificationEvent::new(
                "AnySyncMessageLikeEvent::KeyVerificationReady".to_owned(),
                evt_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                log::warn!("Dropping event for {}: {}", evt_id, e);
            }
        }
        AnySyncMessageLikeEvent::KeyVerificationAccept(SyncMessageLikeEvent::Original(ev)) => {
            let sender = ev.sender.to_string();
            let evt_id = ev.event_id.to_string();
            let evt = EmojiVerificationEvent::new(
                "AnySyncMessageLikeEvent::KeyVerificationAccept".to_owned(),
                evt_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                log::warn!("Dropping event for {}: {}", evt_id, e);
            }
        }
        AnySyncMessageLikeEvent::KeyVerificationKey(SyncMessageLikeEvent::Original(ev)) => {
            let sender = ev.sender.to_string();
            let evt_id = ev.event_id.to_string();
            let evt = EmojiVerificationEvent::new(
                "AnySyncMessageLikeEvent::KeyVerificationKey".to_owned(),
                evt_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                log::warn!("Dropping event for {}: {}", evt_id, e);
            }
        }
        AnySyncMessageLikeEvent::KeyVerificationMac(SyncMessageLikeEvent::Original(ev)) => {
            let sender = ev.sender.to_string();
            let evt_id = ev.event_id.to_string();
            let evt = EmojiVerificationEvent::new(
                "AnySyncMessageLikeEvent::KeyVerificationMac".to_owned(),
                evt_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                log::warn!("Dropping event for {}: {}", evt_id, e);
            }
        }
        AnySyncMessageLikeEvent::KeyVerificationDone(SyncMessageLikeEvent::Original(ev)) => {
            let sender = ev.sender.to_string();
            let evt_id = ev.event_id.to_string();
            let evt = EmojiVerificationEvent::new(
                "AnySyncMessageLikeEvent::KeyVerificationReady".to_owned(),
                evt_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                log::warn!("Dropping event for {}: {}", evt_id, e);
            }
        }
        _ => {}
    }
}

// thread callback must be global function, not member function
pub async fn handle_emoji_to_device_event(
    event: &AnyToDeviceEvent,
    client: &Client,
    tx: &mut Sender<EmojiVerificationEvent>,
) {
    match event {
        AnyToDeviceEvent::KeyVerificationRequest(ev) => {
            let sender = ev.sender.to_string();
            let txn_id = ev.content.transaction_id.to_string();
            let evt = EmojiVerificationEvent::new(
                "AnyToDeviceEvent::KeyVerificationRequest".to_owned(),
                txn_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                log::warn!("Dropping transaction for {}: {}", txn_id, e);
            }
        }
        AnyToDeviceEvent::KeyVerificationReady(ev) => {
            let sender = ev.sender.to_string();
            let txn_id = ev.content.transaction_id.to_string();
            let evt = EmojiVerificationEvent::new(
                "AnyToDeviceEvent::KeyVerificationReady".to_owned(),
                txn_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                log::warn!("Dropping transaction for {}: {}", txn_id, e);
            }
        }
        AnyToDeviceEvent::KeyVerificationStart(ev) => {
            let sender = ev.sender.to_string();
            println!("Verification Start from {}", sender);
            log::warn!("Verification Start from {}", sender);
            let txn_id = ev.content.transaction_id.to_string();
            let evt = EmojiVerificationEvent::new(
                "AnyToDeviceEvent::KeyVerificationStart".to_owned(),
                txn_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                log::warn!("Dropping transaction for {}: {}", txn_id, e);
            }
        }
        AnyToDeviceEvent::KeyVerificationCancel(ev) => {
            let sender = ev.sender.to_string();
            let txn_id = ev.content.transaction_id.to_string();
            let evt = EmojiVerificationEvent::new(
                "AnyToDeviceEvent::KeyVerificationCancel".to_owned(),
                txn_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                log::warn!("Dropping transaction for {}: {}", txn_id, e);
            }
        }
        AnyToDeviceEvent::KeyVerificationAccept(ev) => {
            let sender = ev.sender.to_string();
            let txn_id = ev.content.transaction_id.to_string();
            let evt = EmojiVerificationEvent::new(
                "AnyToDeviceEvent::KeyVerificationAccept".to_owned(),
                txn_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                log::warn!("Dropping transaction for {}: {}", txn_id, e);
            }
        }
        AnyToDeviceEvent::KeyVerificationKey(ev) => {
            let sender = ev.sender.to_string();
            let txn_id = ev.content.transaction_id.to_string();
            let evt = EmojiVerificationEvent::new(
                "AnyToDeviceEvent::KeyVerificationKey".to_owned(),
                txn_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                log::warn!("Dropping transaction for {}: {}", txn_id, e);
            }
        }
        AnyToDeviceEvent::KeyVerificationMac(ev) => {
            let sender = ev.sender.to_string();
            let txn_id = ev.content.transaction_id.to_string();
            let evt = EmojiVerificationEvent::new(
                "AnyToDeviceEvent::KeyVerificationMac".to_owned(),
                txn_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                log::warn!("Dropping transaction for {}: {}", txn_id, e);
            }
        }
        AnyToDeviceEvent::KeyVerificationDone(ev) => {
            let sender = ev.sender.to_string();
            let txn_id = ev.content.transaction_id.to_string();
            let evt = EmojiVerificationEvent::new(
                "AnyToDeviceEvent::KeyVerificationDone".to_owned(),
                txn_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                log::warn!("Dropping transaction for {}: {}", txn_id, e);
            }
        }
        _ => {}
    }
}
