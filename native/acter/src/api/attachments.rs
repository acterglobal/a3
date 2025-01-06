use acter_core::{
    events::{
        attachments::{
            AttachmentBuilder, AttachmentContent, FallbackAttachmentContent, LinkAttachmentContent,
        },
        RefDetails as CoreRefDetails,
    },
    models::{self, can_redact, ActerModel, AnyActerModel},
};
use anyhow::{bail, Context, Result};
use futures::stream::StreamExt;
use matrix_sdk::room::Room;
use matrix_sdk_base::{
    media::{MediaFormat, MediaRequestParameters},
    ruma::{events::MessageLikeEventType, EventId, OwnedEventId, OwnedTransactionId, OwnedUserId},
    RoomState,
};
use std::{fs::exists, io::Write, ops::Deref, path::PathBuf};
use tokio::sync::broadcast::Receiver;
use tokio_stream::Stream;
use tracing::warn;

use super::{client::Client, common::ThumbnailSize, deep_linking::RefDetails, RUNTIME};
use crate::{MsgContent, MsgDraft, OptionString};

impl Client {
    pub async fn wait_for_attachment(
        &self,
        key: String,
        timeout: Option<u8>,
    ) -> Result<Attachment> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let AnyActerModel::Attachment(attachment) =
                    me.wait_for(key.clone(), timeout).await?
                else {
                    bail!("{key} is not a attachment");
                };
                let room = me.room_by_id_typed(&attachment.meta.room_id)?;
                Ok(Attachment {
                    client: me.clone(),
                    room,
                    inner: attachment,
                })
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct Attachment {
    client: Client,
    room: Room,
    inner: models::Attachment,
}

impl Deref for Attachment {
    type Target = models::Attachment;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl Attachment {
    pub fn name(&self) -> Option<String> {
        self.inner.content.name()
    }

    pub fn link(&self) -> Option<String> {
        self.inner.content.link()
    }

    pub fn attachment_id_str(&self) -> String {
        self.inner.meta.event_id.to_string()
    }

    pub fn room_id_str(&self) -> String {
        self.room.room_id().to_string()
    }

    pub fn type_str(&self) -> String {
        self.inner.content().type_str()
    }

    pub fn sender(&self) -> String {
        self.inner.meta.sender.to_string()
    }

    pub fn origin_server_ts(&self) -> u64 {
        self.inner.meta.origin_server_ts.get().into()
    }

    pub fn ref_details(&self) -> Option<RefDetails> {
        if let AttachmentContent::Reference(r) = &self.inner.content {
            Some(RefDetails::new(self.client.clone(), r.clone()))
        } else {
            None
        }
    }

    pub fn msg_content(&self) -> Option<MsgContent> {
        MsgContent::try_from(&self.inner.content).ok()
    }

    pub async fn can_redact(&self) -> Result<bool> {
        let sender = self.inner.meta.sender.to_owned();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move { Ok(can_redact(&room, &sender).await?) })
            .await?
    }

    pub async fn download_media(
        &self,
        thumb_size: Option<Box<ThumbnailSize>>,
        dir_path: String,
    ) -> Result<OptionString> {
        let room = self.room.clone();
        let client = self.client.deref().clone();
        let evt_id = self.inner.meta.event_id.clone();
        let evt_content = self.inner.content().clone();

        RUNTIME
            .spawn(async move {
                // get file extension from msg info
                let (request, mut filename) = match thumb_size.clone() {
                    Some(thumb_size) => match evt_content {
                        AttachmentContent::Image(content) | AttachmentContent::Fallback(FallbackAttachmentContent::Image(content)) => {
                            let request = content
                                .info
                                .as_ref()
                                .and_then(|info| info.thumbnail_source.clone())
                                .map(|source| MediaRequestParameters {
                                    source,
                                    format: MediaFormat::from(thumb_size),
                                });
                            let filename = content
                                .info
                                .clone()
                                .and_then(|info| info.mimetype)
                                .and_then(|mimetype| {
                                    mime2ext::mime2ext(mimetype).map(|ext| {
                                        format!("{}-thumbnail.{}", evt_id, ext)
                                    })
                                });
                            (request, filename)
                        }
                        AttachmentContent::Video(content) | AttachmentContent::Fallback(FallbackAttachmentContent::Video(content)) => {
                            let request = content
                                .info
                                .as_ref()
                                .and_then(|info| info.thumbnail_source.clone())
                                .map(|source| MediaRequestParameters {
                                    source,
                                    format: MediaFormat::from(thumb_size),
                                });
                            let filename = content
                                .info
                                .clone()
                                .and_then(|info| info.mimetype)
                                .and_then(|mimetype| {
                                    mime2ext::mime2ext(mimetype).map(|ext| {
                                        format!("{}-thumbnail.{}", evt_id, ext)
                                    })
                                });
                            (request, filename)
                        }
                        AttachmentContent::File(content) | AttachmentContent::Fallback(FallbackAttachmentContent::File(content)) => {
                            let request = content
                                .info
                                .as_ref()
                                .and_then(|info| info.thumbnail_source.clone())
                                .map(|source| MediaRequestParameters {
                                    source,
                                    format: MediaFormat::from(thumb_size),
                                });
                            let filename = content
                                .info
                                .clone()
                                .and_then(|info| info.mimetype)
                                .and_then(|mimetype| {
                                    mime2ext::mime2ext(mimetype).map(|ext| {
                                        format!("{}-thumbnail.{}", evt_id, ext)
                                    })
                                });
                            (request, filename)
                        }
                        AttachmentContent::Location(content) | AttachmentContent::Fallback(FallbackAttachmentContent::Location(content)) => {
                            let request = content
                                .info
                                .as_ref()
                                .and_then(|info| info.thumbnail_source.clone())
                                .map(|source| MediaRequestParameters {
                                    source,
                                    format: MediaFormat::from(thumb_size),
                                });
                            let filename = content
                                .info
                                .clone()
                                .and_then(|info| info.thumbnail_info)
                                .and_then(|info| info.mimetype)
                                .and_then(|mimetype| {
                                    mime2ext::mime2ext(mimetype).map(|ext| {
                                        format!("{}-thumbnail.{}", evt_id, ext)
                                    })
                                });
                            (request, filename)
                        }
                        _ => bail!("This attachment type is not downloadable"),
                    },
                    None => match evt_content {
                        AttachmentContent::Image(content) | AttachmentContent::Fallback(FallbackAttachmentContent::Image(content)) => {
                            let request = MediaRequestParameters {
                                source: content.source.clone(),
                                format: MediaFormat::File,
                            };
                            let filename = content
                                .info
                                .clone()
                                .and_then(|info| info.mimetype)
                                .and_then(|mimetype| {
                                    mime2ext::mime2ext(mimetype)
                                        .map(|ext| format!("{}.{}", evt_id, ext))
                                });
                            (Some(request), filename)
                        }
                        AttachmentContent::Audio(content) | AttachmentContent::Fallback(FallbackAttachmentContent::Audio(content)) => {
                            let request = MediaRequestParameters {
                                source: content.source.clone(),
                                format: MediaFormat::File,
                            };
                            let filename = content
                                .info
                                .clone()
                                .and_then(|info| info.mimetype)
                                .and_then(|mimetype| {
                                    mime2ext::mime2ext(mimetype)
                                        .map(|ext| format!("{}.{}", evt_id, ext))
                                });
                            (Some(request), filename)
                        }
                        AttachmentContent::Video(content) | AttachmentContent::Fallback(FallbackAttachmentContent::Video(content)) => {
                            let request = MediaRequestParameters {
                                source: content.source.clone(),
                                format: MediaFormat::File,
                            };
                            let filename = content
                                .info
                                .clone()
                                .and_then(|info| info.mimetype)
                                .and_then(|mimetype| {
                                    mime2ext::mime2ext(mimetype)
                                        .map(|ext| format!("{}.{}",evt_id, ext))
                                });
                            (Some(request), filename)
                        }
                        AttachmentContent::File(content) | AttachmentContent::Fallback(FallbackAttachmentContent::File(content)) => {
                            let request = MediaRequestParameters {
                                source: content.source.clone(),
                                format: MediaFormat::File,
                            };
                            let filename = content
                                .info
                                .clone()
                                .and_then(|info| info.mimetype)
                                .and_then(|mimetype| {
                                    mime2ext::mime2ext(mimetype)
                                        .map(|ext| format!("{}.{}", evt_id, ext))
                                });
                            (Some(request), filename)
                        }
                        _ => bail!("This message type is not downloadable"),
                    },
                };
                let Some(request) = request else {
                    warn!("Content info or thumbnail source not found");
                    return Ok(OptionString::new(None));
                };
                let data = client.media().get_media_content(&request, false).await?;
                // infer file extension via parsing of file binary
                if filename.is_none() {
                    if let Some(kind) = infer::get(&data) {
                        filename = Some(if thumb_size.clone().is_some() {
                            format!("{}-thumbnail.{}", evt_id, kind.extension())
                        } else {
                            format!("{}.{}", evt_id, kind.extension())
                        });
                    }
                }
                let mut path = PathBuf::from(dir_path.clone());
                path.push(filename.unwrap_or_else(|| evt_id.to_string()));
                let mut file = std::fs::File::create(path.clone())?;
                file.write_all(&data)?;
                let key = if thumb_size.is_some() {
                    [
                        room.room_id().as_str().as_bytes(),
                        evt_id.as_bytes(),
                        "thumbnail".as_bytes(),
                    ]
                    .concat()
                } else {
                    [room.room_id().as_str().as_bytes(), evt_id.as_bytes()].concat()
                };
                let path_text = path
                    .to_str()
                    .context("Path was generated from strings. Must be string")?;
                client
                    .store()
                    .set_custom_value_no_read(&key, path_text.as_bytes().to_vec())
                    .await?;
                Ok(OptionString::new(Some(path_text.to_string())))
            })
            .await?
    }

    pub async fn media_path(&self, is_thumb: bool) -> Result<OptionString> {
        let room = self.room.clone();
        let client = self.client.deref().clone();

        let evt_id = self.inner.meta.event_id.clone();
        let evt_content = self.inner.content().clone();

        RUNTIME
            .spawn(async move {
                if is_thumb {
                    let available = matches!(
                        evt_content,
                        AttachmentContent::Image(_)
                            | AttachmentContent::Video(_)
                            | AttachmentContent::File(_)
                            | AttachmentContent::Location(_)
                            | AttachmentContent::Fallback(_)
                    );
                    if !available {
                        bail!("This message type is not downloadable");
                    }
                } else {
                    let available = matches!(
                        evt_content,
                        AttachmentContent::Image(_)
                            | AttachmentContent::Audio(_)
                            | AttachmentContent::Video(_)
                            | AttachmentContent::File(_)
                            | AttachmentContent::Fallback(_)
                    );
                    if !available {
                        bail!("This message type is not downloadable");
                    }
                }
                let key = if is_thumb {
                    [
                        room.room_id().as_str().as_bytes(),
                        evt_id.as_bytes(),
                        "thumbnail".as_bytes(),
                    ]
                    .concat()
                } else {
                    [room.room_id().as_str().as_bytes(), evt_id.as_bytes()].concat()
                };
                let Some(path_vec) = client.store().get_custom_value(&key).await? else {
                    return Ok(OptionString::new(None));
                };
                let path_str = std::str::from_utf8(&path_vec)?.to_string();
                if matches!(exists(&path_str), Ok(true)) {
                    return Ok(OptionString::new(Some(path_str)));
                }

                // file wasn’t existing, clear cache.

                client.store().remove_custom_value(&key).await?;
                Ok(OptionString::new(None))
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct AttachmentsManager {
    client: Client,
    room: Room,
    inner: models::AttachmentsManager,
}

impl AttachmentsManager {
    pub fn room_id_str(&self) -> String {
        self.room.room_id().to_string()
    }

    pub fn can_edit_attachments(&self) -> bool {
        // FIXME: this requires an actual configurable option.
        true
    }
}

impl Deref for AttachmentsManager {
    type Target = models::AttachmentsManager;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

pub struct AttachmentDraft {
    client: Client,
    room: Room,
    inner: AttachmentBuilder,
}

impl AttachmentDraft {
    fn is_joined(&self) -> bool {
        matches!(self.room.state(), RoomState::Joined)
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Can only attachment in joined rooms");
        }
        let room = self.room.clone();
        let my_id = self.client.user_id()?;
        let inner = self.inner.build()?;

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::RoomMessage)
                    .await?;
                if !permitted {
                    bail!("No permissions to send message in this room");
                }
                let response = room.send(inner).await?;
                Ok(response.event_id)
            })
            .await?
    }
}

impl AttachmentsManager {
    pub(crate) async fn new(
        client: Client,
        room: Room,
        event_id: OwnedEventId,
    ) -> Result<AttachmentsManager> {
        RUNTIME
            .spawn(async move {
                let inner =
                    models::AttachmentsManager::from_store_and_event_id(client.store(), &event_id)
                        .await;
                Ok(AttachmentsManager {
                    client,
                    room,
                    inner,
                })
            })
            .await?
    }

    pub fn stats(&self) -> models::AttachmentsStats {
        self.inner.stats().clone()
    }

    pub fn has_attachments(&self) -> bool {
        *self.stats().has_attachments()
    }

    pub fn attachments_count(&self) -> u32 {
        *self.stats().total_attachments_count()
    }

    pub async fn reload(&self) -> Result<AttachmentsManager> {
        AttachmentsManager::new(
            self.client.clone(),
            self.room.clone(),
            self.inner.event_id(),
        )
        .await
    }

    pub async fn redact(
        &self,
        attachment_id: String,
        reason: Option<String>,
        txn_id: Option<String>,
    ) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let my_id = self.client.user_id()?;
        let has_entry = self
            .stats()
            .user_attachments
            .into_iter()
            .any(|inner| inner == attachment_id);

        if !has_entry {
            bail!("attachment doesn’t exist");
        }

        let event_id = EventId::parse(&attachment_id)?;
        let txn_id = txn_id.map(OwnedTransactionId::from);

        RUNTIME
            .spawn(async move {
                let evt = room.event(&event_id, None).await?;
                let Some(sender) = evt.kind.raw().get_field::<OwnedUserId>("sender")? else {
                    bail!("Could not determine the sender of the previous event");
                };
                let permitted = if sender == my_id {
                    room.can_user_redact_own(&my_id).await?
                } else {
                    room.can_user_redact_other(&my_id).await?
                };
                if !permitted {
                    bail!("No permissions to redact this message");
                }
                let response = room.redact(&event_id, reason.as_deref(), txn_id).await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn attachments(&self) -> Result<Vec<Attachment>> {
        let manager = self.inner.clone();
        let client = self.client.clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let res = manager
                    .attachments()
                    .await?
                    .into_iter()
                    .map(|inner| Attachment {
                        client: client.clone(),
                        room: room.clone(),
                        inner,
                    })
                    .collect();
                Ok(res)
            })
            .await?
    }

    pub async fn content_draft(&self, base_draft: Box<MsgDraft>) -> Result<AttachmentDraft> {
        let room = self.room.clone();
        let client = self.client.deref().clone();

        let content = RUNTIME
            .spawn(async move {
                if let Ok(msg) = base_draft.into_room_msg(&room).await?.msgtype.try_into() {
                    Ok(msg)
                } else {
                    bail!("non-media content not allowed")
                }
            })
            .await??;

        let mut builder = self.inner.draft_builder();
        builder.content(content);
        Ok(AttachmentDraft {
            client: self.client.clone(),
            room: self.room.clone(),
            inner: builder,
        })
    }

    pub async fn link_draft(&self, url: String, name: Option<String>) -> Result<AttachmentDraft> {
        let room = self.room.clone();
        let client = self.client.deref().clone();

        let content = AttachmentContent::Link(LinkAttachmentContent { link: url, name });

        let mut builder = self.inner.draft_builder();
        builder.content(content);
        Ok(AttachmentDraft {
            client: self.client.clone(),
            room: self.room.clone(),
            inner: builder,
        })
    }

    pub async fn reference_draft(&self, ref_details: Box<RefDetails>) -> Result<AttachmentDraft> {
        let room = self.room.clone();
        let client = self.client.deref().clone();

        let content = AttachmentContent::Reference((*ref_details).deref().clone());

        let mut builder = self.inner.draft_builder();
        builder.content(content);
        Ok(AttachmentDraft {
            client: self.client.clone(),
            room: self.room.clone(),
            inner: builder,
        })
    }

    pub fn subscribe_stream(&self) -> impl Stream<Item = bool> {
        self.client.subscribe_stream(self.inner.update_key())
    }

    pub fn subscribe(&self) -> Receiver<()> {
        self.client.subscribe(self.inner.update_key())
    }
}
