pub use acter_core::spaces::{
    CreateSpaceSettings, CreateSpaceSettingsBuilder, RelationTargetType, SpaceRelation,
    SpaceRelations as CoreSpaceRelations,
};
use acter_core::{
    client::CoreClient,
    error::Error,
    events::{
        calendar::CalendarEventEventContent,
        news::NewsEntryEventContent,
        pins::PinEventContent,
        settings::ActerAppSettingsContent,
        tasks::{TaskEventContent, TaskListEventContent},
    },
    spaces::is_acter_space,
    statics::PURPOSE_FIELD_DEV,
};
use anyhow::{bail, Context, Result};
use core::time::Duration;
use matrix_sdk::{
    deserialized_responses::SyncOrStrippedState,
    media::{MediaFormat, MediaRequest},
    notification_settings::{IsEncrypted, IsOneToOne, RoomNotificationMode},
    room::{Room as SdkRoom, RoomMember},
    ruma::{
        api::client::{
            receipt::create_receipt,
            room::report_content,
            space::{get_hierarchy, SpaceHierarchyRoomsChunk},
        },
        assign, Int, UInt,
    },
    RoomMemberships, RoomState,
};
use ruma_common::{
    room::RoomType, serde::Raw, space::SpaceRoomJoinRule, EventId, OwnedEventId, OwnedMxcUri,
    OwnedRoomAliasId, OwnedRoomId, OwnedUserId, TransactionId, UserId,
};
use ruma_events::{
    receipt::ReceiptThread,
    room::{
        avatar::ImageInfo as AvatarImageInfo,
        join_rules::{AllowRule, JoinRule},
        message::{
            AddMentions, AudioInfo, AudioMessageEventContent, FileInfo, FileMessageEventContent,
            ForwardThread, ImageMessageEventContent, MessageType, RoomMessageEvent,
            RoomMessageEventContent, TextMessageEventContent, VideoInfo, VideoMessageEventContent,
        },
        ImageInfo, MediaSource,
    },
    space::{child::HierarchySpaceChildEvent, parent::SpaceParentEventContent},
    AnyMessageLikeEvent, AnyStateEvent, AnyTimelineEvent, MessageLikeEvent, MessageLikeEventType,
    StateEvent, StateEventType, StaticEventContent,
};
use std::{io::Write, ops::Deref, path::PathBuf};
use tracing::{error, info, warn};

use crate::OptionBuffer;

use super::{
    api::FfiBuffer,
    message::RoomMessage,
    profile::{RoomProfile, UserProfile},
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
    CanPostTaskList,
    CanPostTask,
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
            MemberPermission::CanPostTaskList => {
                if self
                    .acter_app_settings
                    .as_ref()
                    .map(|s| s.tasks().active())
                    .unwrap_or_default()
                {
                    PermissionTest::Message(MessageLikeEventType::from(
                        <TaskListEventContent as StaticEventContent>::TYPE,
                    ))
                } else {
                    // Not an acter space or Pins are not activated..
                    return false;
                }
            }
            MemberPermission::CanPostTask => {
                if self
                    .acter_app_settings
                    .as_ref()
                    .map(|s| s.tasks().active())
                    .unwrap_or_default()
                {
                    PermissionTest::Message(MessageLikeEventType::from(
                        <TaskEventContent as StaticEventContent>::TYPE,
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

    pub async fn ignore(&self) -> Result<bool> {
        let member = self.member.clone();
        RUNTIME
            .spawn(async move {
                member.ignore().await?;
                Ok(true)
            })
            .await?
    }

    pub async fn unignore(&self) -> Result<bool> {
        let member = self.member.clone();
        RUNTIME
            .spawn(async move {
                member.unignore().await?;
                Ok(true)
            })
            .await?
    }
}

pub struct SpaceHierarchyRoomInfo {
    chunk: SpaceHierarchyRoomsChunk,
    client: CoreClient,
}

impl SpaceHierarchyRoomInfo {
    pub fn canonical_alias(&self) -> Option<OwnedRoomAliasId> {
        self.chunk.canonical_alias.clone()
    }

    /// The name of the room, if any.
    pub fn name(&self) -> Option<String> {
        self.chunk.name.clone()
    }

    /// The number of members joined to the room.
    pub fn num_joined_members(&self) -> u64 {
        self.chunk.num_joined_members.into()
    }

    /// The ID of the room.
    pub fn room_id(&self) -> OwnedRoomId {
        self.chunk.room_id.clone()
    }

    pub fn room_id_str(&self) -> String {
        self.room_id().to_string()
    }

    pub fn topic(&self) -> Option<String> {
        self.chunk.topic.clone()
    }

    /// Whether the room may be viewed by guest users without joining.
    pub fn world_readable(&self) -> bool {
        self.chunk.world_readable
    }

    pub fn guest_can_join(&self) -> bool {
        self.chunk.guest_can_join
    }

    pub fn avatar_url(&self) -> Option<OwnedMxcUri> {
        self.chunk.avatar_url.clone()
    }

    pub fn avatar_url_str(&self) -> Option<String> {
        self.avatar_url().map(|a| a.to_string())
    }

    /// The join rule of the room.
    pub fn join_rule(&self) -> SpaceRoomJoinRule {
        self.chunk.join_rule.clone()
    }

    pub fn join_rule_str(&self) -> String {
        self.join_rule().to_string()
    }

    /// The type of room from `m.room.create`, if any.
    pub fn room_type(&self) -> Option<RoomType> {
        self.chunk.room_type.clone()
    }

    pub fn is_space(&self) -> bool {
        matches!(self.chunk.room_type, Some(RoomType::Space))
    }

    /// The stripped `m.space.child` events of the space-room.
    ///
    /// If the room is not a space-room, this should be empty.
    pub fn children_state(&self) -> Vec<Raw<HierarchySpaceChildEvent>> {
        self.chunk.children_state.clone()
    }

    pub fn has_avatar(&self) -> bool {
        self.chunk.avatar_url.is_some()
    }

    pub fn via_server_name(&self) -> Option<String> {
        for v in &self.chunk.children_state {
            let Ok(h) = v.deserialize() else { continue };
            if let Some(v) = h.content.via.into_iter().next() {
                return Some(v.to_string());
            }
        }
        None
    }

    pub async fn get_avatar(&self) -> Result<OptionBuffer> {
        let client = self.client.client().clone();
        if let Some(url) = self.chunk.avatar_url.clone() {
            return RUNTIME
                .spawn(async move {
                    let request = MediaRequest {
                        source: MediaSource::Plain(url),
                        format: MediaFormat::File,
                    };
                    let buf = client.media().get_media_content(&request, true).await?;
                    Ok(OptionBuffer::new(Some(buf)))
                })
                .await?;
        }
        Ok(OptionBuffer::new(None))
    }
}

impl SpaceHierarchyRoomInfo {
    pub(crate) async fn new(chunk: SpaceHierarchyRoomsChunk, client: CoreClient) -> Self {
        SpaceHierarchyRoomInfo { chunk, client }
    }
}

pub struct SpaceHierarchyListResult {
    resp: get_hierarchy::v1::Response,
    client: CoreClient,
}

impl SpaceHierarchyListResult {
    pub fn next_batch(&self) -> Option<String> {
        self.resp.next_batch.clone()
    }

    pub async fn rooms(&self) -> Result<Vec<SpaceHierarchyRoomInfo>> {
        let client = self.client.clone();
        let chunks = self.resp.rooms.clone();
        RUNTIME
            .spawn(async move {
                let iter = chunks
                    .into_iter()
                    .map(|chunk| SpaceHierarchyRoomInfo::new(chunk, client.clone()));
                Ok(futures::future::join_all(iter).await)
            })
            .await?
    }
}

pub struct SpaceRelations {
    pub(crate) core: CoreSpaceRelations,
    pub(crate) room: Room,
}

impl Deref for SpaceRelations {
    type Target = CoreSpaceRelations;
    fn deref(&self) -> &Self::Target {
        &self.core
    }
}

impl SpaceRelations {
    pub fn room_id(&self) -> OwnedRoomId {
        self.room.room_id().to_owned()
    }

    pub fn room_id_str(&self) -> String {
        self.room.room_id().to_string()
    }

    pub async fn query_hierarchy(&self, from: Option<String>) -> Result<SpaceHierarchyListResult> {
        let c = self.room.core.clone();
        let room_id = self.room.room_id().to_owned();
        RUNTIME
            .spawn(async move {
                let request = assign!(get_hierarchy::v1::Request::new(room_id), { from, max_depth: Some(1u32.into()) });
                let resp = c.client().send(request, None).await?;
                Ok(SpaceHierarchyListResult { resp, client: c.clone() })
            })
            .await?
    }
}

fn room_notification_mode_name(input: &RoomNotificationMode) -> String {
    match input {
        RoomNotificationMode::AllMessages => "all".to_owned(),
        RoomNotificationMode::MentionsAndKeywordsOnly => "mentions".to_owned(),
        RoomNotificationMode::Mute => "muted".to_owned(),
    }
}

fn notification_mode_from_input(input: &str) -> Option<RoomNotificationMode> {
    match input.trim().to_lowercase().as_str() {
        "all" => Some(RoomNotificationMode::AllMessages),
        "mentions" => Some(RoomNotificationMode::MentionsAndKeywordsOnly),
        "muted" => Some(RoomNotificationMode::Mute),
        _ => None,
    }
}

#[derive(Clone, Debug)]
pub struct Room {
    pub(crate) core: CoreClient,
    pub(crate) room: SdkRoom,
}

impl Room {
    pub fn new(core: CoreClient, room: SdkRoom) -> Self {
        Room { core, room }
    }

    pub async fn is_acter_space(&self) -> Result<bool> {
        let inner = self.room.clone();
        let result = RUNTIME
            .spawn(async move { is_acter_space(&inner).await })
            .await?;
        Ok(result)
    }

    pub async fn space_relations(&self) -> Result<SpaceRelations> {
        let c = self.core.clone();
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let core = c.space_relations(&me.room).await?;
                Ok(SpaceRelations { core, room: me })
            })
            .await?
    }

    pub async fn add_parent_room(&self, room_id: String, canonical: bool) -> Result<String> {
        if !self.is_joined() {
            bail!("You can't update a room you aren't part of");
        }
        let room_id = OwnedRoomId::try_from(room_id)?;
        if !self
            .get_my_membership()
            .await?
            .can(crate::MemberPermission::CanLinkSpaces)
        {
            bail!("You don't have permissions to add parent to room");
        }
        let room = self.room.clone();
        let client = self.core.client().clone();

        RUNTIME
            .spawn(async move {
                let Some(Ok(homeserver)) = client.homeserver().host_str().map(|h| h.try_into()) else {
                    return Err(Error::HomeserverMissesHostname)?;
                };
                let content = assign!(SpaceParentEventContent::new(vec![homeserver]), { canonical });
                let response = room
                    .send_state_event_for_key(
                        &room_id,
                        content,
                    )
                    .await?;
                Ok(response.event_id.to_string())
            })
            .await?
    }

    pub async fn remove_parent_room(
        &self,
        room_id: String,
        reason: Option<String>,
    ) -> Result<bool> {
        if !self.is_joined() {
            bail!("You can't update a room you aren't part of");
        }
        let room_id = OwnedRoomId::try_from(room_id)?;
        if !self
            .get_my_membership()
            .await?
            .can(crate::MemberPermission::CanLinkSpaces)
        {
            bail!("You don't have permissions to remove parent from room");
        }
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let response = room
                    .get_state_event_static_for_key::<SpaceParentEventContent, OwnedRoomId>(
                        &room_id,
                    )
                    .await?;
                let Some(raw_state) = response else {
                    warn!("Room {} is not a parent", room_id);
                    return Ok(true);
                };
                let Ok(state) = raw_state.deserialize() else {
                    bail!("Invalid room parent event")
                };
                let event_id = match state {
                    SyncOrStrippedState::Stripped(ev) => {
                        bail!("Couldn't get event id about stripped event")
                    }
                    SyncOrStrippedState::Sync(ev) => ev.event_id().to_owned(),
                };
                room.redact(&event_id, reason.as_deref(), None).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn get_my_membership(&self) -> Result<Member> {
        if !self.is_joined() {
            bail!("Not a room we have joined");
        }
        let room = self.room.clone();

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
        if !self.is_joined() {
            bail!("Can't upload avatar to a room we are not in");
        }
        let room = self.room.clone();

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
        if !self.is_joined() {
            bail!("Can't remove avatar to a room we are not in");
        }
        let room = self.room.clone();

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
        if !self.is_joined() {
            bail!("Can't set topic to a room we are not in");
        }
        let room = self.room.clone();

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

    pub async fn set_name(&self, name: String) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Can't set name to a room we are not in");
        }
        let room = self.room.clone();

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

    pub async fn notification_mode(&self) -> Result<String> {
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                room.user_defined_notification_mode()
                    .await
                    .map(|x| room_notification_mode_name(&x))
            })
            .await?
            .context("Mode not set")
    }

    pub async fn default_notification_mode(&self) -> String {
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                let notification_settings = room.client().notification_settings().await;
                let is_encrypted = room.is_encrypted().await.unwrap_or_default();
                // Otherwise, if encrypted status is available, get the default mode for this
                // type of room.
                // From the point of view of notification settings, a `one-to-one` room is one
                // that involves exactly two people.
                let is_one_to_one = IsOneToOne::from(room.active_members_count() == 2);
                let default_mode = notification_settings
                    .get_default_room_notification_mode(
                        IsEncrypted::from(is_encrypted),
                        is_one_to_one,
                    )
                    .await;
                room_notification_mode_name(&default_mode)
            })
            .await
            .unwrap_or_default()
    }

    pub async fn unmute(&self) -> Result<bool> {
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                let notification_settings = room.client().notification_settings().await;
                let is_encrypted = room.is_encrypted().await.unwrap_or_default();
                // Otherwise, if encrypted status is available, get the default mode for this
                // type of room.
                // From the point of view of notification settings, a `one-to-one` room is one
                // that involves exactly two people.
                let is_one_to_one = IsOneToOne::from(room.active_members_count() == 2);
                notification_settings
                    .unmute_room(
                        room.room_id(),
                        IsEncrypted::from(is_encrypted),
                        is_one_to_one,
                    )
                    .await?;
                Ok(true)
            })
            .await?
    }

    pub async fn set_notification_mode(&self, new_mode: Option<String>) -> Result<bool> {
        let room = self.room.clone();
        let mode = new_mode.and_then(|s| notification_mode_from_input(&s));
        RUNTIME
            .spawn(async move {
                let notification_settings = room.client().notification_settings().await;
                let room_id = room.room_id();
                if let Some(mode) = mode {
                    notification_settings
                        .set_room_notification_mode(room_id, mode)
                        .await?;
                } else {
                    notification_settings
                        .delete_user_defined_room_rules(room_id)
                        .await?;
                }
                Ok(true)
            })
            .await?
    }

    pub async fn typing_notice(&self, typing: bool) -> Result<bool> {
        if !self.is_joined() {
            bail!("Can't send typing notice to a room we are not in");
        }
        let room = self.room.clone();

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
        if !self.is_joined() {
            bail!("Can't send read_receipt to a room we are not in");
        }
        let room = self.room.clone();

        let event_id = EventId::parse(event_id)?;

        RUNTIME
            .spawn(async move {
                room.send_single_receipt(
                    create_receipt::v3::ReceiptType::Read,
                    ReceiptThread::Unthreaded,
                    event_id,
                )
                .await?;
                Ok(true)
            })
            .await?
    }

    pub async fn image_binary(&self, event_id: String) -> Result<FfiBuffer<u8>> {
        if !self.is_joined() {
            bail!("Can't read message as image from a room we are not in");
        }
        let room = self.room.clone();
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

    pub async fn audio_binary(&self, event_id: String) -> Result<FfiBuffer<u8>> {
        if !self.is_joined() {
            bail!("Can't read message as audio from a room we are not in");
        }
        let room = self.room.clone();
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

    pub async fn video_binary(&self, event_id: String) -> Result<FfiBuffer<u8>> {
        if !self.is_joined() {
            bail!("Can't read message as video from a room we are not in");
        }
        let room = self.room.clone();
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

    pub async fn file_binary(&self, event_id: String) -> Result<FfiBuffer<u8>> {
        if !self.is_joined() {
            bail!("Can't read message as file from a room we are not in");
        }
        let room = self.room.clone();
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

    fn is_invited(&self) -> bool {
        matches!(self.room.state(), RoomState::Invited)
    }

    pub fn is_joined(&self) -> bool {
        matches!(self.room.state(), RoomState::Joined)
    }

    fn is_left(&self) -> bool {
        matches!(self.room.state(), RoomState::Left)
    }

    pub fn room_id_str(&self) -> String {
        self.room.room_id().to_string()
    }

    pub async fn invite_user(&self, user_id: String) -> Result<bool> {
        if !self.is_joined() {
            bail!("Can't send message to a room we are not in");
        }
        let room = self.room.clone();

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
        if !self.is_left() {
            bail!("Can't join a room we are not left");
        }
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                room.join().await?;
                Ok(true)
            })
            .await?
    }

    pub async fn leave(&self) -> Result<bool> {
        if !self.is_joined() {
            bail!("Can't leave a room we are not joined");
        }
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                room.leave().await?;
                Ok(true)
            })
            .await?
    }

    pub async fn get_invitees(&self) -> Result<Vec<Member>> {
        let my_client = self.room.client();
        if !self.is_invited() {
            bail!("Can't get a room we are not invited");
        }
        let room = self.room.clone();
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
                let mut members = vec![];
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
        if !self.is_joined() {
            bail!("Can't read message from a room we are not in");
        }
        let room = self.room.clone();
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
        if !self.is_joined() {
            bail!("Can't read message from a room we are not in");
        }
        let room = self.room.clone();
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
        if !self.is_joined() {
            bail!("Can't know if a room we are not in is encrypted");
        }
        let room = self.room.clone();

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
        if !self.is_joined() {
            bail!("Can't read message from a room we are not in");
        }
        let room = self.room.clone();
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
        if !self.is_joined() {
            bail!("Can't send reply as text to a room we are not in");
        }
        let room = self.room.clone();

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
                    .make_reply_to(original_message, ForwardThread::Yes, AddMentions::No);

                let response = room
                    .send(content, txn_id.as_deref().map(Into::into))
                    .await?;
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
        size: Option<u64>,
        width: Option<u64>,
        height: Option<u64>,
        event_id: String,
        txn_id: Option<String>,
    ) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Can't send reply as image to a room we are not in");
        }
        let room = self.room.clone();
        let client = room.client();
        let my_id = client.user_id().context("User not found")?.to_owned();

        let path = PathBuf::from(uri);
        let event_id = EventId::parse(event_id)?;
        let content_type = mimetype.parse::<mime::Mime>()?;
        let info = assign!(ImageInfo::new(), {
            height: height.and_then(UInt::new),
            width: width.and_then(UInt::new),
            mimetype: Some(mimetype),
            size: size.and_then(UInt::new),
        });

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }

                let image_buf = std::fs::read(path).context("File should be read")?;

                let timeline_event = room.event(&event_id).await?;

                let event_content = timeline_event.event.deserialize_as::<RoomMessageEvent>()?;

                let original_message = event_content
                    .as_original()
                    .context("Couldn't retrieve original message.")?;

                let response = client.media().upload(&content_type, image_buf).await?;

                let mut image_content = ImageMessageEventContent::plain(name, response.content_uri);
                image_content.info = Some(Box::new(info));
                let content = RoomMessageEventContent::new(MessageType::Image(image_content))
                    .make_reply_to(original_message, ForwardThread::Yes, AddMentions::No);

                let response = room
                    .send(content, txn_id.as_deref().map(Into::into))
                    .await?;
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
        size: Option<u64>,
        secs: Option<u64>,
        event_id: String,
        txn_id: Option<String>,
    ) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Can't send reply as audio to a room we are not in");
        }
        let room = self.room.clone();
        let client = room.client();
        let my_id = client.user_id().context("User not found")?.to_owned();

        let path = PathBuf::from(uri);
        let event_id = EventId::parse(event_id)?;
        let content_type = mimetype.parse::<mime::Mime>()?;
        let info = assign!(AudioInfo::new(), {
            mimetype: Some(mimetype),
            duration: secs.map(Duration::from_secs),
            size: size.and_then(UInt::new),
        });

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }

                let image_buf = std::fs::read(path).context("File should be read")?;

                let timeline_event = room.event(&event_id).await?;

                let event_content = timeline_event.event.deserialize_as::<RoomMessageEvent>()?;

                let original_message = event_content
                    .as_original()
                    .context("Couldn't retrieve original message.")?;

                let response = client.media().upload(&content_type, image_buf).await?;

                let mut audio_content = AudioMessageEventContent::plain(name, response.content_uri);
                audio_content.info = Some(Box::new(info));
                let content = RoomMessageEventContent::new(MessageType::Audio(audio_content))
                    .make_reply_to(original_message, ForwardThread::Yes, AddMentions::No);

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
        mimetype: String,
        size: Option<u64>,
        secs: Option<u64>,
        width: Option<u64>,
        height: Option<u64>,
        blurhash: Option<String>,
        event_id: String,
        txn_id: Option<String>,
    ) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Can't send reply as video to a room we are not in");
        }
        let room = self.room.clone();
        let client = room.client();
        let my_id = client.user_id().context("User not found")?.to_owned();

        let path = PathBuf::from(uri);
        let event_id = EventId::parse(event_id)?;
        let content_type = mimetype.parse::<mime::Mime>()?;
        let info = assign!(VideoInfo::new(), {
            duration: secs.map(Duration::from_secs),
            height: height.and_then(UInt::new),
            width: width.and_then(UInt::new),
            mimetype: Some(mimetype),
            size: size.and_then(UInt::new),
            blurhash,
        });

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }

                let video_buf = std::fs::read(path).context("File should be read")?;

                let timeline_event = room.event(&event_id).await?;

                let event_content = timeline_event.event.deserialize_as::<RoomMessageEvent>()?;

                let original_message = event_content
                    .as_original()
                    .context("Couldn't retrieve original message.")?;

                let response = client.media().upload(&content_type, video_buf).await?;

                let mut video_content = VideoMessageEventContent::plain(name, response.content_uri);
                video_content.info = Some(Box::new(info));
                let content = RoomMessageEventContent::new(MessageType::Video(video_content))
                    .make_reply_to(original_message, ForwardThread::Yes, AddMentions::No);

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
        mimetype: String,
        size: Option<u64>,
        event_id: String,
        txn_id: Option<String>,
    ) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Can't send reply as file to a room we are not in");
        }
        let room = self.room.clone();
        let client = room.client();
        let my_id = client.user_id().context("User not found")?.to_owned();

        let path = PathBuf::from(uri);
        let event_id = EventId::parse(event_id)?;
        let content_type = mimetype.parse::<mime::Mime>()?;
        let info = assign!(FileInfo::new(), {
            mimetype: Some(mimetype),
            size: size.and_then(UInt::new),
        });

        RUNTIME
            .spawn(async move {
                let member = room
                    .get_member(&my_id)
                    .await?
                    .context("Couldn't find me among room members")?;
                if !member.can_send_message(MessageLikeEventType::RoomMessage) {
                    bail!("No permission to send message in this room");
                }

                let file_buf = std::fs::read(path).context("File should be read")?;

                let timeline_event = room.event(&event_id).await?;

                let event_content = timeline_event.event.deserialize_as::<RoomMessageEvent>()?;

                let original_message = event_content
                    .as_original()
                    .context("Couldn't retrieve original message.")?;

                let response = client.media().upload(&content_type, file_buf).await?;

                let mut file_content = FileMessageEventContent::plain(name, response.content_uri);
                file_content.info = Some(Box::new(info));
                let content = RoomMessageEventContent::new(MessageType::File(file_content))
                    .make_reply_to(original_message, ForwardThread::Yes, AddMentions::No);

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
        if !self.is_joined() {
            bail!("Can't redact any message from a room we are not in");
        }
        let room = self.room.clone();

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
        if !self.is_joined() {
            bail!("Can't update power level in a room we are not in");
        }
        let room = self.room.clone();

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

    pub async fn report_content(
        &self,
        event_id: String,
        score: Option<i32>,
        reason: Option<String>,
    ) -> Result<bool> {
        if !self.is_joined() {
            bail!("Can't block content in a room we are not in");
        }
        let room = self.room.clone();
        let event_id = EventId::parse(event_id)?;
        let int_score = score.map(|value| value.into());

        RUNTIME
            .spawn(async move {
                let request = report_content::v3::Request::new(
                    room.room_id().to_owned(),
                    event_id,
                    int_score,
                    reason,
                );
                room.client().send(request, None).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn redact_content(&self, event_id: String, reason: Option<String>) -> Result<bool> {
        if !self.is_joined() {
            bail!("Can't redact content in a room we are not in");
        }
        let event_id = EventId::parse(event_id)?;
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                room.redact(&event_id, reason.as_deref(), None).await?;
                Ok(true)
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
