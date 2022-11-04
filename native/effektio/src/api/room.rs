use anyhow::{bail, Context, Result};
use derive_builder::Builder;
use effektio_core::statics::{PURPOSE_FIELD, PURPOSE_FIELD_DEV, PURPOSE_TEAM_VALUE};
use log::info;
use matrix_sdk::{
    attachment::{AttachmentConfig, AttachmentInfo, BaseFileInfo, BaseImageInfo},
    media::{MediaFormat, MediaRequest},
    room::{Room as MatrixRoom, RoomMember},
    ruma::{
        events::{
            room::message::{MessageType, RoomMessageEventContent},
            AnyMessageLikeEvent, AnyMessageLikeEventContent, AnyTimelineEvent, MessageLikeEvent,
        },
        EventId, UInt, UserId,
    },
    Client as MatrixClient, RoomType,
};
use std::{fs::File, io::Write, path::PathBuf};

use super::{
    account::Account,
    api::FfiBuffer,
    message::RoomMessage,
    profile::{RoomProfile, UserProfile},
    stream::TimelineStream,
    RUNTIME,
};

pub struct Member {
    pub(crate) client: MatrixClient,
    pub(crate) member: RoomMember,
}

impl std::ops::Deref for Member {
    type Target = matrix_sdk::room::RoomMember;
    fn deref(&self) -> &matrix_sdk::room::RoomMember {
        &self.member
    }
}

impl Member {
    pub async fn get_profile(&self) -> Result<UserProfile> {
        let client = self.client.clone();
        let user_id = self.member.user_id().to_owned();
        RUNTIME
            .spawn(async move {
                let mut user_profile = UserProfile::new(client, user_id);
                user_profile.fetch().await;
                Ok(user_profile)
            })
            .await?
    }

    pub fn user_id(&self) -> String {
        self.member.user_id().to_string()
    }
}

#[derive(Clone, Debug)]
pub struct Room {
    pub(crate) client: MatrixClient,
    pub(crate) room: MatrixRoom,
}

impl Room {
    pub(crate) async fn is_effektio_group(&self) -> bool {
        if let Ok(Some(_)) = self
            .room
            .get_state_event(PURPOSE_FIELD.into(), PURPOSE_TEAM_VALUE)
            .await
        {
            true
        } else {
            matches!(
                self.room
                    .get_state_event(PURPOSE_FIELD_DEV.into(), PURPOSE_TEAM_VALUE)
                    .await,
                Ok(Some(_))
            )
        }
    }

    pub async fn get_profile(&self) -> Result<RoomProfile> {
        let client = self.client.clone();
        let room_id = self.room_id().to_owned();
        RUNTIME
            .spawn(async move {
                let mut room_profile = RoomProfile::new(client, room_id);
                room_profile.fetch().await;
                Ok(room_profile)
            })
            .await?
    }

    pub async fn active_members(&self) -> Result<Vec<Member>> {
        let client = self.client.clone();
        let r = self.room.clone();
        RUNTIME
            .spawn(async move {
                let members = r
                    .active_members()
                    .await
                    .context("No members")?
                    .into_iter()
                    .map(|member| Member {
                        client: client.clone(),
                        member,
                    })
                    .collect();
                Ok(members)
            })
            .await?
    }

    pub async fn active_members_no_sync(&self) -> Result<Vec<Member>> {
        let client = self.client.clone();
        let r = self.room.clone();
        RUNTIME
            .spawn(async move {
                let members = r
                    .active_members_no_sync()
                    .await
                    .context("No members")?
                    .into_iter()
                    .map(|member| Member {
                        client: client.clone(),
                        member,
                    })
                    .collect();
                Ok(members)
            })
            .await?
    }

    pub async fn get_member(&self, user_id: String) -> Result<Member> {
        let client = self.client.clone();
        let r = self.room.clone();
        let uid = UserId::parse(user_id)?;
        RUNTIME
            .spawn(async move {
                let member = r.get_member(&uid).await?.context("User not found")?;
                Ok(Member {
                    client: client.clone(),
                    member,
                })
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
                let stream =
                    TimelineStream::new(Box::pin(forward), Box::pin(backward), client, room);
                Ok(stream)
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

    pub async fn send_formatted_message(&self, markdown: String) -> Result<String> {
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
                            RoomMessageEventContent::text_markdown(markdown),
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
                let mut image = std::fs::read(path)?;
                let config = AttachmentConfig::new().info(AttachmentInfo::Image(BaseImageInfo {
                    height: height.map(UInt::from),
                    width: width.map(UInt::from),
                    size: size.map(UInt::from),
                    blurhash: None,
                }));
                let mime_type: mime::Mime = mimetype.parse().unwrap();
                let r = room
                    .send_attachment(name.as_str(), &mime_type, &image, config)
                    .await?;
                Ok(r.event_id.to_string())
            })
            .await?
    }

    pub fn room_type(&self) -> String {
        match self.room.room_type() {
            RoomType::Joined => "joined".to_owned(),
            RoomType::Left => "left".to_owned(),
            RoomType::Invited => "invited".to_owned(),
        }
    }

    pub async fn invite_user(&self, user_id: String) -> Result<bool> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message to a room we are not in")
        };
        // any variable in self can't be called directly in spawn
        RUNTIME
            .spawn(async move {
                let user = <&UserId>::try_from(user_id.as_str()).unwrap();
                room.invite_user_by_id(user).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn join(&self) -> Result<bool> {
        let room = if let MatrixRoom::Left(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't join a room we are not left")
        };
        // any variable in self can't be called directly in spawn
        RUNTIME
            .spawn(async move {
                room.join().await?;
                Ok(true)
            })
            .await?
    }

    pub async fn leave(&self) -> Result<bool> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't leave a room we are not joined")
        };
        // any variable in self can't be called directly in spawn
        RUNTIME
            .spawn(async move {
                room.leave().await?;
                Ok(true)
            })
            .await?
    }

    pub async fn get_invitees(&self) -> Result<Vec<Account>> {
        let my_client = self.client.clone();
        let room = if let MatrixRoom::Invited(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't get a room we are not invited")
        };
        // any variable in self can't be called directly in spawn
        RUNTIME
            .spawn(async move {
                let invited = my_client
                    .store()
                    .get_invited_user_ids(room.room_id())
                    .await
                    .unwrap();
                let mut accounts: Vec<Account> = vec![];
                for user_id in invited.iter() {
                    let other_client = MatrixClient::builder()
                        .server_name(user_id.server_name())
                        .build()
                        .await
                        .unwrap();
                    accounts.push(Account::new(other_client.account(), user_id.to_string()));
                }
                Ok(accounts)
            })
            .await?
    }

    pub async fn image_binary(&self, event_id: String) -> Result<FfiBuffer<u8>> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't read message from a room we are not in")
        };
        let client = self.client.clone();
        // any variable in self can't be called directly in spawn
        RUNTIME
            .spawn(async move {
                let eid = EventId::parse(event_id.clone())?;
                let evt = room.event(&eid).await?;
                if let Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(
                    MessageLikeEvent::Original(m),
                ))) = evt.event.deserialize()
                {
                    if let MessageType::Image(content) = &m.content.msgtype {
                        let source = content.source.clone();
                        let data = client
                            .media()
                            .get_media_content(
                                &MediaRequest {
                                    source,
                                    format: MediaFormat::File,
                                },
                                false,
                            )
                            .await?;
                        Ok(FfiBuffer::new(data))
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
                let mut image = std::fs::read(path)?;
                let config = AttachmentConfig::new().info(AttachmentInfo::File(BaseFileInfo {
                    size: Some(UInt::from(size)),
                }));
                let mime_type: mime::Mime = mimetype.parse().unwrap();
                let r = room
                    .send_attachment(name.as_str(), &mime_type, &image, config)
                    .await?;
                Ok(r.event_id.to_string())
            })
            .await?
    }

    pub async fn save_file(&self, event_id: String, dir_path: String) -> Result<String> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't read message from a room we are not in")
        };
        let client = self.client.clone();
        // any variable in self can't be called directly in spawn
        RUNTIME
            .spawn(async move {
                let eid = EventId::parse(event_id.clone())?;
                let evt = room.event(&eid).await?;
                if let Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(
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
                            .media()
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
            bail!("Can't read message from a room we are not in")
        };
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let eid = EventId::parse(event_id.clone())?;
                let evt = room.event(&eid).await?;
                if let Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(
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
