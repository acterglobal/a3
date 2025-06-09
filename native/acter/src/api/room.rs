mod account_data;
mod preview;
mod subscription;

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
        stories::StoryEventContent,
        tasks::{TaskEventContent, TaskListEventContent},
        RefDetails as CoreRefDetails, RefPreview,
    },
    spaces::is_acter_space,
    statics::PURPOSE_FIELD_DEV,
};
use anyhow::{bail, Context, Result};
use futures::Stream;
use matrix_sdk::{
    notification_settings::{IsEncrypted, IsOneToOne},
    room::{Room as SdkRoom, RoomMember},
};
use matrix_sdk_base::{
    deserialized_responses::SyncOrStrippedState,
    media::{MediaFormat, MediaRequestParameters},
    ruma::{
        api::client::{
            room::report_content,
            space::{get_hierarchy, SpaceHierarchyRoomsChunk},
        },
        assign,
        events::{
            policy::rule::{
                room::PolicyRuleRoomEventContent, server::PolicyRuleServerEventContent,
                user::PolicyRuleUserEventContent, PolicyRuleEventContent, Recommendation,
            },
            room::{
                avatar::ImageInfo,
                encryption::RoomEncryptionEventContent,
                guest_access::{GuestAccess, RoomGuestAccessEventContent},
                history_visibility::{HistoryVisibility, RoomHistoryVisibilityEventContent},
                join_rules::{
                    AllowRule, JoinRule, Restricted, RoomJoinRulesEventContent, RoomMembership,
                },
                message::{MessageType, RoomMessageEvent},
                pinned_events::RoomPinnedEventsEventContent,
                power_levels::RoomPowerLevelsEventContent,
                server_acl::RoomServerAclEventContent,
                tombstone::RoomTombstoneEventContent,
                MediaSource,
            },
            space::{
                child::{HierarchySpaceChildEvent, SpaceChildEventContent},
                parent::SpaceParentEventContent,
            },
            MessageLikeEventType, StateEvent, StateEventType, StaticEventContent,
            TimelineEventType,
        },
        power_levels::NotificationPowerLevels,
        room::RoomType,
        serde::Raw,
        space::SpaceRoomJoinRule,
        EventEncryptionAlgorithm, EventId, IdParseError, Int, OwnedEventId, OwnedMxcUri,
        OwnedRoomAliasId, OwnedRoomId, OwnedTransactionId, OwnedUserId, RoomId, ServerName, UserId,
    },
    RoomDisplayName, RoomMemberships, RoomState,
};
use std::{collections::BTreeMap, fs::exists, io::Write, ops::Deref, path::PathBuf};
use tokio::fs;
use tokio_stream::{wrappers::BroadcastStream, StreamExt};
use tracing::{info, warn};

use super::{
    api::FfiBuffer,
    deep_linking::RefDetails,
    push::{notification_mode_from_input, room_notification_mode_name},
};
use crate::{OptionBuffer, OptionString, ThumbnailSize, UserProfile, RUNTIME};
pub use account_data::UserRoomSettings;
pub use preview::RoomPreview;

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
    CanPostStories,
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
    CanUpdateJoinRule,
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
            MemberPermission::CanUpdateJoinRule => StateEventType::RoomJoinRules.into(),
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
                    // Not an acter space or News are not activated..
                    return false;
                }
            }

            // Acter specific
            MemberPermission::CanPostStories => {
                if self
                    .acter_app_settings
                    .as_ref()
                    .map(|s| s.stories().active())
                    .unwrap_or_default()
                {
                    PermissionTest::Message(MessageLikeEventType::from(
                        <StoryEventContent as StaticEventContent>::TYPE,
                    ))
                } else {
                    // Not an acter space or Stories are not activated..
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
                    // Not an acter space or Events are not activated..
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
                    // Not an acter space or Tasks are not activated..
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
                    // not an acter space, you can’t set setting here
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
    suggested: bool,
}

impl SpaceHierarchyRoomInfo {
    pub fn canonical_alias(&self) -> Option<OwnedRoomAliasId> {
        self.chunk.canonical_alias.clone()
    }

    /// The name of the room, if any.
    pub fn name(&self) -> Option<String> {
        self.chunk.name.clone()
    }

    /// whether or not this room is suggested to join
    pub fn suggested(&self) -> bool {
        self.suggested
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
        self.chunk.avatar_url.as_deref().map(ToString::to_string)
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

    pub fn via_server_names(&self) -> Vec<String> {
        for v in &self.chunk.children_state {
            let Ok(h) = v.deserialize() else { continue };
            return h
                .content
                .via
                .iter()
                .map(ToString::to_string)
                .collect::<Vec<String>>();
        }
        vec![]
    }

    pub async fn get_avatar(&self, thumb_size: Option<Box<ThumbnailSize>>) -> Result<OptionBuffer> {
        let client = self.core.client().clone();
        if let Some(url) = self.chunk.avatar_url.clone() {
            let format = ThumbnailSize::parse_into_media_format(thumb_size);
            return RUNTIME
                .spawn(async move {
                    let request = MediaRequestParameters {
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
    pub(crate) fn new(chunk: SpaceHierarchyRoomsChunk, core: CoreClient, suggested: bool) -> Self {
        SpaceHierarchyRoomInfo {
            chunk,
            core,
            suggested,
        }
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

    pub async fn query_hierarchy(&self) -> Result<Vec<SpaceHierarchyRoomInfo>> {
        let c = self.room.core.clone();
        let suggested_rooms = self
            .core
            .children
            .iter()
            .filter(|c| c.suggested())
            .map(|c| c.room_id())
            .collect::<Vec<_>>();
        let room_id = self.room.room_id().to_owned();
        RUNTIME
            .spawn(async move {
                let mut next : Option<String> = Some("".to_owned());
                let mut rooms = Vec::new();
                while next.is_some() {
                    let request = assign!(get_hierarchy::v1::Request::new(room_id.clone()), { from: next.clone(), max_depth: Some(1u32.into()) });
                    let resp = c.client().send(request).await?;
                    if (resp.rooms.is_empty()) {
                        break; // we are done
                    }
                    next = resp.next_batch;
                    rooms.extend(resp.rooms
                        .into_iter()
                        .filter_map(|chunk| {
                            if chunk.room_id == room_id {
                                return None;
                            }
                            let suggested = suggested_rooms.contains(&chunk.room_id);
                            Some(SpaceHierarchyRoomInfo::new(chunk, c.clone(), suggested))
                        }));
                    }
                Ok(rooms)
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

    pub fn has_avatar(&self) -> bool {
        self.room.avatar_url().is_some()
    }

    pub async fn avatar(&self, thumb_size: Option<Box<ThumbnailSize>>) -> Result<OptionBuffer> {
        let room = self.room.clone();
        let format = ThumbnailSize::parse_into_media_format(thumb_size);
        RUNTIME
            .spawn(async move {
                let buf = room.avatar(format).await?;
                Ok(OptionBuffer::new(buf))
            })
            .await?
    }

    pub async fn display_name(&self) -> Result<OptionString> {
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                let result = room.display_name().await?;
                match result {
                    RoomDisplayName::Named(name) => Ok(OptionString::new(Some(name))),
                    RoomDisplayName::Aliased(name) => Ok(OptionString::new(Some(name))),
                    RoomDisplayName::Calculated(name) => Ok(OptionString::new(Some(name))),
                    RoomDisplayName::EmptyWas(name) => Ok(OptionString::new(Some(name))),
                    RoomDisplayName::Empty => Ok(OptionString::new(None)),
                }
            })
            .await?
    }

    pub fn subscribe_to_updates(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.room.subscribe_to_updates()).map(|f| f.is_ok())
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
            .map(ToOwned::to_owned)
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
            bail!("Unable to update a room you aren’t part of");
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
            bail!("Unable to update a room you aren’t part of");
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

    // order: Must consist of ASCII characters within the range \x20 (space) and \x7E (~), inclusive.
    pub async fn add_child_room(
        &self,
        room_id: String,
        order: Option<String>,
        suggested: bool,
    ) -> Result<String> {
        if !self.is_joined() {
            bail!("Unable to update a room you aren’t part of");
        }
        let room_id = RoomId::parse(room_id)?;
        if !self
            .get_my_membership()
            .await?
            .can(crate::MemberPermission::CanLinkSpaces)
        {
            bail!("No permissions to add child to room");
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
                let content = assign!(SpaceChildEventContent::new(vec![homeserver]), {
                    order, suggested,
                });
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::SpaceChild)
                    .await?;
                if !permitted {
                    bail!("No permissions to change space child of this room");
                }
                let response = room.send_state_event_for_key(&room_id, content).await?;
                Ok(response.event_id.to_string())
            })
            .await?
    }

    pub async fn remove_child_room(&self, room_id: String, reason: Option<String>) -> Result<bool> {
        if !self.is_joined() {
            bail!("Unable to update a room you aren’t part of");
        }
        let room_id = RoomId::parse(room_id)?;
        if !self
            .get_my_membership()
            .await?
            .can(crate::MemberPermission::CanLinkSpaces)
        {
            bail!("No permissions to remove child from room");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;

        RUNTIME
            .spawn(async move {
                let response = room
                    .get_state_event_static_for_key::<SpaceChildEventContent, OwnedRoomId>(&room_id)
                    .await?;
                let Some(raw_state) = response else {
                    warn!("Room {} is not a child", room_id);
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
            Some(self.app_settings_content().await?.unwrap_or_default())
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
                    room: me,
                    acter_app_settings,
                })
            })
            .await?
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
                let content_type = guess.first().context("don’t know mime type")?;
                let buf = std::fs::read(path)?;
                let response = client.media().upload(&content_type, buf, None).await?;

                let content_uri = response.content_uri;
                let info = assign!(ImageInfo::new(), {
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

    pub async fn set_topic(&self, topic: String) -> Result<bool> {
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
                room.set_room_topic(&topic).await?;
                Ok(true)
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
            self.app_settings_content().await?
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
            self.app_settings_content().await?
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
            self.app_settings_content().await?
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
            self.app_settings_content().await?
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
            self.app_settings_content().await?
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
                    room: me,
                    acter_app_settings,
                })
            })
            .await?
    }

    pub async fn notification_mode(&self) -> Result<String> {
        let room = self.room.clone();
        Ok(RUNTIME
            .spawn(async move {
                room.user_defined_notification_mode()
                    .await
                    .map(|x| room_notification_mode_name(&x))
                    .unwrap_or("none".to_owned())
            })
            .await?)
    }

    pub async fn default_notification_mode(&self) -> Result<String> {
        let client = self.core.client().clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let notification_settings = client.notification_settings().await;
                let is_encrypted = room.latest_encryption_state().await?.is_encrypted();
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
                Ok(room_notification_mode_name(&default_mode))
            })
            .await?
    }

    pub async fn unmute(&self) -> Result<bool> {
        let client = self.core.client().clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let notification_settings = client.notification_settings().await;
                let is_encrypted = room.latest_encryption_state().await?.is_encrypted();
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
                let evt = room.event(&event_id, None).await?;
                let event_content = evt.kind.raw().deserialize_as::<RoomMessageEvent>()?;
                let original = event_content
                    .as_original()
                    .context("Couldn’t get original msg")?;
                let (source, format) = match thumb_size {
                    Some(thumb_size) => {
                        let source = match &original.content.msgtype {
                            MessageType::Image(content) => {
                                if let Some(source) = content
                                    .info
                                    .as_deref()
                                    .and_then(|info| info.thumbnail_source.clone())
                                {
                                    source
                                } else {
                                    return Ok(FfiBuffer::new(vec![]));
                                }
                            }
                            MessageType::Video(content) => {
                                if let Some(source) = content
                                    .info
                                    .as_deref()
                                    .and_then(|info| info.thumbnail_source.clone())
                                {
                                    source
                                } else {
                                    return Ok(FfiBuffer::new(vec![]));
                                }
                            }
                            MessageType::File(content) => {
                                if let Some(source) = content
                                    .info
                                    .as_deref()
                                    .and_then(|info| info.thumbnail_source.clone())
                                {
                                    source
                                } else {
                                    return Ok(FfiBuffer::new(vec![]));
                                }
                            }
                            MessageType::Location(content) => {
                                if let Some(source) = content
                                    .info
                                    .as_deref()
                                    .and_then(|info| info.thumbnail_source.clone())
                                {
                                    source
                                } else {
                                    return Ok(FfiBuffer::new(vec![]));
                                }
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
                let request = MediaRequestParameters { source, format };
                let data = client.media().get_media_content(&request, false).await?;
                Ok(FfiBuffer::new(data))
            })
            .await?
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
            self.app_settings_content().await?
        } else {
            None
        };

        RUNTIME
            .spawn(async move {
                let invited = client
                    .state_store()
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
        let evt_id = EventId::parse(&event_id)?;

        RUNTIME
            .spawn(async move {
                let evt = room.event(&evt_id, None).await?;
                let event_content = evt.kind.raw().deserialize_as::<RoomMessageEvent>()?;
                let original = event_content
                    .as_original()
                    .context("Unable to get original msg")?;
                // get file extension from msg info
                let (request, mut filename) = match thumb_size.as_ref() {
                    Some(thumb_size) => match &original.content.msgtype {
                        MessageType::Image(content) => {
                            let request = content
                                .info
                                .as_deref()
                                .and_then(|info| info.thumbnail_source.clone())
                                .map(|source| MediaRequestParameters {
                                    source,
                                    format: MediaFormat::from(thumb_size.clone()),
                                });
                            let filename = content
                                .info
                                .as_deref()
                                .and_then(|info| info.mimetype.as_deref())
                                .and_then(|mimetype| {
                                    mime2ext::mime2ext(mimetype)
                                        .map(|ext| format!("{}-thumbnail.{}", &event_id, ext))
                                });
                            (request, filename)
                        }
                        MessageType::Video(content) => {
                            let request = content
                                .info
                                .as_deref()
                                .and_then(|info| info.thumbnail_source.clone())
                                .map(|source| MediaRequestParameters {
                                    source,
                                    format: MediaFormat::from(thumb_size.clone()),
                                });
                            let filename = content
                                .info
                                .as_deref()
                                .and_then(|info| info.mimetype.as_deref())
                                .and_then(|mimetype| {
                                    mime2ext::mime2ext(mimetype)
                                        .map(|ext| format!("{}-thumbnail.{}", &event_id, ext))
                                });
                            (request, filename)
                        }
                        MessageType::File(content) => {
                            let request = content
                                .info
                                .as_deref()
                                .and_then(|info| info.thumbnail_source.clone())
                                .map(|source| MediaRequestParameters {
                                    source,
                                    format: MediaFormat::from(thumb_size.clone()),
                                });
                            let filename = content
                                .info
                                .as_deref()
                                .and_then(|info| info.mimetype.as_deref())
                                .and_then(|mimetype| {
                                    mime2ext::mime2ext(mimetype)
                                        .map(|ext| format!("{}-thumbnail.{}", &event_id, ext))
                                });
                            (request, filename)
                        }
                        MessageType::Location(content) => {
                            let request = content
                                .info
                                .as_deref()
                                .and_then(|info| info.thumbnail_source.clone())
                                .map(|source| MediaRequestParameters {
                                    source,
                                    format: MediaFormat::from(thumb_size.clone()),
                                });
                            let filename = content
                                .info
                                .as_deref()
                                .and_then(|info| info.thumbnail_info.as_deref())
                                .and_then(|info| info.mimetype.as_deref())
                                .and_then(|mimetype| {
                                    mime2ext::mime2ext(mimetype)
                                        .map(|ext| format!("{}-thumbnail.{}", &event_id, ext))
                                });
                            (request, filename)
                        }
                        _ => bail!("This message type is not downloadable"),
                    },
                    None => match &original.content.msgtype {
                        MessageType::Image(content) => {
                            let request = MediaRequestParameters {
                                source: content.source.clone(),
                                format: MediaFormat::File,
                            };
                            let filename = content
                                .info
                                .as_deref()
                                .and_then(|info| info.mimetype.as_deref())
                                .and_then(|mimetype| {
                                    mime2ext::mime2ext(mimetype)
                                        .map(|ext| format!("{}.{}", &event_id, ext))
                                });
                            (Some(request), filename)
                        }
                        MessageType::Audio(content) => {
                            let request = MediaRequestParameters {
                                source: content.source.clone(),
                                format: MediaFormat::File,
                            };
                            let filename = content
                                .info
                                .as_deref()
                                .and_then(|info| info.mimetype.as_deref())
                                .and_then(|mimetype| {
                                    mime2ext::mime2ext(mimetype)
                                        .map(|ext| format!("{}.{}", &event_id, ext))
                                });
                            (Some(request), filename)
                        }
                        MessageType::Video(content) => {
                            let request = MediaRequestParameters {
                                source: content.source.clone(),
                                format: MediaFormat::File,
                            };
                            let filename = content
                                .info
                                .as_deref()
                                .and_then(|info| info.mimetype.as_deref())
                                .and_then(|mimetype| {
                                    mime2ext::mime2ext(mimetype)
                                        .map(|ext| format!("{}.{}", &event_id, ext))
                                });
                            (Some(request), filename)
                        }
                        MessageType::File(content) => {
                            let request = MediaRequestParameters {
                                source: content.source.clone(),
                                format: MediaFormat::File,
                            };
                            let filename = content
                                .info
                                .as_deref()
                                .and_then(|info| info.mimetype.as_deref())
                                .and_then(|mimetype| {
                                    mime2ext::mime2ext(mimetype)
                                        .map(|ext| format!("{}.{}", &event_id, ext))
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
                let data = client.media().get_media_content(&request, true).await?;
                // infer file extension via parsing of file binary
                if filename.is_none() {
                    if let Some(kind) = infer::get(&data) {
                        let fname = if thumb_size.is_some() {
                            format!("{}-thumbnail.{}", &event_id, kind.extension())
                        } else {
                            format!("{}.{}", &event_id, kind.extension())
                        };
                        filename = Some(fname);
                    }
                }
                let mut path = PathBuf::from(dir_path);
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
                    .state_store()
                    .set_custom_value_no_read(&key, path_text.as_bytes().to_vec())
                    .await?;
                Ok(OptionString::new(Some(path_text.to_owned())))
            })
            .await?
    }

    pub async fn media_path(&self, event_id: String, is_thumb: bool) -> Result<OptionString> {
        if !self.is_joined() {
            bail!("Unable to read message from a room we are not in");
        }
        let room = self.room.clone();
        let client = self.core.client().clone();
        let evt_id = EventId::parse(&event_id)?;

        RUNTIME
            .spawn(async move {
                let evt = room.event(&evt_id, None).await?;
                let event_content = evt.kind.raw().deserialize_as::<RoomMessageEvent>()?;
                let original = event_content
                    .as_original()
                    .context("Couldn’t get original msg")?;
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
                let Some(path_vec) = client.state_store().get_custom_value(&key).await? else {
                    return Ok(OptionString::new(None));
                };
                let path_str = std::str::from_utf8(&path_vec)?.to_owned();
                if matches!(exists(&path_str), Ok(true)) {
                    return Ok(OptionString::new(Some(path_str)));
                }

                // file wasn’t existing, clear cache.

                client.state_store().remove_custom_value(&key).await?;
                Ok(OptionString::new(None))
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
                let encrypted = room.latest_encryption_state().await?.is_encrypted();
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
        let txn_id = txn_id.map(OwnedTransactionId::from);

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
                let response = room.redact(&event_id, reason.as_deref(), txn_id).await?;
                Ok(response.event_id)
            })
            .await?
    }

    // initial level of room creator is 100
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
                client.send(request).await?;
                Ok(true)
            })
            .await?
    }

    /// sent a redaction message for this content
    /// it’s the callers job to ensure the person has the privileges to
    /// redact that content.
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
                let response = room.redact(&event_id, reason.as_deref(), None).await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn ref_details(&self) -> Result<RefDetails> {
        let room = self.room.clone();
        let client = self.core.client().clone();
        let room_id = self.room.room_id().to_owned();

        RUNTIME
            .spawn(async move {
                let via = room.route().await?;
                let room_display_name = room.cached_display_name();
                Ok(RefDetails::new(
                    client,
                    CoreRefDetails::Room {
                        room_id,
                        is_space: room.is_space(),
                        via,
                        preview: RefPreview::new(None, room_display_name),
                    },
                ))
            })
            .await?
    }

    // entity: #*:example.org
    // reason: undesirable content
    // state key: rule:#*:example.org
    pub async fn set_policy_rule_room(
        &self,
        entity: String,
        reason: String,
    ) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Unable to change policy rule room in a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;
        let state_key = format!("rule:{}", &entity);
        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::PolicyRuleRoom)
                    .await?;
                if !permitted {
                    bail!("No permissions to change policy rule room in this room");
                }
                let content = PolicyRuleEventContent::new(entity, Recommendation::Ban, reason);
                let response = room
                    .send_state_event_for_key(&state_key, PolicyRuleRoomEventContent(content))
                    .await?;
                Ok(response.event_id)
            })
            .await?
    }

    // entity: *.example.org
    // reason: undesirable engagement
    // state key: rule:*.example.org
    pub async fn set_policy_rule_server(
        &self,
        entity: String,
        reason: String,
    ) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Unable to change policy rule server in a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;
        let state_key = format!("rule:{}", &entity);
        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::PolicyRuleServer)
                    .await?;
                if !permitted {
                    bail!("No permissions to change policy rule server in this room");
                }
                let content = PolicyRuleEventContent::new(entity, Recommendation::Ban, reason);
                let response = room
                    .send_state_event_for_key(&state_key, PolicyRuleServerEventContent(content))
                    .await?;
                Ok(response.event_id)
            })
            .await?
    }

    // entity: @alice*:example.org
    // reason: undesirable behaviour
    // state key: rule:@alice*:example.org
    pub async fn set_policy_rule_user(
        &self,
        entity: String,
        reason: String,
    ) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Unable to change policy rule user in a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;
        let state_key = format!("rule:{}", &entity);
        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::PolicyRuleUser)
                    .await?;
                if !permitted {
                    bail!("No permissions to change policy rule user in this room");
                }
                let content = PolicyRuleEventContent::new(entity, Recommendation::Ban, reason);
                let response = room
                    .send_state_event_for_key(&state_key, PolicyRuleUserEventContent(content))
                    .await?;
                Ok(response.event_id)
            })
            .await?
    }

    // m.olm.v1.curve25519-aes-sha2 or m.megolm.v1.aes-sha2
    // initial algorithm is m.megolm.v1.aes-sha2
    pub async fn set_encryption(&self, algorithm: String) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Unable to change room encryption in a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;
        let algorithm = EventEncryptionAlgorithm::from(algorithm.as_str());
        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::RoomEncryption)
                    .await?;
                if !permitted {
                    bail!("No permissions to change room encryption in this room");
                }
                let content = RoomEncryptionEventContent::new(algorithm);
                let response = room.send_state_event(content).await?;
                Ok(response.event_id)
            })
            .await?
    }

    // can_join or forbidden
    pub async fn set_guest_access(&self, guest_access: String) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Unable to change room guest access in a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;
        let guest_access = GuestAccess::from(guest_access.as_str());
        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::RoomGuestAccess)
                    .await?;
                if !permitted {
                    bail!("No permissions to change room guest access in this room");
                }
                let content = RoomGuestAccessEventContent::new(guest_access);
                let response = room.send_state_event(content).await?;
                Ok(response.event_id)
            })
            .await?
    }

    // invited, joined, shared, or world_readable
    pub async fn set_history_visibility(&self, history_visibility: String) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Unable to change room history visiblity in a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;
        let history_visibility = HistoryVisibility::from(history_visibility.as_str());
        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::RoomHistoryVisibility)
                    .await?;
                if !permitted {
                    bail!("No permissions to change room history visibility in this room");
                }
                let content = RoomHistoryVisibilityEventContent::new(history_visibility);
                let response = room.send_state_event(content).await?;
                Ok(response.event_id)
            })
            .await?
    }

    // initial rule is Invite
    pub async fn set_join_rules(&self, join_rule: String) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Unable to change room join rules in a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;
        let join_rule = match (join_rule.as_str()) {
            "invite" => JoinRule::Invite,
            "knock" => JoinRule::Knock,
            "private" => JoinRule::Private,
            "public" => JoinRule::Public,
            _ => bail!("invalid join rule"),
        };
        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::RoomJoinRules)
                    .await?;
                if !permitted {
                    bail!("No permissions to change room join rules in this room");
                }
                let content = RoomJoinRulesEventContent::new(join_rule);
                let response = room.send_state_event(content).await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn set_pinned_events(&self, event_ids: String) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Unable to change room pinned events in a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;
        let pinned = serde_json::from_str::<Vec<OwnedEventId>>(&event_ids)?;
        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::RoomPinnedEvents)
                    .await?;
                if !permitted {
                    bail!("No permissions to change room pinned events in this room");
                }
                let content = RoomPinnedEventsEventContent::new(pinned);
                let response = room.send_state_event(content).await?;
                Ok(response.event_id)
            })
            .await?
    }

    // initial level is 50
    pub async fn set_power_levels_ban(&self, level: i32) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Unable to change ban of power level in a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;
        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::RoomPowerLevels)
                    .await?;
                if !permitted {
                    bail!("No permissions to change ban of power levels in this room");
                }
                let content = assign!(RoomPowerLevelsEventContent::new(), {
                    ban: Int::from(level),
                });
                let response = room.send_state_event(content).await?;
                Ok(response.event_id)
            })
            .await?
    }

    // initial value of "m.room.avatar": 50
    // initial value of "m.room.canonical_alias": 50
    // initial value of "m.room.encryption": 100
    // initial value of "m.room.history_visibility": 100
    // initial value of "m.room.name": 50
    // initial value of "m.room.power_levels": 100
    // initial value of "m.room.server_acl": 100
    // initial value of "m.room.tombstone": 100
    pub async fn set_power_levels_events(
        &self,
        event_type: String,
        level: i32,
    ) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Unable to change events of power levels in a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;
        let key = TimelineEventType::from(event_type);
        let value = Int::from(level);
        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::RoomPowerLevels)
                    .await?;
                if !permitted {
                    bail!("No permissions to change events of power levels in this room");
                }
                let mut events = BTreeMap::new();
                events.insert(key, value);
                let content = assign!(RoomPowerLevelsEventContent::new(), {
                    events,
                });
                let response = room.send_state_event(content).await?;
                Ok(response.event_id)
            })
            .await?
    }

    // initial level is 0
    pub async fn set_power_levels_events_default(&self, level: i32) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Unable to change events_default of power levels in a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;
        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::RoomPowerLevels)
                    .await?;
                if !permitted {
                    bail!("No permissions to change events_default of power levels in this room");
                }
                let content = assign!(RoomPowerLevelsEventContent::new(), {
                    events_default: Int::from(level),
                });
                let response = room.send_state_event(content).await?;
                Ok(response.event_id)
            })
            .await?
    }

    // initial level is 0
    pub async fn set_power_levels_invite(&self, level: i32) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Unable to change invite of power levels in a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;
        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::RoomPowerLevels)
                    .await?;
                if !permitted {
                    bail!("No permissions to change invite of power levels in this room");
                }
                let content = assign!(RoomPowerLevelsEventContent::new(), {
                    invite: Int::from(level),
                });
                let response = room.send_state_event(content).await?;
                Ok(response.event_id)
            })
            .await?
    }

    // initial level is 50
    pub async fn set_power_levels_kick(&self, level: i32) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Unable to change kick of power levels in a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;
        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::RoomPowerLevels)
                    .await?;
                if !permitted {
                    bail!("No permissions to change kick of power levels in this room");
                }
                let content = assign!(RoomPowerLevelsEventContent::new(), {
                    kick: Int::from(level),
                });
                let response = room.send_state_event(content).await?;
                Ok(response.event_id)
            })
            .await?
    }

    // initial level is 50
    pub async fn set_power_levels_redact(&self, level: i32) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Unable to change redact of power levels in a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;
        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::RoomPowerLevels)
                    .await?;
                if !permitted {
                    bail!("No permissions to change redact of power levels in this room");
                }
                let content = assign!(RoomPowerLevelsEventContent::new(), {
                    redact: Int::from(level),
                });
                let response = room.send_state_event(content).await?;
                Ok(response.event_id)
            })
            .await?
    }

    // initial level is 50
    pub async fn set_power_levels_state_default(&self, level: i32) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Unable to change state_default of power levels in a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;
        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::RoomPowerLevels)
                    .await?;
                if !permitted {
                    bail!("No permissions to change state_default of power levels in this room");
                }
                let content = assign!(RoomPowerLevelsEventContent::new(), {
                    state_default: Int::from(level),
                });
                let response = room.send_state_event(content).await?;
                Ok(response.event_id)
            })
            .await?
    }

    // initial level is 0
    pub async fn set_power_levels_users_default(&self, level: i32) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Unable to change users_default of power levels in a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;
        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::RoomPowerLevels)
                    .await?;
                if !permitted {
                    bail!("No permissions to change users_default of power levels in this room");
                }
                let content = assign!(RoomPowerLevelsEventContent::new(), {
                    users_default: Int::from(level),
                });
                let response = room.send_state_event(content).await?;
                Ok(response.event_id)
            })
            .await?
    }

    // initial level is 50
    pub async fn set_power_levels_notifications(&self, level: i32) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Unable to change notifications of power levels in a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;
        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::RoomPowerLevels)
                    .await?;
                if !permitted {
                    bail!("No permissions to change notifications of power levels in this room");
                }
                let notifications = assign!(NotificationPowerLevels::new(), {
                    room: Int::from(level),
                });
                let content = assign!(RoomPowerLevelsEventContent::new(), {
                    notifications,
                });
                let response = room.send_state_event(content).await?;
                Ok(response.event_id)
            })
            .await?
    }

    // allow_ip_literals: true
    // allow: ["*"]
    // deny: ["1.1.1.1"]
    pub async fn set_server_acl(
        &self,
        allow_ip_literals: bool,
        allow: String,
        deny: String,
    ) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Unable to change room server acl in a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;
        let allow = serde_json::from_str::<Vec<String>>(&allow)?;
        let deny = serde_json::from_str::<Vec<String>>(&deny)?;
        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::RoomServerAcl)
                    .await?;
                if !permitted {
                    bail!("No permissions to change room server acl in this room");
                }
                let content = RoomServerAclEventContent::new(allow_ip_literals, allow, deny);
                let response = room.send_state_event(content).await?;
                Ok(response.event_id)
            })
            .await?
    }

    pub async fn set_tombstone(
        &self,
        body: String,
        replacement_room_id: String,
    ) -> Result<OwnedEventId> {
        if !self.is_joined() {
            bail!("Unable to change room tombstone in a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.user_id()?;
        let replacement_room = RoomId::parse(replacement_room_id)?;
        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::RoomTombstone)
                    .await?;
                if !permitted {
                    bail!("No permissions to change room tombstone in this room");
                }
                let content = RoomTombstoneEventContent::new(body, replacement_room);
                let response = room.send_state_event(content).await?;
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
