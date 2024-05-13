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
use matrix_sdk::{
    deserialized_responses::SyncOrStrippedState,
    media::{MediaFormat, MediaRequest},
    notification_settings::{IsEncrypted, IsOneToOne},
    room::{Room as SdkRoom, RoomMember},
    RoomMemberships, RoomState,
};
use ruma::{assign, Int};
use ruma_client_api::{
    room::report_content,
    space::{get_hierarchy, SpaceHierarchyRoomsChunk},
};
use ruma_common::{
    room::RoomType, serde::Raw, space::SpaceRoomJoinRule, EventId, IdParseError, OwnedEventId,
    OwnedMxcUri, OwnedRoomAliasId, OwnedRoomId, OwnedTransactionId, OwnedUserId, RoomId,
    ServerName, UserId,
};
use ruma_events::{
    room::{
        avatar::ImageInfo as AvatarImageInfo,
        join_rules::{AllowRule, JoinRule, Restricted, RoomJoinRulesEventContent, RoomMembership},
        message::{MessageType, RoomMessageEvent},
        MediaSource,
    },
    space::{child::HierarchySpaceChildEvent, parent::SpaceParentEventContent},
    MessageLikeEventType, StateEvent, StateEventType, StaticEventContent,
};
use std::{io::Write, ops::Deref, path::PathBuf};
use tracing::{info, warn};

use crate::{
    OptionBuffer, OptionString, RoomMessage, RoomProfile, ThumbnailSize, UserProfile, RUNTIME,
};

use super::{
    api::FfiBuffer,
    push::{notification_mode_from_input, room_notification_mode_name},
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
    CanToggleReaction,
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
    CanRedactOwn,
    CanRedactOther,
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
    pub(crate) room: Room,
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

    pub fn room_id_str(&self) -> String {
        self.room.room_id().to_string()
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
            MemberPermission::CanRedactOwn => return self.member.can_redact_own(),
            MemberPermission::CanRedactOther => return self.member.can_redact_other(),
            MemberPermission::CanKick => return self.member.can_kick(),
            MemberPermission::CanTriggerRoomNotification => {
                return self.member.can_trigger_room_notification()
            }
            MemberPermission::CanSendChatMessages => MessageLikeEventType::RoomMessage.into(), // or should this check for encrypted?
            MemberPermission::CanToggleReaction => MessageLikeEventType::Reaction.into(),
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

    pub async fn kick(&self, msg: Option<String>) -> Result<bool> {
        let room = self.room.clone();
        let my_id = room.user_id()?;
        let member_id = self.member.user_id().to_owned();

        RUNTIME
            .spawn(async move {
                let permitted = room.can_user_kick(&my_id).await?;
                if !permitted {
                    bail!("No permissions to kick other in this room");
                }
                room.kick_user(&member_id, msg.as_deref()).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn ban(&self, msg: Option<String>) -> Result<bool> {
        let room = self.room.clone();
        let my_id = room.user_id()?;
        let member_id = self.member.user_id().to_owned();

        RUNTIME
            .spawn(async move {
                let permitted = room.can_user_ban(&my_id).await?;
                if !permitted {
                    bail!("No permissions to ban/unban other in this room");
                }
                room.ban_user(&member_id, msg.as_deref()).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn unban(&self, msg: Option<String>) -> Result<bool> {
        let room = self.room.clone();
        let my_id = room.user_id()?;
        let member_id = self.member.user_id().to_owned();

        RUNTIME
            .spawn(async move {
                let permitted = room.can_user_ban(&my_id).await?;
                if !permitted {
                    bail!("No permissions to ban/unban other in this room");
                }
                room.unban_user(&member_id, msg.as_deref()).await?;
                Ok(true)
            })
            .await?
    }
}

pub struct SpaceHierarchyRoomInfo {
    chunk: SpaceHierarchyRoomsChunk,
    core: CoreClient,
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

    pub async fn get_avatar(&self, thumb_size: Option<Box<ThumbnailSize>>) -> Result<OptionBuffer> {
        let client = self.core.client().clone();
        if let Some(url) = self.chunk.avatar_url.clone() {
            let format = ThumbnailSize::parse_into_media_format(thumb_size);
            return RUNTIME
                .spawn(async move {
                    let request = MediaRequest {
                        source: MediaSource::Plain(url),
                        format,
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
    pub(crate) async fn new(chunk: SpaceHierarchyRoomsChunk, core: CoreClient) -> Self {
        SpaceHierarchyRoomInfo { chunk, core }
    }
}

pub struct SpaceHierarchyListResult {
    resp: get_hierarchy::v1::Response,
    core: CoreClient,
}

impl SpaceHierarchyListResult {
    pub fn next_batch(&self) -> Option<String> {
        self.resp.next_batch.clone()
    }

    pub async fn rooms(&self) -> Result<Vec<SpaceHierarchyRoomInfo>> {
        let core = self.core.clone();
        let chunks = self.resp.rooms.clone();
        RUNTIME
            .spawn(async move {
                let iter = chunks
                    .into_iter()
                    .map(|chunk| SpaceHierarchyRoomInfo::new(chunk, core.clone()));
                Ok(futures::future::join_all(iter).await)
            })
            .await?
    }
}

pub struct JoinRuleBuilder {
    rule: String,
    restricted_rooms: Vec<String>,
}

impl JoinRuleBuilder {
    fn new() -> Self {
        JoinRuleBuilder {
            rule: "private".to_owned(),
            restricted_rooms: Vec::new(),
        }
    }

    pub fn join_rule(&mut self, input: String) {
        self.rule = input;
    }

    pub fn add_room(&mut self, new_room: String) {
        self.restricted_rooms.push(new_room);
    }

    fn build(self) -> Result<RoomJoinRulesEventContent> {
        let JoinRuleBuilder {
            rule,
            restricted_rooms,
        } = self;
        let allow_rules = restricted_rooms
            .iter()
            .map(|s| RoomId::parse(s).map(AllowRule::room_membership))
            .collect::<Result<Vec<AllowRule>, IdParseError>>()?;
        Ok(match rule.to_lowercase().as_str() {
            "private" => RoomJoinRulesEventContent::new(JoinRule::Private),
            "public" => RoomJoinRulesEventContent::new(JoinRule::Public),
            "invite" => RoomJoinRulesEventContent::new(JoinRule::Invite),
            "knock" => RoomJoinRulesEventContent::new(JoinRule::Knock),
            "restricted" => RoomJoinRulesEventContent::restricted(allow_rules),
            "knock_restricted" => RoomJoinRulesEventContent::knock_restricted(allow_rules),
            _ => bail!("Unsupported join rule {rule}"),
        })
    }
}

pub fn new_join_rule_builder() -> JoinRuleBuilder {
    JoinRuleBuilder::new()
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
                Ok(SpaceHierarchyListResult { resp, core: c.clone() })
            })
            .await?
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

    pub(crate) fn user_id(&self) -> Result<OwnedUserId> {
        self.core
            .client()
            .user_id()
            .context("You must be logged in to do that")
            .map(|x| x.to_owned())
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
            bail!("Unable to update a room you aren't part of");
        }
        let room_id = RoomId::parse(room_id)?;
        if !self
            .get_my_membership()
            .await?
            .can(crate::MemberPermission::CanLinkSpaces)
        {
            bail!("No permissions to add parent to room");
        }
        let client = self.core.client().clone();
        let room = self.room.clone();
        let my_id = self.user_id()?;

        RUNTIME
            .spawn(async move {
                let Some(Ok(homeserver)) = client.homeserver().host_str().map(ServerName::parse)
                else {
                    return Err(Error::HomeserverMissesHostname)?;
                };
                let content = assign!(SpaceParentEventContent::new(vec![homeserver]), {
                    canonical
                });
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::SpaceParent)
                    .await?;
                if !permitted {
                    bail!("No permissions to change space parent of this room");
                }
                let response = room.send_state_event_for_key(&room_id, content).await?;
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
            bail!("Unable to update a room you aren't part of");
        }
        let room_id = RoomId::parse(room_id)?;
        if !self
            .get_my_membership()
            .await?
            .can(crate::MemberPermission::CanLinkSpaces)
        {
            bail!("No permissions to remove parent from room");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;

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
                let event_id = match raw_state.deserialize()? {
                    SyncOrStrippedState::Stripped(ev) => {
                        bail!("Unable to get event id about stripped event")
                    }
                    SyncOrStrippedState::Sync(ev) => {
                        let permitted = if ev.sender() == my_id {
                            room.can_user_redact_own(&my_id).await?
                        } else {
                            room.can_user_redact_other(&my_id).await?
                        };
                        if !permitted {
                            bail!("No permissions to redact this message");
                        }
                        ev.event_id().to_owned()
                    }
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
        let me = self.clone();

        let my_id = self.user_id()?;
        let is_acter_space = self.is_acter_space().await?;
        let acter_app_settings = if is_acter_space {
            Some(self.app_settings_content().await?)
        } else {
            None
        };

        RUNTIME
            .spawn(async move {
                let member = me
                    .room
                    .get_member(&my_id)
                    .await?
                    .context("Unable to find me in room")?;
                Ok(Member {
                    member,
                    room: me.clone(),
                    acter_app_settings,
                })
            })
            .await?
    }

    pub fn get_profile(&self) -> RoomProfile {
        RoomProfile::new(self.room.clone())
    }

    pub async fn upload_avatar(&self, uri: String) -> Result<OwnedMxcUri> {
        if !self.is_joined() {
            bail!("Unable to upload avatar to a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;
        let path = PathBuf::from(uri);
        let client = self.core.client().clone();

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::RoomAvatar)
                    .await?;
                if !permitted {
                    bail!("No permissions to change avatar of this room");
                }

                let guess = mime_guess::from_path(path.clone());
                let content_type = guess.first().context("don't know mime type")?;
                let buf = std::fs::read(path)?;
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
            bail!("Unable to remove avatar to a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::RoomAvatar)
                    .await?;
                if !permitted {
                    bail!("No permissions to change avatar of this room");
                }
                let response = room.remove_avatar().await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn set_topic(&self, topic: String) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Unable to set topic to a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::RoomTopic)
                    .await?;
                if !permitted {
                    bail!("No permissions to change topic of this room");
                }
                let response = room.set_room_topic(&topic).await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn set_name(&self, name: String) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Unable to set name to a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::RoomName)
                    .await?;
                if !permitted {
                    bail!("No permissions to change name of this room");
                }
                let response = room.set_name(name).await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn active_members(&self) -> Result<Vec<Member>> {
        let me = self.clone();

        let is_acter_space = self.is_acter_space().await?;
        let acter_app_settings = if is_acter_space {
            Some(self.app_settings_content().await?)
        } else {
            None
        };

        RUNTIME
            .spawn(async move {
                let members = me
                    .room
                    .members(RoomMemberships::ACTIVE)
                    .await?
                    .into_iter()
                    .map(|member| Member {
                        member,
                        room: me.clone(),
                        acter_app_settings: acter_app_settings.clone(),
                    })
                    .collect();
                Ok(members)
            })
            .await?
    }

    pub async fn active_members_ids(&self) -> Result<Vec<String>> {
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
                    .map(|member| member.user_id().to_string())
                    .collect();
                Ok(members)
            })
            .await?
    }

    pub async fn invited_members(&self) -> Result<Vec<Member>> {
        let me = self.clone();
        let is_acter_space = self.is_acter_space().await?;
        let acter_app_settings = if is_acter_space {
            Some(self.app_settings_content().await?)
        } else {
            None
        };

        RUNTIME
            .spawn(async move {
                let members = me
                    .room
                    .members(RoomMemberships::INVITE)
                    .await?
                    .into_iter()
                    .map(|member| Member {
                        member,
                        room: me.clone(),
                        acter_app_settings: acter_app_settings.clone(),
                    })
                    .collect();
                Ok(members)
            })
            .await?
    }

    pub async fn active_members_no_sync(&self) -> Result<Vec<Member>> {
        let me = self.clone();
        let is_acter_space = self.is_acter_space().await?;
        let acter_app_settings = if is_acter_space {
            Some(self.app_settings_content().await?)
        } else {
            None
        };

        RUNTIME
            .spawn(async move {
                let members = me
                    .room
                    .members_no_sync(RoomMemberships::ACTIVE)
                    .await?
                    .into_iter()
                    .map(|member| Member {
                        member,
                        room: me.clone(),
                        acter_app_settings: acter_app_settings.clone(),
                    })
                    .collect();
                Ok(members)
            })
            .await?
    }

    pub async fn get_member(&self, user_id: String) -> Result<Member> {
        let me = self.clone();
        let uid = UserId::parse(user_id)?;
        let is_acter_space = self.is_acter_space().await?;
        let acter_app_settings = if is_acter_space {
            Some(self.app_settings_content().await?)
        } else {
            None
        };

        RUNTIME
            .spawn(async move {
                let member = me
                    .room
                    .get_member(&uid)
                    .await?
                    .context("Unable to find user in room")?;
                Ok(Member {
                    member,
                    room: me.clone(),
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
        let client = self.core.client().clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let notification_settings = client.notification_settings().await;
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
        let client = self.core.client().clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let notification_settings = client.notification_settings().await;
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
        let my_id = self.user_id()?;
        let client = self.core.client().clone();
        let mode = new_mode.and_then(|s| notification_mode_from_input(&s));

        RUNTIME
            .spawn(async move {
                let notification_settings = client.notification_settings().await;
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
            bail!("Unable to send typing notice to a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::RoomMessage)
                    .await?;
                if !permitted {
                    bail!("No permissions to send message in this room");
                }
                room.typing_notice(typing).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn media_binary(
        &self,
        event_id: String,
        thumb_size: Option<Box<ThumbnailSize>>,
    ) -> Result<FfiBuffer<u8>> {
        if !self.is_joined() {
            bail!("Unable to read media message from a room we are not in");
        }
        let room = self.room.clone();
        let client = self.core.client().clone();
        let event_id = EventId::parse(event_id)?;

        RUNTIME
            .spawn(async move {
                let evt = room.event(&event_id).await?;
                let event_content = evt.event.deserialize_as::<RoomMessageEvent>()?;
                let original = event_content
                    .as_original()
                    .context("Couldn't get original msg")?;
                let (source, format) = match thumb_size {
                    Some(thumb_size) => {
                        let source = match &original.content.msgtype {
                            MessageType::Image(content) => {
                                let Some(info) = content.info.clone() else {
                                    return Ok(FfiBuffer::new(vec![]));
                                };
                                let Some(thumbnail_source) = info.thumbnail_source else {
                                    return Ok(FfiBuffer::new(vec![]));
                                };
                                thumbnail_source
                            }
                            MessageType::Video(content) => {
                                let Some(info) = content.info.clone() else {
                                    return Ok(FfiBuffer::new(vec![]));
                                };
                                let Some(thumbnail_source) = info.thumbnail_source else {
                                    return Ok(FfiBuffer::new(vec![]));
                                };
                                thumbnail_source
                            }
                            MessageType::File(content) => {
                                let Some(info) = content.info.clone() else {
                                    return Ok(FfiBuffer::new(vec![]));
                                };
                                let Some(thumbnail_source) = info.thumbnail_source else {
                                    return Ok(FfiBuffer::new(vec![]));
                                };
                                thumbnail_source
                            }
                            MessageType::Location(content) => {
                                let Some(info) = content.info.clone() else {
                                    return Ok(FfiBuffer::new(vec![]));
                                };
                                let Some(thumbnail_source) = info.thumbnail_source else {
                                    return Ok(FfiBuffer::new(vec![]));
                                };
                                thumbnail_source
                            }
                            _ => {
                                bail!("Not an Image, Location, Video or Regular file.")
                            }
                        };
                        (source, thumb_size.into())
                    }
                    None => {
                        let source = match &original.content.msgtype {
                            MessageType::Image(content) => content.source.clone(),
                            MessageType::Audio(content) => content.source.clone(),
                            MessageType::Video(content) => content.source.clone(),
                            MessageType::File(content) => content.source.clone(),
                            _ => {
                                bail!("Not an Image, Audio, Video or Regular file.")
                            }
                        };
                        (source, MediaFormat::File)
                    }
                };
                let request = MediaRequest { source, format };
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

    pub async fn is_direct(&self) -> Result<bool> {
        let room = self.room.clone();

        Ok(RUNTIME
            .spawn(async move { room.is_direct().await })
            .await??)
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
            bail!("Unable to send message to a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;
        let user_id = UserId::parse(&user_id)?;

        RUNTIME
            .spawn(async move {
                let permitted = room.can_user_invite(&my_id).await?;
                if !permitted {
                    bail!("No permissions to invite someone in this room");
                }
                room.invite_user_by_id(&user_id).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn join(&self) -> Result<bool> {
        if !self.is_left() {
            bail!("Unable to join a room we are not left");
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
            bail!("Unable to leave a room we are not joined");
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
        let client = self.core.client().clone();
        if !self.is_invited() {
            bail!("Unable to get a room we are not invited");
        }
        let me = self.clone();
        let is_acter_space = self.is_acter_space().await?;
        let acter_app_settings = if is_acter_space {
            Some(self.app_settings_content().await?)
        } else {
            None
        };

        RUNTIME
            .spawn(async move {
                let invited = client
                    .store()
                    .get_user_ids(me.room.room_id(), RoomMemberships::INVITE)
                    .await?;
                let mut members = vec![];
                for user_id in invited.iter() {
                    if let Some(member) = me.room.get_member(user_id).await? {
                        members.push(Member {
                            member,
                            room: me.clone(),
                            acter_app_settings: acter_app_settings.clone(),
                        });
                    }
                }
                Ok(members)
            })
            .await?
    }

    pub async fn download_media(
        &self,
        event_id: String,
        thumb_size: Option<Box<ThumbnailSize>>,
        dir_path: String,
    ) -> Result<OptionString> {
        if !self.is_joined() {
            bail!("Unable to read message from a room we are not in");
        }
        let room = self.room.clone();
        let client = self.core.client().clone();
        let evt_id = EventId::parse(event_id.clone())?;

        RUNTIME
            .spawn(async move {
                let evt = room.event(&evt_id).await?;
                let event_content = evt.event.deserialize_as::<RoomMessageEvent>()?;
                let original = event_content
                    .as_original()
                    .context("Unable to get original msg")?;
                // get file extension from msg info
                let (request, mut filename) = match thumb_size.clone() {
                    Some(thumb_size) => match &original.content.msgtype {
                        MessageType::Image(content) => {
                            let request = content
                                .info
                                .as_ref()
                                .and_then(|info| info.thumbnail_source.clone())
                                .map(|source| MediaRequest {
                                    source,
                                    format: MediaFormat::from(thumb_size),
                                });
                            let filename = content
                                .info
                                .clone()
                                .and_then(|info| info.mimetype)
                                .and_then(|mimetype| {
                                    mime2ext::mime2ext(mimetype).map(|ext| {
                                        format!("{}-thumbnail.{}", event_id.clone(), ext)
                                    })
                                });
                            (request, filename)
                        }
                        MessageType::Video(content) => {
                            let request = content
                                .info
                                .as_ref()
                                .and_then(|info| info.thumbnail_source.clone())
                                .map(|source| MediaRequest {
                                    source,
                                    format: MediaFormat::from(thumb_size),
                                });
                            let filename = content
                                .info
                                .clone()
                                .and_then(|info| info.mimetype)
                                .and_then(|mimetype| {
                                    mime2ext::mime2ext(mimetype).map(|ext| {
                                        format!("{}-thumbnail.{}", event_id.clone(), ext)
                                    })
                                });
                            (request, filename)
                        }
                        MessageType::File(content) => {
                            let request = content
                                .info
                                .as_ref()
                                .and_then(|info| info.thumbnail_source.clone())
                                .map(|source| MediaRequest {
                                    source,
                                    format: MediaFormat::from(thumb_size),
                                });
                            let filename = content
                                .info
                                .clone()
                                .and_then(|info| info.mimetype)
                                .and_then(|mimetype| {
                                    mime2ext::mime2ext(mimetype).map(|ext| {
                                        format!("{}-thumbnail.{}", event_id.clone(), ext)
                                    })
                                });
                            (request, filename)
                        }
                        MessageType::Location(content) => {
                            let request = content
                                .info
                                .as_ref()
                                .and_then(|info| info.thumbnail_source.clone())
                                .map(|source| MediaRequest {
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
                                        format!("{}-thumbnail.{}", event_id.clone(), ext)
                                    })
                                });
                            (request, filename)
                        }
                        _ => bail!("This message type is not downloadable"),
                    },
                    None => match &original.content.msgtype {
                        MessageType::Image(content) => {
                            let request = MediaRequest {
                                source: content.source.clone(),
                                format: MediaFormat::File,
                            };
                            let filename = content
                                .info
                                .clone()
                                .and_then(|info| info.mimetype)
                                .and_then(|mimetype| {
                                    mime2ext::mime2ext(mimetype)
                                        .map(|ext| format!("{}.{}", event_id.clone(), ext))
                                });
                            (Some(request), filename)
                        }
                        MessageType::Audio(content) => {
                            let request = MediaRequest {
                                source: content.source.clone(),
                                format: MediaFormat::File,
                            };
                            let filename = content
                                .info
                                .clone()
                                .and_then(|info| info.mimetype)
                                .and_then(|mimetype| {
                                    mime2ext::mime2ext(mimetype)
                                        .map(|ext| format!("{}.{}", event_id.clone(), ext))
                                });
                            (Some(request), filename)
                        }
                        MessageType::Video(content) => {
                            let request = MediaRequest {
                                source: content.source.clone(),
                                format: MediaFormat::File,
                            };
                            let filename = content
                                .info
                                .clone()
                                .and_then(|info| info.mimetype)
                                .and_then(|mimetype| {
                                    mime2ext::mime2ext(mimetype)
                                        .map(|ext| format!("{}.{}", event_id.clone(), ext))
                                });
                            (Some(request), filename)
                        }
                        MessageType::File(content) => {
                            let request = MediaRequest {
                                source: content.source.clone(),
                                format: MediaFormat::File,
                            };
                            let filename = content
                                .info
                                .clone()
                                .and_then(|info| info.mimetype)
                                .and_then(|mimetype| {
                                    mime2ext::mime2ext(mimetype)
                                        .map(|ext| format!("{}.{}", event_id.clone(), ext))
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
                            format!("{}-thumbnail.{}", event_id.clone(), kind.extension())
                        } else {
                            format!("{}.{}", event_id.clone(), kind.extension())
                        });
                    }
                }
                let mut path = PathBuf::from(dir_path.clone());
                path.push(filename.unwrap_or_else(|| event_id.clone()));
                let mut file = std::fs::File::create(path.clone())?;
                file.write_all(&data)?;
                let key = if thumb_size.is_some() {
                    [
                        room.room_id().as_str().as_bytes(),
                        event_id.as_bytes(),
                        "thumbnail".as_bytes(),
                    ]
                    .concat()
                } else {
                    [room.room_id().as_str().as_bytes(), event_id.as_bytes()].concat()
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

    pub async fn media_path(&self, event_id: String, is_thumb: bool) -> Result<OptionString> {
        if !self.is_joined() {
            bail!("Unable to read message from a room we are not in");
        }
        let room = self.room.clone();
        let client = self.core.client().clone();
        let evt_id = EventId::parse(event_id.clone())?;

        RUNTIME
            .spawn(async move {
                let evt = room.event(&evt_id).await?;
                let event_content = evt.event.deserialize_as::<RoomMessageEvent>()?;
                let original = event_content
                    .as_original()
                    .context("Couldn't get original msg")?;
                if is_thumb {
                    let available = matches!(
                        &original.content.msgtype,
                        MessageType::Image(_)
                            | MessageType::Video(_)
                            | MessageType::File(_)
                            | MessageType::Location(_)
                    );
                    if !available {
                        bail!("This message type is not downloadable");
                    }
                } else {
                    let available = matches!(
                        &original.content.msgtype,
                        MessageType::Image(_)
                            | MessageType::Audio(_)
                            | MessageType::Video(_)
                            | MessageType::File(_)
                    );
                    if !available {
                        bail!("This message type is not downloadable");
                    }
                }
                let key = if is_thumb {
                    [
                        room.room_id().as_str().as_bytes(),
                        event_id.as_bytes(),
                        "thumbnail".as_bytes(),
                    ]
                    .concat()
                } else {
                    [room.room_id().as_str().as_bytes(), event_id.as_bytes()].concat()
                };
                let path = client.store().get_custom_value(&key).await?;
                let text = match path {
                    Some(path) => Some(std::str::from_utf8(&path)?.to_string()),
                    None => None,
                };
                Ok(OptionString::new(text))
            })
            .await?
    }

    pub async fn is_encrypted(&self) -> Result<bool> {
        if !self.is_joined() {
            bail!("Unable to know if a room we are not in is encrypted");
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

    /// set the join_rul to `join_rule`. if that is `restricted` or `knock_restricted`
    /// use the given `restricted_rooms` as subset of rooms to use.
    pub async fn set_join_rule(&self, join_rule_builder: Box<JoinRuleBuilder>) -> Result<bool> {
        let room = self.room.clone();
        let my_id = self.user_id()?;
        let join_rule = join_rule_builder.build()?;

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::RoomJoinRules)
                    .await?;
                if !permitted {
                    bail!("No permissions to change join rule in this room");
                }
                let evt = room.send_state_event(join_rule).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn redact_message(
        &self,
        event_id: String,
        sender_id: String,
        reason: Option<String>,
        txn_id: Option<String>,
    ) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Unable to redact any message from a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;
        let event_id = EventId::parse(event_id)?;
        let sender_id = UserId::parse(sender_id)?;

        RUNTIME
            .spawn(async move {
                let permitted = if sender_id == my_id {
                    room.can_user_redact_own(&my_id).await?
                } else {
                    room.can_user_redact_other(&my_id).await?
                };
                if !permitted {
                    bail!("No permissions to redact this message");
                }
                let response = room
                    .redact(
                        &event_id,
                        reason.as_deref(),
                        txn_id.map(OwnedTransactionId::from),
                    )
                    .await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn update_power_level(&self, user_id: String, level: i32) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Unable to update power level in a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;
        let user_id = UserId::parse(user_id)?;

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::RoomPowerLevels)
                    .await?;
                if !permitted {
                    bail!("No permissions to change power levels in this room");
                }
                let response = room
                    .update_power_levels(vec![(&user_id, Int::from(level))])
                    .await?;
                Ok(response.event_id)
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
            bail!("Unable to block content in a room we are not in");
        }
        let client = self.core.client().clone();
        let room_id = self.room.room_id().to_owned();
        let event_id = EventId::parse(event_id)?;
        let int_score = score.map(|value| value.into());

        RUNTIME
            .spawn(async move {
                let request =
                    report_content::v3::Request::new(room_id, event_id, int_score, reason);
                client.send(request, None).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn redact_content(
        &self,
        event_id: String,
        reason: Option<String>,
    ) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Unable to redact content in a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;
        let event_id = EventId::parse(event_id)?;

        RUNTIME
            .spawn(async move {
                let evt = room.event(&event_id).await?;
                let event_content = evt.event.deserialize_as::<RoomMessageEvent>()?;
                let permitted = if event_content.sender() == my_id {
                    room.can_user_redact_own(&my_id).await?
                } else {
                    room.can_user_redact_other(&my_id).await?
                };
                if !permitted {
                    bail!("No permissions to redact this message");
                }
                let response = room.redact(&event_id, reason.as_deref(), None).await?;
                Ok(response.event_id)
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
