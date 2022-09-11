use anyhow::{bail, Context, Result};
use effektio_core::statics::{PURPOSE_FIELD, PURPOSE_FIELD_DEV, PURPOSE_TEAM_VALUE};
use futures::{pin_mut, StreamExt};
use matrix_sdk::{
    attachment::{AttachmentConfig, AttachmentInfo, BaseFileInfo, BaseImageInfo},
    media::{MediaFormat, MediaRequest},
    room::Room as MatrixRoom,
    ruma::{
        self,
        events::{
            room::message::{MessageType, RoomMessageEventContent},
            AnyMessageLikeEvent, AnyMessageLikeEventContent, AnyRoomEvent, MessageLikeEvent,
        },
        EventId, UInt, UserId,
    },
    Client as MatrixClient,
};
use std::{fs::File, io::Write, path::PathBuf};

use super::message::{sync_event_to_message, RoomMessage};
use super::{api, TimelineStream, RUNTIME};

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

    pub fn user_id(&self) -> String {
        self.member.user_id().to_string()
    }
}

#[derive(Clone)]
pub struct Room {
    pub(crate) client: MatrixClient,
    pub(crate) room: MatrixRoom,
}

impl Room {
    pub(crate) async fn is_effektio_group(&self) -> bool {
        #[allow(clippy::match_like_matches_macro)]
        if let Ok(Some(_)) = self
            .room
            .get_state_event(PURPOSE_FIELD.into(), PURPOSE_TEAM_VALUE)
            .await
        {
            true
        } else if let Ok(Some(_)) = self
            .room
            .get_state_event(PURPOSE_FIELD_DEV.into(), PURPOSE_TEAM_VALUE)
            .await
        {
            true
        } else {
            false
        }
    }

    pub fn get_room_id(&self) -> String {
        self.room_id().to_string()
    }

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

    pub async fn get_member(&self, user_id: String) -> Result<Member> {
        let r = self.room.clone();
        let uid = UserId::parse(user_id)?;
        RUNTIME
            .spawn(async move {
                let member = r.get_member(&uid).await?.context("User not found")?;
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
        size: Option<u32>,
        width: Option<u32>,
        height: Option<u32>,
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
                    height: height.map(UInt::from),
                    width: width.map(UInt::from),
                    size: size.map(UInt::from),
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
                if let Ok(AnyRoomEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(
                    MessageLikeEvent::Original(m),
                ))) = evt.event.deserialize()
                {
                    if let MessageType::Image(content) = &m.content.msgtype {
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
                    } else {
                        bail!("Invalid file format")
                    }
                } else {
                    bail!("Invalid file format")
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

    pub async fn save_file(&self, event_id: String, dir_path: String) -> Result<String> {
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
                if let Ok(AnyRoomEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(
                    MessageLikeEvent::Original(m),
                ))) = evt.event.deserialize()
                {
                    if let MessageType::File(content) = m.content.msgtype {
                        let source = content.source.clone();
                        let name = content.body.clone();
                        let mut path = PathBuf::from(dir_path.clone());
                        path.push(name);
                        let mut file = File::create(path.clone())?;
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
                        let path_text = path
                            .to_str()
                            .expect("Path was generated from strings. Must be string");
                        client
                            .store()
                            .set_custom_value(&key, path_text.as_bytes().to_vec())
                            .await?;
                        Ok(path_text.to_owned())
                    } else {
                        bail!("This message type is not file")
                    }
                } else {
                    bail!("It is not message")
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
                if let Ok(AnyRoomEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(
                    MessageLikeEvent::Original(m),
                ))) = evt.event.deserialize()
                {
                    if let MessageType::File(content) = m.content.msgtype {
                        let key = [
                            room.room_id().as_str().as_bytes(),
                            event_id.as_str().as_bytes(),
                        ]
                        .concat();
                        let path = client.store().get_custom_value(&key).await?;
                        if let Some(value) = path {
                            let text = std::str::from_utf8(&value).unwrap();
                            Ok(text.to_owned())
                        } else {
                            bail!("Couldn't get the path of saved file")
                        }
                    } else {
                        bail!("This message type is not file")
                    }
                } else {
                    bail!("It is not message")
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
