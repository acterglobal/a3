use acter_core::models::status::{
    MembershipContent, PolicyRuleRoomContent, PolicyRuleServerContent, PolicyRuleUserContent,
    ProfileContent, RoomAvatarContent, RoomCreateContent, RoomEncryptionContent,
    RoomGuestAccessContent, RoomHistoryVisibilityContent, RoomJoinRulesContent, RoomNameContent,
    RoomPinnedEventsContent, RoomPowerLevelsContent, RoomServerAclContent, RoomTombstoneContent,
};
use matrix_sdk_base::ruma::events::room::message::MessageType;
use serde::{Deserialize, Serialize};

use super::MsgContent;
use crate::MediaSource;

#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum TimelineEventContent {
    Message(MsgContent),
    MembershipChange(MembershipContent),
    ProfileChange(ProfileContent),
    PolicyRuleRoom(PolicyRuleRoomContent),
    PolicyRuleServer(PolicyRuleServerContent),
    PolicyRuleUser(PolicyRuleUserContent),
    RoomAvatar(RoomAvatarContent),
    RoomCreate(RoomCreateContent),
    RoomEncryption(RoomEncryptionContent),
    RoomGuestAccess(RoomGuestAccessContent),
    RoomHistoryVisibility(RoomHistoryVisibilityContent),
    RoomJoinRules(RoomJoinRulesContent),
    RoomName(RoomNameContent),
    RoomPinnedEvents(RoomPinnedEventsContent),
    RoomPowerLevels(RoomPowerLevelsContent),
    RoomServerAcl(RoomServerAclContent),
    RoomTombstone(RoomTombstoneContent),
}

impl TryFrom<&MessageType> for TimelineEventContent {
    type Error = ();

    fn try_from(value: &MessageType) -> Result<Self, Self::Error> {
        match value {
            MessageType::Text(content) => {
                Ok(TimelineEventContent::Message(MsgContent::from(content)))
            }
            MessageType::Emote(content) => {
                Ok(TimelineEventContent::Message(MsgContent::from(content)))
            }
            MessageType::Image(content) => {
                Ok(TimelineEventContent::Message(MsgContent::from(content)))
            }
            MessageType::Audio(content) => {
                Ok(TimelineEventContent::Message(MsgContent::from(content)))
            }
            MessageType::Video(content) => {
                Ok(TimelineEventContent::Message(MsgContent::from(content)))
            }
            MessageType::File(content) => {
                Ok(TimelineEventContent::Message(MsgContent::from(content)))
            }
            MessageType::Location(content) => {
                Ok(TimelineEventContent::Message(MsgContent::from(content)))
            }
            MessageType::Notice(content) => {
                Ok(TimelineEventContent::Message(MsgContent::from(content)))
            }
            MessageType::ServerNotice(content) => {
                Ok(TimelineEventContent::Message(MsgContent::from(content)))
            }
            _ => Err(()),
        }
    }
}
