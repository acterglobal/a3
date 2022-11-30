use log::info;
use matrix_sdk::{
    deserialized_responses::{SyncTimelineEvent, TimelineEvent},
    room::{
        timeline::{EventTimelineItem, ReactionDetails, TimelineItem, TimelineItemContent},
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
    is_reply: bool,
    reactions: HashMap<String, ReactionDescription>,
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
        is_reply: bool,
        reactions: HashMap<String, ReactionDescription>,
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
            is_reply,
            reactions,
        }
    }

    pub(crate) fn from_original(
        event: &OriginalSyncMessageLikeEvent<RoomMessageEventContent>,
        room: Room,
    ) -> Self {
        info!("room message from original sync event");
        let fallback = match &event.content.msgtype {
            MessageType::Audio(audio) => "sent an audio.".to_string(),
            MessageType::Emote(emote) => emote.body.clone(),
            MessageType::File(file) => "sent a file.".to_string(),
            MessageType::Image(image) => "sent an image.".to_string(),
            MessageType::Location(location) => location.body.to_string(),
            MessageType::Notice(notice) => notice.body.clone(),
            MessageType::ServerNotice(server_notice) => server_notice.body.clone(),
            MessageType::Text(text) => text.body.clone(),
            MessageType::Video(video) => "sent a video.".to_string(),
            _ => "Unknown timeline item".to_string(),
        };
        let mut formatted_body: Option<String> = None;
        let mut image_description: Option<ImageDescription> = None;
        let mut file_description: Option<FileDescription> = None;
        match &event.content.msgtype {
            MessageType::Text(content) => {
                if let Some(formatted) = &content.formatted {
                    if formatted.format == MessageFormat::Html {
                        formatted_body = Some(formatted.body.clone());
                    }
                }
            }
            MessageType::Image(content) => {
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
            MessageType::File(content) => {
                if let Some(info) = content.info.as_ref() {
                    file_description = Some(FileDescription {
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
        RoomMessage::new(
            event.event_id.to_string(),
            room.room_id().to_string(),
            fallback,
            formatted_body,
            event.sender.to_string(),
            Some(event.origin_server_ts.get().into()),
            event.content.msgtype().to_string(),
            image_description,
            file_description,
            is_reply,
            Default::default(),
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
            false,
            Default::default(),
        )
    }

    pub(crate) fn from_timeline_item(event: &EventTimelineItem, room: Room) -> Option<Self> {
        let mut reactions: HashMap<String, ReactionDescription> = HashMap::new();
        for (key, value) in event.reactions().iter() {
            reactions.insert(
                key.to_string(),
                ReactionDescription::new(value.count.into()),
            );
        }
        let event_id = match event.event_id() {
            Some(id) => id.to_string(),
            None => format!("{:?}", event.key()),
        };
        match event.content() {
            TimelineItemContent::Message(msg) => {
                let msgtype = msg.msgtype();
                let fallback = match &msgtype {
                    MessageType::Audio(audio) => "sent an audio.".to_string(),
                    MessageType::Emote(emote) => emote.body.clone(),
                    MessageType::File(file) => "sent a file.".to_string(),
                    MessageType::Image(image) => "sent an image.".to_string(),
                    MessageType::Location(location) => location.body.clone(),
                    MessageType::Notice(notice) => notice.body.clone(),
                    MessageType::ServerNotice(server_notice) => server_notice.body.clone(),
                    MessageType::Text(text) => text.body.clone(),
                    MessageType::Video(video) => "sent a video.".to_string(),
                    _ => "Unknown timeline item".to_string(),
                };
                let mut formatted_body: Option<String> = None;
                let mut image_description: Option<ImageDescription> = None;
                let mut file_description: Option<FileDescription> = None;
                match msgtype {
                    MessageType::Text(content) => {
                        if let Some(formatted) = &content.formatted {
                            if formatted.format == MessageFormat::Html {
                                formatted_body = Some(formatted.body.clone());
                            }
                        }
                    }
                    MessageType::Image(content) => {
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
                    MessageType::File(content) => {
                        if let Some(info) = content.info.as_ref() {
                            file_description = Some(FileDescription {
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
                return Some(RoomMessage::new(
                    event_id,
                    room.room_id().to_string(),
                    fallback,
                    formatted_body,
                    event.sender().to_string(),
                    event.origin_server_ts().map(|x| x.get().into()),
                    msgtype.msgtype().to_string(),
                    image_description,
                    file_description,
                    is_reply,
                    reactions,
                ));
            }
            TimelineItemContent::RedactedMessage => {
                info!("Edit event applies to a redacted message, discarding");
            }
            TimelineItemContent::UnableToDecrypt(encrypted_msg) => {
                info!("Edit event applies to event that couldn't be decrypted, discarding");
            }
            TimelineItemContent::FailedToParseMessageLike { event_type, error } => {}
            TimelineItemContent::FailedToParseState {
                event_type,
                state_key,
                error,
            } => {}
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

    pub(crate) fn is_reply(&self) -> bool {
        self.is_reply
    }

    pub(crate) fn simplify_body(&mut self) {
        if let Some(text) = self.formatted_body.clone() {
            let re = Regex::new(r"^<mx-reply>[\s\S]+</mx-reply>").unwrap();
            self.body = re.replace(text.as_str(), "").to_string();
            info!("regex replaced");
        }
    }

    pub fn reaction_keys(&self) -> Vec<String> {
        self.reactions.keys().cloned().collect()
    }

    pub fn reaction_description(&self, key: String) -> Option<ReactionDescription> {
        if self.reactions.contains_key(&key) {
            Some(self.reactions[&key].clone())
        } else {
            None
        }
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

#[derive(Clone, Debug)]
pub struct ReactionDescription {
    count: u64,
}

impl ReactionDescription {
    pub(crate) fn new(count: u64) -> Self {
        ReactionDescription { count }
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

pub(crate) fn timeline_item_to_message(item: Arc<TimelineItem>, room: Room) -> Option<RoomMessage> {
    if let Some(event) = item.as_event() {
        return RoomMessage::from_timeline_item(event, room);
    }
    None
}
