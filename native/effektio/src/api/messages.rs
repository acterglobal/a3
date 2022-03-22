use std::sync::Arc;

use matrix_sdk::{
    deserialized_responses::SyncRoomEvent,
    ruma::{
        events::{room::message::MessageType, AnySyncMessageEvent, AnySyncRoomEvent},
        MxcUri,
    },
};

#[derive(Clone)]
pub struct BaseMessage {
    id: String,
    content: String,
    sender: String,
    origin_server_ts: u64,
}

impl BaseMessage {
    pub fn id(&self) -> String {
        self.id.clone()
    }

    pub fn content(&self) -> String {
        self.content.clone()
    }

    pub fn sender(&self) -> String {
        self.sender.clone()
    }

    pub fn origin_server_ts(&self) -> u64 {
        self.origin_server_ts.clone()
    }
}

pub struct TextMessage {
    base_message: Arc<BaseMessage>,
}

impl TextMessage {
    pub fn base_message(&self) -> Arc<BaseMessage> {
        return self.base_message.clone();
    }
}

pub struct ImageMessage {
    base_message: Arc<BaseMessage>,
    url: Option<Box<MxcUri>>,
}

impl ImageMessage {
    pub fn base_message(&self) -> Arc<BaseMessage> {
        return self.base_message.clone();
    }

    pub fn url(&self) -> Option<String> {
        match self.url.clone() {
            Some(url) => return Some(url.to_string()),
            _ => return None,
        }
    }
}

pub struct AnyMessage {
    text: Option<Arc<TextMessage>>,
    image: Option<Arc<ImageMessage>>,
}

impl AnyMessage {
    pub fn text(&self) -> Option<Arc<TextMessage>> {
        self.text.clone()
    }

    pub fn image(&self) -> Option<Arc<ImageMessage>> {
        self.image.clone()
    }
}

pub fn sync_event_to_message(sync_event: SyncRoomEvent) -> Option<Arc<AnyMessage>> {
    match sync_event.event.deserialize() {
        Ok(AnySyncRoomEvent::Message(AnySyncMessageEvent::RoomMessage(m))) => {
            let base_message = Arc::new(BaseMessage {
                id: m.event_id.to_string(),
                content: m.content.body().to_string(),
                sender: m.sender.to_string(),
                origin_server_ts: m.origin_server_ts.as_secs().into(),
            });

            match m.content.msgtype {
                MessageType::Image(content) => {
                    let any_message = AnyMessage {
                        text: None,
                        image: Some(Arc::new(ImageMessage {
                            base_message,
                            url: content.url,
                        })),
                    };

                    return Some(Arc::new(any_message));
                }
                // MessageType::Audio(content) => {

                // }
                // MessageType::Emote(content) => {

                // }
                // MessageType::Location(content) => {

                // }
                // MessageType::File(content) => {

                // }
                // MessageType::Video(content) => {

                // }
                // MessageType::Text(content) => {

                // }
                _ => {
                    let any_message = AnyMessage {
                        text: Some(Arc::new(TextMessage { base_message })),
                        image: None,
                    };
                    return Some(Arc::new(any_message));
                }
            }
        }
        _ => None,
    }
}
