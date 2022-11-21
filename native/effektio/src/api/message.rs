use log::info;
use matrix_sdk::{
    deserialized_responses::{SyncTimelineEvent, TimelineEvent},
    room::{
        timeline::{EventTimelineItem, TimelineItem, TimelineItemContent},
        Room,
    },
    ruma::events::{
        room::{
            encrypted::OriginalSyncRoomEncryptedEvent,
            message::{MessageFormat, MessageType, RoomMessageEventContent},
        },
        AnySyncMessageLikeEvent, AnySyncTimelineEvent, OriginalSyncMessageLikeEvent,
        SyncMessageLikeEvent,
    },
};
use std::sync::Arc;

#[derive(Clone, Debug)]
pub struct RoomMessage {
    event_id: String,
    room_id: String,
    body: String,
    formatted_body: Option<String>,
    sender: String,
    origin_server_ts: Option<u64>,
    msgtype: String,
    image_description: Option<ImageDescription>,
    file_description: Option<FileDescription>,
}

impl RoomMessage {
    #[allow(clippy::too_many_arguments)]
    fn new(
        event_id: String,
        room_id: String,
        body: String,
        formatted_body: Option<String>,
        sender: String,
        origin_server_ts: Option<u64>,
        msgtype: String,
        image_description: Option<ImageDescription>,
        file_description: Option<FileDescription>,
    ) -> Self {
        RoomMessage {
            event_id,
            room_id,
            body,
            formatted_body,
            sender,
            origin_server_ts,
            msgtype,
            image_description,
            file_description,
        }
    }

    pub(crate) fn from_original(
        event: &OriginalSyncMessageLikeEvent<RoomMessageEventContent>,
        room: Room,
    ) -> Self {
        let mut formatted_body: Option<String> = None;
        if let MessageType::Text(content) = &event.content.msgtype {
            if let Some(formatted) = &content.formatted {
                if formatted.format == MessageFormat::Html {
                    formatted_body = Some(formatted.body.clone());
                }
            }
        }
        let mut image_description: Option<ImageDescription> = None;
        if let MessageType::Image(content) = &event.content.msgtype {
            if let Some(info) = content.info.as_ref() {
                image_description = Some(ImageDescription {
                    name: content.body.clone(),
                    mimetype: info.mimetype.clone(),
                    size: info.size.map(u64::from),
                    width: info.width.map(u64::from),
                    height: info.height.map(u64::from),
                });
            }
        }
        let mut file_description: Option<FileDescription> = None;
        if let MessageType::File(content) = &event.content.msgtype {
            if let Some(info) = content.info.as_ref() {
                file_description = Some(FileDescription {
                    name: content.body.clone(),
                    mimetype: info.mimetype.clone(),
                    size: info.size.map(u64::from),
                });
            }
        }
        RoomMessage::new(
            event.event_id.to_string(),
            room.room_id().to_string(),
            event.content.body().to_string(),
            formatted_body,
            event.sender.to_string(),
            Some(event.origin_server_ts.get().into()),
            event.content.msgtype().to_string(),
            image_description,
            file_description,
        )
    }

    pub(crate) fn from_timeline_event(
        event: &OriginalSyncRoomEncryptedEvent,
        decrypted: &TimelineEvent,
        room: Room,
    ) -> Self {
        let mut formatted_body: Option<String> = None;
        info!("sync room encrypted: {:?}", decrypted.event.deserialize());
        // if let MessageType::Text(content) = decrypted.event.deserialize() {
        //     if let Some(formatted) = &content.formatted {
        //         if formatted.format == MessageFormat::Html {
        //             formatted_body = Some(formatted.body.clone());
        //         }
        //     }
        // }
        RoomMessage::new(
            event.event_id.to_string(),
            room.room_id().to_string(),
            "OriginalSyncRoomEncryptedEvent".to_string(),
            formatted_body,
            event.sender.to_string(),
            Some(event.origin_server_ts.get().into()),
            "m.room.encrypted".to_string(),
            None,
            None,
        )
    }

    pub(crate) fn from_timeline_item(
        event: &EventTimelineItem,
        room: Room,
        body: String,
        msgtype: String,
    ) -> Option<Self> {
        let event_id = match event.event_id() {
            Some(id) => id.to_string(),
            None => format!("{:?}", event.key()),
        };
        let mut formatted_body: Option<String> = None;
        let mut image_description: Option<ImageDescription> = None;
        let mut file_description: Option<FileDescription> = None;
        match event.content() {
            TimelineItemContent::Message(msg) => {
                if let MessageType::Text(content) = msg.msgtype() {
                    if let Some(formatted) = &content.formatted {
                        if formatted.format == MessageFormat::Html {
                            formatted_body = Some(formatted.body.clone());
                        }
                    }
                }
                if let MessageType::Image(content) = msg.msgtype() {
                    if let Some(info) = content.info.as_ref() {
                        image_description = Some(ImageDescription {
                            name: content.body.clone(),
                            mimetype: info.mimetype.clone(),
                            size: info.size.map(u64::from),
                            width: info.width.map(u64::from),
                            height: info.height.map(u64::from),
                        });
                    }
                }
                if let MessageType::File(content) = msg.msgtype() {
                    if let Some(info) = content.info.as_ref() {
                        file_description = Some(FileDescription {
                            name: content.body.clone(),
                            mimetype: info.mimetype.clone(),
                            size: info.size.map(u64::from),
                        });
                    }
                }
                return Some(RoomMessage::new(
                    event_id,
                    room.room_id().to_string(),
                    body,
                    formatted_body,
                    event.sender().to_string(),
                    event.origin_server_ts().map(|x| x.get().into()),
                    msgtype,
                    image_description,
                    file_description,
                ));
            }
            TimelineItemContent::RedactedMessage => {
                info!("Edit event applies to a redacted message, discarding");
            }
        }
        None
    }

    pub fn event_id(&self) -> String {
        self.event_id.clone()
    }

    pub fn room_id(&self) -> String {
        self.room_id.clone()
    }

    pub fn body(&self) -> String {
        self.body.clone()
    }

    pub fn formatted_body(&self) -> Option<String> {
        self.formatted_body.clone()
    }

    pub fn sender(&self) -> String {
        self.sender.clone()
    }

    pub fn origin_server_ts(&self) -> Option<u64> {
        self.origin_server_ts
    }

    pub fn msgtype(&self) -> String {
        self.msgtype.clone()
    }

    pub fn image_description(&self) -> Option<ImageDescription> {
        self.image_description.clone()
    }

    pub fn file_description(&self) -> Option<FileDescription> {
        self.file_description.clone()
    }
}

#[derive(Clone, Debug)]
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

#[derive(Clone, Debug)]
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
                return Some(RoomMessage::from_original(&m, room));
            }
            _ => {}
        }
    }
    None
}

pub(crate) fn timeline_item_to_message(item: Arc<TimelineItem>, room: Room) -> Option<RoomMessage> {
    if let Some(event) = item.as_event() {
        if let TimelineItemContent::Message(msg) = event.content() {
            let fallback = match &msg.msgtype() {
                MessageType::Audio(audio) => audio.body.clone(),
                MessageType::Emote(emote) => emote.body.clone(),
                MessageType::File(file) => file.body.clone(),
                MessageType::Image(image) => image.body.clone(),
                MessageType::Location(location) => location.body.clone(),
                MessageType::Notice(notice) => notice.body.clone(),
                MessageType::ServerNotice(service_notice) => service_notice.body.clone(),
                MessageType::Text(text) => text.body.clone(),
                MessageType::Video(video) => video.body.clone(),
                _ => "Unknown timeline item".to_string(),
            };
            info!("timeline fallback: {:?}", fallback);
            return RoomMessage::from_timeline_item(
                event,
                room,
                fallback,
                msg.msgtype().msgtype().to_string(),
            );
        }
    }
    None
}
