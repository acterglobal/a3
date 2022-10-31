use log::info;
use matrix_sdk::{
    deserialized_responses::SyncTimelineEvent,
    room::Room,
    ruma::events::{
        room::message::{MessageFormat, MessageType, OriginalSyncRoomMessageEvent},
        AnySyncMessageLikeEvent, AnySyncTimelineEvent, SyncMessageLikeEvent,
    },
};

#[derive(Clone, Debug)]
pub struct RoomMessage {
    inner: OriginalSyncRoomMessageEvent,
    room: Room,
    fallback: String,
}

impl RoomMessage {
    pub(crate) fn new(inner: OriginalSyncRoomMessageEvent, room: Room, fallback: String) -> Self {
        RoomMessage {
            inner,
            room,
            fallback,
        }
    }

    pub fn event_id(&self) -> String {
        self.inner.event_id.to_string()
    }

    pub fn room_id(&self) -> String {
        self.room.room_id().to_string()
    }

    pub fn body(&self) -> String {
        self.fallback.clone()
    }

    pub fn formatted_body(&self) -> Option<String> {
        let m = self.inner.clone();
        if let MessageType::Text(content) = m.content.msgtype {
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
        self.inner.origin_server_ts.get().into()
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
    info!("sync event to message: {:?}", ev);
    if let Ok(AnySyncTimelineEvent::MessageLike(evt)) = ev.event.deserialize() {
        match evt {
            AnySyncMessageLikeEvent::RoomEncrypted(SyncMessageLikeEvent::Original(m)) => {}
            AnySyncMessageLikeEvent::RoomMessage(SyncMessageLikeEvent::Original(m)) => {
                info!("sync event to message okay");
                return Some(RoomMessage {
                    fallback: m.content.body().to_string(),
                    room,
                    inner: m,
                });
            }
            _ => {}
        }
    }
    info!("sync event to message none");
    None
}
