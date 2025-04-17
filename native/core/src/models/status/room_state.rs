use matrix_sdk_base::ruma::events::policy::rule::room::{
    PolicyRuleRoomEventContent, PossiblyRedactedPolicyRuleRoomEventContent,
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
