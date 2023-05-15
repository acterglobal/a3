use acter_core::{
    ruma::{
        api::client::receipt::create_receipt::v3::ReceiptType as CreateReceiptType, OwnedEventId,
    },
    spaces::is_acter_space,
};
use anyhow::{bail, Context, Result};
use core::time::Duration;
use log::{info, warn};
use matrix_sdk::{
    attachment::{
        AttachmentConfig, AttachmentInfo, BaseAudioInfo, BaseFileInfo, BaseImageInfo, BaseVideoInfo,
    },
    media::{MediaFormat, MediaRequest},
    room::{Room as MatrixRoom, RoomMember},
    ruma::{
        assign,
        events::{
            reaction::ReactionEventContent,
            receipt::ReceiptThread,
            relation::Annotation,
            room::{
                message::{
                    AudioInfo, AudioMessageEventContent, FileInfo, FileMessageEventContent,
                    ForwardThread, ImageMessageEventContent, MessageType, RoomMessageEvent,
                    RoomMessageEventContent, TextMessageEventContent, VideoInfo,
                    VideoMessageEventContent,
                },
                ImageInfo,
            },
            AnyMessageLikeEvent, AnyStateEvent, AnyTimelineEvent, MessageLikeEvent, StateEvent,
        },
        room::RoomType,
        EventId, Int, OwnedUserId, TransactionId, UInt, UserId,
    },
    Client as MatrixClient, RoomState,
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
    type Target = RoomMember;
    fn deref(&self) -> &RoomMember {
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

    pub fn user_id(&self) -> OwnedUserId {
        self.member.user_id().to_owned()
    }
}

#[derive(Clone, Debug)]
pub struct Room {
    pub(crate) room: MatrixRoom,
}

impl Room {
    pub(crate) async fn is_acter_space(&self) -> bool {
        is_acter_space(&self.room).await
    }

    pub async fn get_profile(&self) -> Result<RoomProfile> {
        let client = self.room.client();
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
        let client = self.room.client();
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
        let client = self.room.client();
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
        let client = self.room.client();
        let room = self.room.clone();

        let uid = UserId::parse(user_id).context("Couldn't parse user id to get member")?;

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

        RUNTIME
            .spawn(async move {
                let timeline = Arc::new(room.timeline().await);
                let stream = TimelineStream::new(room, timeline);
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
                room.typing_notice(typing)
                    .await
                    .context("Couldn't send typing notice")?;
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

        let event_id =
            EventId::parse(event_id).context("Couldn't parse event id to read receipt")?;

        RUNTIME
            .spawn(async move {
                room.send_single_receipt(
                    CreateReceiptType::Read,
                    ReceiptThread::Unthreaded,
                    event_id,
                )
                .await
                .context("Couldn't send single receipt")?;
                Ok(true)
            })
            .await?
    }

    pub async fn send_plain_message(&self, message: String) -> Result<OwnedEventId> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message to a room we are not in")
        };

        RUNTIME
            .spawn(async move {
                let content = RoomMessageEventContent::text_plain(message);
                let txn_id = TransactionId::new();
                let response = room
                    .send(content, Some(&txn_id))
                    .await
                    .context("Couldn't send plain text message")?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn send_formatted_message(&self, markdown: String) -> Result<OwnedEventId> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message to a room we are not in")
        };

        RUNTIME
            .spawn(async move {
                let content = RoomMessageEventContent::text_markdown(markdown);
                let txn_id = TransactionId::new();
                let response = room
                    .send(content, Some(&txn_id))
                    .await
                    .context("Couldn't send formatted text message")?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn send_reaction(&self, event_id: String, key: String) -> Result<OwnedEventId> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message to a room we are not in")
        };

        let event_id =
            EventId::parse(event_id).context("Couldn't parse event id to send reaction")?;

        RUNTIME
            .spawn(async move {
                let relates_to = Annotation::new(event_id, key);
                let content = ReactionEventContent::new(relates_to);
                let txn_id = TransactionId::new();
                let response = room
                    .send(content, Some(&txn_id))
                    .await
                    .context("Couldn't send reaction")?;
                Ok(response.event_id)
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
    ) -> Result<OwnedEventId> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message as image to a room we are not in")
        };

        let path = PathBuf::from(uri);
        let config = AttachmentConfig::new().info(AttachmentInfo::Image(BaseImageInfo {
            height: height.map(UInt::from),
            width: width.map(UInt::from),
            size: size.map(UInt::from),
            blurhash: None,
        }));
        let mime_type = mimetype.parse::<mime::Mime>()?;

        RUNTIME
            .spawn(async move {
                let image_buf = std::fs::read(path).context("Couldn't read image data to send")?;
                let response = room
                    .send_attachment(name.as_str(), &mime_type, image_buf, config)
                    .await
                    .context("Couldn't send image attachment")?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn image_binary(&self, event_id: String) -> Result<FfiBuffer<u8>> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't read message from a room we are not in")
        };
        let client = self.room.client();

        let event_id =
            EventId::parse(event_id).context("Couldn't parse event id to get image binary")?;

        RUNTIME
            .spawn(async move {
                let evt = room
                    .event(&event_id)
                    .await
                    .context("Couldn't get room message")?;
                let Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(
                    MessageLikeEvent::Original(m),
                ))) = evt.event.deserialize() else {
                    bail!("It is not message");
                };
                let MessageType::Image(content) = &m.content.msgtype else {
                    bail!("Invalid file format");
                };
                let request = MediaRequest {
                    source: content.source.clone(),
                    format: MediaFormat::File,
                };
                let data = client
                    .media()
                    .get_media_content(&request, false)
                    .await
                    .context("Coudln't get media content")?;
                Ok(FfiBuffer::new(data))
            })
            .await?
    }

    pub async fn send_audio_message(
        &self,
        uri: String,
        name: String,
        mimetype: String,
        secs: Option<u32>,
        size: Option<u32>,
    ) -> Result<OwnedEventId> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message as audio to a room we are not in")
        };

        let path = PathBuf::from(uri);
        let config = AttachmentConfig::new().info(AttachmentInfo::Audio(BaseAudioInfo {
            duration: secs.map(|x| Duration::from_secs(x as u64)),
            size: size.map(UInt::from),
        }));
        let mime_type = mimetype.parse::<mime::Mime>()?;

        RUNTIME
            .spawn(async move {
                let audio_buf = std::fs::read(path).context("Couldn't read audio data to send")?;
                let response = room
                    .send_attachment(name.as_str(), &mime_type, audio_buf, config)
                    .await
                    .context("Couldn't send attachment")?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn audio_binary(&self, event_id: String) -> Result<FfiBuffer<u8>> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't read message from a room we are not in")
        };
        let client = self.room.client();

        let event_id =
            EventId::parse(event_id).context("Couldn't parse event id to get audio binary")?;

        RUNTIME
            .spawn(async move {
                let evt = room
                    .event(&event_id)
                    .await
                    .context("Couldn't get room message")?;
                let Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(
                    MessageLikeEvent::Original(m),
                ))) = evt.event.deserialize() else {
                    bail!("It is not message");
                };
                let MessageType::Audio(content) = &m.content.msgtype else {
                    bail!("Invalid file format");
                };
                let request = MediaRequest {
                    source: content.source.clone(),
                    format: MediaFormat::File,
                };
                let data = client
                    .media()
                    .get_media_content(&request, false)
                    .await
                    .context("Coudln't get media content")?;
                Ok(FfiBuffer::new(data))
            })
            .await?
    }

    #[allow(clippy::too_many_arguments)]
    pub async fn send_video_message(
        &self,
        uri: String,
        name: String,
        mimetype: String,
        secs: Option<u32>,
        height: Option<u32>,
        width: Option<u32>,
        size: Option<u32>,
        blurhash: Option<String>,
    ) -> Result<OwnedEventId> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message as video to a room we are not in")
        };

        let path = PathBuf::from(uri);
        let config = AttachmentConfig::new().info(AttachmentInfo::Video(BaseVideoInfo {
            duration: secs.map(|x| Duration::from_secs(x as u64)),
            height: height.map(UInt::from),
            width: width.map(UInt::from),
            size: size.map(UInt::from),
            blurhash,
        }));
        let mime_type = mimetype.parse::<mime::Mime>()?;

        RUNTIME
            .spawn(async move {
                let video_buf = std::fs::read(path).context("Couldn't read video data to send")?;
                let response = room
                    .send_attachment(name.as_str(), &mime_type, video_buf, config)
                    .await
                    .context("Couldn't send attachment")?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn video_binary(&self, event_id: String) -> Result<FfiBuffer<u8>> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't read message from a room we are not in")
        };
        let client = self.room.client();

        let event_id =
            EventId::parse(event_id).context("Couldn't parse event id to get video binary")?;

        RUNTIME
            .spawn(async move {
                let evt = room
                    .event(&event_id)
                    .await
                    .context("Couldn't get room message")?;
                let Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(
                    MessageLikeEvent::Original(m),
                ))) = evt.event.deserialize() else {
                    bail!("It is not message");
                };
                let MessageType::Video(content) = &m.content.msgtype else {
                    bail!("Invalid file format");
                };
                let request = MediaRequest {
                    source: content.source.clone(),
                    format: MediaFormat::File,
                };
                let data = client
                    .media()
                    .get_media_content(&request, false)
                    .await
                    .context("Coudln't get media content")?;
                Ok(FfiBuffer::new(data))
            })
            .await?
    }

    pub async fn send_file_message(
        &self,
        uri: String,
        name: String,
        mimetype: String,
        size: u32,
    ) -> Result<OwnedEventId> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message as file to a room we are not in")
        };

        let path = PathBuf::from(uri);
        let config = AttachmentConfig::new().info(AttachmentInfo::File(BaseFileInfo {
            size: Some(UInt::from(size)),
        }));
        let mime_type = mimetype.parse::<mime::Mime>()?;

        RUNTIME
            .spawn(async move {
                let file_buf = std::fs::read(path).context("Couldn't read file data to send")?;
                let response = room
                    .send_attachment(name.as_str(), &mime_type, file_buf, config)
                    .await
                    .context("Couldn't send attachment")?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn file_binary(&self, event_id: String) -> Result<FfiBuffer<u8>> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't read message from a room we are not in")
        };
        let client = self.room.client();

        let event_id =
            EventId::parse(event_id).context("Couldn't parse event id to get file binary")?;

        RUNTIME
            .spawn(async move {
                let evt = room
                    .event(&event_id)
                    .await
                    .context("Couldn't get room message")?;
                let Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(
                    MessageLikeEvent::Original(m),
                ))) = evt.event.deserialize() else {
                    bail!("It is not message");
                };
                let MessageType::File(content) = &m.content.msgtype else {
                    bail!("Invalid file format");
                };
                let request = MediaRequest {
                    source: content.source.clone(),
                    format: MediaFormat::File,
                };
                let data = client
                    .media()
                    .get_media_content(&request, false)
                    .await
                    .context("Coudln't get media content")?;
                Ok(FfiBuffer::new(data))
            })
            .await?
    }

    pub fn room_type(&self) -> String {
        match self.room.state() {
            RoomState::Joined => "joined".to_string(),
            RoomState::Left => "left".to_string(),
            RoomState::Invited => "invited".to_string(),
        }
    }

    pub async fn invite_user(&self, user_id: String) -> Result<bool> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message to a room we are not in")
        };

        let user_id =
            UserId::parse(user_id.as_str()).context("Couldn't parse user id to invite")?;

        RUNTIME
            .spawn(async move {
                room.invite_user_by_id(&user_id)
                    .await
                    .context("Couldn't invite user by id")?;
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

        RUNTIME
            .spawn(async move {
                room.join().await.context("Join failed")?;
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

        RUNTIME
            .spawn(async move {
                room.leave().await.context("Leave failed")?;
                Ok(true)
            })
            .await?
    }

    pub async fn get_invitees(&self) -> Result<Vec<Account>> {
        let my_client = self.room.client();
        let room = if let MatrixRoom::Invited(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't get a room we are not invited")
        };

        RUNTIME
            .spawn(async move {
                let invited = my_client
                    .store()
                    .get_invited_user_ids(room.room_id())
                    .await
                    .context("Couldn't get invited user ids from store")?;
                let mut accounts: Vec<Account> = vec![];
                for user_id in invited.iter() {
                    let other_client = MatrixClient::builder()
                        .server_name(user_id.server_name())
                        .build()
                        .await
                        .context("Couldn't build matrix client")?;
                    accounts.push(Account::new(other_client.account(), user_id.clone()));
                }
                Ok(accounts)
            })
            .await?
    }

    pub async fn download_media(&self, event_id: String, dir_path: String) -> Result<String> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't read message from a room we are not in")
        };
        let client = self.room.client();

        let eid =
            EventId::parse(event_id.clone()).context("Couldn't parse event id to download file")?;

        RUNTIME
            .spawn(async move {
                let evt = room
                    .event(&eid)
                    .await
                    .context("Couldn't get room message")?;
                let Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(
                    MessageLikeEvent::Original(m),
                ))) = evt.event.deserialize() else {
                    bail!("It is not message");
                };
                let (request, name) = match m.content.msgtype {
                    MessageType::Image(content) => {
                        let request = MediaRequest {
                            source: content.source.clone(),
                            format: MediaFormat::File,
                        };
                        let name = content.body.clone();
                        (request, name)
                    }
                    MessageType::Audio(content) => {
                        let request = MediaRequest {
                            source: content.source.clone(),
                            format: MediaFormat::File,
                        };
                        let name = content.body.clone();
                        (request, name)
                    }
                    MessageType::Video(content) => {
                        let request = MediaRequest {
                            source: content.source.clone(),
                            format: MediaFormat::File,
                        };
                        let name = content.body.clone();
                        (request, name)
                    }
                    MessageType::File(content) => {
                        let request = MediaRequest {
                            source: content.source.clone(),
                            format: MediaFormat::File,
                        };
                        let name = content.body.clone();
                        (request, name)
                    }
                    _ => bail!("This message type is not downloadable"),
                };
                let mut path = PathBuf::from(dir_path.clone());
                path.push(name);
                let mut file = File::create(path.clone())
                    .context("Couldn't create file to write the fetched data")?;
                let data = client
                    .media()
                    .get_media_content(&request, false)
                    .await
                    .context("Couldn't get media content")?;
                file.write_all(&data)
                    .context("Couldn't write data to file")?;
                let key = [
                    room.room_id().as_str().as_bytes(),
                    event_id.as_str().as_bytes(),
                ]
                .concat();
                let path_text = path
                    .to_str()
                    .context("Path was generated from strings. Must be string")?;
                client
                    .store()
                    .set_custom_value(&key, path_text.as_bytes().to_vec())
                    .await?
                    .context("Saving the file path to storage was failed")?;
                Ok(path_text.to_string())
            })
            .await?
    }

    pub async fn media_path(&self, event_id: String) -> Result<String> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't read message from a room we are not in")
        };
        let client = self.room.client();

        let eid = EventId::parse(event_id.clone())
            .context("Couldn't parse event id to get downloaded media path")?;

        RUNTIME
            .spawn(async move {
                let evt = room
                    .event(&eid)
                    .await
                    .context("Couldn't get room message")?;
                let Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(
                    MessageLikeEvent::Original(m),
                ))) = evt.event.deserialize() else {
                    bail!("It is not message");
                };
                match m.content.msgtype {
                    MessageType::Image(content) => {}
                    MessageType::Audio(content) => {}
                    MessageType::Video(content) => {}
                    MessageType::File(content) => {}
                    _ => bail!("This message type is not downloadable"),
                }
                let key = [
                    room.room_id().as_str().as_bytes(),
                    event_id.as_str().as_bytes(),
                ]
                .concat();
                let path = client
                    .store()
                    .get_custom_value(&key)
                    .await?
                    .context("Couldn't get the path of downloaded media")?;
                let text = std::str::from_utf8(&path).context("Couldn't get string from utf8")?;
                Ok(text.to_string())
            })
            .await?
    }

    pub async fn is_encrypted(&self) -> Result<bool> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't know if a room we are not in is encrypted")
        };

        RUNTIME
            .spawn(async move {
                let encrypted = room
                    .is_encrypted()
                    .await
                    .context("Couldn't check if room is encrypted")?;
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
        let r = self.room.clone();

        let event_id =
            EventId::parse(event_id).context("Couldn't parse event id to get message")?;

        RUNTIME
            .spawn(async move {
                let evt = room
                    .event(&event_id)
                    .await
                    .context("Coudln't get room message")?;
                match evt.event.deserialize() {
                    Ok(AnyTimelineEvent::State(AnyStateEvent::PolicyRuleRoom(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::policy_rule_room_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::PolicyRuleServer(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::policy_rule_server_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::PolicyRuleUser(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::policy_rule_user_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomAliases(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::room_aliases_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomAvatar(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::room_avatar_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomCanonicalAlias(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::room_canonical_alias_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomCreate(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::room_create_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomEncryption(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::room_encryption_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomGuestAccess(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::room_guest_access_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomHistoryVisibility(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::room_history_visibility_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomJoinRules(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::room_join_rules_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomMember(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::room_member_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomName(StateEvent::Original(
                        e,
                    )))) => {
                        let msg = RoomMessage::room_name_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomPinnedEvents(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::room_pinned_events_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomPowerLevels(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::room_power_levels_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomServerAcl(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::room_server_acl_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomThirdPartyInvite(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::room_third_party_invite_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomTombstone(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::room_tombstone_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomTopic(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::room_topic_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::SpaceChild(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::space_child_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::SpaceParent(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::space_parent_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(_)) => {
                        bail!("Invalid AnyTimelineEvent::State: other");
                    }
                    Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::CallAnswer(
                        MessageLikeEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::call_answer_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::CallCandidates(
                        MessageLikeEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::call_candidates_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::CallHangup(
                        MessageLikeEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::call_hangup_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::CallInvite(
                        MessageLikeEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::call_invite_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::MessageLike(
                        AnyMessageLikeEvent::KeyVerificationAccept(MessageLikeEvent::Original(e)),
                    )) => {
                        let msg = RoomMessage::key_verification_accept_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::MessageLike(
                        AnyMessageLikeEvent::KeyVerificationCancel(MessageLikeEvent::Original(e)),
                    )) => {
                        let msg = RoomMessage::key_verification_cancel_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::MessageLike(
                        AnyMessageLikeEvent::KeyVerificationDone(MessageLikeEvent::Original(e)),
                    )) => {
                        let msg = RoomMessage::key_verification_done_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::KeyVerificationKey(
                        MessageLikeEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::key_verification_key_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::KeyVerificationMac(
                        MessageLikeEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::key_verification_mac_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::MessageLike(
                        AnyMessageLikeEvent::KeyVerificationReady(MessageLikeEvent::Original(e)),
                    )) => {
                        let msg = RoomMessage::key_verification_ready_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::MessageLike(
                        AnyMessageLikeEvent::KeyVerificationStart(MessageLikeEvent::Original(e)),
                    )) => {
                        let msg = RoomMessage::key_verification_start_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::Reaction(
                        MessageLikeEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::reaction_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomEncrypted(
                        MessageLikeEvent::Original(e),
                    ))) => {
                        info!("RoomEncrypted: {:?}", e.content);
                        let msg = RoomMessage::room_encrypted_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(
                        MessageLikeEvent::Original(m),
                    ))) => {
                        let msg = RoomMessage::room_message_from_event(m, &r, false);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomRedaction(e))) => {
                        let msg = RoomMessage::room_redaction_from_event(e, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::Sticker(
                        MessageLikeEvent::Original(s),
                    ))) => {
                        let msg = RoomMessage::sticker_from_event(s, &r);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::MessageLike(_)) => {
                        bail!("Invalid AnyTimelineEvent::MessageLike: other");
                    }
                    Err(e) => {
                        warn!("Error deserializing event {:?}", e);
                        bail!("Invalid event deserialization error");
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
    ) -> Result<OwnedEventId> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send reply as text to a room we are not in")
        };

        let event_id = EventId::parse(event_id).context("Couldn't parse event id to reply")?;

        RUNTIME
            .spawn(async move {
                let timeline_event = room
                    .event(&event_id)
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
                let content = RoomMessageEventContent::new(MessageType::Text(text_content))
                    .make_reply_to(original_message, ForwardThread::Yes);

                let response = room
                    .send(content, txn_id.as_deref().map(Into::into))
                    .await
                    .context("Couldn't send text reply")?;
                Ok(response.event_id)
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
    ) -> Result<OwnedEventId> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send reply as image to a room we are not in")
        };
        let client = self.room.client();
        let r = self.room.clone();

        let path = PathBuf::from(uri);
        let event_id = EventId::parse(event_id).context("Couldn't parse event id to reply")?;
        let content_type = mimetype.parse::<mime::Mime>()?;
        let info = assign!(ImageInfo::new(), {
            height: height.map(UInt::from),
            width: width.map(UInt::from),
            mimetype: Some(mimetype),
            size: size.map(UInt::from),
        });

        RUNTIME
            .spawn(async move {
                let image_buf =
                    std::fs::read(path).context("Couldn't read image buffer to reply")?;

                let timeline_event = room
                    .event(&event_id)
                    .await
                    .context("Couldn't find event.")?;

                let event_content = timeline_event
                    .event
                    .deserialize_as::<RoomMessageEvent>()
                    .context("Couldn't deserialise event")?;

                let original_message = event_content
                    .as_original()
                    .context("Couldn't retrieve original message.")?;

                let response = client
                    .media()
                    .upload(&content_type, image_buf)
                    .await
                    .context("Couldn't upload image to reply")?;

                let image_content = ImageMessageEventContent::plain(
                    name,
                    response.content_uri,
                    Some(Box::new(info)),
                );
                let content = RoomMessageEventContent::new(MessageType::Image(image_content))
                    .make_reply_to(original_message, ForwardThread::Yes);

                let response = room
                    .send(content, txn_id.as_deref().map(Into::into))
                    .await
                    .context("Couldn't send image reply")?;
                Ok(response.event_id)
            })
            .await?
    }

    #[allow(clippy::too_many_arguments)]
    pub async fn send_audio_reply(
        &self,
        uri: String,
        name: String,
        mimetype: String,
        secs: Option<u32>,
        size: Option<u32>,
        event_id: String,
        txn_id: Option<String>,
    ) -> Result<OwnedEventId> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send reply as audio to a room we are not in")
        };
        let client = self.room.client();
        let r = self.room.clone();

        let path = PathBuf::from(uri);
        let event_id = EventId::parse(event_id).context("Couldn't parse event id to reply")?;
        let content_type = mimetype.parse::<mime::Mime>()?;
        let info = assign!(AudioInfo::new(), {
            mimetype: Some(mimetype),
            duration: secs.map(|x| Duration::from_secs(x as u64)),
            size: size.map(UInt::from),
        });

        RUNTIME
            .spawn(async move {
                let image_buf =
                    std::fs::read(path).context("Couldn't read audio buffer to reply")?;

                let timeline_event = room
                    .event(&event_id)
                    .await
                    .context("Couldn't find event.")?;

                let event_content = timeline_event
                    .event
                    .deserialize_as::<RoomMessageEvent>()
                    .context("Couldn't deserialise event")?;

                let original_message = event_content
                    .as_original()
                    .context("Couldn't retrieve original message.")?;

                let response = client
                    .media()
                    .upload(&content_type, image_buf)
                    .await
                    .context("Couldn't upload audio to reply")?;

                let audio_content = AudioMessageEventContent::plain(
                    name,
                    response.content_uri,
                    Some(Box::new(info)),
                );
                let content = RoomMessageEventContent::new(MessageType::Audio(audio_content))
                    .make_reply_to(original_message, ForwardThread::Yes);

                let response = room
                    .send(content, txn_id.as_deref().map(Into::into))
                    .await
                    .context("Couldn't send audio reply")?;
                Ok(response.event_id)
            })
            .await?
    }

    #[allow(clippy::too_many_arguments)]
    pub async fn send_video_reply(
        &self,
        uri: String,
        name: String,
        mimetype: String,
        secs: Option<u32>,
        width: Option<u32>,
        height: Option<u32>,
        size: Option<u32>,
        blurhash: Option<String>,
        event_id: String,
        txn_id: Option<String>,
    ) -> Result<OwnedEventId> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send reply as video to a room we are not in")
        };
        let client = self.room.client();
        let r = self.room.clone();

        let path = PathBuf::from(uri);
        let event_id = EventId::parse(event_id).context("Couldn't parse event id to reply")?;
        let content_type = mimetype.parse::<mime::Mime>()?;
        let info = assign!(VideoInfo::new(), {
            duration: secs.map(|x| Duration::from_secs(x as u64)),
            height: height.map(UInt::from),
            width: width.map(UInt::from),
            mimetype: Some(mimetype),
            size: size.map(UInt::from),
            blurhash,
        });

        RUNTIME
            .spawn(async move {
                let video_buf =
                    std::fs::read(path).context("Couldn't read video buffer to reply")?;

                let timeline_event = room
                    .event(&event_id)
                    .await
                    .context("Couldn't find event.")?;

                let event_content = timeline_event
                    .event
                    .deserialize_as::<RoomMessageEvent>()
                    .context("Couldn't deserialise event")?;

                let original_message = event_content
                    .as_original()
                    .context("Couldn't retrieve original message.")?;

                let response = client
                    .media()
                    .upload(&content_type, video_buf)
                    .await
                    .context("Couldn't upload video to reply")?;

                let video_content = VideoMessageEventContent::plain(
                    name,
                    response.content_uri,
                    Some(Box::new(info)),
                );
                let content = RoomMessageEventContent::new(MessageType::Video(video_content))
                    .make_reply_to(original_message, ForwardThread::Yes);

                let response = room
                    .send(content, txn_id.as_deref().map(Into::into))
                    .await
                    .context("Couldn't send video reply")?;
                Ok(response.event_id)
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
    ) -> Result<OwnedEventId> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send reply as file to a room we are not in")
        };
        let client = self.room.client();

        let path = PathBuf::from(uri);
        let event_id = EventId::parse(event_id).context("Couldn't parse event id to reply")?;
        let content_type = mimetype.parse::<mime::Mime>()?;
        let info = assign!(FileInfo::new(), {
            mimetype: Some(mimetype),
            size: size.map(UInt::from),
        });

        RUNTIME
            .spawn(async move {
                let file_buf = std::fs::read(path).context("Couldn't read file buffer to reply")?;

                let timeline_event = room
                    .event(&event_id)
                    .await
                    .context("Couldn't find event.")?;

                let event_content = timeline_event
                    .event
                    .deserialize_as::<RoomMessageEvent>()
                    .context("Couldn't deserialise event")?;

                let original_message = event_content
                    .as_original()
                    .context("Couldn't retrieve original message.")?;

                let response = client
                    .media()
                    .upload(&content_type, file_buf)
                    .await
                    .context("Couldn't upload file to reply")?;

                let file_content = FileMessageEventContent::plain(
                    name,
                    response.content_uri,
                    Some(Box::new(info)),
                );
                let content = RoomMessageEventContent::new(MessageType::File(file_content))
                    .make_reply_to(original_message, ForwardThread::Yes);

                let response = room
                    .send(content, txn_id.as_deref().map(Into::into))
                    .await
                    .context("Couldn't send file reply")?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn redact_message(
        &self,
        event_id: String,
        reason: Option<String>,
        txn_id: Option<String>,
    ) -> Result<OwnedEventId> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't redact any message from a room we are not in")
        };

        let event_id = EventId::parse(event_id).context("Couldn't parse event id to redact")?;

        RUNTIME
            .spawn(async move {
                let response = room
                    .redact(&event_id, reason.as_deref(), txn_id.map(Into::into))
                    .await
                    .context("Couldn't redact message")?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn update_power_level(&self, user_id: String, level: i32) -> Result<OwnedEventId> {
        let room = if let MatrixRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't update power level in a room we are not in")
        };

        let user_id =
            UserId::parse(user_id).context("Couldn't parse user id to change power level")?;

        RUNTIME
            .spawn(async move {
                let resp = room
                    .update_power_levels(vec![(&user_id, Int::from(level))])
                    .await
                    .context("Couldn't change power level")?;
                Ok(resp.event_id)
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
