use futures::{
    channel::mpsc::{channel, Receiver, Sender},
    StreamExt,
};
use log::{info, warn};
use matrix_sdk::{
    deserialized_responses::SyncTimelineEvent,
    event_handler::Ctx,
    room::Room,
    ruma::events::{
        room::message::{MessageFormat, MessageType, OriginalSyncRoomMessageEvent, RoomMessageEventContent},
        AnySyncMessageLikeEvent, AnySyncTimelineEvent, OriginalSyncMessageLikeEvent,
        SyncMessageLikeEvent,
    },
    Client as MatrixClient,
};
use parking_lot::Mutex;
use std::sync::Arc;

use super::client::Client;

#[derive(Debug)]
pub struct RoomMessage {
    inner: OriginalSyncMessageLikeEvent<RoomMessageEventContent>,
    room: Room,
    fallback: String,
}

impl RoomMessage {
    pub(crate) fn new(
        inner: OriginalSyncMessageLikeEvent<RoomMessageEventContent>,
        room: Room,
        fallback: String,
    ) -> Self {
        RoomMessage {
            inner,
            room,
            fallback,
        }
    }

    pub fn event_id(&self) -> String {
        self.inner.event_id.to_string()
    }

    pub fn body(&self) -> String {
        self.fallback.clone()
    }

    pub fn formatted_body(&self) -> Option<String> {
        let m = self.inner.clone();
        if let MessageType::Text(content) = m.content.msgtype {
            let mut html_body: Option<String> = None;
            if let Some(formatted_body) = content.formatted {
                if formatted_body.format == MessageFormat::Html {
                    return Some(formatted_body.body);
                }
            }
        }
        None
    }

    pub fn sender(&self) -> String {
        self.inner.sender.to_string()
    }

    pub fn origin_server_ts(&self) -> u64 {
        self.inner.origin_server_ts.as_secs().into()
    }

    pub fn msgtype(&self) -> String {
        self.inner.content.msgtype().to_string()
    }

    pub fn image_description(&self) -> Option<ImageDescription> {
        if let MessageType::Image(content) = &self.inner.content.msgtype {
            let info = content.info.as_ref().unwrap();
            let description = ImageDescription {
                name: content.body.clone(),
                mimetype: info.mimetype.clone(),
                size: info.size.map(u64::from),
                width: info.width.map(u64::from),
                height: info.height.map(u64::from),
            };
            Some(description)
        } else {
            None
        }
    }

    pub fn file_description(&self) -> Option<FileDescription> {
        if let MessageType::File(content) = &self.inner.content.msgtype {
            let info = content.info.as_ref().unwrap();
            let description = FileDescription {
                name: content.body.clone(),
                mimetype: info.mimetype.clone(),
                size: info.size.map(u64::from),
            };
            Some(description)
        } else {
            None
        }
    }
}

pub struct ImageDescription {
    name: String,
    mimetype: Option<String>,
    size: Option<u64>,
    width: Option<u64>,
    height: Option<u64>,
}

impl ImageDescription {
    pub fn name(&self) -> String {
        self.name.clone()
    }

    pub fn mimetype(&self) -> Option<String> {
        self.mimetype.clone()
    }

    pub fn size(&self) -> Option<u64> {
        self.size
    }

    pub fn width(&self) -> Option<u64> {
        self.width
    }

    pub fn height(&self) -> Option<u64> {
        self.height
    }
}

pub struct FileDescription {
    name: String,
    mimetype: Option<String>,
    size: Option<u64>,
}

impl FileDescription {
    pub fn name(&self) -> String {
        self.name.clone()
    }

    pub fn mimetype(&self) -> Option<String> {
        self.mimetype.clone()
    }

    pub fn size(&self) -> Option<u64> {
        self.size
    }
}

pub(crate) fn sync_event_to_message(ev: SyncTimelineEvent, room: Room) -> Option<RoomMessage> {
    if let Ok(AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::RoomMessage(
        SyncMessageLikeEvent::Original(m),
    ))) = ev.event.deserialize()
    {
        Some(RoomMessage {
            fallback: m.content.body().to_string(),
            room,
            inner: m,
        })
    } else {
        None
    }
}

#[derive(Clone)]
pub(crate) struct MessageController {
    event_tx: Sender<RoomMessage>,
    event_rx: Arc<Mutex<Option<Receiver<RoomMessage>>>>,
}

impl MessageController {
    pub fn new() -> Self {
        let (tx, rx) = channel::<RoomMessage>(10); // dropping after more than 10 items queued
        MessageController {
            event_tx: tx,
            event_rx: Arc::new(Mutex::new(Some(rx))),
        }
    }

    pub fn setup(&self, client: &MatrixClient) {
        let me = self.clone();
        client.add_event_handler_context(client.clone());
        client.add_event_handler_context(me.clone());
        client.add_event_handler(
            |ev: OriginalSyncRoomMessageEvent,
             room: Room,
             Ctx(client): Ctx<MatrixClient>,
             Ctx(me): Ctx<MessageController>| async move {
                me.clone().process_room_message(ev, &room, &client);
            },
        );
    }

    fn process_room_message(
        &self,
        ev: OriginalSyncRoomMessageEvent,
        room: &Room,
        client: &MatrixClient,
    ) {
        info!("original sync room message event: {:?}", ev);
        if let Room::Joined(joined) = room {
            let room_id = room.room_id().to_owned();
            let msg = RoomMessage::new(ev.clone(), room.clone(), ev.content.body().to_string());
            let mut event_tx = self.event_tx.clone();
            if let Err(e) = event_tx.try_send(msg) {
                warn!("Dropping ephemeral event for {}: {}", room_id, e);
            }
        }
    }
}

impl Client {
    pub fn message_event_rx(&self) -> Option<Receiver<RoomMessage>> {
        self.message_controller.event_rx.lock().take()
    }
}
