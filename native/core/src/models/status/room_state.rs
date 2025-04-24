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
    },
};
use serde::{Deserialize, Serialize};

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
