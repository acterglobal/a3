use super::messages::{sync_event_to_message, RoomMessage};
use super::{api, TimelineStream, RUNTIME};
use anyhow::{bail, Context, Result};
use futures::{pin_mut, stream, Stream, StreamExt};
use matrix_sdk::{
    attachment::{AttachmentConfig, AttachmentInfo, BaseFileInfo, BaseImageInfo},
    media::{MediaFormat, MediaRequest},
    room::Room as MatrixRoom,
    ruma::{
        events::{
            room::message::{MessageType, RoomMessageEventContent},
            AnyMessageLikeEvent, AnyMessageLikeEventContent, AnyRoomEvent, MessageLikeEvent,
        },
        EventId, OwnedUserId, UInt,
    },
    Client as MatrixClient,
};
use std::{fs::File, io::Write, path::PathBuf};

pub struct Member {
    pub(crate) member: matrix_sdk::RoomMember,
}

impl std::ops::Deref for Member {
    type Target = matrix_sdk::RoomMember;
    fn deref(&self) -> &matrix_sdk::RoomMember {
        &self.member
    }
}

impl Member {
    pub async fn avatar(&self) -> Result<api::FfiBuffer<u8>> {
        let r = self.member.clone();
        RUNTIME
            .spawn(async move {
                Ok(api::FfiBuffer::new(
                    r.avatar(MediaFormat::File).await?.context("No avatar")?,
                ))
            })
            .await?
    }
    pub fn display_name(&self) -> Option<String> {
        self.member.display_name().map(|s| s.to_owned())
    }

    pub fn user_id(&self) -> OwnedUserId {
        self.member.user_id().to_owned()
    }
}

pub struct Room {
    pub(crate) client: MatrixClient,
    pub(crate) room: MatrixRoom,
}

impl Room {
    pub async fn display_name(&self) -> Result<String> {
        let r = self.room.clone();
        RUNTIME
            .spawn(async move { Ok(r.display_name().await?.to_string()) })
            .await?
    }

    pub async fn avatar(&self) -> Result<api::FfiBuffer<u8>> {
        let r = self.room.clone();
        RUNTIME
            .spawn(async move {
                Ok(api::FfiBuffer::new(
                    r.avatar(MediaFormat::File).await?.context("No avatar")?,
                ))
            })
            .await?
    }

    pub async fn active_members(&self) -> Result<Vec<Member>> {
        let r = self.room.clone();
        RUNTIME
            .spawn(async move {
                Ok(r.active_members()
                    .await
                    .context("No members")?
                    .into_iter()
                    .map(|member| Member { member })
                    .collect())
            })
            .await?
    }

    pub async fn active_members_no_sync(&self) -> Result<Vec<Member>> {
        let r = self.room.clone();
        RUNTIME
            .spawn(async move {
                Ok(r.active_members_no_sync()
                    .await
                    .context("No members")?
                    .into_iter()
                    .map(|member| Member { member })
                    .collect())
            })
            .await?
    }

    pub async fn get_member(&self, user_id: Box<OwnedUserId>) -> Result<Member> {
        let r = self.room.clone();
        RUNTIME
            .spawn(async move {
                let member = r.get_member(&user_id).await?.context("User not found")?;
                Ok(Member { member })
            })
            .await?
    }

    pub async fn timeline(&self) -> Result<TimelineStream> {
        let room = self.room.clone();
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let (forward, backward) = room
                    .timeline()
                    .await
                    .context("Failed acquiring timeline streams")?;
                Ok(TimelineStream::new(
                    Box::pin(forward),
                    Box::pin(backward),
                    client,
                    room,
                ))
            })
            .await?
    }

    pub async fn latest_message(&self) -> Result<RoomMessage> {
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                let stream = room
                    .timeline_backward()
                    .await
                    .context("Failed acquiring timeline streams")?;
                pin_mut!(stream);
                loop {
                    match stream.next().await {
                        None => break,
                        Some(Ok(e)) => {
                            if let Some(a) = sync_event_to_message(e, room.clone()) {
                                return Ok(a);
                            }
                        }
                        _ => {
                            // we ignore errors
                        }
                    }
                }

                bail!("No Message found")
            })
            .await?
    }

    pub async fn typing_notice(&self, typing: bool) -> Result<bool> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send typing notice to a room we are not in")
        };
        RUNTIME
            .spawn(async move {
                room.typing_notice(typing).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn read_receipt(&self, event_id: String) -> Result<bool> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send read_receipt to a room we are not in")
        };
        let event_id = EventId::parse(event_id)?;
        RUNTIME
            .spawn(async move {
                room.read_receipt(&event_id).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn send_plain_message(&self, message: String) -> Result<String> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message to a room we are not in")
        };
        RUNTIME
            .spawn(async move {
                let r = room
                    .send(
                        AnyMessageLikeEventContent::RoomMessage(
                            RoomMessageEventContent::text_plain(message),
                        ),
                        None,
                    )
                    .await?;
                Ok(r.event_id.to_string())
            })
            .await?
    }

    pub async fn send_image_message(
        &self,
        uri: String,
        name: String,
        mimetype: String,
        size: u32,
        width: u32,
        height: u32,
    ) -> Result<String> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message to a room we are not in")
        };
        RUNTIME
            .spawn(async move {
                let path = PathBuf::from(uri);
                let mut image = File::open(path)?;
                let config = AttachmentConfig::new().info(AttachmentInfo::Image(BaseImageInfo {
                    height: Some(UInt::from(height)),
                    width: Some(UInt::from(width)),
                    size: Some(UInt::from(size)),
                    blurhash: None,
                }));
                let mime_type: mime::Mime = mimetype.parse().unwrap();
                let r = room
                    .send_attachment(name.as_str(), &mime_type, &mut image, config)
                    .await?;
                Ok(r.event_id.to_string())
            })
            .await?
    }

    pub async fn image_binary(&self, event_id: String) -> Result<api::FfiBuffer<u8>> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message to a room we are not in")
        };
        let client = self.client.clone();
        // any variable in self can't be called directly in spawn
        RUNTIME
            .spawn(async move {
                let eid = EventId::parse(event_id.clone())?;
                let evt = room.event(&eid).await?;
                match evt.event.deserialize() {
                    Ok(AnyRoomEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(
                        MessageLikeEvent::Original(m),
                    ))) => match &m.content.msgtype {
                        MessageType::Image(content) => {
                            let source = content.source.clone();
                            let data = client
                                .get_media_content(
                                    &MediaRequest {
                                        source,
                                        format: MediaFormat::File,
                                    },
                                    false,
                                )
                                .await?;
                            Ok(api::FfiBuffer::new(data))
                        }
                        _ => bail!("Invalid file format"),
                    },
                    _ => bail!("Invalid file format"),
                }
            })
            .await?
    }

    pub async fn send_file_message(
        &self,
        uri: String,
        name: String,
        mimetype: String,
        size: u32,
    ) -> Result<String> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message to a room we are not in")
        };
        RUNTIME
            .spawn(async move {
                let path = PathBuf::from(uri);
                let mut image = File::open(path)?;
                let config = AttachmentConfig::new().info(AttachmentInfo::File(BaseFileInfo {
                    size: Some(UInt::from(size)),
                }));
                let mime_type: mime::Mime = mimetype.parse().unwrap();
                let r = room
                    .send_attachment(name.as_str(), &mime_type, &mut image, config)
                    .await?;
                Ok(r.event_id.to_string())
            })
            .await?
    }

    pub async fn save_file(&self, event_id: String, uri: String) -> Result<bool> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message to a room we are not in")
        };
        let client = self.client.clone();
        // any variable in self can't be called directly in spawn
        RUNTIME
            .spawn(async move {
                let eid = EventId::parse(event_id.clone())?;
                let evt = room.event(&eid).await?;
                match evt.event.deserialize() {
                    Ok(AnyRoomEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(
                        MessageLikeEvent::Original(m),
                    ))) => match m.content.msgtype {
                        MessageType::File(content) => {
                            let source = content.source.clone();
                            let path = PathBuf::from(uri.clone());
                            let mut file = File::create(path)?;
                            let data = client
                                .get_media_content(
                                    &MediaRequest {
                                        source,
                                        format: MediaFormat::File,
                                    },
                                    false,
                                )
                                .await?;
                            file.write_all(&data)?;
                            let key =
                                [room.room_id().as_str().as_bytes(), event_id.as_bytes()].concat();
                            client
                                .store()
                                .set_custom_value(&key, uri.as_str().as_bytes().to_vec())
                                .await?;
                            Ok(true)
                        }
                        _ => Ok(false),
                    },
                    _ => Ok(false),
                }
            })
            .await?
    }

    pub async fn file_path(&self, event_id: String) -> Result<String> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message to a room we are not in")
        };
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let eid = EventId::parse(event_id.clone())?;
                let evt = room.event(&eid).await?;
                match evt.event.deserialize() {
                    Ok(AnyRoomEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(
                        MessageLikeEvent::Original(m),
                    ))) => match m.content.msgtype {
                        MessageType::File(content) => {
                            let key = [
                                room.room_id().as_str().as_bytes(),
                                event_id.as_str().as_bytes(),
                            ]
                            .concat();
                            let path = client.store().get_custom_value(&key).await?;
                            match path {
                                Some(value) => {
                                    let text = std::str::from_utf8(&value).unwrap();
                                    Ok(text.to_owned())
                                }
                                None => Ok("".to_owned()),
                            }
                        }
                        _ => Ok("".to_owned()),
                    },
                    _ => Ok("".to_owned()),
                }
            })
            .await?
    }
}

impl std::ops::Deref for Room {
    type Target = MatrixRoom;
    fn deref(&self) -> &MatrixRoom {
        &self.room
    }
}
