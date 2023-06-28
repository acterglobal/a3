use acter_core::spaces::is_acter_space;
use anyhow::{bail, Context, Result};
use core::time::Duration;
use matrix_sdk::{
    attachment::{
        AttachmentConfig, AttachmentInfo, BaseAudioInfo, BaseFileInfo, BaseImageInfo, BaseVideoInfo,
    },
    media::{MediaFormat, MediaRequest},
    room::{Room as SdkRoom, RoomMember},
    ruma::{
        api::client::receipt::create_receipt::v3::ReceiptType as CreateReceiptType,
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
            AnyMessageLikeEvent, AnyStateEvent, AnyTimelineEvent, MessageLikeEvent,
            MessageLikeEventType, StateEvent, StateEventType,
        },
        room::RoomType,
        EventId, Int, OwnedEventId, OwnedUserId, TransactionId, UInt, UserId,
    },
    Client, RoomMemberships, RoomState,
};
use matrix_sdk_ui::timeline::RoomExt;
use std::{fs::File, io::Write, ops::Deref, path::PathBuf, sync::Arc};
use tracing::{error, info};

use super::{
    account::Account,
    api::FfiBuffer,
    message::RoomMessage,
    profile::{RoomProfile, UserProfile},
    stream::TimelineStream,
    RUNTIME,
};

pub struct Member {
    pub(crate) member: RoomMember,
}

impl Deref for Member {
    type Target = RoomMember;
    fn deref(&self) -> &RoomMember {
        &self.member
    }
}

impl Member {
    pub fn get_profile(&self) -> UserProfile {
        let member = self.member.clone();
        UserProfile::from_member(member)
    }

    pub fn user_id(&self) -> OwnedUserId {
        self.member.user_id().to_owned()
    }
}

#[derive(Clone, Debug)]
pub struct Room {
    pub(crate) room: SdkRoom,
}

impl Room {
    pub(crate) async fn is_acter_space(&self) -> bool {
        is_acter_space(&self.room).await
    }

    pub fn get_profile(&self) -> RoomProfile {
        let client = self.room.client();
        let room_id = self.room_id().to_owned();
        RoomProfile::new(client, room_id)
    }

    pub async fn active_members(&self) -> Result<Vec<Member>> {
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let members = room
                    .members(RoomMemberships::ACTIVE)
                    .await?
                    .into_iter()
                    .map(|member| Member { member })
                    .collect();
                Ok(members)
            })
            .await?
    }

    pub async fn active_members_no_sync(&self) -> Result<Vec<Member>> {
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let members = room
                    .members_no_sync(RoomMemberships::ACTIVE)
                    .await?
                    .into_iter()
                    .map(|member| Member { member })
                    .collect();
                Ok(members)
            })
            .await?
    }

    pub async fn get_member(&self, user_id: String) -> Result<Member> {
        let room = self.room.clone();
        let uid = UserId::parse(user_id)?;

        RUNTIME
            .spawn(async move {
                let member = room.get_member(&uid).await?.context("User not found")?;
                Ok(Member { member })
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
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send typing notice to a room we are not in")
        };

        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }
                room.typing_notice(typing).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn read_receipt(&self, event_id: String) -> Result<bool> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send read_receipt to a room we are not in")
        };

        let event_id = EventId::parse(event_id)?;

        RUNTIME
            .spawn(async move {
                room.send_single_receipt(
                    CreateReceiptType::Read,
                    ReceiptThread::Unthreaded,
                    event_id,
                )
                .await?;
                Ok(true)
            })
            .await?
    }

    pub async fn send_plain_message(&self, message: String) -> Result<OwnedEventId> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message to a room we are not in")
        };

        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }
                let content = RoomMessageEventContent::text_plain(message);
                let txn_id = TransactionId::new();
                let response = room.send(content, Some(&txn_id)).await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn send_formatted_message(&self, markdown: String) -> Result<OwnedEventId> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message to a room we are not in")
        };

        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }
                let content = RoomMessageEventContent::text_markdown(markdown);
                let txn_id = TransactionId::new();
                let response = room.send(content, Some(&txn_id)).await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn send_reaction(&self, event_id: String, key: String) -> Result<OwnedEventId> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message to a room we are not in")
        };

        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();

        let event_id = EventId::parse(event_id)?;

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::Reaction) {
                    bail!("No permission to send reaction in this room");
                }
                let relates_to = Annotation::new(event_id, key);
                let content = ReactionEventContent::new(relates_to);
                let txn_id = TransactionId::new();
                let response = room.send(content, Some(&txn_id)).await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn send_image_message(
        &self,
        uri: String,
        name: String,
        blurhash: Option<String>,
    ) -> Result<SendImageResponse> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message as image to a room we are not in")
        };

        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();

        let path = PathBuf::from(uri);
        let guess = mime_guess::from_path(path.clone());
        let content_type = guess.first().context("No MIME type")?;
        if !content_type.to_string().starts_with("image/") {
            bail!("Image message accepts only image file");
        }

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }
                let buf = std::fs::read(path.clone())?;
                let file_size = buf.len() as u64;
                let mut base_info = BaseImageInfo {
                    height: None,
                    width: None,
                    size: UInt::new(file_size),
                    blurhash,
                };
                let mut width = None;
                let mut height = None;
                if let Ok(size) = imagesize::size(path.to_string_lossy().to_string()) {
                    width = Some(size.width as u64);
                    base_info.width = UInt::new(size.width as u64);
                    height = Some(size.height as u64);
                    base_info.height = UInt::new(size.height as u64);
                }
                let config = AttachmentConfig::new().info(AttachmentInfo::Image(base_info));
                let response = room
                    .send_attachment(name.as_str(), &content_type, buf, config)
                    .await?;
                Ok(SendImageResponse {
                    event_id: response.event_id,
                    file_size,
                    width,
                    height,
                })
            })
            .await?
    }

    pub async fn image_binary(&self, event_id: String) -> Result<FfiBuffer<u8>> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't read message from a room we are not in")
        };
        let client = self.room.client();

        let event_id = EventId::parse(event_id)?;

        RUNTIME
            .spawn(async move {
                let evt = room.event(&event_id).await?;
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
                let data = client.media().get_media_content(&request, false).await?;
                Ok(FfiBuffer::new(data))
            })
            .await?
    }

    pub async fn send_audio_message(
        &self,
        uri: String,
        name: String,
        secs: Option<u32>,
    ) -> Result<OwnedEventId> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message as audio to a room we are not in")
        };

        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();

        let path = PathBuf::from(uri);
        let guess = mime_guess::from_path(path.clone());
        let content_type = guess.first().context("No MIME type")?;
        if !content_type.to_string().starts_with("audio/") {
            bail!("Audio message accepts only audio file");
        }

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }
                let buf = std::fs::read(path)?;
                let config = AttachmentConfig::new().info(AttachmentInfo::Audio(BaseAudioInfo {
                    duration: secs.map(|x| Duration::from_secs(x as u64)),
                    size: UInt::new(buf.len() as u64),
                }));
                let response = room
                    .send_attachment(name.as_str(), &content_type, buf, config)
                    .await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn audio_binary(&self, event_id: String) -> Result<FfiBuffer<u8>> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't read message from a room we are not in")
        };
        let client = self.room.client();

        let event_id = EventId::parse(event_id)?;

        RUNTIME
            .spawn(async move {
                let evt = room.event(&event_id).await?;
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
                let data = client.media().get_media_content(&request, false).await?;
                Ok(FfiBuffer::new(data))
            })
            .await?
    }

    pub async fn send_video_message(
        &self,
        uri: String,
        name: String,
        secs: Option<u32>,
        height: Option<u32>,
        width: Option<u32>,
        blurhash: Option<String>,
    ) -> Result<OwnedEventId> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message as video to a room we are not in")
        };

        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();

        let path = PathBuf::from(uri);
        let guess = mime_guess::from_path(path.clone());
        let content_type = guess.first().context("No MIME type")?;
        if !content_type.to_string().starts_with("video/") {
            bail!("Video message accepts only video file");
        }

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }
                let buf = std::fs::read(path)?;
                let config = AttachmentConfig::new().info(AttachmentInfo::Video(BaseVideoInfo {
                    duration: secs.map(|x| Duration::from_secs(x as u64)),
                    height: height.map(UInt::from),
                    width: width.map(UInt::from),
                    size: UInt::new(buf.len() as u64),
                    blurhash,
                }));
                let response = room
                    .send_attachment(name.as_str(), &content_type, buf, config)
                    .await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn video_binary(&self, event_id: String) -> Result<FfiBuffer<u8>> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't read message from a room we are not in")
        };
        let client = self.room.client();

        let event_id = EventId::parse(event_id)?;

        RUNTIME
            .spawn(async move {
                let evt = room.event(&event_id).await?;
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
                let data = client.media().get_media_content(&request, false).await?;
                Ok(FfiBuffer::new(data))
            })
            .await?
    }

    pub async fn send_file_message(&self, uri: String, name: String) -> Result<OwnedEventId> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message as file to a room we are not in")
        };

        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();

        let path = PathBuf::from(uri);
        let guess = mime_guess::from_path(path.clone());
        let content_type = guess.first().context("No MIME type")?;

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }
                let buf = std::fs::read(path)?;
                let config = AttachmentConfig::new().info(AttachmentInfo::File(BaseFileInfo {
                    size: UInt::new(buf.len() as u64),
                }));
                let response = room
                    .send_attachment(name.as_str(), &content_type, buf, config)
                    .await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn file_binary(&self, event_id: String) -> Result<FfiBuffer<u8>> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't read message from a room we are not in")
        };
        let client = self.room.client();

        let event_id = EventId::parse(event_id)?;

        RUNTIME
            .spawn(async move {
                let evt = room.event(&event_id).await?;
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
                let data = client.media().get_media_content(&request, false).await?;
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
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message to a room we are not in")
        };

        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();

        let user_id = UserId::parse(user_id.as_str())?;

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_invite() {
                    bail!("No permission to invite someone in this room");
                }
                room.invite_user_by_id(&user_id).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn join(&self) -> Result<bool> {
        let room = if let SdkRoom::Left(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't join a room we are not left")
        };

        RUNTIME
            .spawn(async move {
                room.join().await?;
                Ok(true)
            })
            .await?
    }

    pub async fn leave(&self) -> Result<bool> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't leave a room we are not joined")
        };

        RUNTIME
            .spawn(async move {
                room.leave().await?;
                Ok(true)
            })
            .await?
    }

    pub async fn get_invitees(&self) -> Result<Vec<Member>> {
        let my_client = self.room.client();
        let room = if let SdkRoom::Invited(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't get a room we are not invited")
        };

        RUNTIME
            .spawn(async move {
                let invited = my_client
                    .store()
                    .get_user_ids(room.room_id(), RoomMemberships::INVITE)
                    .await?;
                let mut members: Vec<Member> = vec![];
                for user_id in invited.iter() {
                    if let Some(member) = room.get_member(user_id).await? {
                        members.push(Member { member });
                    }
                }
                Ok(members)
            })
            .await?
    }

    pub async fn download_media(&self, event_id: String, dir_path: String) -> Result<String> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't read message from a room we are not in")
        };
        let client = self.room.client();

        let eid = EventId::parse(event_id.clone())?;

        RUNTIME
            .spawn(async move {
                let evt = room.event(&eid).await?;
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
                        (request, content.body)
                    }
                    MessageType::Audio(content) => {
                        let request = MediaRequest {
                            source: content.source.clone(),
                            format: MediaFormat::File,
                        };
                        (request, content.body)
                    }
                    MessageType::Video(content) => {
                        let request = MediaRequest {
                            source: content.source.clone(),
                            format: MediaFormat::File,
                        };
                        (request, content.body)
                    }
                    MessageType::File(content) => {
                        let request = MediaRequest {
                            source: content.source.clone(),
                            format: MediaFormat::File,
                        };
                        (request, content.body)
                    }
                    _ => bail!("This message type is not downloadable"),
                };
                let mut path = PathBuf::from(dir_path.clone());
                path.push(name);
                let mut file = File::create(path.clone())?;
                let data = client.media().get_media_content(&request, false).await?;
                file.write_all(&data)?;
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
                    .await?;
                Ok(path_text.to_string())
            })
            .await?
    }

    pub async fn media_path(&self, event_id: String) -> Result<String> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't read message from a room we are not in")
        };
        let client = self.room.client();

        let eid = EventId::parse(event_id.clone())?;

        RUNTIME
            .spawn(async move {
                let evt = room.event(&eid).await?;
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
                let text = std::str::from_utf8(&path)?;
                Ok(text.to_string())
            })
            .await?
    }

    pub async fn is_encrypted(&self) -> Result<bool> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't know if a room we are not in is encrypted")
        };

        RUNTIME
            .spawn(async move {
                let encrypted = room.is_encrypted().await?;
                Ok(encrypted)
            })
            .await?
    }

    pub async fn get_message(&self, event_id: String) -> Result<RoomMessage> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't read message from a room we are not in")
        };
        let r = self.room.clone();

        let event_id = EventId::parse(event_id)?;

        RUNTIME
            .spawn(async move {
                let evt = room.event(&event_id).await?;
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
                        error!("Error deserializing event {:?}", e);
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
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send reply as text to a room we are not in")
        };

        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();

        let event_id = EventId::parse(event_id)?;

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }

                let timeline_event = room.event(&event_id).await?;

                let event_content = timeline_event.event.deserialize_as::<RoomMessageEvent>()?;

                let original_message = event_content
                    .as_original()
                    .context("Couldn't retrieve original message.")?;

                let text_content = TextMessageEventContent::markdown(msg);
                let content = RoomMessageEventContent::new(MessageType::Text(text_content))
                    .make_reply_to(original_message, ForwardThread::Yes);

                let response = room
                    .send(content, txn_id.as_deref().map(Into::into))
                    .await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn send_image_reply(
        &self,
        uri: String,
        name: String,
        event_id: String,
        txn_id: Option<String>,
    ) -> Result<OwnedEventId> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send reply as image to a room we are not in")
        };
        let client = room.client();
        let my_id = client.user_id().context("User not found")?.to_owned();

        let path = PathBuf::from(uri);
        let event_id = EventId::parse(event_id)?;
        let guess = mime_guess::from_path(path.clone());
        let content_type = guess.first().context("No MIME type")?;
        if !content_type.to_string().starts_with("image/") {
            bail!("Image reply accepts only image file");
        }

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }

                let buf = std::fs::read(path.clone())?;
                let mut info = assign!(ImageInfo::new(), {
                    height: None,
                    width: None,
                    mimetype: Some(content_type.to_string()),
                    size: UInt::new(buf.len() as u64),
                });
                if let Ok(size) = imagesize::size(path.to_string_lossy().to_string()) {
                    info.width = UInt::new(size.width as u64);
                    info.height = UInt::new(size.height as u64);
                }

                let timeline_event = room.event(&event_id).await?;

                let event_content = timeline_event.event.deserialize_as::<RoomMessageEvent>()?;

                let original_message = event_content
                    .as_original()
                    .context("Couldn't retrieve original message.")?;

                let response = client.media().upload(&content_type, buf).await?;

                let image_content = ImageMessageEventContent::plain(
                    name,
                    response.content_uri,
                    Some(Box::new(info)),
                );
                let content = RoomMessageEventContent::new(MessageType::Image(image_content))
                    .make_reply_to(original_message, ForwardThread::Yes);

                let response = room
                    .send(content, txn_id.as_deref().map(Into::into))
                    .await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn send_audio_reply(
        &self,
        uri: String,
        name: String,
        secs: Option<u32>,
        event_id: String,
        txn_id: Option<String>,
    ) -> Result<OwnedEventId> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send reply as audio to a room we are not in")
        };
        let client = room.client();
        let my_id = client.user_id().context("User not found")?.to_owned();

        let path = PathBuf::from(uri);
        let event_id = EventId::parse(event_id)?;
        let guess = mime_guess::from_path(path.clone());
        let content_type = guess.first().context("No MIME type")?;
        if !content_type.to_string().starts_with("audio/") {
            bail!("Audio message accepts only audio file");
        }

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }

                let buf = std::fs::read(path)?;
                let info = assign!(AudioInfo::new(), {
                    mimetype: Some(content_type.to_string()),
                    duration: secs.map(|x| Duration::from_secs(x as u64)),
                    size: UInt::new(buf.len() as u64),
                });

                let timeline_event = room.event(&event_id).await?;

                let event_content = timeline_event.event.deserialize_as::<RoomMessageEvent>()?;

                let original_message = event_content
                    .as_original()
                    .context("Couldn't retrieve original message.")?;

                let response = client.media().upload(&content_type, buf).await?;

                let audio_content = AudioMessageEventContent::plain(
                    name,
                    response.content_uri,
                    Some(Box::new(info)),
                );
                let content = RoomMessageEventContent::new(MessageType::Audio(audio_content))
                    .make_reply_to(original_message, ForwardThread::Yes);

                let response = room
                    .send(content, txn_id.as_deref().map(Into::into))
                    .await?;
                Ok(response.event_id)
            })
            .await?
    }

    #[allow(clippy::too_many_arguments)]
    pub async fn send_video_reply(
        &self,
        uri: String,
        name: String,
        secs: Option<u32>,
        width: Option<u32>,
        height: Option<u32>,
        blurhash: Option<String>,
        event_id: String,
        txn_id: Option<String>,
    ) -> Result<OwnedEventId> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send reply as video to a room we are not in")
        };
        let client = room.client();
        let my_id = client.user_id().context("User not found")?.to_owned();

        let path = PathBuf::from(uri);
        let event_id = EventId::parse(event_id)?;
        let guess = mime_guess::from_path(path.clone());
        let content_type = guess.first().context("No MIME type")?;
        if !content_type.to_string().starts_with("video/") {
            bail!("Video message accepts only video file");
        }

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }

                let buf = std::fs::read(path)?;
                let info = assign!(VideoInfo::new(), {
                    duration: secs.map(|x| Duration::from_secs(x as u64)),
                    height: height.map(UInt::from),
                    width: width.map(UInt::from),
                    mimetype: Some(content_type.to_string()),
                    size: UInt::new(buf.len() as u64),
                    blurhash,
                });

                let timeline_event = room.event(&event_id).await?;

                let event_content = timeline_event.event.deserialize_as::<RoomMessageEvent>()?;

                let original_message = event_content
                    .as_original()
                    .context("Couldn't retrieve original message.")?;

                let response = client.media().upload(&content_type, buf).await?;

                let video_content = VideoMessageEventContent::plain(
                    name,
                    response.content_uri,
                    Some(Box::new(info)),
                );
                let content = RoomMessageEventContent::new(MessageType::Video(video_content))
                    .make_reply_to(original_message, ForwardThread::Yes);

                let response = room
                    .send(content, txn_id.as_deref().map(Into::into))
                    .await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn send_file_reply(
        &self,
        uri: String,
        name: String,
        event_id: String,
        txn_id: Option<String>,
    ) -> Result<OwnedEventId> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send reply as file to a room we are not in")
        };
        let client = room.client();
        let my_id = client.user_id().context("User not found")?.to_owned();

        let path = PathBuf::from(uri);
        let event_id = EventId::parse(event_id)?;
        let guess = mime_guess::from_path(path.clone());
        let content_type = guess.first().context("No MIME type")?;

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }

                let buf = std::fs::read(path)?;
                let info = assign!(FileInfo::new(), {
                    mimetype: Some(content_type.to_string()),
                    size: UInt::new(buf.len() as u64),
                });

                let timeline_event = room.event(&event_id).await?;

                let event_content = timeline_event.event.deserialize_as::<RoomMessageEvent>()?;

                let original_message = event_content
                    .as_original()
                    .context("Couldn't retrieve original message.")?;

                let response = client.media().upload(&content_type, buf).await?;

                let file_content = FileMessageEventContent::plain(
                    name,
                    response.content_uri,
                    Some(Box::new(info)),
                );
                let content = RoomMessageEventContent::new(MessageType::File(file_content))
                    .make_reply_to(original_message, ForwardThread::Yes);

                let response = room
                    .send(content, txn_id.as_deref().map(Into::into))
                    .await?;
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
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't redact any message from a room we are not in")
        };

        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();

        let event_id = EventId::parse(event_id)?;

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_redact() {
                    bail!("No permission to redact message in this room");
                }
                let response = room
                    .redact(&event_id, reason.as_deref(), txn_id.map(Into::into))
                    .await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn update_power_level(&self, user_id: String, level: i32) -> Result<OwnedEventId> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't update power level in a room we are not in")
        };

        let my_id = room
            .client()
            .user_id()
            .context("User not found")?
            .to_owned();

        let user_id = UserId::parse(user_id)?;

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_state(StateEventType::RoomPowerLevels) {
                    bail!("No permission to change power levels in this room");
                }
                let resp = room
                    .update_power_levels(vec![(&user_id, Int::from(level))])
                    .await?;
                Ok(resp.event_id)
            })
            .await?
    }
}

impl Deref for Room {
    type Target = SdkRoom;
    fn deref(&self) -> &SdkRoom {
        &self.room
    }
}

pub struct SendImageResponse {
    event_id: OwnedEventId,
    file_size: u64,
    width: Option<u64>,
    height: Option<u64>,
}

impl SendImageResponse {
    pub fn event_id(&self) -> OwnedEventId {
        self.event_id.clone()
    }

    pub fn file_size(&self) -> u64 {
        self.file_size
    }

    pub fn width(&self) -> Option<u64> {
        self.width
    }

    pub fn height(&self) -> Option<u64> {
        self.height
    }
}
