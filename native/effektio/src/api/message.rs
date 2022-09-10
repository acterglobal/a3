use matrix_sdk::{
    deserialized_responses::SyncRoomEvent,
    room::Room,
    ruma::events::{
        room::message::{MessageType, RoomMessageEventContent},
        AnySyncMessageLikeEvent, AnySyncRoomEvent, OriginalSyncMessageLikeEvent,
        SyncMessageLikeEvent,
    },
};

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
        RoomMessage { inner, room, fallback }
    }

    pub fn event_id(&self) -> String {
        self.inner.event_id.to_string()
    }

    pub fn body(&self) -> String {
        self.fallback.clone()
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
                img_name: content.body.clone(),
                img_mimetype: info.mimetype.clone(),
                img_size: info.size.map(u64::from),
                img_width: info.width.map(u64::from),
                img_height: info.height.map(u64::from),
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
                f_name: content.body.clone(),
                f_mimetype: info.mimetype.clone(),
                f_size: info.size.map(u64::from),
            };
            Some(description)
        } else {
            None
        }
    }
}

pub struct ImageDescription {
    img_name: String,
    img_mimetype: Option<String>,
    img_size: Option<u64>,
    img_width: Option<u64>,
    img_height: Option<u64>,
}

impl ImageDescription {
    pub fn name(&self) -> String {
        self.img_name.clone()
    }

    pub fn mimetype(&self) -> Option<String> {
        self.img_mimetype.clone()
    }

    pub fn size(&self) -> Option<u64> {
        self.img_size
    }

    pub fn width(&self) -> Option<u64> {
        self.img_width
    }

    pub fn height(&self) -> Option<u64> {
        self.img_height
    }
}

pub struct FileDescription {
    f_name: String,
    f_mimetype: Option<String>,
    f_size: Option<u64>,
}

impl FileDescription {
    pub fn name(&self) -> String {
        self.f_name.clone()
    }

    pub fn mimetype(&self) -> Option<String> {
        self.f_mimetype.clone()
    }

    pub fn size(&self) -> Option<u64> {
        self.f_size
    }
}

pub fn sync_event_to_message(ev: SyncRoomEvent, room: Room) -> Option<RoomMessage> {
    if let Ok(AnySyncRoomEvent::MessageLike(AnySyncMessageLikeEvent::RoomMessage(
        SyncMessageLikeEvent::Original(msg),
    ))) = ev.event.deserialize()
    {
        let res = RoomMessage::new(msg.clone(), room, msg.content.body().to_string());
        Some(res)
    } else {
        None
    }
}
