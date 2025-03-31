use acter_core::{
    models::status::membership::{MembershipChange, ProfileChange},
    util::do_vecs_match,
};
use anyhow::{bail, Result};
use chrono::{DateTime, Utc};
use derive_builder::Builder;
use indexmap::IndexMap;
use matrix_sdk::{room::Room, send_queue::SendHandle};
use matrix_sdk_base::ruma::{
    events::{
        policy::rule::{
            room::{PolicyRuleRoomEventContent, PossiblyRedactedPolicyRuleRoomEventContent},
            server::{PolicyRuleServerEventContent, PossiblyRedactedPolicyRuleServerEventContent},
            user::{PolicyRuleUserEventContent, PossiblyRedactedPolicyRuleUserEventContent},
        },
        receipt::Receipt,
        room::message::MessageType,
        FullStateEventContent,
    },
    OwnedEventId, OwnedRoomAliasId, OwnedTransactionId, OwnedUserId,
};
use matrix_sdk_ui::timeline::{
    AnyOtherFullStateEventContent, EventSendState as SdkEventSendState, EventTimelineItem,
    OtherState as SdkOtherState, TimelineEventItemId, TimelineItem as SdkTimelineItem,
    TimelineItemContent as SdkTimelineItemContent, TimelineItemKind, VirtualTimelineItem,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tracing::info;

use super::{
    room_event::{PollContent, Sticker, TimelineEventContent},
    room_state::{
        OtherState, PolicyRuleRoomContent, PolicyRuleServerContent, PolicyRuleUserContent,
        RoomAliasesContent, RoomAvatarContent, RoomCanonicalAliasContent, RoomCreateContent,
        RoomEncryptionContent, RoomGuestAccessContent, RoomHistoryVisibilityContent,
        RoomJoinRulesContent, RoomNameContent, RoomPinnedEventsContent, RoomPowerLevelsContent,
        RoomServerAclContent, RoomThirdPartyInviteContent, RoomTombstoneContent, RoomTopicContent,
        SpaceChildContent, SpaceParentContent,
    },
};

use crate::{MsgContent, ReactionRecord, RUNTIME};

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct EventSendState {
    state: String,
    error: Option<String>,
    event_id: Option<OwnedEventId>,
    #[serde(default, skip)]
    send_handle: Option<SendHandle>,
}

impl EventSendState {
    fn new(inner: &SdkEventSendState, send_handle: Option<SendHandle>) -> Self {
        let (state, error, event_id) = match inner {
            SdkEventSendState::NotSentYet => ("NotSentYet".to_string(), None, None),
            SdkEventSendState::SendingFailed {
                error,
                is_recoverable,
            } => (
                "SendingFailed".to_string(),
                Some(error.to_owned().to_string()),
                None,
            ),

            SdkEventSendState::Sent { event_id } => {
                ("Sent".to_string(), None, Some(event_id.clone()))
            }
        };
        EventSendState {
            state,
            error,
            event_id,
            send_handle,
        }
    }

    pub fn state(&self) -> String {
        self.state.clone()
    }

    pub fn error(&self) -> Option<String> {
        self.error.clone()
    }

    pub fn event_id(&self) -> Option<OwnedEventId> {
        self.event_id.clone()
    }

    pub async fn abort(&self) -> Result<bool> {
        let Some(handle) = self.send_handle.clone() else {
            bail!("No send handle found");
        };

        RUNTIME
            .spawn(async move {
                let result = handle.abort().await?;
                Ok(result)
            })
            .await?
    }
}

#[derive(Clone, Debug, Serialize, Deserialize, Builder)]
#[builder(derive(Debug))]
pub struct TimelineEventItem {
    #[builder(default)]
    event_id: Option<OwnedEventId>,
    #[builder(default)]
    txn_id: Option<OwnedTransactionId>,
    sender: OwnedUserId,
    #[builder(default)]
    send_state: Option<EventSendState>,
    origin_server_ts: u64,
    #[builder(default)]
    msg_type: Option<String>,
    #[builder(default)]
    content: Option<TimelineEventContent>,
    #[builder(default)]
    in_reply_to: Option<OwnedEventId>,
    #[builder(default)]
    read_receipts: IndexMap<String, Receipt>,
    #[builder(default)]
    reactions: IndexMap<String, Vec<ReactionRecord>>,
    #[builder(default)]
    editable: bool,
    #[builder(default)]
    edited: bool,
}

impl TimelineEventItem {
    pub(crate) fn new(event: &EventTimelineItem, my_id: OwnedUserId) -> Self {
        let mut me = TimelineEventItemBuilder::default();

        me.event_id(event.event_id().map(ToOwned::to_owned))
            .txn_id(event.transaction_id().map(ToOwned::to_owned))
            .sender(event.sender().to_owned())
            .send_state(
                event
                    .send_state()
                    .map(|s| EventSendState::new(s, event.local_echo_send_handle())),
            )
            .origin_server_ts(event.timestamp().get().into())
            .read_receipts(
                event
                    .read_receipts()
                    .iter()
                    .map(|(u, receipt)| (u.to_string(), receipt.clone()))
                    .collect(),
            )
            .reactions(
                event
                    .content()
                    .reactions()
                    .iter()
                    .map(|(key, group)| {
                        (
                            key.clone(),
                            group
                                .iter()
                                .map(|(sender_id, info)| {
                                    ReactionRecord::new(
                                        sender_id.clone(),
                                        info.timestamp,
                                        *sender_id == my_id,
                                    )
                                })
                                .collect::<Vec<ReactionRecord>>(),
                        )
                    })
                    .collect(),
            )
            .editable(event.is_editable()); // which means _images_ can't be edited right now ... but that is probably fine

        match event.content() {
            SdkTimelineItemContent::Message(msg) => {
                let msg_type = msg.msgtype();
                me.msg_type(Some(msg_type.msgtype().to_string()));
                let content = match msg_type {
                    MessageType::Text(content) => {
                        Some(TimelineEventContent::Message(MsgContent::from(content)))
                    }
                    MessageType::Emote(content) => {
                        Some(TimelineEventContent::Message(MsgContent::from(content)))
                    }
                    MessageType::Image(content) => {
                        Some(TimelineEventContent::Message(MsgContent::from(content)))
                    }
                    MessageType::Audio(content) => {
                        Some(TimelineEventContent::Message(MsgContent::from(content)))
                    }
                    MessageType::Video(content) => {
                        Some(TimelineEventContent::Message(MsgContent::from(content)))
                    }
                    MessageType::File(content) => {
                        Some(TimelineEventContent::Message(MsgContent::from(content)))
                    }
                    MessageType::Location(content) => {
                        Some(TimelineEventContent::Message(MsgContent::from(content)))
                    }
                    MessageType::Notice(content) => {
                        Some(TimelineEventContent::Message(MsgContent::from(content)))
                    }
                    MessageType::ServerNotice(content) => {
                        Some(TimelineEventContent::Message(MsgContent::from(content)))
                    }
                    _ => None,
                };
                me.content(content);
                if let Some(in_reply_to) = msg.in_reply_to() {
                    me.in_reply_to(Some(in_reply_to.clone().event_id));
                }
                me.edited(msg.is_edited());
            }
            SdkTimelineItemContent::RedactedMessage => {
                info!("Edit event applies to a redacted message");
                me.content(Some(TimelineEventContent::RedactedMessage));
            }
            SdkTimelineItemContent::Sticker(s) => {
                // FIXME: proper sticker support needed
                // me.msg_content(Some(MsgContent::from(s.content())));
                if let Ok(c) = Sticker::try_from(s) {
                    me.content(Some(TimelineEventContent::Sticker(c)));
                }
            }
            SdkTimelineItemContent::UnableToDecrypt(encrypted_msg) => {
                info!("Edit event applies to event that couldn’t be decrypted");
                me.content(Some(TimelineEventContent::UnableToDecrypt));
            }
            SdkTimelineItemContent::MembershipChange(m) => {
                info!("Edit event applies to a state event");
                let c = MembershipChange::from(m);
                me.content(Some(TimelineEventContent::MembershipChange(c)));
            }
            SdkTimelineItemContent::ProfileChange(p) => {
                info!("Edit event applies to a state event");
                let c = ProfileChange::from(p);
                me.content(Some(TimelineEventContent::ProfileChange(c)));
            }
            SdkTimelineItemContent::OtherState(s) => {
                info!("Edit event applies to a state event");
                if let Some(c) = me.handle_other_state(s) {
                    me.content(Some(TimelineEventContent::OtherState(c)));
                }
            }
            SdkTimelineItemContent::FailedToParseMessageLike { event_type, error } => {
                info!("Edit event applies to message that couldn’t be parsed");
                me.content(Some(TimelineEventContent::FailedToParseMessageLike {
                    event_type: event_type.clone(),
                    error: error.to_string(),
                }));
            }
            SdkTimelineItemContent::FailedToParseState {
                event_type,
                state_key,
                error,
            } => {
                info!("Edit event applies to state that couldn’t be parsed");
                me.content(Some(TimelineEventContent::FailedToParseState {
                    event_type: event_type.clone(),
                    state_key: state_key.clone(),
                    error: error.to_string(),
                }));
            }
            SdkTimelineItemContent::Poll(p) => {
                info!("Edit event applies to a poll state");
                let c = PollContent::from(p);
                me.content(Some(TimelineEventContent::Poll(c)));
            }
            SdkTimelineItemContent::CallInvite => {
                me.content(Some(TimelineEventContent::CallInvite));
            }
            SdkTimelineItemContent::CallNotify => {
                me.content(Some(TimelineEventContent::CallNotify));
            }
        };
        me.build().expect("Building Room Event doesn’t fail")
    }

    pub fn event_id(&self) -> Option<String> {
        self.event_id.as_ref().map(ToString::to_string)
    }

    pub fn sender(&self) -> String {
        self.sender.to_string()
    }

    pub fn send_state(&self) -> Option<EventSendState> {
        self.send_state.clone()
    }

    pub fn origin_server_ts(&self) -> u64 {
        self.origin_server_ts
    }

    pub fn event_type(&self) -> String {
        if let Some(content) = &self.content {
            return match content {
                TimelineEventContent::Message(_) => "m.room.message".to_owned(),
                TimelineEventContent::RedactedMessage => "m.room.redaction".to_owned(),
                TimelineEventContent::Sticker(_) => "m.sticker".to_owned(),
                TimelineEventContent::UnableToDecrypt => "m.room.encrypted".to_owned(),
                TimelineEventContent::MembershipChange(_) => "membershipChange".to_owned(), // some of m.room.member
                TimelineEventContent::ProfileChange(_) => "profileChange".to_owned(), // some of m.room.member
                TimelineEventContent::OtherState(OtherState::PolicyRuleRoom(_)) => {
                    "m.policy.rule.room".to_owned()
                }
                TimelineEventContent::OtherState(OtherState::PolicyRuleServer(_)) => {
                    "m.policy.rule.server".to_owned()
                }
                TimelineEventContent::OtherState(OtherState::PolicyRuleUser(_)) => {
                    "m.policy.rule.user".to_owned()
                }
                TimelineEventContent::OtherState(OtherState::RoomAliases(_)) => {
                    "m.room.aliases".to_owned()
                }
                TimelineEventContent::OtherState(OtherState::RoomAvatar(_)) => {
                    "m.room.avatar".to_owned()
                }
                TimelineEventContent::OtherState(OtherState::RoomCanonicalAlias(_)) => {
                    "m.room.canonical_alias".to_owned()
                }
                TimelineEventContent::OtherState(OtherState::RoomCreate(_)) => {
                    "m.room.create".to_owned()
                }
                TimelineEventContent::OtherState(OtherState::RoomEncryption(_)) => {
                    "m.room.encryption".to_owned()
                }
                TimelineEventContent::OtherState(OtherState::RoomGuestAccess(_)) => {
                    "m.room.guest_access".to_owned()
                }
                TimelineEventContent::OtherState(OtherState::RoomHistoryVisibility(_)) => {
                    "m.room.history_visibility".to_owned()
                }
                TimelineEventContent::OtherState(OtherState::RoomJoinRules(_)) => {
                    "m.room.join_rules".to_owned()
                }
                TimelineEventContent::OtherState(OtherState::RoomName(_)) => {
                    "m.room.name".to_owned()
                }
                TimelineEventContent::OtherState(OtherState::RoomPinnedEvents(_)) => {
                    "m.room.pinned_events".to_owned()
                }
                TimelineEventContent::OtherState(OtherState::RoomPowerLevels(_)) => {
                    "m.room.power_levels".to_owned()
                }
                TimelineEventContent::OtherState(OtherState::RoomServerAcl(_)) => {
                    "m.room.server_acl".to_owned()
                }
                TimelineEventContent::OtherState(OtherState::RoomThirdPartyInvite(_)) => {
                    "m.room.third_party_invite".to_owned()
                }
                TimelineEventContent::OtherState(OtherState::RoomTombstone(_)) => {
                    "m.room.tombstone".to_owned()
                }
                TimelineEventContent::OtherState(OtherState::RoomTopic(_)) => {
                    "m.room.topic".to_owned()
                }
                TimelineEventContent::OtherState(OtherState::SpaceChild(_)) => {
                    "m.space.child".to_owned()
                }
                TimelineEventContent::OtherState(OtherState::SpaceParent(_)) => {
                    "m.space.parent".to_owned()
                }
                TimelineEventContent::FailedToParseMessageLike { event_type, .. } => {
                    event_type.to_string()
                }
                TimelineEventContent::FailedToParseState { event_type, .. } => {
                    event_type.to_string()
                }
                TimelineEventContent::Poll(_) => "m.poll.start".to_owned(),
                TimelineEventContent::CallInvite => "m.call_invite".to_owned(),
                TimelineEventContent::CallNotify => "m.call_notify".to_owned(),
            };
        }
        "".to_owned()
    }

    pub fn msg_type(&self) -> Option<String> {
        self.msg_type.clone()
    }

    pub fn message(&self) -> Option<MsgContent> {
        if let Some(TimelineEventContent::Message(c)) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn sticker(&self) -> Option<Sticker> {
        if let Some(TimelineEventContent::Sticker(c)) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn membership_change(&self) -> Option<MembershipChange> {
        if let Some(TimelineEventContent::MembershipChange(c)) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn profile_change(&self) -> Option<ProfileChange> {
        if let Some(TimelineEventContent::ProfileChange(c)) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn poll(&self) -> Option<PollContent> {
        if let Some(TimelineEventContent::Poll(c)) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn in_reply_to(&self) -> Option<String> {
        self.in_reply_to.as_ref().map(|x| x.to_string())
    }

    pub fn read_users(&self) -> Vec<String> {
        // don’t use cloned().
        // create string vector to deallocate string item using toDartString().
        // apply this way for only function that string vector is calculated indirectly.
        let mut users = vec![];
        for seen_by in self.read_receipts.keys() {
            users.push(seen_by.to_string());
        }
        users
    }

    pub fn receipt_ts(&self, seen_by: String) -> Option<u64> {
        if self.read_receipts.contains_key(&seen_by) {
            self.read_receipts[&seen_by].ts.map(|x| x.get().into())
        } else {
            None
        }
    }

    pub fn reaction_keys(&self) -> Vec<String> {
        // don’t use cloned().
        // create string vector to deallocate string item using toDartString().
        // apply this way for only function that string vector is calculated indirectly.
        let mut keys = vec![];
        for key in self.reactions.keys() {
            keys.push(key.to_owned());
        }
        keys
    }

    pub fn reaction_records(&self, key: String) -> Option<Vec<ReactionRecord>> {
        if self.reactions.contains_key(&key) {
            Some(self.reactions[&key].clone())
        } else {
            None
        }
    }

    pub fn is_editable(&self) -> bool {
        self.editable
    }

    pub fn was_edited(&self) -> bool {
        self.edited
    }
}

// room state change
impl TimelineEventItem {
    pub fn policy_rule_room(&self) -> Option<PolicyRuleRoomContent> {
        if let Some(TimelineEventContent::OtherState(OtherState::PolicyRuleRoom(c))) = &self.content
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn policy_rule_server(&self) -> Option<PolicyRuleServerContent> {
        if let Some(TimelineEventContent::OtherState(OtherState::PolicyRuleServer(c))) =
            &self.content
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn policy_rule_user(&self) -> Option<PolicyRuleUserContent> {
        if let Some(TimelineEventContent::OtherState(OtherState::PolicyRuleUser(c))) = &self.content
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_aliases(&self) -> Option<RoomAliasesContent> {
        if let Some(TimelineEventContent::OtherState(OtherState::RoomAliases(c))) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_avatar(&self) -> Option<RoomAvatarContent> {
        if let Some(TimelineEventContent::OtherState(OtherState::RoomAvatar(c))) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_canonical_alias(&self) -> Option<RoomCanonicalAliasContent> {
        if let Some(TimelineEventContent::OtherState(OtherState::RoomCanonicalAlias(c))) =
            &self.content
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_create(&self) -> Option<RoomCreateContent> {
        if let Some(TimelineEventContent::OtherState(OtherState::RoomCreate(c))) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_encryption(&self) -> Option<RoomEncryptionContent> {
        if let Some(TimelineEventContent::OtherState(OtherState::RoomEncryption(c))) = &self.content
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_guest_access(&self) -> Option<RoomGuestAccessContent> {
        if let Some(TimelineEventContent::OtherState(OtherState::RoomGuestAccess(c))) =
            &self.content
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_history_visibility(&self) -> Option<RoomHistoryVisibilityContent> {
        if let Some(TimelineEventContent::OtherState(OtherState::RoomHistoryVisibility(c))) =
            &self.content
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_join_rules(&self) -> Option<RoomJoinRulesContent> {
        if let Some(TimelineEventContent::OtherState(OtherState::RoomJoinRules(c))) = &self.content
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_name(&self) -> Option<RoomNameContent> {
        if let Some(TimelineEventContent::OtherState(OtherState::RoomName(c))) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_pinned_events(&self) -> Option<RoomPinnedEventsContent> {
        if let Some(TimelineEventContent::OtherState(OtherState::RoomPinnedEvents(c))) =
            &self.content
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_power_levels(&self) -> Option<RoomPowerLevelsContent> {
        if let Some(TimelineEventContent::OtherState(OtherState::RoomPowerLevels(c))) =
            &self.content
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_server_acl(&self) -> Option<RoomServerAclContent> {
        if let Some(TimelineEventContent::OtherState(OtherState::RoomServerAcl(c))) = &self.content
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_third_party_invite(&self) -> Option<RoomThirdPartyInviteContent> {
        if let Some(TimelineEventContent::OtherState(OtherState::RoomThirdPartyInvite(c))) =
            &self.content
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_tombstone(&self) -> Option<RoomTombstoneContent> {
        if let Some(TimelineEventContent::OtherState(OtherState::RoomTombstone(c))) = &self.content
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_topic(&self) -> Option<RoomTopicContent> {
        if let Some(TimelineEventContent::OtherState(OtherState::RoomTopic(c))) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn space_child(&self) -> Option<SpaceChildContent> {
        if let Some(TimelineEventContent::OtherState(OtherState::SpaceChild(c))) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn space_parent(&self) -> Option<SpaceParentContent> {
        if let Some(TimelineEventContent::OtherState(OtherState::SpaceParent(c))) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }
}

impl TimelineEventItemBuilder {
    fn handle_other_state(&mut self, state: &SdkOtherState) -> Option<OtherState> {
        match state.content() {
            AnyOtherFullStateEventContent::PolicyRuleRoom(c) => match c {
                FullStateEventContent::Original {
                    content,
                    prev_content,
                } => {
                    let c = PolicyRuleRoomContent::new(content.clone(), prev_content.clone());
                    Some(OtherState::PolicyRuleRoom(c))
                }
                FullStateEventContent::Redacted(r) => None,
            },
            AnyOtherFullStateEventContent::PolicyRuleServer(c) => match c {
                FullStateEventContent::Original {
                    content,
                    prev_content,
                } => {
                    let c = PolicyRuleServerContent::new(content.clone(), prev_content.clone());
                    Some(OtherState::PolicyRuleServer(c))
                }
                FullStateEventContent::Redacted(r) => None,
            },
            AnyOtherFullStateEventContent::PolicyRuleUser(c) => match c {
                FullStateEventContent::Original {
                    content,
                    prev_content,
                } => {
                    let c = PolicyRuleUserContent::new(content.clone(), prev_content.clone());
                    Some(OtherState::PolicyRuleUser(c))
                }
                FullStateEventContent::Redacted(r) => None,
            },
            AnyOtherFullStateEventContent::RoomAliases(c) => match c {
                FullStateEventContent::Original {
                    content,
                    prev_content,
                } => {
                    let c = RoomAliasesContent::new(content.clone(), prev_content.clone());
                    Some(OtherState::RoomAliases(c))
                }
                FullStateEventContent::Redacted(r) => None,
            },
            AnyOtherFullStateEventContent::RoomAvatar(c) => match c {
                FullStateEventContent::Original {
                    content,
                    prev_content,
                } => {
                    let c = RoomAvatarContent::new(content.clone(), prev_content.clone());
                    Some(OtherState::RoomAvatar(c))
                }
                FullStateEventContent::Redacted(r) => None,
            },
            AnyOtherFullStateEventContent::RoomCanonicalAlias(c) => match c {
                FullStateEventContent::Original {
                    content,
                    prev_content,
                } => {
                    let c = RoomCanonicalAliasContent::new(content.clone(), prev_content.clone());
                    Some(OtherState::RoomCanonicalAlias(c))
                }
                FullStateEventContent::Redacted(r) => None,
            },
            AnyOtherFullStateEventContent::RoomCreate(c) => match c {
                FullStateEventContent::Original {
                    content,
                    prev_content,
                } => {
                    let c = RoomCreateContent::new(content.clone(), prev_content.clone());
                    Some(OtherState::RoomCreate(c))
                }
                FullStateEventContent::Redacted(r) => None,
            },
            AnyOtherFullStateEventContent::RoomEncryption(c) => match c {
                FullStateEventContent::Original {
                    content,
                    prev_content,
                } => {
                    let c = RoomEncryptionContent::new(content.clone(), prev_content.clone());
                    Some(OtherState::RoomEncryption(c))
                }
                FullStateEventContent::Redacted(r) => None,
            },
            AnyOtherFullStateEventContent::RoomGuestAccess(c) => match c {
                FullStateEventContent::Original {
                    content,
                    prev_content,
                } => {
                    let c = RoomGuestAccessContent::new(content.clone(), prev_content.clone());
                    Some(OtherState::RoomGuestAccess(c))
                }
                FullStateEventContent::Redacted(r) => None,
            },
            AnyOtherFullStateEventContent::RoomHistoryVisibility(c) => match c {
                FullStateEventContent::Original {
                    content,
                    prev_content,
                } => {
                    let c =
                        RoomHistoryVisibilityContent::new(content.clone(), prev_content.clone());
                    Some(OtherState::RoomHistoryVisibility(c))
                }
                FullStateEventContent::Redacted(r) => None,
            },
            AnyOtherFullStateEventContent::RoomJoinRules(c) => match c {
                FullStateEventContent::Original {
                    content,
                    prev_content,
                } => {
                    let c = RoomJoinRulesContent::new(content.clone(), prev_content.clone());
                    Some(OtherState::RoomJoinRules(c))
                }
                FullStateEventContent::Redacted(r) => None,
            },
            AnyOtherFullStateEventContent::RoomName(c) => match c {
                FullStateEventContent::Original {
                    content,
                    prev_content,
                } => {
                    let c = RoomNameContent::new(content.clone(), prev_content.clone());
                    Some(OtherState::RoomName(c))
                }
                FullStateEventContent::Redacted(r) => None,
            },
            AnyOtherFullStateEventContent::RoomPinnedEvents(c) => match c {
                FullStateEventContent::Original {
                    content,
                    prev_content,
                } => {
                    let c = RoomPinnedEventsContent::new(content.clone(), prev_content.clone());
                    Some(OtherState::RoomPinnedEvents(c))
                }
                FullStateEventContent::Redacted(r) => None,
            },
            AnyOtherFullStateEventContent::RoomPowerLevels(c) => match c {
                FullStateEventContent::Original {
                    content,
                    prev_content,
                } => {
                    let c = RoomPowerLevelsContent::new(content.clone(), prev_content.clone());
                    Some(OtherState::RoomPowerLevels(c))
                }
                FullStateEventContent::Redacted(r) => None,
            },
            AnyOtherFullStateEventContent::RoomServerAcl(c) => match c {
                FullStateEventContent::Original {
                    content,
                    prev_content,
                } => {
                    let c = RoomServerAclContent::new(content.clone(), prev_content.clone());
                    Some(OtherState::RoomServerAcl(c))
                }
                FullStateEventContent::Redacted(r) => None,
            },
            AnyOtherFullStateEventContent::RoomThirdPartyInvite(c) => match c {
                FullStateEventContent::Original {
                    content,
                    prev_content,
                } => {
                    let c = RoomThirdPartyInviteContent::new(content.clone(), prev_content.clone());
                    Some(OtherState::RoomThirdPartyInvite(c))
                }
                FullStateEventContent::Redacted(r) => None,
            },
            AnyOtherFullStateEventContent::RoomTombstone(c) => match c {
                FullStateEventContent::Original {
                    content,
                    prev_content,
                } => {
                    let c = RoomTombstoneContent::new(content.clone(), prev_content.clone());
                    Some(OtherState::RoomTombstone(c))
                }
                FullStateEventContent::Redacted(r) => None,
            },
            AnyOtherFullStateEventContent::RoomTopic(c) => match c {
                FullStateEventContent::Original {
                    content,
                    prev_content,
                } => {
                    let c = RoomTopicContent::new(content.clone(), prev_content.clone());
                    Some(OtherState::RoomTopic(c))
                }
                FullStateEventContent::Redacted(r) => None,
            },
            AnyOtherFullStateEventContent::SpaceChild(c) => match c {
                FullStateEventContent::Original {
                    content,
                    prev_content,
                } => {
                    let c = SpaceChildContent::new(content.clone(), prev_content.clone());
                    Some(OtherState::SpaceChild(c))
                }
                FullStateEventContent::Redacted(r) => None,
            },
            AnyOtherFullStateEventContent::SpaceParent(c) => match c {
                FullStateEventContent::Original {
                    content,
                    prev_content,
                } => {
                    let c = SpaceParentContent::new(content.clone(), prev_content.clone());
                    Some(OtherState::SpaceParent(c))
                }
                FullStateEventContent::Redacted(r) => None,
            },
            _ => None,
        }
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct TimelineVirtualItem {
    event_type: String,
    description: Option<String>,
}

impl From<&VirtualTimelineItem> for TimelineVirtualItem {
    fn from(value: &VirtualTimelineItem) -> TimelineVirtualItem {
        match value {
            VirtualTimelineItem::DateDivider(ts) => {
                let description = if let Some(st) = ts.to_system_time() {
                    let dt: DateTime<Utc> = st.into();
                    Some(dt.format("%Y-%m-%d").to_string())
                } else {
                    None
                };
                TimelineVirtualItem {
                    event_type: "DayDivider".to_owned(),
                    description,
                }
            }
            VirtualTimelineItem::ReadMarker => TimelineVirtualItem {
                event_type: "ReadMarker".to_owned(),
                description: None,
            },
        }
    }
}

impl TimelineVirtualItem {
    pub fn event_type(&self) -> String {
        self.event_type.clone()
    }

    pub fn description(&self) -> Option<String> {
        self.description.clone()
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
enum TimelineItemContent {
    Event(TimelineEventItem),
    Virtual(TimelineVirtualItem),
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct TimelineItem {
    content: TimelineItemContent,
    unique_id: String,
}

impl TimelineItem {
    pub(crate) fn new_event_item(event_item: &EventTimelineItem, my_id: OwnedUserId) -> Self {
        TimelineItem {
            content: TimelineItemContent::Event(TimelineEventItem::new(event_item, my_id)),
            unique_id: match event_item.identifier() {
                TimelineEventItemId::EventId(e) => e.to_string(),
                TimelineEventItemId::TransactionId(t) => t.to_string(),
            },
        }
    }

    pub fn is_virtual(&self) -> bool {
        if let TimelineItemContent::Virtual(content) = &self.content {
            true
        } else {
            false
        }
    }

    pub fn event_item(&self) -> Option<TimelineEventItem> {
        if let TimelineItemContent::Event(content) = &self.content {
            Some(content.clone())
        } else {
            None
        }
    }

    pub(crate) fn event_id(&self) -> Option<String> {
        if let TimelineItemContent::Event(content) = &self.content {
            content.event_id()
        } else {
            None
        }
    }

    pub fn unique_id(&self) -> String {
        self.unique_id.clone()
    }

    pub(crate) fn event_type(&self) -> String {
        match &self.content {
            TimelineItemContent::Event(content) => content.event_type(),
            TimelineItemContent::Virtual(content) => content.event_type(),
        }
    }

    pub(crate) fn origin_server_ts(&self) -> Option<u64> {
        if let TimelineItemContent::Event(content) = &self.content {
            Some(content.origin_server_ts())
        } else {
            None
        }
    }

    pub fn virtual_item(&self) -> Option<TimelineVirtualItem> {
        if let TimelineItemContent::Virtual(content) = &self.content {
            Some(content.clone())
        } else {
            None
        }
    }
}

impl From<(Arc<SdkTimelineItem>, OwnedUserId)> for TimelineItem {
    fn from(value: (Arc<SdkTimelineItem>, OwnedUserId)) -> TimelineItem {
        let (item, my_id) = value;
        match item.kind() {
            TimelineItemKind::Event(event_item) => TimelineItem::new_event_item(event_item, my_id),
            TimelineItemKind::Virtual(virtual_item) => TimelineItem {
                content: TimelineItemContent::Virtual(TimelineVirtualItem::from(virtual_item)),
                unique_id: item.unique_id().0.clone(),
            },
        }
    }
}
