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
        self.origin_server_ts
    }
}

#[derive(Clone)]
pub struct TextMessage {
    base_message: BaseMessage,
}

impl TextMessage {
    pub fn base_message(&self) -> BaseMessage {
        self.base_message.clone()
    }
}

#[derive(Clone)]
pub struct ImageMessage {
    base_message: BaseMessage,
    url: Option<Box<MxcUri>>,
}

impl ImageMessage {
    pub fn base_message(&self) -> BaseMessage {
        self.base_message.clone()
    }

    pub fn url(&self) -> Option<String> {
        self.url.clone().map(|url| url.to_string())
    }
}

#[derive(Clone)]
pub struct AnyMessage {
    text: Option<TextMessage>,
    image: Option<ImageMessage>,
}

impl AnyMessage {
    pub fn text(&self) -> Option<TextMessage> {
        self.text.clone()
    }

    pub fn image(&self) -> Option<ImageMessage> {
        self.image.clone()
    }
}

pub fn sync_event_to_message(sync_event: SyncRoomEvent) -> Option<AnyMessage> {
    match sync_event.event.deserialize() {
        Ok(AnySyncRoomEvent::Message(AnySyncMessageEvent::RoomMessage(m))) => {
            let base_message = BaseMessage {
                id: m.event_id.to_string(),
                content: m.content.body().to_string(),
                sender: m.sender.to_string(),
                origin_server_ts: m.origin_server_ts.as_secs().into(),
            };

            match m.content.msgtype {
                MessageType::Image(content) => {
                    let any_message = AnyMessage {
                        text: None,
                        image: Some(ImageMessage {
                            base_message,
                            url: content.url,
                        }),
                    };

                    Some(any_message)
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
                        text: Some(TextMessage { base_message }),
                        image: None,
                    };
                    Some(any_message)
                }
            }
        }
        _ => None,
    }
}
