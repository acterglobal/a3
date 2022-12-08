use log::info;
use matrix_sdk::{
    deserialized_responses::{SyncTimelineEvent, TimelineEvent},
    room::{
        timeline::{
            EventTimelineItem, ReactionDetails, TimelineItem, TimelineItemContent,
            VirtualTimelineItem,
        },
        Room,
    },
    ruma::events::{
        room::{
            encrypted::OriginalSyncRoomEncryptedEvent,
            message::{MessageFormat, MessageType, Relation, RoomMessageEventContent},
        },
        AnySyncMessageLikeEvent, AnySyncTimelineEvent, OriginalSyncMessageLikeEvent,
        SyncMessageLikeEvent,
    },
};
use regex::Regex;
use std::{collections::HashMap, sync::Arc};

#[derive(Clone, Debug)]
pub struct RoomEventItem {
    event_id: String,
    sender: String,
    origin_server_ts: Option<u64>,
    item_content_type: String,
    msgtype: Option<String>,
    text_desc: Option<TextDesc>,
    image_desc: Option<ImageDesc>,
    file_desc: Option<FileDesc>,
    is_reply: bool,
    reactions: HashMap<String, ReactionDesc>,
    is_editable: bool,
}

impl RoomEventItem {
    #[allow(clippy::too_many_arguments)]
    fn new(
        event_id: String,
        sender: String,
        origin_server_ts: Option<u64>,
        item_content_type: String,
        msgtype: Option<String>,
        text_desc: Option<TextDesc>,
        image_desc: Option<ImageDesc>,
        file_desc: Option<FileDesc>,
        is_reply: bool,
        reactions: HashMap<String, ReactionDesc>,
        is_editable: bool,
    ) -> Self {
        RoomEventItem {
            event_id,
            sender,
            origin_server_ts,
            item_content_type,
            msgtype,
            text_desc,
            image_desc,
            file_desc,
            is_reply,
            reactions,
            is_editable,
        }
    }

    pub fn event_id(&self) -> String {
        self.event_id.clone()
    }

    pub fn sender(&self) -> String {
        self.sender.clone()
    }

    pub fn origin_server_ts(&self) -> Option<u64> {
        self.origin_server_ts
    }

    pub fn item_content_type(&self) -> String {
        self.item_content_type.clone()
    }

    pub fn msgtype(&self) -> Option<String> {
        self.msgtype.clone()
    }

    pub fn text_desc(&self) -> Option<TextDesc> {
        self.text_desc.clone()
    }

    pub fn image_desc(&self) -> Option<ImageDesc> {
        self.image_desc.clone()
    }

    pub fn file_desc(&self) -> Option<FileDesc> {
        self.file_desc.clone()
    }

    pub(crate) fn is_reply(&self) -> bool {
        self.is_reply
    }

    pub(crate) fn simplify_body(&mut self) {
        if let Some(mut text_desc) = self.text_desc.clone() {
            if let Some(text) = text_desc.formatted_body() {
                let re = Regex::new(r"^<mx-reply>[\s\S]+</mx-reply>").unwrap();
                let simplified = re.replace(text.as_str(), "").to_string();
                text_desc.set_body(simplified);
                self.text_desc = Some(text_desc);
                info!("regex replaced");
            }
        }
    }

    pub fn reaction_keys(&self) -> Vec<String> {
        self.reactions.keys().cloned().collect()
    }

    pub fn reaction_desc(&self, key: String) -> Option<ReactionDesc> {
        if self.reactions.contains_key(&key) {
            Some(self.reactions[&key].clone())
        } else {
            None
        }
    }

    pub fn is_editable(&self) -> bool {
        self.is_editable
    }
}

#[derive(Clone, Debug)]
pub struct RoomVirtualItem {}

#[derive(Clone, Debug)]
pub struct RoomMessage {
    item_type: String,
    room_id: String,
    event_item: Option<RoomEventItem>,
    virtual_item: Option<RoomVirtualItem>,
}

impl RoomMessage {
    fn new(
        item_type: String,
        room_id: String,
        event_item: Option<RoomEventItem>,
        virtual_item: Option<RoomVirtualItem>,
    ) -> Self {
        RoomMessage {
            item_type,
            room_id,
            event_item,
            virtual_item,
        }
    }

    pub(crate) fn from_original(
        event: &OriginalSyncMessageLikeEvent<RoomMessageEventContent>,
        room: Room,
    ) -> Self {
        info!("room message from original sync event");
        let mut sent_by_me = false;
        if let Some(user_id) = room.client().user_id() {
            if *user_id == event.sender {
                sent_by_me = true;
            }
        }
        let fallback = match &event.content.msgtype {
            MessageType::Audio(content) => "sent an audio.".to_string(),
            MessageType::Emote(content) => content.body.clone(),
            MessageType::File(content) => "sent a file.".to_string(),
            MessageType::Image(content) => "sent an image.".to_string(),
            MessageType::Location(content) => content.body.to_string(),
            MessageType::Notice(content) => content.body.clone(),
            MessageType::ServerNotice(content) => content.body.clone(),
            MessageType::Text(content) => content.body.clone(),
            MessageType::Video(content) => "sent a video.".to_string(),
            _ => "Unknown timeline item".to_string(),
        };
        let mut text_desc = TextDesc {
            body: fallback,
            formatted_body: None,
        };
        let mut image_desc: Option<ImageDesc> = None;
        let mut file_desc: Option<FileDesc> = None;
        let mut is_editable = false;
        match &event.content.msgtype {
            MessageType::Text(content) => {
                if let Some(formatted) = &content.formatted {
                    if formatted.format == MessageFormat::Html {
                        text_desc.set_formatted_body(Some(formatted.body.clone()));
                    }
                }
                if sent_by_me {
                    is_editable = true;
                }
            }
            MessageType::Emote(content) => {
                if sent_by_me {
                    is_editable = true;
                }
            }
            MessageType::Image(content) => {
                if let Some(info) = content.info.as_ref() {
                    image_desc = Some(ImageDesc {
                        name: content.body.clone(),
                        mimetype: info.mimetype.clone(),
                        size: info.size.map(u64::from),
                        width: info.width.map(u64::from),
                        height: info.height.map(u64::from),
                    });
                }
            }
            MessageType::File(content) => {
                if let Some(info) = content.info.as_ref() {
                    file_desc = Some(FileDesc {
                        name: content.body.clone(),
                        mimetype: info.mimetype.clone(),
                        size: info.size.map(u64::from),
                    });
                }
            }
            _ => {}
        }
        let is_reply = matches!(
            &event.content.relates_to,
            Some(Relation::Reply { in_reply_to }),
        );
        // room list needn't show message reaction
        // so sync event handler should keep `reactions` empty
        // reaction event handler needn't exist in conversation controller
        let event_item = RoomEventItem::new(
            event.sender.to_string(),
            event.sender.to_string(),
            Some(event.origin_server_ts.get().into()),
            "Message".to_string(),
            Some(event.content.msgtype().to_string()),
            Some(text_desc),
            image_desc,
            file_desc,
            is_reply,
            Default::default(),
            is_editable,
        );
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(event_item),
            None,
        )
    }

    pub(crate) fn from_timeline_event(
        event: &OriginalSyncRoomEncryptedEvent,
        decrypted: &TimelineEvent,
        room: Room,
    ) -> Self {
        let mut text_desc = TextDesc {
            body: "OriginalSyncRoomEncryptedEvent".to_string(),
            formatted_body: None,
        };
        info!("sync room encrypted: {:?}", decrypted.event.deserialize());
        // if let MessageType::Text(content) = decrypted.event.deserialize() {
        //     if let Some(formatted) = &content.formatted {
        //         if formatted.format == MessageFormat::Html {
        //             text_desc.set_formatted_body(Some(formatted.body.clone()));
        //         }
        //     }
        // }
        let event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            Some(event.origin_server_ts.get().into()),
            "Message".to_string(),
            Some("m.room.encrypted".to_string()),
            Some(text_desc),
            None,
            None,
            false,
            Default::default(),
            false,
        );
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(event_item),
            None,
        )
    }

    pub(crate) fn from_event_timeline_item(event: &EventTimelineItem, room: Room) -> Self {
        let event_id = match event.event_id() {
            Some(id) => id.to_string(),
            None => format!("{:?}", event.key()),
        };
        let room_id = room.room_id().to_string();
        let sender = event.sender().to_string();
        let origin_server_ts: Option<u64> = event.origin_server_ts().map(|x| x.get().into());
        let mut reactions: HashMap<String, ReactionDesc> = HashMap::new();
        for (key, value) in event.reactions().iter() {
            reactions.insert(key.to_string(), ReactionDesc::new(value.count.into()));
        }

        let event_item = match event.content() {
            TimelineItemContent::Message(msg) => {
                let mut sent_by_me = false;
                if let Some(user_id) = room.client().user_id() {
                    if user_id == event.sender() {
                        sent_by_me = true;
                    }
                }
                let msgtype = msg.msgtype();
                let fallback = match msgtype {
                    MessageType::Audio(content) => "sent an audio.".to_string(),
                    MessageType::Emote(content) => content.body.clone(),
                    MessageType::File(content) => "sent a file.".to_string(),
                    MessageType::Image(content) => "sent an image.".to_string(),
                    MessageType::Location(content) => content.body.clone(),
                    MessageType::Notice(content) => content.body.clone(),
                    MessageType::ServerNotice(content) => content.body.clone(),
                    MessageType::Text(content) => content.body.clone(),
                    MessageType::Video(content) => "sent a video.".to_string(),
                    _ => "Unknown timeline item".to_string(),
                };
                let mut text_desc = TextDesc {
                    body: fallback,
                    formatted_body: None,
                };
                let mut image_desc: Option<ImageDesc> = None;
                let mut file_desc: Option<FileDesc> = None;
                let mut is_editable = false;
                match msgtype {
                    MessageType::Text(content) => {
                        if let Some(formatted) = &content.formatted {
                            if formatted.format == MessageFormat::Html {
                                text_desc.set_formatted_body(Some(formatted.body.clone()));
                            }
                        }
                        if sent_by_me {
                            is_editable = true;
                        }
                    }
                    MessageType::Emote(content) => {
                        if sent_by_me {
                            is_editable = true;
                        }
                    }
                    MessageType::Image(content) => {
                        if let Some(info) = content.info.as_ref() {
                            image_desc = Some(ImageDesc {
                                name: content.body.clone(),
                                mimetype: info.mimetype.clone(),
                                size: info.size.map(u64::from),
                                width: info.width.map(u64::from),
                                height: info.height.map(u64::from),
                            });
                        }
                    }
                    MessageType::File(content) => {
                        if let Some(info) = content.info.as_ref() {
                            file_desc = Some(FileDesc {
                                name: content.body.clone(),
                                mimetype: info.mimetype.clone(),
                                size: info.size.map(u64::from),
                            });
                        }
                    }
                    _ => {}
                }
                let is_reply = match msg.in_reply_to() {
                    Some(in_reply_to) => true,
                    None => false,
                };
                RoomEventItem::new(
                    event_id,
                    sender,
                    origin_server_ts,
                    "Message".to_string(),
                    Some(msgtype.msgtype().to_string()),
                    Some(text_desc),
                    image_desc,
                    file_desc,
                    is_reply,
                    reactions,
                    is_editable,
                )
            }
            TimelineItemContent::RedactedMessage => {
                info!("Edit event applies to a redacted message, discarding");
                RoomEventItem::new(
                    event_id,
                    sender,
                    origin_server_ts,
                    "RedactedMessage".to_string(),
                    None,
                    None,
                    None,
                    None,
                    false,
                    Default::default(),
                    false,
                )
            }
            TimelineItemContent::UnableToDecrypt(encrypted_msg) => {
                info!("Edit event applies to event that couldn't be decrypted, discarding");
                RoomEventItem::new(
                    event_id,
                    sender,
                    origin_server_ts,
                    "UnableToDecrypt".to_string(),
                    None,
                    None,
                    None,
                    None,
                    false,
                    Default::default(),
                    false,
                )
            }
            TimelineItemContent::FailedToParseMessageLike { event_type, error } => {
                info!("Edit event applies to event that couldn't be parsed, discarding");
                RoomEventItem::new(
                    event_id,
                    sender,
                    origin_server_ts,
                    "FailedToParseMessageLike".to_string(),
                    None,
                    None,
                    None,
                    None,
                    false,
                    Default::default(),
                    false,
                )
            }
            TimelineItemContent::FailedToParseState {
                event_type,
                state_key,
                error,
            } => {
                info!("Edit event applies to event that couldn't be parsed, discarding");
                RoomEventItem::new(
                    event_id,
                    sender,
                    origin_server_ts,
                    "FailedToParseState".to_string(),
                    None,
                    None,
                    None,
                    None,
                    false,
                    Default::default(),
                    false,
                )
            }
        };
        RoomMessage::new("event".to_string(), room_id, Some(event_item), None)
    }

    pub(crate) fn from_virtual_timeline_item(event: &VirtualTimelineItem, room: Room) -> Self {
        let room_id = room.room_id().to_string();
        RoomMessage::new(
            "virtual".to_string(),
            room_id,
            None,
            Some(RoomVirtualItem {}),
        )
    }

    pub fn item_type(&self) -> String {
        self.item_type.clone()
    }

    pub fn room_id(&self) -> String {
        self.room_id.clone()
    }

    pub fn event_item(&self) -> Option<RoomEventItem> {
        self.event_item.clone()
    }

    pub(crate) fn set_event_item(&mut self, event_item: Option<RoomEventItem>) {
        self.event_item = event_item;
    }

    pub fn virtual_item(&self) -> Option<RoomVirtualItem> {
        self.virtual_item.clone()
    }
}

#[derive(Clone, Debug)]
pub struct TextDesc {
    body: String,
    formatted_body: Option<String>,
}

impl TextDesc {
    pub fn body(&self) -> String {
        self.body.clone()
    }

    pub(crate) fn set_body(&mut self, text: String) {
        self.body = text;
    }

    pub fn formatted_body(&self) -> Option<String> {
        self.formatted_body.clone()
    }

    pub(crate) fn set_formatted_body(&mut self, text: Option<String>) {
        self.formatted_body = text;
    }
}

#[derive(Clone, Debug)]
pub struct ImageDesc {
    name: String,
    mimetype: Option<String>,
    size: Option<u64>,
    width: Option<u64>,
    height: Option<u64>,
}

impl ImageDesc {
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
pub struct FileDesc {
    name: String,
    mimetype: Option<String>,
    size: Option<u64>,
}

impl FileDesc {
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

#[derive(Clone, Debug)]
pub struct ReactionDesc {
    count: u64,
}

impl ReactionDesc {
    pub(crate) fn new(count: u64) -> Self {
        ReactionDesc { count }
    }

    pub fn count(&self) -> u64 {
        self.count
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

pub(crate) fn timeline_item_to_message(item: Arc<TimelineItem>, room: Room) -> RoomMessage {
    match item.as_ref() {
        TimelineItem::Event(event_item) => RoomMessage::from_event_timeline_item(event_item, room),
        TimelineItem::Virtual(virtual_item) => {
            RoomMessage::from_virtual_timeline_item(virtual_item, room)
        }
    }
}
