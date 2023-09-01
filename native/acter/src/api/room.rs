use acter_core::{
    events::{
        calendar::CalendarEventEventContent,
        news::{NewsContent, NewsEntryEvent, NewsEntryEventContent},
        pins::PinEventContent,
        settings::{ActerAppSettings, ActerAppSettingsContent},
    },
    spaces::is_acter_space,
    statics::PURPOSE_FIELD_DEV,
};
use anyhow::{bail, Context, Result};
use core::time::Duration;
#[cfg(feature = "audio-meta")]
use lofty::{AudioFile, Probe};
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
            relation::{Annotation, Replacement},
            room::{
                avatar::ImageInfo as AvatarImageInfo,
                join_rules::{AllowRule, JoinRule},
                message::{
                    AudioInfo, AudioMessageEventContent, FileInfo, FileMessageEventContent,
                    ForwardThread, ImageMessageEventContent, LocationMessageEventContent,
                    MessageType, Relation, RoomMessageEvent, RoomMessageEventContent,
                    TextMessageEventContent, VideoInfo, VideoMessageEventContent,
                },
                ImageInfo,
            },
            AnyMessageLikeEvent, AnyStateEvent, AnyTimelineEvent, MessageLikeEvent,
            MessageLikeEventType, StateEvent, StateEventType, StaticEventContent,
        },
        room::RoomType,
        EventId, Int, MxcUri, OwnedEventId, OwnedMxcUri, OwnedUserId, TransactionId, UInt, UserId,
    },
    Client, RoomMemberships, RoomState,
};
use matrix_sdk_ui::timeline::RoomExt;
use std::{io::Write, ops::Deref, path::PathBuf, sync::Arc};
use tracing::{error, info};

#[cfg(feature = "video-meta")]
use super::platform::{parse_video, VideoMetadata};
use super::{
    account::Account,
    api::FfiBuffer,
    message::RoomMessage,
    profile::{RoomProfile, UserProfile},
    stream::TimelineStream,
    RUNTIME,
};

#[derive(Eq, PartialEq, Clone, strum::Display, strum::EnumString, Debug)]
#[strum(serialize_all = "PascalCase")]
pub enum MembershipStatus {
    Admin,
    Mod,
    Custom,
    Regular,
}

#[derive(Eq, PartialEq, Clone, strum::Display, strum::EnumString, Debug)]
#[strum(serialize_all = "PascalCase")]
pub enum MemberPermission {
    // regular interaction
    CanSendChatMessages,
    CanSendReaction,
    CanSendSticker,
    // Acter Specific actions
    CanPostNews,
    CanPostPin,
    CanPostEvent,
    // moderation tools
    CanBan,
    CanInvite,
    CanKick,
    CanRedact,
    CanTriggerRoomNotification,
    // state events
    CanUpgradeToActerSpace,
    CanSetName,
    CanUpdateAvatar,
    CanSetTopic,
    CanLinkSpaces,
    CanSetParentSpace,
    CanUpdatePowerLevels,
    CanChangeAppSettings,
}

enum PermissionTest {
    StateEvent(StateEventType),
    Message(MessageLikeEventType),
}

impl From<StateEventType> for PermissionTest {
    fn from(value: StateEventType) -> Self {
        PermissionTest::StateEvent(value)
    }
}

impl From<MessageLikeEventType> for PermissionTest {
    fn from(value: MessageLikeEventType) -> Self {
        PermissionTest::Message(value)
    }
}

pub struct Member {
    pub(crate) member: RoomMember,
    pub(crate) acter_app_settings: Option<ActerAppSettingsContent>,
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

    pub fn can_string(&self, input: String) -> bool {
        let Ok(permission) = MemberPermission::try_from(input.as_str()) else {
            return false;
        };
        self.can(permission)
    }

    pub fn membership_status(&self) -> MembershipStatus {
        match self.member.normalized_power_level() {
            100 => MembershipStatus::Admin,
            50 => MembershipStatus::Mod,
            0 => MembershipStatus::Regular,
            _ => MembershipStatus::Custom,
        }
    }

    pub fn membership_status_str(&self) -> String {
        self.membership_status().to_string()
    }

    pub fn can(&self, permission: MemberPermission) -> bool {
        let tester: PermissionTest = match permission {
            MemberPermission::CanBan => return self.member.can_ban(),
            MemberPermission::CanInvite => return self.member.can_invite(),
            MemberPermission::CanRedact => return self.member.can_redact(),
            MemberPermission::CanKick => return self.member.can_kick(),
            MemberPermission::CanTriggerRoomNotification => {
                return self.member.can_trigger_room_notification()
            }
            MemberPermission::CanSendChatMessages => MessageLikeEventType::RoomMessage.into(), // or should this check for encrypted?
            MemberPermission::CanSendReaction => MessageLikeEventType::Reaction.into(),
            MemberPermission::CanSendSticker => MessageLikeEventType::Sticker.into(),
            MemberPermission::CanSetName => StateEventType::RoomName.into(),
            MemberPermission::CanUpdateAvatar => StateEventType::RoomAvatar.into(),
            MemberPermission::CanSetTopic => StateEventType::RoomTopic.into(),
            MemberPermission::CanLinkSpaces => StateEventType::SpaceChild.into(),
            MemberPermission::CanSetParentSpace => StateEventType::SpaceParent.into(),
            MemberPermission::CanUpdatePowerLevels => StateEventType::RoomPowerLevels.into(),

            // Acter specific
            MemberPermission::CanPostNews => {
                if self
                    .acter_app_settings
                    .as_ref()
                    .map(|s| s.news().active())
                    .unwrap_or_default()
                {
                    PermissionTest::Message(MessageLikeEventType::from(
                        <NewsEntryEventContent as StaticEventContent>::TYPE,
                    ))
                } else {
                    // Not an acter space or news Posts are not activated..
                    return false;
                }
            }
            MemberPermission::CanPostPin => {
                if self
                    .acter_app_settings
                    .as_ref()
                    .map(|s| s.pins().active())
                    .unwrap_or_default()
                {
                    PermissionTest::Message(MessageLikeEventType::from(
                        <PinEventContent as StaticEventContent>::TYPE,
                    ))
                } else {
                    // Not an acter space or Pins are not activated..
                    return false;
                }
            }
            MemberPermission::CanPostEvent => {
                if self
                    .acter_app_settings
                    .as_ref()
                    .map(|s| s.events().active())
                    .unwrap_or_default()
                {
                    PermissionTest::Message(MessageLikeEventType::from(
                        <CalendarEventEventContent as StaticEventContent>::TYPE,
                    ))
                } else {
                    // Not an acter space or Pins are not activated..
                    return false;
                }
            }
            MemberPermission::CanUpgradeToActerSpace => {
                if self.acter_app_settings.is_some() {
                    return false; // already an acter space
                }
                StateEventType::from(PURPOSE_FIELD_DEV).into()
            }
            MemberPermission::CanChangeAppSettings => {
                if self.acter_app_settings.is_some() {
                    PermissionTest::StateEvent(ActerAppSettingsContent::TYPE.into())
                } else {
                    // not an acter space, you can't set setting here
                    return false;
                }
            }
        };
        match tester {
            PermissionTest::Message(msg) => self.member.can_send_message(msg),
            PermissionTest::StateEvent(state) => self.member.can_send_state(state),
        }
    }
}

#[derive(Clone, Debug)]
pub struct Room {
    pub(crate) room: SdkRoom,
}

impl Room {
    pub async fn is_acter_space(&self) -> Result<bool> {
        let inner = self.room.clone();
        let result = RUNTIME
            .spawn(async move { is_acter_space(&inner).await })
            .await?;
        Ok(result)
    }

    pub async fn get_my_membership(&self) -> Result<Member> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Not a room we have joined")
        };

        let client = room.client();
        let my_id = client.user_id().context("User not found")?.to_owned();
        let is_acter_space = self.is_acter_space().await?;
        let acter_app_settings = if is_acter_space {
            Some(self.app_settings_content().await?)
        } else {
            None
        };

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                Ok(Member {
                    member,
                    acter_app_settings,
                })
            })
            .await?
    }

    pub fn get_profile(&self) -> RoomProfile {
        let client = self.room.client();
        let room_id = self.room_id().to_owned();
        RoomProfile::new(client, room_id)
    }

    pub async fn upload_avatar(&self, uri: String) -> Result<OwnedMxcUri> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't upload avatar to a room we are not in")
        };

        let client = room.client();
        let my_id = client.user_id().context("User not found")?.to_owned();
        let path = PathBuf::from(uri);

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_state(StateEventType::RoomAvatar) {
                    bail!("No permission to change avatar of this room");
                }

                let guess = mime_guess::from_path(path.clone());
                let content_type = guess.first().context("MIME type should be given")?;
                let buf = std::fs::read(path).context("File should be read")?;
                let response = client.media().upload(&content_type, buf).await?;

                let content_uri = response.content_uri;
                let info = assign!(AvatarImageInfo::new(), {
                    blurhash: response.blurhash,
                    mimetype: Some(content_type.to_string()),
                });
                let response = room.set_avatar_url(&content_uri, Some(info)).await?;
                Ok(content_uri)
            })
            .await?
    }

    pub async fn remove_avatar(&self) -> Result<OwnedEventId> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't remove avatar to a room we are not in")
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
                if !member.can_send_state(StateEventType::RoomAvatar) {
                    bail!("No permission to change avatar of this room");
                }
                let resp = room
                    .remove_avatar()
                    .await
                    .context("Couldn't remove avatar from room")?;
                Ok(resp.event_id)
            })
            .await?
    }

    pub async fn set_topic(&self, topic: String) -> Result<OwnedEventId> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't set topic to a room we are not in")
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
                if !member.can_send_state(StateEventType::RoomTopic) {
                    bail!("No permission to change topic of this room");
                }
                let resp = room
                    .set_room_topic(topic.as_str())
                    .await
                    .context("Couldn't set topic to the room")?;
                Ok(resp.event_id)
            })
            .await?
    }

    pub async fn set_name(&self, name: Option<String>) -> Result<OwnedEventId> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't set name to a room we are not in")
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
                if !member.can_send_state(StateEventType::RoomName) {
                    bail!("No permission to change name of this room");
                }
                let resp = room
                    .set_name(name)
                    .await
                    .context("Couldn't set name to the room")?;
                Ok(resp.event_id)
            })
            .await?
    }

    pub async fn active_members(&self) -> Result<Vec<Member>> {
        let room = self.room.clone();

        let is_acter_space = self.is_acter_space().await?;
        let acter_app_settings = if is_acter_space {
            Some(self.app_settings_content().await?)
        } else {
            None
        };

        RUNTIME
            .spawn(async move {
                let members = room
                    .members(RoomMemberships::ACTIVE)
                    .await?
                    .into_iter()
                    .map(|member| Member {
                        member,
                        acter_app_settings: acter_app_settings.clone(),
                    })
                    .collect();
                Ok(members)
            })
            .await?
    }

    pub async fn invited_members(&self) -> Result<Vec<Member>> {
        let room = self.room.clone();
        let is_acter_space = self.is_acter_space().await?;
        let acter_app_settings = if is_acter_space {
            Some(self.app_settings_content().await?)
        } else {
            None
        };

        RUNTIME
            .spawn(async move {
                let members = room
                    .members(RoomMemberships::INVITE)
                    .await?
                    .into_iter()
                    .map(|member| Member {
                        member,
                        acter_app_settings: acter_app_settings.clone(),
                    })
                    .collect();
                Ok(members)
            })
            .await?
    }

    pub async fn active_members_no_sync(&self) -> Result<Vec<Member>> {
        let room = self.room.clone();
        let is_acter_space = self.is_acter_space().await?;
        let acter_app_settings = if is_acter_space {
            Some(self.app_settings_content().await?)
        } else {
            None
        };

        RUNTIME
            .spawn(async move {
                let members = room
                    .members_no_sync(RoomMemberships::ACTIVE)
                    .await?
                    .into_iter()
                    .map(|member| Member {
                        member,
                        acter_app_settings: acter_app_settings.clone(),
                    })
                    .collect();
                Ok(members)
            })
            .await?
    }

    pub async fn get_member(&self, user_id: String) -> Result<Member> {
        let room = self.room.clone();
        let uid = UserId::parse(user_id)?;
        let is_acter_space = self.is_acter_space().await?;
        let acter_app_settings = if is_acter_space {
            Some(self.app_settings_content().await?)
        } else {
            None
        };

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&uid)
                    .await?
                    .context("User not found among room members")?;
                Ok(Member {
                    member,
                    acter_app_settings: acter_app_settings.clone(),
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
            bail!("Can't send message as plain text to a room we are not in")
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

    pub async fn edit_plain_message(
        &self,
        event_id: String,
        new_msg: String,
    ) -> Result<OwnedEventId> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't edit message as plain text to a room we are not in")
        };
        let event_id = EventId::parse(event_id)?;
        let client = self.room.client();

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

                let timeline_event = room.event(&event_id).await?;
                let event_content = timeline_event
                    .event
                    .deserialize_as::<RoomMessageEvent>()
                    .context("Couldn't deserialise event")?;

                let mut sent_by_me = false;
                if let Some(user_id) = client.user_id() {
                    if user_id == event_content.sender() {
                        sent_by_me = true;
                    }
                }
                if !sent_by_me {
                    bail!("Can't edit an event not sent by own user");
                }

                let replacement = Replacement::new(
                    event_id.to_owned(),
                    MessageType::text_plain(new_msg.to_string()),
                );
                let mut edited_content = RoomMessageEventContent::text_markdown(new_msg);
                edited_content.relates_to = Some(Relation::Replacement(replacement));

                let txn_id = TransactionId::new();
                let response = room.send(edited_content, Some(&txn_id)).await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn send_formatted_message(&self, markdown: String) -> Result<OwnedEventId> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message as formatted text to a room we are not in")
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

    pub async fn edit_formatted_message(
        &self,
        event_id: String,
        new_msg: String,
    ) -> Result<OwnedEventId> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't edit message as formatted text to a room we are not in")
        };
        let event_id = EventId::parse(event_id)?;
        let client = self.room.client();

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

                let timeline_event = room.event(&event_id).await?;
                let event_content = timeline_event
                    .event
                    .deserialize_as::<RoomMessageEvent>()
                    .context("Couldn't deserialise event")?;

                let mut sent_by_me = false;
                if let Some(user_id) = client.user_id() {
                    if user_id == event_content.sender() {
                        sent_by_me = true;
                    }
                }
                if !sent_by_me {
                    bail!("Can't edit an event not sent by own user");
                }

                let replacement = Replacement::new(
                    event_id.to_owned(),
                    MessageType::text_markdown(new_msg.to_string()),
                );
                let mut edited_content = RoomMessageEventContent::text_markdown(new_msg);
                edited_content.relates_to = Some(Relation::Replacement(replacement));

                let txn_id = TransactionId::new();
                let response = room.send(edited_content, Some(&txn_id)).await?;
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
        url_or_path: String,
        body: String,
        blurhash: Option<String>,
    ) -> Result<SendImageResult> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message as image to a room we are not in")
        };
        let client = room.client();

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

                let url = Box::<MxcUri>::from(url_or_path.as_str()); // http not allowed for remote url
                let mut file_size = None;
                let mut width = None;
                let mut height = None;
                let image_content = if url.is_valid() {
                    ImageMessageEventContent::plain(body, url.into())
                } else {
                    let path = PathBuf::from(url_or_path);
                    let guess = mime_guess::from_path(path.clone());
                    let content_type = guess.first().context("No MIME type")?;
                    let mimetype = content_type.to_string();
                    if !mimetype.starts_with("image/") {
                        bail!("Image message accepts only image file");
                    }
                    let mut content = if room.is_encrypted().await? {
                        let mut reader = std::fs::File::open(path.clone())?;
                        let encrypted_file = client
                            .prepare_encrypted_file(&content_type, &mut reader)
                            .await?;
                        ImageMessageEventContent::encrypted(body, encrypted_file)
                    } else {
                        let buf = std::fs::read(path.clone())?;
                        let response = client.media().upload(&content_type, buf).await?;
                        ImageMessageEventContent::plain(body, response.content_uri)
                    };
                    let buf = std::fs::read(path.clone())?;
                    let size = buf.len() as u64;
                    file_size = Some(size);
                    let mut info = assign!(ImageInfo::new(), {
                        mimetype: Some(mimetype),
                        size: UInt::new(size),
                        blurhash,
                    });
                    #[cfg(feature = "image-meta")]
                    if let Ok(size) = imagesize::size(path.to_string_lossy().to_string()) {
                        info.width = UInt::new(size.width as u64);
                        info.height = UInt::new(size.height as u64);
                        width = Some(size.width as u64);
                        height = Some(size.height as u64);
                    }
                    content.info = Some(Box::new(info));
                    content
                };

                let content = RoomMessageEventContent::new(MessageType::Image(image_content));
                let response = room.send(content, None).await?;

                Ok(SendImageResult {
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
            bail!("Can't read message as image from a room we are not in")
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

    #[allow(clippy::too_many_arguments)]
    pub async fn edit_image_message(
        &self,
        event_id: String,
        uri: String,
        name: String,
        mimetype: String,
        size: Option<u32>,
        width: Option<u32>,
        height: Option<u32>,
    ) -> Result<OwnedEventId> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't edit message as image to a room we are not in")
        };
        let event_id = EventId::parse(event_id)?;
        let client = self.room.client();

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

                let path = PathBuf::from(uri);
                let mut image_buf = std::fs::read(path)?;

                let timeline_event = room.event(&event_id).await?;
                let event_content = timeline_event
                    .event
                    .deserialize_as::<RoomMessageEvent>()
                    .context("Couldn't deserialise event")?;

                let mut sent_by_me = false;
                if let Some(user_id) = client.user_id() {
                    if user_id == event_content.sender() {
                        sent_by_me = true;
                    }
                }
                if !sent_by_me {
                    bail!("Can't edit an event not sent by own user");
                }

                let content_type: mime_guess::Mime = mimetype.parse()?;
                let response = client.media().upload(&content_type, image_buf).await?;

                let info = assign!(ImageInfo::new(), {
                    height: height.map(UInt::from),
                    width: width.map(UInt::from),
                    mimetype: Some(mimetype),
                    size: size.map(UInt::from),
                });
                let mut image_content = ImageMessageEventContent::plain(name, response.content_uri);
                image_content.info = Some(Box::new(info));
                let mut edited_content =
                    RoomMessageEventContent::new(MessageType::Image(image_content.clone()));
                let replacement =
                    Replacement::new(event_id.to_owned(), MessageType::Image(image_content));
                edited_content.relates_to = Some(Relation::Replacement(replacement));

                let txn_id = TransactionId::new();
                let response = room.send(edited_content, Some(&txn_id)).await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn send_audio_message(
        &self,
        url_or_path: String,
        body: String,
    ) -> Result<SendAudioResult> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message as audio to a room we are not in")
        };
        let client = room.client();

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

                let url = Box::<MxcUri>::from(url_or_path.as_str()); // http not allowed for remote url
                let mut file_size = None;
                let mut duration = None;
                let audio_content = if url.is_valid() {
                    AudioMessageEventContent::plain(body, url.into())
                } else {
                    let path = PathBuf::from(url_or_path);
                    let guess = mime_guess::from_path(path.clone());
                    let content_type = guess.first().context("No MIME type")?;
                    let mimetype = content_type.to_string();
                    if !mimetype.starts_with("audio/") {
                        bail!("Audio message accepts only audio file");
                    }
                    let mut content = if room.is_encrypted().await? {
                        let mut reader = std::fs::File::open(path.clone())?;
                        let encrypted_file = client
                            .prepare_encrypted_file(&content_type, &mut reader)
                            .await?;
                        AudioMessageEventContent::encrypted(body, encrypted_file)
                    } else {
                        let buf = std::fs::read(path.clone())?;
                        let response = client.media().upload(&content_type, buf).await?;
                        AudioMessageEventContent::plain(body, response.content_uri)
                    };
                    let buf = std::fs::read(path.clone())?;
                    let size = buf.len() as u64;
                    file_size = Some(size);
                    let mut info = assign!(AudioInfo::new(), {
                        size: UInt::new(size),
                    });
                    #[cfg(feature = "audio-meta")]
                    if let Ok(probe) = Probe::open(path) {
                        if let Ok(tagged_file) = probe.read() {
                            info.duration = Some(tagged_file.properties().duration());
                        }
                    }
                    content.info = Some(Box::new(info));
                    content
                };

                let content = RoomMessageEventContent::new(MessageType::Audio(audio_content));
                let response = room.send(content, None).await?;

                Ok(SendAudioResult {
                    event_id: response.event_id,
                    file_size,
                    duration,
                })
            })
            .await?
    }

    pub async fn audio_binary(&self, event_id: String) -> Result<FfiBuffer<u8>> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't read message as audio from a room we are not in")
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

    #[allow(clippy::too_many_arguments)]
    pub async fn edit_audio_message(
        &self,
        event_id: String,
        uri: String,
        name: String,
        mimetype: String,
        secs: Option<u32>,
        size: Option<u32>,
    ) -> Result<OwnedEventId> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't edit message as audio to a room we are not in")
        };
        let event_id = EventId::parse(event_id)?;
        let client = self.room.client();

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

                let path = PathBuf::from(uri);
                let mut audio_buf = std::fs::read(path)?;

                let timeline_event = room.event(&event_id).await?;
                let event_content = timeline_event
                    .event
                    .deserialize_as::<RoomMessageEvent>()
                    .context("Couldn't deserialise event")?;

                let mut sent_by_me = false;
                if let Some(user_id) = client.user_id() {
                    if user_id == event_content.sender() {
                        sent_by_me = true;
                    }
                }
                if !sent_by_me {
                    bail!("Can't edit an event not sent by own user");
                }

                let content_type: mime_guess::Mime = mimetype.parse()?;
                let response = client.media().upload(&content_type, audio_buf).await?;

                let info = assign!(AudioInfo::new(), {
                    duration: secs.map(|x| Duration::from_secs(x as u64)),
                    mimetype: Some(mimetype),
                    size: size.map(UInt::from),
                });
                let mut audio_content = AudioMessageEventContent::plain(name, response.content_uri);
                audio_content.info = Some(Box::new(info));
                let mut edited_content =
                    RoomMessageEventContent::new(MessageType::Audio(audio_content.clone()));
                let replacement =
                    Replacement::new(event_id.to_owned(), MessageType::Audio(audio_content));
                edited_content.relates_to = Some(Relation::Replacement(replacement));

                let txn_id = TransactionId::new();
                let response = room.send(edited_content, Some(&txn_id)).await?;
                Ok(response.event_id)
            })
            .await?
    }

    #[allow(clippy::too_many_arguments)]
    pub async fn send_video_message(
        &self,
        url_or_path: String,
        body: String,
        blurhash: Option<String>,
    ) -> Result<SendVideoResult> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message as video to a room we are not in")
        };
        let client = room.client();

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

                let url = Box::<MxcUri>::from(url_or_path.as_str()); // http not allowed for remote url
                let mut file_size = None;
                let mut duration = None;
                let mut width = None;
                let mut height = None;
                let video_content = if url.is_valid() {
                    VideoMessageEventContent::plain(body, url.into())
                } else {
                    let path = PathBuf::from(url_or_path.clone());
                    let guess = mime_guess::from_path(path.clone());
                    let content_type = guess.first().context("No MIME type")?;
                    let mimetype = content_type.to_string();
                    if !mimetype.starts_with("video/") {
                        bail!("Video message accepts only video file");
                    }
                    let mut content = if room.is_encrypted().await? {
                        let mut reader = std::fs::File::open(path.clone())?;
                        let encrypted_file = client
                            .prepare_encrypted_file(&content_type, &mut reader)
                            .await?;
                        VideoMessageEventContent::encrypted(body, encrypted_file)
                    } else {
                        let buf = std::fs::read(path.clone())?;
                        let response = client.media().upload(&content_type, buf).await?;
                        VideoMessageEventContent::plain(body, response.content_uri)
                    };
                    let buf = std::fs::read(path)?;
                    let size = buf.len() as u64;
                    file_size = Some(size);
                    let mut info = assign!(VideoInfo::new(), {
                        mimetype: Some(mimetype),
                        size: UInt::new(size),
                        blurhash,
                    });
                    #[cfg(feature = "video-meta")]
                    if let Ok(Some(metadata)) = parse_video(url_or_path).await {
                        info.duration = Some(Duration::from_secs(metadata.duration));
                        info.width = UInt::new(metadata.width as u64);
                        info.height = UInt::new(metadata.height as u64);
                        duration = info.duration.clone();
                        width = Some(metadata.width);
                        height = Some(metadata.height);
                    }
                    content.info = Some(Box::new(info));
                    content
                };

                let content = RoomMessageEventContent::new(MessageType::Video(video_content));
                let response = room.send(content, None).await?;

                Ok(SendVideoResult {
                    event_id: response.event_id,
                    file_size,
                    duration,
                    width,
                    height,
                })
            })
            .await?
    }

    pub async fn video_binary(&self, event_id: String) -> Result<FfiBuffer<u8>> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't read message as video from a room we are not in")
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

    #[allow(clippy::too_many_arguments)]
    pub async fn edit_video_message(
        &self,
        event_id: String,
        uri: String,
        name: String,
        mimetype: String,
        secs: Option<u32>,
        height: Option<u32>,
        width: Option<u32>,
        size: Option<u32>,
    ) -> Result<OwnedEventId> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't edit message as video to a room we are not in")
        };
        let event_id = EventId::parse(event_id)?;
        let client = self.room.client();

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

                let path = PathBuf::from(uri);
                let mut video_buf = std::fs::read(path)?;

                let timeline_event = room.event(&event_id).await?;
                let event_content = timeline_event
                    .event
                    .deserialize_as::<RoomMessageEvent>()
                    .context("Couldn't deserialise event")?;

                let mut sent_by_me = false;
                if let Some(user_id) = client.user_id() {
                    if user_id == event_content.sender() {
                        sent_by_me = true;
                    }
                }
                if !sent_by_me {
                    bail!("Can't edit an event not sent by own user");
                }

                let content_type: mime_guess::Mime = mimetype.parse()?;
                let response = client.media().upload(&content_type, video_buf).await?;

                let info = assign!(VideoInfo::new(), {
                    duration: secs.map(|x| Duration::from_secs(x as u64)),
                    height: height.map(UInt::from),
                    width: width.map(UInt::from),
                    mimetype: Some(mimetype),
                    size: size.map(UInt::from),
                });
                let mut video_content = VideoMessageEventContent::plain(name, response.content_uri);
                video_content.info = Some(Box::new(info));
                let mut edited_content =
                    RoomMessageEventContent::new(MessageType::Video(video_content.clone()));
                let replacement =
                    Replacement::new(event_id.to_owned(), MessageType::Video(video_content));
                edited_content.relates_to = Some(Relation::Replacement(replacement));

                let txn_id = TransactionId::new();
                let response = room.send(edited_content, Some(&txn_id)).await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn send_file_message(
        &self,
        url_or_path: String,
        body: String,
    ) -> Result<OwnedEventId> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message as file to a room we are not in")
        };
        let client = room.client();

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

                let url = Box::<MxcUri>::from(url_or_path.as_str()); // http not allowed for remote url
                let mut file_size = None;
                let file_content = if url.is_valid() {
                    FileMessageEventContent::plain(body, url.into())
                } else {
                    let path = PathBuf::from(url_or_path);
                    let guess = mime_guess::from_path(path.clone());
                    let content_type = guess
                        .first()
                        .unwrap_or(mime_guess::mime::APPLICATION_OCTET_STREAM);
                    let mimetype = content_type.to_string();
                    let mut content = if room.is_encrypted().await? {
                        let mut reader = std::fs::File::open(path.clone())?;
                        let encrypted_file = client
                            .prepare_encrypted_file(&content_type, &mut reader)
                            .await?;
                        FileMessageEventContent::encrypted(body, encrypted_file)
                    } else {
                        let buf = std::fs::read(path.clone())?;
                        let response = client.media().upload(&content_type, buf).await?;
                        FileMessageEventContent::plain(body, response.content_uri)
                    };
                    let buf = std::fs::read(path)?;
                    let size = buf.len() as u64;
                    file_size = Some(size);
                    let info = assign!(FileInfo::new(), {
                        mimetype: Some(mimetype),
                        size: UInt::new(size),
                    });
                    content.info = Some(Box::new(info));
                    content
                };

                let content = RoomMessageEventContent::new(MessageType::File(file_content));
                let response = room.send(content, None).await?;

                Ok(response.event_id)
            })
            .await?
    }

    pub async fn file_binary(&self, event_id: String) -> Result<FfiBuffer<u8>> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't read message as file from a room we are not in")
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

    pub async fn edit_file_message(
        &self,
        event_id: String,
        uri: String,
        name: String,
        mimetype: String,
        size: Option<u32>,
    ) -> Result<OwnedEventId> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't edit message as file to a room we are not in")
        };
        let event_id = EventId::parse(event_id)?;
        let client = self.room.client();

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

                let path = PathBuf::from(uri);
                let mut file_buf = std::fs::read(path)?;

                let timeline_event = room.event(&event_id).await?;
                let event_content = timeline_event
                    .event
                    .deserialize_as::<RoomMessageEvent>()
                    .context("Couldn't deserialise event")?;

                let mut sent_by_me = false;
                if let Some(user_id) = client.user_id() {
                    if user_id == event_content.sender() {
                        sent_by_me = true;
                    }
                }
                if !sent_by_me {
                    bail!("Can't edit an event not sent by own user");
                }

                let content_type: mime_guess::Mime = mimetype.parse()?;
                let response = client.media().upload(&content_type, file_buf).await?;

                let info = assign!(FileInfo::new(), {
                    mimetype: Some(mimetype),
                    size: size.map(UInt::from),
                });
                let mut file_content = FileMessageEventContent::plain(name, response.content_uri);
                file_content.info = Some(Box::new(info));
                let mut edited_content =
                    RoomMessageEventContent::new(MessageType::File(file_content.clone()));
                let replacement =
                    Replacement::new(event_id.to_owned(), MessageType::File(file_content));
                edited_content.relates_to = Some(Relation::Replacement(replacement));

                let txn_id = TransactionId::new();
                let response = room.send(edited_content, Some(&txn_id)).await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn send_location_message(
        &self,
        body: String,
        geo_uri: String,
    ) -> Result<OwnedEventId> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't send message as location to a room we are not in")
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
                let location_content = LocationMessageEventContent::new(body, geo_uri);
                let content = RoomMessageEventContent::new(MessageType::Location(location_content));
                let txn_id = TransactionId::new();
                let response = room.send(content, Some(&txn_id)).await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn edit_location_message(
        &self,
        event_id: String,
        body: String,
        geo_uri: String,
    ) -> Result<OwnedEventId> {
        let room = if let SdkRoom::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't edit message as location to a room we are not in")
        };
        let event_id = EventId::parse(event_id)?;
        let client = self.room.client();

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

                let timeline_event = room.event(&event_id).await?;
                let event_content = timeline_event
                    .event
                    .deserialize_as::<RoomMessageEvent>()
                    .context("Couldn't deserialise event")?;

                let mut sent_by_me = false;
                if let Some(user_id) = client.user_id() {
                    if user_id == event_content.sender() {
                        sent_by_me = true;
                    }
                }
                if !sent_by_me {
                    bail!("Can't edit an event not sent by own user");
                }

                let location_content = LocationMessageEventContent::new(body, geo_uri);
                let mut edited_content =
                    RoomMessageEventContent::new(MessageType::Location(location_content.clone()));
                let replacement =
                    Replacement::new(event_id.to_owned(), MessageType::Location(location_content));
                edited_content.relates_to = Some(Relation::Replacement(replacement));

                let txn_id = TransactionId::new();
                let response = room.send(edited_content, Some(&txn_id)).await?;
                Ok(response.event_id)
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

    pub fn is_joined(&self) -> bool {
        matches!(self.room, SdkRoom::Joined(_))
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
        let is_acter_space = self.is_acter_space().await?;
        let acter_app_settings = if is_acter_space {
            Some(self.app_settings_content().await?)
        } else {
            None
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
                        members.push(Member {
                            member,
                            acter_app_settings: acter_app_settings.clone(),
                        });
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
                let mut file =
                    std::fs::File::create(path.clone()).context("File should be created")?;
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

    pub fn join_rule_str(&self) -> String {
        match self.room.join_rule() {
            JoinRule::Invite => "invite".to_owned(),
            JoinRule::Knock => "knock".to_owned(),
            JoinRule::KnockRestricted(_) => "knock_restricted".to_owned(),
            JoinRule::Restricted(_) => "restricted".to_owned(),
            JoinRule::Private => "private".to_owned(),
            JoinRule::Public => "public".to_owned(),
            _ => "unknown".to_owned(),
        }
    }

    pub fn restricted_room_ids_str(&self) -> Vec<String> {
        match self.room.join_rule() {
            JoinRule::KnockRestricted(res) | JoinRule::Restricted(res) => res
                .allow
                .into_iter()
                .filter_map(|a| match a {
                    AllowRule::RoomMembership(o) => Some(o.room_id.to_string()),
                    _ => None,
                })
                .collect(),
            _ => vec![],
        }
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
                        let msg =
                            RoomMessage::policy_rule_room_from_event(e, r.room_id().to_owned());
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::PolicyRuleServer(
                        StateEvent::Original(e),
                    ))) => {
                        let msg =
                            RoomMessage::policy_rule_server_from_event(e, r.room_id().to_owned());
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::PolicyRuleUser(
                        StateEvent::Original(e),
                    ))) => {
                        let msg =
                            RoomMessage::policy_rule_user_from_event(e, r.room_id().to_owned());
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomAliases(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::room_aliases_from_event(e, r.room_id().to_owned());
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomAvatar(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::room_avatar_from_event(e, r.room_id().to_owned());
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomCanonicalAlias(
                        StateEvent::Original(e),
                    ))) => {
                        let msg =
                            RoomMessage::room_canonical_alias_from_event(e, r.room_id().to_owned());
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomCreate(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::room_create_from_event(e, r.room_id().to_owned());
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomEncryption(
                        StateEvent::Original(e),
                    ))) => {
                        let msg =
                            RoomMessage::room_encryption_from_event(e, r.room_id().to_owned());
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomGuestAccess(
                        StateEvent::Original(e),
                    ))) => {
                        let msg =
                            RoomMessage::room_guest_access_from_event(e, r.room_id().to_owned());
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomHistoryVisibility(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::room_history_visibility_from_event(
                            e,
                            r.room_id().to_owned(),
                        );
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomJoinRules(
                        StateEvent::Original(e),
                    ))) => {
                        let msg =
                            RoomMessage::room_join_rules_from_event(e, r.room_id().to_owned());
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomMember(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::room_member_from_event(e, r.room_id().to_owned());
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomName(StateEvent::Original(
                        e,
                    )))) => {
                        let msg = RoomMessage::room_name_from_event(e, r.room_id().to_owned());
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomPinnedEvents(
                        StateEvent::Original(e),
                    ))) => {
                        let msg =
                            RoomMessage::room_pinned_events_from_event(e, r.room_id().to_owned());
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomPowerLevels(
                        StateEvent::Original(e),
                    ))) => {
                        let msg =
                            RoomMessage::room_power_levels_from_event(e, r.room_id().to_owned());
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomServerAcl(
                        StateEvent::Original(e),
                    ))) => {
                        let msg =
                            RoomMessage::room_server_acl_from_event(e, r.room_id().to_owned());
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomThirdPartyInvite(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::room_third_party_invite_from_event(
                            e,
                            r.room_id().to_owned(),
                        );
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomTombstone(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::room_tombstone_from_event(e, r.room_id().to_owned());
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::RoomTopic(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::room_topic_from_event(e, r.room_id().to_owned());
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::SpaceChild(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::space_child_from_event(e, r.room_id().to_owned());
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(AnyStateEvent::SpaceParent(
                        StateEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::space_parent_from_event(e, r.room_id().to_owned());
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::State(_)) => {
                        bail!("Invalid AnyTimelineEvent::State: other");
                    }
                    Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::CallAnswer(
                        MessageLikeEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::call_answer_from_event(e, r.room_id().to_owned());
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::CallCandidates(
                        MessageLikeEvent::Original(e),
                    ))) => {
                        let msg =
                            RoomMessage::call_candidates_from_event(e, r.room_id().to_owned());
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::CallHangup(
                        MessageLikeEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::call_hangup_from_event(e, r.room_id().to_owned());
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::CallInvite(
                        MessageLikeEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::call_invite_from_event(e, r.room_id().to_owned());
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::Reaction(
                        MessageLikeEvent::Original(e),
                    ))) => {
                        let msg = RoomMessage::reaction_from_event(e, r.room_id().to_owned());
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomEncrypted(
                        MessageLikeEvent::Original(e),
                    ))) => {
                        info!("RoomEncrypted: {:?}", e.content);
                        let msg = RoomMessage::room_encrypted_from_event(e, r.room_id().to_owned());
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(
                        MessageLikeEvent::Original(m),
                    ))) => {
                        let msg = RoomMessage::room_message_from_event(m, r, false);
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomRedaction(e))) => {
                        let msg = RoomMessage::room_redaction_from_event(e, r.room_id().to_owned());
                        Ok(msg)
                    }
                    Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::Sticker(
                        MessageLikeEvent::Original(s),
                    ))) => {
                        let msg = RoomMessage::sticker_from_event(s, r.room_id().to_owned());
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
        url_or_path: String,
        body: String,
        blurhash: Option<String>,
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

                let url = Box::<MxcUri>::from(url_or_path.as_str()); // http not allowed for remote url
                let image_content = if url.is_valid() {
                    ImageMessageEventContent::plain(body, url.into())
                } else {
                    let path = PathBuf::from(url_or_path);
                    let guess = mime_guess::from_path(path.clone());
                    let content_type = guess.first().context("No MIME type")?;
                    let mimetype = content_type.to_string();
                    if !mimetype.starts_with("image/") {
                        bail!("Image reply accepts only image file");
                    }
                    let mut content = if room.is_encrypted().await? {
                        let mut reader = std::fs::File::open(path.clone())?;
                        let encrypted_file = client
                            .prepare_encrypted_file(&content_type, &mut reader)
                            .await?;
                        ImageMessageEventContent::encrypted(body, encrypted_file)
                    } else {
                        let buf = std::fs::read(path.clone())?;
                        let response = client.media().upload(&content_type, buf).await?;
                        ImageMessageEventContent::plain(body, response.content_uri)
                    };
                    let buf = std::fs::read(path.clone())?;
                    let mut info = assign!(ImageInfo::new(), {
                        mimetype: Some(mimetype),
                        size: UInt::new(buf.len() as u64),
                        blurhash,
                    });
                    #[cfg(feature = "image-meta")]
                    if let Ok(size) = imagesize::size(path.to_string_lossy().to_string()) {
                        info.width = UInt::new(size.width as u64);
                        info.height = UInt::new(size.height as u64);
                    }
                    content.info = Some(Box::new(info));
                    content
                };

                let timeline_event = room.event(&event_id).await?;
                let event_content = timeline_event.event.deserialize_as::<RoomMessageEvent>()?;
                let original_message = event_content
                    .as_original()
                    .context("Couldn't retrieve original message.")?;
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
        url_or_path: String,
        body: String,
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

                let url = Box::<MxcUri>::from(url_or_path.as_str()); // http not allowed for remote url
                let audio_content = if url.is_valid() {
                    AudioMessageEventContent::plain(body, url.into())
                } else {
                    let path = PathBuf::from(url_or_path);
                    let guess = mime_guess::from_path(path.clone());
                    let content_type = guess.first().context("No MIME type")?;
                    let mimetype = content_type.to_string();
                    if !mimetype.starts_with("audio/") {
                        bail!("Audio reply accepts only audio file");
                    }
                    let mut content = if room.is_encrypted().await? {
                        let mut reader = std::fs::File::open(path.clone())?;
                        let encrypted_file = client
                            .prepare_encrypted_file(&content_type, &mut reader)
                            .await?;
                        AudioMessageEventContent::encrypted(body, encrypted_file)
                    } else {
                        let buf = std::fs::read(path.clone())?;
                        let response = client.media().upload(&content_type, buf).await?;
                        AudioMessageEventContent::plain(body, response.content_uri)
                    };
                    let buf = std::fs::read(path.clone())?;
                    let mut info = assign!(AudioInfo::new(), {
                        mimetype: Some(mimetype),
                        duration: None,
                        size: UInt::new(buf.len() as u64),
                    });
                    #[cfg(feature = "audio-meta")]
                    if let Ok(probe) = Probe::open(path) {
                        if let Ok(tagged_file) = probe.read() {
                            info.duration = Some(tagged_file.properties().duration());
                        }
                    }
                    content.info = Some(Box::new(info));
                    content
                };

                let timeline_event = room.event(&event_id).await?;
                let event_content = timeline_event.event.deserialize_as::<RoomMessageEvent>()?;
                let original_message = event_content
                    .as_original()
                    .context("Couldn't retrieve original message.")?;
                let content = RoomMessageEventContent::new(MessageType::Audio(audio_content))
                    .make_reply_to(original_message, ForwardThread::Yes);

                let response = room
                    .send(content, txn_id.as_deref().map(Into::into))
                    .await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn send_video_reply(
        &self,
        url_or_path: String,
        body: String,
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

                let url = Box::<MxcUri>::from(url_or_path.as_str()); // http not allowed for remote url
                let video_content = if url.is_valid() {
                    VideoMessageEventContent::plain(body, url.into())
                } else {
                    let path = PathBuf::from(url_or_path.clone());
                    let guess = mime_guess::from_path(path.clone());
                    let content_type = guess.first().context("No MIME type")?;
                    let mimetype = content_type.to_string();
                    if !mimetype.starts_with("video/") {
                        bail!("Video reply accepts only video file");
                    }
                    let mut content = if room.is_encrypted().await? {
                        let mut reader = std::fs::File::open(path.clone())?;
                        let encrypted_file = client
                            .prepare_encrypted_file(&content_type, &mut reader)
                            .await?;
                        VideoMessageEventContent::encrypted(body, encrypted_file)
                    } else {
                        let buf = std::fs::read(path.clone())?;
                        let response = client.media().upload(&content_type, buf).await?;
                        VideoMessageEventContent::plain(body, response.content_uri)
                    };
                    let buf = std::fs::read(path)?;
                    let mut info = assign!(VideoInfo::new(), {
                        mimetype: Some(mimetype),
                        size: UInt::new(buf.len() as u64),
                        blurhash,
                    });
                    #[cfg(feature = "video-meta")]
                    if let Ok(Some(metadata)) = parse_video(url_or_path).await {
                        info.duration = Some(Duration::from_secs(metadata.duration));
                        info.width = UInt::new(metadata.width as u64);
                        info.height = UInt::new(metadata.height as u64);
                    }
                    content.info = Some(Box::new(info));
                    content
                };

                let timeline_event = room.event(&event_id).await?;
                let event_content = timeline_event.event.deserialize_as::<RoomMessageEvent>()?;
                let original_message = event_content
                    .as_original()
                    .context("Couldn't retrieve original message.")?;
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
        url_or_path: String,
        body: String,
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

                let url = Box::<MxcUri>::from(url_or_path.as_str()); // http not allowed for remote url
                let file_content = if url.is_valid() {
                    FileMessageEventContent::plain(body, url.into())
                } else {
                    let path = PathBuf::from(url_or_path);
                    let guess = mime_guess::from_path(path.clone());
                    let content_type = guess
                        .first()
                        .unwrap_or(mime_guess::mime::APPLICATION_OCTET_STREAM);
                    let mimetype = content_type.to_string();
                    let mut content = if room.is_encrypted().await? {
                        let mut reader = std::fs::File::open(path.clone())?;
                        let encrypted_file = client
                            .prepare_encrypted_file(&content_type, &mut reader)
                            .await?;
                        FileMessageEventContent::encrypted(body, encrypted_file)
                    } else {
                        let buf = std::fs::read(path.clone())?;
                        let response = client.media().upload(&content_type, buf).await?;
                        FileMessageEventContent::plain(body, response.content_uri)
                    };
                    let buf = std::fs::read(path)?;
                    let info = assign!(FileInfo::new(), {
                        mimetype: Some(mimetype),
                        size: UInt::new(buf.len() as u64),
                    });
                    content.info = Some(Box::new(info));
                    content
                };

                let timeline_event = room.event(&event_id).await?;
                let event_content = timeline_event.event.deserialize_as::<RoomMessageEvent>()?;
                let original_message = event_content
                    .as_original()
                    .context("Couldn't retrieve original message.")?;
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

pub struct SendImageResult {
    event_id: OwnedEventId,
    file_size: Option<u64>, // unknown for remote url
    width: Option<u32>,     // unknown for remote url
    height: Option<u32>,    // unknown for remote url
}

impl SendImageResult {
    pub fn event_id(&self) -> OwnedEventId {
        self.event_id.clone()
    }

    pub fn file_size(&self) -> Option<u64> {
        self.file_size
    }

    pub fn width(&self) -> Option<u32> {
        self.width
    }

    pub fn height(&self) -> Option<u32> {
        self.height
    }
}

pub struct SendAudioResult {
    event_id: OwnedEventId,
    file_size: Option<u64>,     // unknown for remote url
    duration: Option<Duration>, // unknown for remote url
}

impl SendAudioResult {
    pub fn event_id(&self) -> OwnedEventId {
        self.event_id.clone()
    }

    pub fn file_size(&self) -> Option<u64> {
        self.file_size
    }

    pub fn duration(&self) -> Option<Duration> {
        self.duration
    }
}

pub struct SendVideoResult {
    event_id: OwnedEventId,
    file_size: Option<u64>,     // unknown for remote url
    duration: Option<Duration>, // unknown for remote url
    width: Option<u32>,         // unknown for remote url
    height: Option<u32>,        // unknown for remote url
}

impl SendVideoResult {
    pub fn event_id(&self) -> OwnedEventId {
        self.event_id.clone()
    }

    pub fn file_size(&self) -> Option<u64> {
        self.file_size
    }

    pub fn duration(&self) -> Option<Duration> {
        self.duration
    }

    pub fn width(&self) -> Option<u32> {
        self.width
    }

    pub fn height(&self) -> Option<u32> {
        self.height
    }
}
