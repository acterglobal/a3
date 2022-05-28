use super::{api, RUNTIME};
use anyhow::{bail, Result};
use matrix_sdk::{
    deserialized_responses::SyncRoomEvent,
    media::{MediaFormat, MediaRequest},
    ruma::events::{
        room::message::{MessageType, RoomMessageEventContent},
        AnySyncMessageLikeEvent, AnySyncRoomEvent, OriginalSyncMessageLikeEvent,
        SyncMessageLikeEvent,
    },
    Client as MatrixClient,
};
use std::sync::Arc;
use url::Url;

pub struct RoomMessage {
    inner: OriginalSyncMessageLikeEvent<RoomMessageEventContent>,
    client: MatrixClient,
    fallback: String,
}

impl RoomMessage {
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

    pub async fn image_binary(&self) -> Result<api::FfiBuffer<u8>> {
        match &self.inner.content.msgtype {
            MessageType::Image(content) => {
                let l = self.client.clone();
                let source = content.source.clone();
                // any variable in self can't be called directly in spawn
                RUNTIME
                    .spawn(async move {
                        let data = l
                            .get_media_content(
                                &MediaRequest {
                                    source,
                                    format: MediaFormat::File,
                                },
                                false,
                            )
                            .await?;
                        Ok(api::FfiBuffer::new(data))
                    })
                    .await?
            }
            _ => bail!("Invalid file format"),
        }
    }

    pub fn image_description(&self) -> Result<ImageDescription> {
        match &self.inner.content.msgtype {
            MessageType::Image(content) => {
                let info = content.info.as_ref().unwrap();
                let description = ImageDescription {
                    img_name: content.body.clone(),
                    img_mimetype: info.mimetype.clone(),
                    img_size: match info.size {
                        Some(value) => u64::from(value),
                        None => 0,
                    },
                    img_width: info.width.map(u64::from),
                    img_height: info.height.map(u64::from),
                };
                Ok(description)
            }
            _ => bail!("Invalid file format"),
        }
    }
}

pub struct ImageDescription {
    img_name: String,
    img_mimetype: Option<String>,
    img_size: u64,
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

    pub fn size(&self) -> u64 {
        self.img_size
    }

    pub fn width(&self) -> Option<u64> {
        self.img_width
    }

    pub fn height(&self) -> Option<u64> {
        self.img_height
    }
}

pub fn sync_event_to_message(
    sync_event: SyncRoomEvent,
    client: MatrixClient,
) -> Option<RoomMessage> {
    match sync_event.event.deserialize() {
        Ok(AnySyncRoomEvent::MessageLike(AnySyncMessageLikeEvent::RoomMessage(
            SyncMessageLikeEvent::Original(m),
        ))) => Some(RoomMessage {
            fallback: m.content.body().to_string(),
            client,
            inner: m,
        }),
        _ => None,
    }
}
