use futures::channel::mpsc::Sender;
use log::{debug, error, info, trace, warn};
use matrix_sdk::ruma::{
    events::{
        room::message::MessageType, AnySyncMessageLikeEvent, AnyToDeviceEvent, SyncMessageLikeEvent,
    },
    OwnedRoomId,
};

#[derive(Clone, Debug)]
pub struct EmojiVerificationEvent {
    event_name: String,
    txn_id: String,
    sender: String,
}

impl EmojiVerificationEvent {
    pub(crate) fn new(event_name: String, txn_id: String, sender: String) -> Self {
        Self {
            event_name,
            txn_id,
            sender,
        }
    }

    pub fn get_event_name(&self) -> String {
        self.event_name.clone()
    }

    pub fn get_txn_id(&self) -> String {
        self.txn_id.clone()
    }

    pub fn get_sender(&self) -> String {
        self.sender.clone()
    }
}

// thread callback must be global function, not member function
pub fn handle_emoji_sync_msg_event(
    room_id: &OwnedRoomId,
    event: &AnySyncMessageLikeEvent,
    tx: &mut Sender<EmojiVerificationEvent>,
) {
    match event {
        AnySyncMessageLikeEvent::RoomMessage(SyncMessageLikeEvent::Original(m)) => {
            if let MessageType::VerificationRequest(_) = &m.content.msgtype {
                let sender = m.sender.to_string();
                let txn_id = m.event_id.to_string();
                info!("m.room.message");
                let evt = EmojiVerificationEvent::new(
                    "m.room.message".to_owned(),
                    txn_id.clone(),
                    sender,
                );
                if let Err(e) = tx.try_send(evt) {
                    warn!("Dropping event for {}: {}", txn_id, e);
                }
            }
        }
        AnySyncMessageLikeEvent::KeyVerificationReady(SyncMessageLikeEvent::Original(ev)) => {
            let sender = ev.sender.to_string();
            let txn_id = ev.content.relates_to.event_id.as_str().to_owned();
            info!("m.key.verification.ready");
            let evt = EmojiVerificationEvent::new(
                "m.key.verification.ready".to_owned(),
                txn_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                warn!("Dropping event for {}: {}", txn_id, e);
            }
        }
        AnySyncMessageLikeEvent::KeyVerificationStart(SyncMessageLikeEvent::Original(ev)) => {
            let sender = ev.sender.to_string();
            let txn_id = ev.content.relates_to.event_id.as_str().to_owned();
            info!("m.key.verification.start");
            let evt = EmojiVerificationEvent::new(
                "m.key.verification.start".to_owned(),
                txn_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                warn!("Dropping event for {}: {}", txn_id, e);
            }
        }
        AnySyncMessageLikeEvent::KeyVerificationCancel(SyncMessageLikeEvent::Original(ev)) => {
            let sender = ev.sender.to_string();
            let txn_id = ev.content.relates_to.event_id.as_str().to_owned();
            info!("m.key.verification.cancel");
            let evt = EmojiVerificationEvent::new(
                "m.key.verification.cancel".to_owned(),
                txn_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                warn!("Dropping event for {}: {}", txn_id, e);
            }
        }
        AnySyncMessageLikeEvent::KeyVerificationAccept(SyncMessageLikeEvent::Original(ev)) => {
            let sender = ev.sender.to_string();
            let txn_id = ev.content.relates_to.event_id.as_str().to_owned();
            info!("m.key.verification.accept");
            let evt = EmojiVerificationEvent::new(
                "m.key.verification.accept".to_owned(),
                txn_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                warn!("Dropping event for {}: {}", txn_id, e);
            }
        }
        AnySyncMessageLikeEvent::KeyVerificationKey(SyncMessageLikeEvent::Original(ev)) => {
            let sender = ev.sender.to_string();
            let txn_id = ev.content.relates_to.event_id.as_str().to_owned();
            info!("m.key.verification.key");
            let evt = EmojiVerificationEvent::new(
                "m.key.verification.key".to_owned(),
                txn_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                warn!("Dropping event for {}: {}", txn_id, e);
            }
        }
        AnySyncMessageLikeEvent::KeyVerificationMac(SyncMessageLikeEvent::Original(ev)) => {
            let sender = ev.sender.to_string();
            let txn_id = ev.content.relates_to.event_id.as_str().to_owned();
            info!("m.key.verification.mac");
            let evt = EmojiVerificationEvent::new(
                "m.key.verification.mac".to_owned(),
                txn_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                warn!("Dropping event for {}: {}", txn_id, e);
            }
        }
        AnySyncMessageLikeEvent::KeyVerificationDone(SyncMessageLikeEvent::Original(ev)) => {
            let sender = ev.sender.to_string();
            let txn_id = ev.content.relates_to.event_id.as_str().to_owned();
            info!("m.key.verification.done");
            let evt = EmojiVerificationEvent::new(
                "m.key.verification.done".to_owned(),
                txn_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                warn!("Dropping event for {}: {}", txn_id, e);
            }
        }
        _ => {}
    }
}

// thread callback must be global function, not member function
pub fn handle_emoji_to_device_event(
    event: &AnyToDeviceEvent,
    tx: &mut Sender<EmojiVerificationEvent>,
) {
    match event {
        AnyToDeviceEvent::KeyVerificationRequest(ev) => {
            let sender = ev.sender.to_string();
            let txn_id = ev.content.transaction_id.to_string();
            info!("m.key.verification.request");
            let evt = EmojiVerificationEvent::new(
                "m.key.verification.request".to_owned(),
                txn_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                warn!("Dropping transaction for {}: {}", txn_id, e);
            }
        }
        AnyToDeviceEvent::KeyVerificationReady(ev) => {
            let sender = ev.sender.to_string();
            let txn_id = ev.content.transaction_id.to_string();
            info!("m.key.verification.ready");
            let evt = EmojiVerificationEvent::new(
                "m.key.verification.ready".to_owned(),
                txn_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                warn!("Dropping transaction for {}: {}", txn_id, e);
            }
        }
        AnyToDeviceEvent::KeyVerificationStart(ev) => {
            let sender = ev.sender.to_string();
            let txn_id = ev.content.transaction_id.to_string();
            info!("m.key.verification.start");
            let evt = EmojiVerificationEvent::new(
                "m.key.verification.start".to_owned(),
                txn_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                warn!("Dropping transaction for {}: {}", txn_id, e);
            }
        }
        AnyToDeviceEvent::KeyVerificationCancel(ev) => {
            let sender = ev.sender.to_string();
            let txn_id = ev.content.transaction_id.to_string();
            info!("m.key.verification.cancel");
            let evt = EmojiVerificationEvent::new(
                "m.key.verification.cancel".to_owned(),
                txn_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                warn!("Dropping transaction for {}: {}", txn_id, e);
            }
        }
        AnyToDeviceEvent::KeyVerificationAccept(ev) => {
            let sender = ev.sender.to_string();
            let txn_id = ev.content.transaction_id.to_string();
            info!("m.key.verification.accept");
            let evt = EmojiVerificationEvent::new(
                "m.key.verification.accept".to_owned(),
                txn_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                warn!("Dropping transaction for {}: {}", txn_id, e);
            }
        }
        AnyToDeviceEvent::KeyVerificationKey(ev) => {
            let sender = ev.sender.to_string();
            let txn_id = ev.content.transaction_id.to_string();
            info!("m.key.verification.key");
            let evt = EmojiVerificationEvent::new(
                "m.key.verification.key".to_owned(),
                txn_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                warn!("Dropping transaction for {}: {}", txn_id, e);
            }
        }
        AnyToDeviceEvent::KeyVerificationMac(ev) => {
            let sender = ev.sender.to_string();
            let txn_id = ev.content.transaction_id.to_string();
            info!("m.key.verification.mac");
            let evt = EmojiVerificationEvent::new(
                "m.key.verification.mac".to_owned(),
                txn_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                warn!("Dropping transaction for {}: {}", txn_id, e);
            }
        }
        AnyToDeviceEvent::KeyVerificationDone(ev) => {
            let sender = ev.sender.to_string();
            let txn_id = ev.content.transaction_id.to_string();
            info!("m.key.verification.done");
            let evt = EmojiVerificationEvent::new(
                "m.key.verification.done".to_owned(),
                txn_id.clone(),
                sender,
            );
            if let Err(e) = tx.try_send(evt) {
                warn!("Dropping transaction for {}: {}", txn_id, e);
            }
        }
        _ => {}
    }
}
