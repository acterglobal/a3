use anyhow::{bail, Context, Result};
use derive_builder::Builder;
use effektio_core::statics::{PURPOSE_FIELD, PURPOSE_FIELD_DEV, PURPOSE_TEAM_VALUE};
use log::{info, warn};

use matrix_sdk::{
    attachment::{AttachmentConfig, AttachmentInfo, BaseFileInfo, BaseImageInfo},
    media::{MediaFormat, MediaRequest},
    room::{Room as MatrixRoom, RoomMember},
    ruma::{
        assign,
        events::{
            reaction::ReactionEventContent,
            relation::Annotation,
            room::{
                message::{
                    FileInfo, FileMessageEventContent, ForwardThread, ImageMessageEventContent,
                    MessageType, RoomMessageEvent, RoomMessageEventContent, TextMessageEventContent,
                },
                ImageInfo,
            },
            AnyMessageLikeEvent, AnyMessageLikeEventContent, AnyTimelineEvent, MessageLikeEvent,
        },
        EventId, UInt, UserId,
    },
    Client as MatrixClient, RoomType,
};
use std::{fs::File, io::Write, path::PathBuf, sync::Arc};

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
        let member = self.member.clone();
        RUNTIME
            .spawn(async move {
                let user_profile = UserProfile::new(
                    client,
                    member.user_id().to_owned(),
                    member.avatar_url().map(|x| (*x).to_owned()),
                    member.display_name().map(|x| x.to_string()),
                );
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
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                let members = room
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
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                let members = room
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
        let room = self.room.clone();
        let uid = UserId::parse(user_id)?;
        RUNTIME
            .spawn(async move {
                let member = room.get_member(&uid).await?.context("User not found")?;
                Ok(Member {
                    client: client.clone(),
                    member,
                })
            })
            .await?
    }

    pub async fn timeline_stream(&self) -> Result<TimelineStream> {
        let room = self.room.clone();
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let timeline = Arc::new(room.timeline().await);
                let stream = TimelineStream::new(client, room, timeline);
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
                let content = AnyMessageLikeEventContent::RoomMessage(
                    RoomMessageEventContent::text_plain(message),
                );
                let response = room.send(content, None).await?;
                Ok(response.event_id.to_string())
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
                let content = AnyMessageLikeEventContent::RoomMessage(
                    RoomMessageEventContent::text_markdown(markdown),
                );
                let response = room.send(content, None).await?;
                Ok(response.event_id.to_string())
            })
            .await?
    }

    pub async fn send_reaction(&self, event_id: String, key: String) -> Result<String> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message to a room we are not in")
        };
        let event_id = EventId::parse(event_id)?;
        RUNTIME
            .spawn(async move {
                let relates_to = Annotation::new(event_id, key);
                let content = ReactionEventContent::new(relates_to);
                let response = room.send(content, None).await?;
                Ok(response.event_id.to_string())
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
                let mime_type: mime::Mime = mimetype.parse()?;
                let response = room
                    .send_attachment(name.as_str(), &mime_type, image, config)
                    .await?;
                Ok(response.event_id.to_string())
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
                let uid = UserId::parse(user_id.as_str())?;
                room.invite_user_by_id(&uid).await?;
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
                    .await?;
                let mut accounts: Vec<Account> = vec![];
                for user_id in invited.iter() {
                    let other_client = MatrixClient::builder()
                        .server_name(user_id.server_name())
                        .build()
                        .await?;
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
                        let request = MediaRequest {
                            source: content.source.clone(),
                            format: MediaFormat::File,
                        };
                        let data = client.media().get_media_content(&request, false).await?;
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
                let mime_type: mime::Mime = mimetype.parse()?;
                let response = room
                    .send_attachment(name.as_str(), &mime_type, image, config)
                    .await?;
                Ok(response.event_id.to_string())
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
                        let request = MediaRequest {
                            source: content.source.clone(),
                            format: MediaFormat::File,
                        };
                        let name = content.body.clone();
                        let mut path = PathBuf::from(dir_path.clone());
                        path.push(name);
                        let mut file = File::create(path.clone())?;
                        let data = client.media().get_media_content(&request, false).await?;
                        file.write_all(&data)?;
                        let key =
                            [room.room_id().as_str().as_bytes(), event_id.as_bytes()].concat();
                        let path_text = path
                            .to_str()
                            .context("Path was generated from strings. Must be string")?;
                        client
                            .store()
                            .set_custom_value(&key, path_text.as_bytes().to_vec())
                            .await?
                            .context("Saving the file path to storage was failed")?;
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
                        let path = client
                            .store()
                            .get_custom_value(&key)
                            .await?
                            .context("Couldn't get the path of saved file")?;
                        let text = std::str::from_utf8(&path)?;
                        Ok(text.to_owned())
                    } else {
                        bail!("This message type is not file")
                    }
                } else {
                    bail!("It is not message")
                }
            })
            .await?
    }

    pub async fn is_encrypted(&self) -> Result<bool> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't know if a room we are not in is encrypted")
        };
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let encrypted = room.is_encrypted().await?;
                Ok(encrypted)
            })
            .await?
    }

    pub async fn get_message(&self, event_id: String) -> Result<RoomMessage> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't read message from a room we are not in")
        };
        let client = self.client.clone();
        let r = self.room.clone();
        // any variable in self can't be called directly in spawn
        RUNTIME
            .spawn(async move {
                let eid = EventId::parse(event_id.clone())?;
                let evt = room.event(&eid).await?;
                match evt.event.deserialize() {
                    Ok(AnyTimelineEvent::State(s)) => {
                        bail!("Invalid AnyTimelineEvent::State: {:?}", s)
                    }
                    Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomRedaction(r))) => {
                        if let Some(r) = r.as_original() {
                            info!("RoomRedaction: {:?}", r.content);
                        }
                        bail!("Invalid AnyMessageLikeEvent::RoomRedaction: {:?}", r)
                    }
                    Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomEncrypted(e))) => {
                        if let Some(e) = e.as_original() {
                            info!("RoomEncrypted: {:?}", e.content);
                        }
                        bail!("Invalid AnyMessageLikeEvent::RoomEncrypted: {:?}", e)
                    }
                    Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(m))) => {
                        match m {
                            MessageLikeEvent::Original(m) => {
                                let msg = RoomMessage::from_sync_event(
                                    Some(m.content.msgtype),
                                    m.content.relates_to,
                                    m.event_id.to_string(),
                                    m.sender.to_string(),
                                    m.origin_server_ts.get().into(),
                                    "Message".to_string(),
                                    &r,
                                    false, // not needed for parent msg
                                );
                                Ok(msg)
                            }
                            MessageLikeEvent::Redacted(m) => {
                                let msg = RoomMessage::from_sync_event(
                                    None,
                                    None,
                                    m.event_id.to_string(),
                                    m.sender.to_string(),
                                    m.origin_server_ts.get().into(),
                                    "RedactedMessage".to_string(),
                                    &r,
                                    false, // not needed for deleted msg
                                );
                                Ok(msg)
                            }
                        }
                    }
                    Ok(AnyTimelineEvent::MessageLike(_)) => {
                        bail!("Invalid AnyTimelineEvent::MessageLike: other")
                    }
                    Err(e) => {
                        warn!("Error deserializing event {:?}", e);
                        bail!("Invalid event deserialization error")
                    }
                }
            })
            .await?
    }

    pub async fn send_text_reply(
        &self,
        msg: String,
        event_id: String,
        txn_id: Option<String>,
    ) -> Result<bool> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send reply as text to a room we are not in")
        };
        let eid = EventId::parse(event_id)?;

        // any variable in self can't be called directly in spawn
        RUNTIME
            .spawn(async move {
                let timeline = Arc::new(room.timeline().await);
                let timeline_event = room
                    .event(&eid)
                    .await
                    .context("Couldn't find event.")?;

                let event_content = timeline_event
                    .event
                    .deserialize_as::<RoomMessageEvent>()
                    .context("Couldn't deserialise event")?;

                let original_message = event_content
                    .as_original()
                    .context("Couldn't retrieve original message.")?;

                let text_content = TextMessageEventContent::markdown(msg);
                let reply_content = RoomMessageEventContent::new(MessageType::Text(text_content))
                    .make_reply_to(original_message, ForwardThread::Yes);

                timeline
                    .send(reply_content.into(), txn_id.as_deref().map(Into::into))
                    .await?;
                Ok(true)
            })
            .await?
    }

    #[allow(clippy::too_many_arguments)]
    pub async fn send_image_reply(
        &self,
        uri: String,
        name: String,
        mimetype: String,
        size: Option<u32>,
        width: Option<u32>,
        height: Option<u32>,
        event_id: String,
        txn_id: Option<String>,
    ) -> Result<bool> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send reply as image to a room we are not in")
        };
        let client = self.client.clone();
        let r = self.room.clone();
        let eid = EventId::parse(event_id)?;

        // any variable in self can't be called directly in spawn
        RUNTIME
            .spawn(async move {
                let path = PathBuf::from(uri);
                let mut image_buf = std::fs::read(path)?;

                let timeline = Arc::new(room.timeline().await);
                let timeline_event = room
                    .event(&eid)
                    .await
                    .context("Couldn't find event.")?;

                let event_content = timeline_event
                    .event
                    .deserialize_as::<RoomMessageEvent>()
                    .context("Couldn't deserialise event")?;

                let original_message = event_content
                    .as_original()
                    .context("Couldn't retrieve original message.")?;

                let content_type: mime::Mime = mimetype.parse()?;
                let response = client.media().upload(&content_type, image_buf).await?;

                let info = assign!(ImageInfo::new(), {
                    height: height.map(UInt::from),
                    width: width.map(UInt::from),
                    mimetype: Some(mimetype),
                    size: size.map(UInt::from),
                });
                let image_content = ImageMessageEventContent::plain(
                    name,
                    response.content_uri,
                    Some(Box::new(info)),
                );
                let reply_content = RoomMessageEventContent::new(MessageType::Image(image_content))
                    .make_reply_to(original_message, ForwardThread::Yes);

                timeline
                    .send(reply_content.into(), txn_id.as_deref().map(Into::into))
                    .await?;
                Ok(true)
            })
            .await?
    }

    pub async fn send_file_reply(
        &self,
        uri: String,
        name: String,
        mimetype: String,
        size: Option<u32>,
        event_id: String,
        txn_id: Option<String>,
    ) -> Result<bool> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send reply as file to a room we are not in")
        };
        let client = self.client.clone();
        let r = self.room.clone();
        let eid = EventId::parse(event_id)?;

        // any variable in self can't be called directly in spawn
        RUNTIME
            .spawn(async move {
                let path = PathBuf::from(uri);
                let mut file_buf = std::fs::read(path)?;

                let timeline = Arc::new(room.timeline().await);
                let timeline_event = room
                    .event(&eid)
                    .await
                    .context("Couldn't find event.")?;

                let event_content = timeline_event
                    .event
                    .deserialize_as::<RoomMessageEvent>()
                    .context("Couldn't deserialise event")?;

                let original_message = event_content
                    .as_original()
                    .context("Couldn't retrieve original message.")?;

                let content_type: mime::Mime = mimetype.parse()?;
                let response = client.media().upload(&content_type, file_buf).await?;

                let info = assign!(FileInfo::new(), {
                    mimetype: Some(mimetype),
                    size: size.map(UInt::from),
                });
                let file_content = FileMessageEventContent::plain(
                    name,
                    response.content_uri,
                    Some(Box::new(info)),
                );
                let reply_content = RoomMessageEventContent::new(MessageType::File(file_content))
                    .make_reply_to(original_message, ForwardThread::Yes);

                timeline
                    .send(reply_content.into(), txn_id.as_deref().map(Into::into))
                    .await?;
                Ok(true)
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
