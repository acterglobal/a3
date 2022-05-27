use super::{api, Client, RUNTIME};
use anyhow::{bail, Result};
use matrix_sdk::{
    Client as MatrixClient,
    deserialized_responses::SyncRoomEvent,
    media::{MediaFormat, MediaRequest},
    ruma::{
        events::{
            room::{
                message::{MessageType, RoomMessageEventContent},
                MediaSource,
            },
            AnySyncMessageLikeEvent, AnySyncRoomEvent, OriginalSyncMessageLikeEvent,
            SyncMessageLikeEvent,
        },
        MxcUri, OwnedMxcUri,
    },
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

    pub async fn image_description(&self) -> Result<ImageDescription> {
        match &self.inner.content.msgtype {
            MessageType::Image(content) => {
                let client = self.client.clone();
                let info = content.info.as_ref().unwrap();
                RUNTIME.block_on(async move {
                    let bin_data = client
                        .get_media_content(
                            &MediaRequest {
                                source: content.source.clone(),
                                format: MediaFormat::File,
                            },
                            false,
                        )
                        .await?;
                    let description = ImageDescription {
                        client: client.clone(),
                        _bin_data: bin_data,
                        _name: content.body.clone(),
                        _mimetype: match info.mimetype.as_ref() {
                            Some(value) => Some(value.clone()),
                            None => None,
                        },
                        _size: match info.size {
                            Some(value) => u64::from(value),
                            None => 0,
                        },
                        _width: match info.width {
                            Some(value) => Some(u64::from(value)),
                            None => None,
                        },
                        _height: match info.height {
                            Some(value) => Some(u64::from(value)),
                            None => None,
                        },
                    };
                    Ok(description)
                })
            }
            _ => bail!("Invalid file format"),
        }
    }
}

pub struct ImageDescription {
    client: MatrixClient,
    _bin_data: Vec<u8>,
    _name: String,
    _mimetype: Option<String>,
    _size: u64,
    _width: Option<u64>,
    _height: Option<u64>,
}

impl ImageDescription {
    pub async fn bin_data(&self) -> Result<api::FfiBuffer<u8>> {
        let data = self._bin_data.clone();
        // any variable in self can't be called directly in spawn
        RUNTIME
            .spawn(async move { Ok(api::FfiBuffer::new(data)) })
            .await?
    }

    pub fn name(&self) -> String {
        self._name.clone()
    }

    pub fn mimetype(&self) -> Option<String> {
        self._mimetype.clone()
    }

    pub fn size(&self) -> u64 {
        self._size
    }

    pub fn width(&self) -> Option<u64> {
        self._width
    }

    pub fn height(&self) -> Option<u64> {
        self._height
    }
}

pub fn sync_event_to_message(sync_event: SyncRoomEvent, client: MatrixClient) -> Option<RoomMessage> {
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
