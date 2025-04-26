use matrix_sdk_base::ruma::events::{
    policy::rule::{
        room::{PolicyRuleRoomEventContent, PossiblyRedactedPolicyRuleRoomEventContent},
        server::{PolicyRuleServerEventContent, PossiblyRedactedPolicyRuleServerEventContent},
        user::{PolicyRuleUserEventContent, PossiblyRedactedPolicyRuleUserEventContent},
    },
    room::{
        avatar::RoomAvatarEventContent,
        create::RoomCreateEventContent,
        encryption::{PossiblyRedactedRoomEncryptionEventContent, RoomEncryptionEventContent},
        guest_access::{PossiblyRedactedRoomGuestAccessEventContent, RoomGuestAccessEventContent},
        history_visibility::RoomHistoryVisibilityEventContent,
        join_rules::RoomJoinRulesEventContent,
        name::{PossiblyRedactedRoomNameEventContent, RoomNameEventContent},
        pinned_events::{
            PossiblyRedactedRoomPinnedEventsEventContent, RoomPinnedEventsEventContent,
        },
        power_levels::RoomPowerLevelsEventContent,
        server_acl::RoomServerAclEventContent,
        tombstone::{PossiblyRedactedRoomTombstoneEventContent, RoomTombstoneEventContent},
    },
    TimelineEventType,
};
use serde::{Deserialize, Serialize};

use crate::util::do_vecs_match;

// m.policy.rule.room
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct PolicyRuleRoomContent {
    content: PolicyRuleRoomEventContent,
    prev_content: Option<PossiblyRedactedPolicyRuleRoomEventContent>,
}

impl PolicyRuleRoomContent {
    pub fn new(
        content: PolicyRuleRoomEventContent,
        prev_content: Option<PossiblyRedactedPolicyRuleRoomEventContent>,
    ) -> Self {
        PolicyRuleRoomContent {
            content,
            prev_content,
        }
    }

    pub fn entity_change(&self) -> Option<String> {
        let PolicyRuleRoomEventContent(content) = &self.content;
        if let Some(PossiblyRedactedPolicyRuleRoomEventContent(prev_content)) = &self.prev_content {
            if let Some(prev_entity) = &prev_content.entity {
                if content.entity == *prev_entity {
                    return None;
                } else {
                    return Some("Changed".to_owned());
                }
            }
        }
        Some("Set".to_owned())
    }

    pub fn entity_new_val(&self) -> String {
        let PolicyRuleRoomEventContent(content) = &self.content;
        content.entity.clone()
    }

    pub fn entity_old_val(&self) -> Option<String> {
        if let Some(PossiblyRedactedPolicyRuleRoomEventContent(prev_content)) = &self.prev_content {
            prev_content.entity.clone()
        } else {
            None
        }
    }

    pub fn reason_change(&self) -> Option<String> {
        let PolicyRuleRoomEventContent(content) = &self.content;
        if let Some(PossiblyRedactedPolicyRuleRoomEventContent(prev_content)) = &self.prev_content {
            if let Some(prev_reason) = &prev_content.reason {
                if content.reason == *prev_reason {
                    return None;
                } else {
                    return Some("Changed".to_owned());
                }
            }
        }
        Some("Set".to_owned())
    }

    pub fn reason_new_val(&self) -> String {
        let PolicyRuleRoomEventContent(content) = &self.content;
        content.reason.clone()
    }

    pub fn reason_old_val(&self) -> Option<String> {
        if let Some(PossiblyRedactedPolicyRuleRoomEventContent(prev_content)) = &self.prev_content {
            prev_content.reason.clone()
        } else {
            None
        }
    }

    pub fn recommendation_change(&self) -> Option<String> {
        let PolicyRuleRoomEventContent(content) = &self.content;
        if let Some(PossiblyRedactedPolicyRuleRoomEventContent(prev_content)) = &self.prev_content {
            if let Some(prev_recommendation) = &prev_content.recommendation {
                if content.recommendation == *prev_recommendation {
                    return None;
                } else {
                    return Some("Changed".to_owned());
                }
            }
        }
        Some("Set".to_owned())
    }

    pub fn recommendation_new_val(&self) -> String {
        let PolicyRuleRoomEventContent(content) = &self.content;
        content.recommendation.to_string()
    }

    pub fn recommendation_old_val(&self) -> Option<String> {
        if let Some(PossiblyRedactedPolicyRuleRoomEventContent(prev_content)) = &self.prev_content {
            prev_content
                .recommendation
                .as_ref()
                .map(ToString::to_string)
        } else {
            None
        }
    }
}

// m.policy.rule.server
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct PolicyRuleServerContent {
    content: PolicyRuleServerEventContent,
    prev_content: Option<PossiblyRedactedPolicyRuleServerEventContent>,
}

impl PolicyRuleServerContent {
    pub fn new(
        content: PolicyRuleServerEventContent,
        prev_content: Option<PossiblyRedactedPolicyRuleServerEventContent>,
    ) -> Self {
        PolicyRuleServerContent {
            content,
            prev_content,
        }
    }

    pub fn entity_change(&self) -> Option<String> {
        let PolicyRuleServerEventContent(content) = &self.content;
        if let Some(PossiblyRedactedPolicyRuleServerEventContent(prev_content)) = &self.prev_content
        {
            if let Some(prev_entity) = &prev_content.entity {
                if content.entity == *prev_entity {
                    return None;
                } else {
                    return Some("Changed".to_owned());
                }
            }
        }
        Some("Set".to_owned())
    }

    pub fn entity_new_val(&self) -> String {
        let PolicyRuleServerEventContent(content) = &self.content;
        content.entity.clone()
    }

    pub fn entity_old_val(&self) -> Option<String> {
        if let Some(PossiblyRedactedPolicyRuleServerEventContent(prev_content)) = &self.prev_content
        {
            prev_content.entity.clone()
        } else {
            None
        }
    }

    pub fn reason_change(&self) -> Option<String> {
        let PolicyRuleServerEventContent(content) = &self.content;
        if let Some(PossiblyRedactedPolicyRuleServerEventContent(prev_content)) = &self.prev_content
        {
            if let Some(prev_reason) = &prev_content.reason {
                if content.reason == *prev_reason {
                    return None;
                } else {
                    return Some("Changed".to_owned());
                }
            }
        }
        Some("Set".to_owned())
    }

    pub fn reason_new_val(&self) -> String {
        let PolicyRuleServerEventContent(content) = &self.content;
        content.reason.clone()
    }

    pub fn reason_old_val(&self) -> Option<String> {
        if let Some(PossiblyRedactedPolicyRuleServerEventContent(prev_content)) = &self.prev_content
        {
            prev_content.reason.clone()
        } else {
            None
        }
    }

    pub fn recommendation_change(&self) -> Option<String> {
        let PolicyRuleServerEventContent(content) = &self.content;
        if let Some(PossiblyRedactedPolicyRuleServerEventContent(prev_content)) = &self.prev_content
        {
            if let Some(prev_recommendation) = &prev_content.recommendation {
                if content.recommendation == *prev_recommendation {
                    return None;
                } else {
                    return Some("Changed".to_owned());
                }
            }
        }
        Some("Set".to_owned())
    }

    pub fn recommendation_new_val(&self) -> String {
        let PolicyRuleServerEventContent(content) = &self.content;
        content.recommendation.to_string()
    }

    pub fn recommendation_old_val(&self) -> Option<String> {
        if let Some(PossiblyRedactedPolicyRuleServerEventContent(prev_content)) = &self.prev_content
        {
            prev_content
                .recommendation
                .as_ref()
                .map(ToString::to_string)
        } else {
            None
        }
    }
}

// m.policy.rule.user
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct PolicyRuleUserContent {
    content: PolicyRuleUserEventContent,
    prev_content: Option<PossiblyRedactedPolicyRuleUserEventContent>,
}

impl PolicyRuleUserContent {
    pub fn new(
        content: PolicyRuleUserEventContent,
        prev_content: Option<PossiblyRedactedPolicyRuleUserEventContent>,
    ) -> Self {
        PolicyRuleUserContent {
            content,
            prev_content,
        }
    }

    pub fn entity_change(&self) -> Option<String> {
        let PolicyRuleUserEventContent(content) = &self.content;
        if let Some(PossiblyRedactedPolicyRuleUserEventContent(prev_content)) = &self.prev_content {
            if let Some(prev_entity) = &prev_content.entity {
                if content.entity == *prev_entity {
                    return None;
                } else {
                    return Some("Changed".to_owned());
                }
            }
        }
        Some("Set".to_owned())
    }

    pub fn entity_new_val(&self) -> String {
        let PolicyRuleUserEventContent(content) = &self.content;
        content.entity.clone()
    }

    pub fn entity_old_val(&self) -> Option<String> {
        if let Some(PossiblyRedactedPolicyRuleUserEventContent(prev_content)) = &self.prev_content {
            prev_content.entity.clone()
        } else {
            None
        }
    }

    pub fn reason_change(&self) -> Option<String> {
        let PolicyRuleUserEventContent(content) = &self.content;
        if let Some(PossiblyRedactedPolicyRuleUserEventContent(prev_content)) = &self.prev_content {
            if let Some(prev_reason) = &prev_content.reason {
                if content.reason == *prev_reason {
                    return None;
                } else {
                    return Some("Changed".to_owned());
                }
            }
        }
        Some("Set".to_owned())
    }

    pub fn reason_new_val(&self) -> String {
        let PolicyRuleUserEventContent(content) = &self.content;
        content.reason.clone()
    }

    pub fn reason_old_val(&self) -> Option<String> {
        if let Some(PossiblyRedactedPolicyRuleUserEventContent(prev_content)) = &self.prev_content {
            prev_content.reason.clone()
        } else {
            None
        }
    }

    pub fn recommendation_change(&self) -> Option<String> {
        let PolicyRuleUserEventContent(content) = &self.content;
        if let Some(PossiblyRedactedPolicyRuleUserEventContent(prev_content)) = &self.prev_content {
            if let Some(prev_recommendation) = &prev_content.recommendation {
                if content.recommendation == *prev_recommendation {
                    return None;
                } else {
                    return Some("Changed".to_owned());
                }
            }
        }
        Some("Set".to_owned())
    }

    pub fn recommendation_new_val(&self) -> String {
        let PolicyRuleUserEventContent(content) = &self.content;
        content.recommendation.to_string()
    }

    pub fn recommendation_old_val(&self) -> Option<String> {
        if let Some(PossiblyRedactedPolicyRuleUserEventContent(prev_content)) = &self.prev_content {
            prev_content
                .recommendation
                .as_ref()
                .map(ToString::to_string)
        } else {
            None
        }
    }
}

// m.room.avatar
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct RoomAvatarContent {
    content: RoomAvatarEventContent,
    prev_content: Option<RoomAvatarEventContent>,
}

impl RoomAvatarContent {
    pub fn new(
        content: RoomAvatarEventContent,
        prev_content: Option<RoomAvatarEventContent>,
    ) -> Self {
        RoomAvatarContent {
            content,
            prev_content,
        }
    }

    pub fn url_change(&self) -> Option<String> {
        let prev_url = self.prev_content.as_ref().and_then(|prev| prev.url.clone());
        match (self.content.url.clone(), prev_url) {
            (Some(new_val), Some(old_val)) => {
                if new_val != old_val {
                    return Some("Changed".to_owned());
                }
            }
            (None, Some(_old_val)) => {
                return Some("Unset".to_owned());
            }
            (Some(_new_val), None) => {
                return Some("Set".to_owned());
            }
            (None, None) => {}
        }
        None
    }

    pub fn url_new_val(&self) -> Option<String> {
        self.content.url.as_ref().map(ToString::to_string)
    }

    pub fn url_old_val(&self) -> Option<String> {
        self.prev_content
            .as_ref()
            .and_then(|prev| prev.url.as_ref())
            .map(ToString::to_string)
    }
}

// m.room.create
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct RoomCreateContent {
    content: RoomCreateEventContent,
    prev_content: Option<RoomCreateEventContent>,
}

impl RoomCreateContent {
    pub fn new(
        content: RoomCreateEventContent,
        prev_content: Option<RoomCreateEventContent>,
    ) -> Self {
        RoomCreateContent {
            content,
            prev_content,
        }
    }
}

// m.room.encryption
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct RoomEncryptionContent {
    content: RoomEncryptionEventContent,
    prev_content: Option<PossiblyRedactedRoomEncryptionEventContent>,
}

impl RoomEncryptionContent {
    pub fn new(
        content: RoomEncryptionEventContent,
        prev_content: Option<PossiblyRedactedRoomEncryptionEventContent>,
    ) -> Self {
        RoomEncryptionContent {
            content,
            prev_content,
        }
    }

    pub fn algorithm_change(&self) -> Option<String> {
        if let Some(prev_algorithm) = self
            .prev_content
            .as_ref()
            .and_then(|prev| prev.algorithm.as_ref())
        {
            if self.content.algorithm == *prev_algorithm {
                return None;
            } else {
                return Some("Changed".to_owned());
            }
        }
        Some("Set".to_owned())
    }

    pub fn algorithm_new_val(&self) -> String {
        self.content.algorithm.to_string()
    }

    pub fn algorithm_old_val(&self) -> Option<String> {
        self.prev_content
            .as_ref()
            .and_then(|prev| prev.algorithm.as_ref())
            .map(ToString::to_string)
    }
}

// m.room.guest_access
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct RoomGuestAccessContent {
    content: RoomGuestAccessEventContent,
    prev_content: Option<PossiblyRedactedRoomGuestAccessEventContent>,
}

impl RoomGuestAccessContent {
    pub fn new(
        content: RoomGuestAccessEventContent,
        prev_content: Option<PossiblyRedactedRoomGuestAccessEventContent>,
    ) -> Self {
        RoomGuestAccessContent {
            content,
            prev_content,
        }
    }

    pub fn change(&self) -> Option<String> {
        if let Some(prev_guest_access) = self
            .prev_content
            .as_ref()
            .and_then(|prev| prev.guest_access.as_ref())
        {
            if self.content.guest_access == *prev_guest_access {
                return None;
            } else {
                return Some("Changed".to_owned());
            }
        }
        Some("Set".to_owned())
    }

    pub fn new_val(&self) -> String {
        self.content.guest_access.to_string()
    }

    pub fn old_val(&self) -> Option<String> {
        self.prev_content
            .as_ref()
            .and_then(|prev| prev.guest_access.as_ref())
            .map(ToString::to_string)
    }
}

// m.room.history_visibility
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct RoomHistoryVisibilityContent {
    content: RoomHistoryVisibilityEventContent,
    prev_content: Option<RoomHistoryVisibilityEventContent>,
}

impl RoomHistoryVisibilityContent {
    pub fn new(
        content: RoomHistoryVisibilityEventContent,
        prev_content: Option<RoomHistoryVisibilityEventContent>,
    ) -> Self {
        RoomHistoryVisibilityContent {
            content,
            prev_content,
        }
    }

    pub fn change(&self) -> Option<String> {
        if let Some(prev_content) = &self.prev_content {
            if self.content.history_visibility == prev_content.history_visibility {
                None
            } else {
                Some("Changed".to_owned())
            }
        } else {
            Some("Set".to_owned())
        }
    }

    pub fn new_val(&self) -> String {
        self.content.history_visibility.to_string()
    }

    pub fn old_val(&self) -> Option<String> {
        self.prev_content
            .as_ref()
            .map(|prev| prev.history_visibility.to_string())
    }
}

// m.room.join_rules
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct RoomJoinRulesContent {
    content: RoomJoinRulesEventContent,
    prev_content: Option<RoomJoinRulesEventContent>,
}

impl RoomJoinRulesContent {
    pub fn new(
        content: RoomJoinRulesEventContent,
        prev_content: Option<RoomJoinRulesEventContent>,
    ) -> Self {
        RoomJoinRulesContent {
            content,
            prev_content,
        }
    }

    pub fn change(&self) -> Option<String> {
        if let Some(prev_content) = &self.prev_content {
            if self.content.join_rule == prev_content.join_rule {
                None
            } else {
                Some("Changed".to_owned())
            }
        } else {
            Some("Set".to_owned())
        }
    }

    pub fn new_val(&self) -> String {
        self.content.join_rule.as_str().to_owned()
    }

    pub fn old_val(&self) -> Option<String> {
        self.prev_content
            .as_ref()
            .map(|prev| prev.join_rule.as_str().to_owned())
    }
}

// m.room.name
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct RoomNameContent {
    content: RoomNameEventContent,
    prev_content: Option<PossiblyRedactedRoomNameEventContent>,
}

impl RoomNameContent {
    pub fn new(
        content: RoomNameEventContent,
        prev_content: Option<PossiblyRedactedRoomNameEventContent>,
    ) -> Self {
        RoomNameContent {
            content,
            prev_content,
        }
    }

    pub fn change(&self) -> Option<String> {
        if let Some(prev_name) = self
            .prev_content
            .as_ref()
            .and_then(|prev| prev.name.as_ref())
        {
            if self.content.name == *prev_name {
                return None;
            } else {
                return Some("Changed".to_owned());
            }
        }
        Some("Set".to_owned())
    }

    pub fn new_val(&self) -> String {
        self.content.name.clone()
    }

    pub fn old_val(&self) -> Option<String> {
        self.prev_content
            .as_ref()
            .and_then(|prev| prev.name.clone())
    }
}

// m.room.pinned_events
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct RoomPinnedEventsContent {
    content: RoomPinnedEventsEventContent,
    prev_content: Option<PossiblyRedactedRoomPinnedEventsEventContent>,
}

impl RoomPinnedEventsContent {
    pub fn new(
        content: RoomPinnedEventsEventContent,
        prev_content: Option<PossiblyRedactedRoomPinnedEventsEventContent>,
    ) -> Self {
        RoomPinnedEventsContent {
            content,
            prev_content,
        }
    }

    pub fn change(&self) -> Option<String> {
        if let Some(prev_pinned) = self
            .prev_content
            .as_ref()
            .and_then(|prev| prev.pinned.as_ref())
        {
            if do_vecs_match(&self.content.pinned, prev_pinned) {
                None
            } else {
                Some("Changed".to_owned())
            }
        } else {
            Some("Set".to_owned())
        }
    }

    pub fn new_val(&self) -> Vec<String> {
        self.content
            .pinned
            .iter()
            .map(ToString::to_string)
            .collect::<Vec<String>>()
    }

    pub fn old_val(&self) -> Option<Vec<String>> {
        self.prev_content
            .as_ref()
            .and_then(|prev| prev.pinned.as_ref())
            .map(|pinned| {
                pinned
                    .iter()
                    .map(ToString::to_string)
                    .collect::<Vec<String>>()
            })
    }
}

// m.room.power_levels
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct RoomPowerLevelsContent {
    content: RoomPowerLevelsEventContent,
    prev_content: Option<RoomPowerLevelsEventContent>,
}

impl RoomPowerLevelsContent {
    pub fn new(
        content: RoomPowerLevelsEventContent,
        prev_content: Option<RoomPowerLevelsEventContent>,
    ) -> Self {
        RoomPowerLevelsContent {
            content,
            prev_content,
        }
    }

    pub fn ban_change(&self) -> Option<String> {
        if let Some(prev_content) = &self.prev_content {
            if self.content.ban == prev_content.ban {
                None
            } else {
                Some("Changed".to_owned())
            }
        } else {
            Some("Set".to_owned())
        }
    }

    pub fn ban_new_val(&self) -> i64 {
        self.content.ban.into()
    }

    pub fn ban_old_val(&self) -> Option<i64> {
        self.prev_content.as_ref().map(|prev| prev.ban.into())
    }

    pub fn events_change(&self, event_type: String) -> Option<String> {
        if let Some(prev_content) = &self.prev_content {
            let event_type = TimelineEventType::from(event_type);
            if self.content.events[&event_type] == prev_content.events[&event_type] {
                None
            } else {
                Some("Changed".to_owned())
            }
        } else {
            Some("Set".to_owned())
        }
    }

    pub fn events_new_val(&self, event_type: String) -> i64 {
        let key = TimelineEventType::from(event_type);
        self.content.events[&key].into()
    }

    pub fn events_old_val(&self, event_type: String) -> Option<i64> {
        let key = TimelineEventType::from(event_type);
        self.prev_content
            .as_ref()
            .map(|prev| prev.events[&key].into())
    }

    pub fn events_default_change(&self) -> Option<String> {
        if let Some(prev_content) = &self.prev_content {
            if self.content.events_default == prev_content.events_default {
                None
            } else {
                Some("Changed".to_owned())
            }
        } else {
            Some("Set".to_owned())
        }
    }

    pub fn events_default_new_val(&self) -> i64 {
        self.content.events_default.into()
    }

    pub fn events_default_old_val(&self) -> Option<i64> {
        self.prev_content
            .as_ref()
            .map(|prev| prev.events_default.into())
    }

    pub fn invite_change(&self) -> Option<String> {
        if let Some(prev_content) = &self.prev_content {
            if self.content.invite == prev_content.invite {
                None
            } else {
                Some("Changed".to_owned())
            }
        } else {
            Some("Set".to_owned())
        }
    }

    pub fn invite_new_val(&self) -> i64 {
        self.content.invite.into()
    }

    pub fn invite_old_val(&self) -> Option<i64> {
        self.prev_content.as_ref().map(|prev| prev.invite.into())
    }

    pub fn kick_change(&self) -> Option<String> {
        if let Some(prev_content) = &self.prev_content {
            if self.content.kick == prev_content.kick {
                None
            } else {
                Some("Changed".to_owned())
            }
        } else {
            Some("Set".to_owned())
        }
    }

    pub fn kick_new_val(&self) -> i64 {
        self.content.kick.into()
    }

    pub fn kick_old_val(&self) -> Option<i64> {
        self.prev_content.as_ref().map(|prev| prev.kick.into())
    }

    pub fn notifications_change(&self) -> Option<String> {
        if let Some(prev_content) = &self.prev_content {
            if self.content.notifications.room == prev_content.notifications.room {
                None
            } else {
                Some("Changed".to_owned())
            }
        } else {
            Some("Set".to_owned())
        }
    }

    pub fn notifications_new_val(&self) -> i64 {
        self.content.notifications.room.into()
    }

    pub fn notifications_old_val(&self) -> Option<i64> {
        self.prev_content
            .as_ref()
            .map(|prev| prev.notifications.room.into())
    }

    pub fn redact_change(&self) -> Option<String> {
        if let Some(prev_content) = &self.prev_content {
            if self.content.redact == prev_content.redact {
                None
            } else {
                Some("Changed".to_owned())
            }
        } else {
            Some("Set".to_owned())
        }
    }

    pub fn redact_new_val(&self) -> i64 {
        self.content.redact.into()
    }

    pub fn redact_old_val(&self) -> Option<i64> {
        self.prev_content.as_ref().map(|prev| prev.redact.into())
    }

    pub fn state_default_change(&self) -> Option<String> {
        if let Some(prev_content) = &self.prev_content {
            if self.content.state_default == prev_content.state_default {
                None
            } else {
                Some("Changed".to_owned())
            }
        } else {
            Some("Set".to_owned())
        }
    }

    pub fn state_default_new_val(&self) -> i64 {
        self.content.state_default.into()
    }

    pub fn state_default_old_val(&self) -> Option<i64> {
        self.prev_content
            .as_ref()
            .map(|prev| prev.state_default.into())
    }

    pub fn users_change(&self) -> Option<String> {
        if let Some(prev_content) = &self.prev_content {
            if self.content.users == prev_content.users {
                None
            } else {
                Some("Changed".to_owned())
            }
        } else {
            Some("Set".to_owned())
        }
    }

    pub fn users_default_change(&self) -> Option<String> {
        if let Some(prev_content) = &self.prev_content {
            if self.content.users_default == prev_content.users_default {
                None
            } else {
                Some("Changed".to_owned())
            }
        } else {
            Some("Set".to_owned())
        }
    }

    pub fn users_default_new_val(&self) -> i64 {
        self.content.users_default.into()
    }

    pub fn users_default_old_val(&self) -> Option<i64> {
        self.prev_content
            .as_ref()
            .map(|prev| prev.users_default.into())
    }
}

// m.room.server_acl
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct RoomServerAclContent {
    content: RoomServerAclEventContent,
    prev_content: Option<RoomServerAclEventContent>,
}

impl RoomServerAclContent {
    pub fn new(
        content: RoomServerAclEventContent,
        prev_content: Option<RoomServerAclEventContent>,
    ) -> Self {
        RoomServerAclContent {
            content,
            prev_content,
        }
    }

    pub fn allow_ip_literals_change(&self) -> Option<String> {
        if let Some(prev_content) = &self.prev_content {
            if self.content.allow_ip_literals == prev_content.allow_ip_literals {
                None
            } else {
                Some("Changed".to_owned())
            }
        } else {
            Some("Set".to_owned())
        }
    }

    pub fn allow_ip_literals_new_val(&self) -> bool {
        self.content.allow_ip_literals
    }

    pub fn allow_ip_literals_old_val(&self) -> Option<bool> {
        self.prev_content
            .as_ref()
            .map(|prev| prev.allow_ip_literals)
    }

    pub fn allow_change(&self) -> Option<String> {
        if let Some(prev_content) = &self.prev_content {
            if do_vecs_match(&self.content.allow, &prev_content.allow) {
                None
            } else {
                Some("Changed".to_owned())
            }
        } else {
            Some("Set".to_owned())
        }
    }

    pub fn allow_new_val(&self) -> Vec<String> {
        self.content.allow.clone()
    }

    pub fn allow_old_val(&self) -> Option<Vec<String>> {
        self.prev_content.as_ref().map(|prev| prev.allow.clone())
    }

    pub fn deny_change(&self) -> Option<String> {
        if let Some(prev_content) = &self.prev_content {
            if do_vecs_match(&self.content.deny, &prev_content.deny) {
                None
            } else {
                Some("Changed".to_owned())
            }
        } else {
            Some("Set".to_owned())
        }
    }

    pub fn deny_new_val(&self) -> Vec<String> {
        self.content.deny.clone()
    }

    pub fn deny_old_val(&self) -> Option<Vec<String>> {
        self.prev_content.as_ref().map(|prev| prev.deny.clone())
    }
}

// m.room.tombstone
#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct RoomTombstoneContent {
    content: RoomTombstoneEventContent,
    prev_content: Option<PossiblyRedactedRoomTombstoneEventContent>,
}

impl RoomTombstoneContent {
    pub fn new(
        content: RoomTombstoneEventContent,
        prev_content: Option<PossiblyRedactedRoomTombstoneEventContent>,
    ) -> Self {
        RoomTombstoneContent {
            content,
            prev_content,
        }
    }

    pub fn body_change(&self) -> Option<String> {
        if let Some(prev_body) = self
            .prev_content
            .as_ref()
            .and_then(|prev| prev.body.as_ref())
        {
            if self.content.body == *prev_body {
                return None;
            } else {
                return Some("Changed".to_owned());
            }
        }
        Some("Set".to_owned())
    }

    pub fn body_new_val(&self) -> String {
        self.content.body.clone()
    }

    pub fn body_old_val(&self) -> Option<String> {
        self.prev_content
            .as_ref()
            .and_then(|prev| prev.body.clone())
    }

    pub fn replacement_room_change(&self) -> Option<String> {
        if let Some(prev_replacement_room) = self
            .prev_content
            .as_ref()
            .and_then(|prev| prev.replacement_room.as_ref())
        {
            if self.content.replacement_room == *prev_replacement_room {
                return None;
            } else {
                return Some("Changed".to_owned());
            }
        }
        Some("Set".to_owned())
    }

    pub fn replacement_room_new_val(&self) -> String {
        self.content.replacement_room.to_string()
    }

    pub fn replacement_room_old_val(&self) -> Option<String> {
        self.prev_content
            .as_ref()
            .and_then(|prev| prev.replacement_room.as_ref())
            .map(ToString::to_string)
    }
}
