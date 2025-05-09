use acter_core::{
    models::status::{
        MembershipContent, PolicyRuleRoomContent, PolicyRuleServerContent, PolicyRuleUserContent,
        ProfileContent, RoomAvatarContent, RoomCreateContent, RoomEncryptionContent,
        RoomGuestAccessContent, RoomHistoryVisibilityContent, RoomJoinRulesContent,
        RoomNameContent, RoomPinnedEventsContent, RoomPowerLevelsContent, RoomServerAclContent,
        RoomTombstoneContent, RoomTopicContent, SpaceChildContent, SpaceParentContent,
    },
    util::do_vecs_match,
};
use anyhow::{bail, Result};
use chrono::{DateTime, Utc};
use derive_builder::Builder;
use futures::stream::Any;
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
    AnyOtherFullStateEventContent, EventSendState as SdkEventSendState, EventTimelineItem, MsgLikeContent, MsgLikeKind, OtherState, RepliedToEvent, TimelineDetails, TimelineEventItemId, TimelineItem as SdkTimelineItem, TimelineItemContent as SdkTimelineItemContent, TimelineItemKind, VirtualTimelineItem
};
use serde::{Deserialize, Serialize};
use std::{ops::Deref, sync::Arc};
use tracing::info;

use super::{MsgContent, TimelineEventContent};
use crate::{ReactionRecord, RUNTIME};

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
    event_type: String,
    #[builder(default)]
    msg_type: Option<String>,
    #[builder(default)]
    content: Option<TimelineEventContent>,
    #[builder(default)]
    in_reply_to_id: Option<OwnedEventId>,
    #[builder(default)]
    in_reply_to_event: Option<Box<TimelineEventItem>>,
    #[builder(default)]
    read_receipts: IndexMap<String, Receipt>,
    #[builder(default)]
    reactions: IndexMap<String, Vec<ReactionRecord>>,
    #[builder(default)]
    editable: bool,
    #[builder(default)]
    edited: bool,
}

impl TimelineEventItemBuilder {

    fn parse_content(self: &mut TimelineEventItemBuilder, content: &SdkTimelineItemContent, when: u64, my_id: OwnedUserId) {
        self.origin_server_ts(when);
        match content {
            SdkTimelineItemContent::MsgLike(msg_like) => match &msg_like.kind {
                MsgLikeKind::Message(msg) => {
                    self.event_type("m.room.message".to_owned());
                    let msg_type = msg.msgtype();
                    self.msg_type(Some(msg_type.msgtype().to_string()));
                    self.content(TimelineEventContent::try_from(msg_type).ok());
                    if let Some(in_reply_to) = &msg_like.in_reply_to {
                        self.in_reply_to_id(Some(in_reply_to.event_id.clone()));
                        if let TimelineDetails::Ready(event) = &in_reply_to.event {
                            self.in_reply_to_event(Some(Box::new(TimelineEventItem::new_replied_to(&event, in_reply_to.event_id.clone(), when, my_id))));
                        }
                    }
                    self.edited(msg.is_edited());
                }
                MsgLikeKind::Redacted => {
                    info!("Edit event applies to a redacted message");
                    self.event_type("m.room.redaction".to_string());
                }
                MsgLikeKind::Sticker(s) => {
                    self.event_type("m.sticker".to_string());
                    // FIXME: proper sticker support needed
                    // self.msg_content(Some(MsgContent::from(s.content())));
                }
                MsgLikeKind::UnableToDecrypt(encrypted_msg) => {
                    info!("Edit event applies to event that couldn’t be decrypted");
                    self.event_type("m.room.encrypted".to_string());
                }

                MsgLikeKind::Poll(s) => {
                    info!("Edit event applies to a poll state");
                    self.event_type("m.poll.start".to_string());
                    if let Some(fallback) = s.fallback_text() {
                        let msg_content = MsgContent::from_text(fallback);
                        self.content(Some(TimelineEventContent::Message(msg_content)));
                    }
                }
            },
            SdkTimelineItemContent::MembershipChange(m) => {
                info!("Edit event applies to membership change event");
                self.event_type("MembershipChange".to_string());
                if let Ok(content) = MembershipContent::try_from(m) {
                    self.content(Some(TimelineEventContent::MembershipChange(content)));
                }
            }
            SdkTimelineItemContent::ProfileChange(p) => {
                info!("Edit event applies to profile change event");
                self.event_type("ProfileChange".to_string());
                let content = ProfileContent::from(p);
                self.content(Some(TimelineEventContent::ProfileChange(content)));
            }

            SdkTimelineItemContent::OtherState(s) => {
                info!("Edit event applies to a state event");
                self.handle_other_state(s);
            }

            SdkTimelineItemContent::FailedToParseMessageLike { event_type, error } => {
                info!("Edit event applies to message that couldn’t be parsed");
                self.event_type(event_type.to_string());
            }
            SdkTimelineItemContent::FailedToParseState {
                event_type,
                state_key,
                error,
            } => {
                info!("Edit event applies to state that couldn’t be parsed");
                self.event_type(event_type.to_string());
            }
            SdkTimelineItemContent::CallInvite => {
                self.event_type("m.call_invite".to_owned());
            }
            SdkTimelineItemContent::CallNotify => {
                self.event_type("m.call_notify".to_owned());
            }
        };
    }
}

impl TimelineEventItem {

    pub (crate) fn new_replied_to(event: &Box<RepliedToEvent>, event_id: OwnedEventId, when: u64, my_id: OwnedUserId) -> Self {
        let mut me: TimelineEventItemBuilder = TimelineEventItemBuilder::default();
        me.event_id(Some(event_id))
            .sender(event.sender().to_owned());

        me.parse_content(event.content(),when, my_id);
        me.build().expect("Building Room Event doesn’t fail")
    }

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

        me.parse_content(event.content(), event.timestamp().get().into(), my_id);
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
        self.event_type.clone()
    }

    pub fn msg_type(&self) -> Option<String> {
        self.msg_type.clone()
    }

    pub fn msg_content(&self) -> Option<MsgContent> {
        if let Some(TimelineEventContent::Message(c)) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn membership_content(&self) -> Option<MembershipContent> {
        if let Some(TimelineEventContent::MembershipChange(c)) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn profile_content(&self) -> Option<ProfileContent> {
        if let Some(TimelineEventContent::ProfileChange(c)) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn policy_rule_room_content(&self) -> Option<PolicyRuleRoomContent> {
        if let Some(TimelineEventContent::PolicyRuleRoom(c)) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn policy_rule_server_content(&self) -> Option<PolicyRuleServerContent> {
        if let Some(TimelineEventContent::PolicyRuleServer(c)) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn policy_rule_user_content(&self) -> Option<PolicyRuleUserContent> {
        if let Some(TimelineEventContent::PolicyRuleUser(c)) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_avatar_content(&self) -> Option<RoomAvatarContent> {
        if let Some(TimelineEventContent::RoomAvatar(c)) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_create_content(&self) -> Option<RoomCreateContent> {
        if let Some(TimelineEventContent::RoomCreate(c)) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_encryption_content(&self) -> Option<RoomEncryptionContent> {
        if let Some(TimelineEventContent::RoomEncryption(c)) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_guest_access_content(&self) -> Option<RoomGuestAccessContent> {
        if let Some(TimelineEventContent::RoomGuestAccess(c)) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_history_visibility_content(&self) -> Option<RoomHistoryVisibilityContent> {
        if let Some(TimelineEventContent::RoomHistoryVisibility(c)) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_join_rules_content(&self) -> Option<RoomJoinRulesContent> {
        if let Some(TimelineEventContent::RoomJoinRules(c)) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_name_content(&self) -> Option<RoomNameContent> {
        if let Some(TimelineEventContent::RoomName(c)) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_pinned_events_content(&self) -> Option<RoomPinnedEventsContent> {
        if let Some(TimelineEventContent::RoomPinnedEvents(c)) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_power_levels_content(&self) -> Option<RoomPowerLevelsContent> {
        if let Some(TimelineEventContent::RoomPowerLevels(c)) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_server_acl_content(&self) -> Option<RoomServerAclContent> {
        if let Some(TimelineEventContent::RoomServerAcl(c)) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_tombstone_content(&self) -> Option<RoomTombstoneContent> {
        if let Some(TimelineEventContent::RoomTombstone(c)) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_topic_content(&self) -> Option<RoomTopicContent> {
        if let Some(TimelineEventContent::RoomTopic(c)) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn space_child_content(&self) -> Option<SpaceChildContent> {
        if let Some(TimelineEventContent::SpaceChild(c)) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn space_parent_content(&self) -> Option<SpaceParentContent> {
        if let Some(TimelineEventContent::SpaceParent(c)) = &self.content {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn in_reply_to_id(&self) -> Option<String> {
        self.in_reply_to_id.as_ref().map(ToString::to_string)
    }

    pub fn in_reply_to_event(&self) -> Option<TimelineEventItem> {
        self.in_reply_to_event.as_ref().map(|e| e.deref().clone())
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

impl TimelineEventItemBuilder {
    fn handle_other_state(&mut self, state: &OtherState) {
        match state.content() {
            AnyOtherFullStateEventContent::PolicyRuleRoom(FullStateEventContent::Original {
                content,
                prev_content,
            }) => {
                self.event_type("m.policy.rule.room".to_owned());
                let c = PolicyRuleRoomContent::new(content.clone(), prev_content.clone());
                self.content(Some(TimelineEventContent::PolicyRuleRoom(c)));
            }
            AnyOtherFullStateEventContent::PolicyRuleServer(FullStateEventContent::Original {
                content,
                prev_content,
            }) => {
                self.event_type("m.policy.rule.server".to_owned());
                let c = PolicyRuleServerContent::new(content.clone(), prev_content.clone());
                self.content(Some(TimelineEventContent::PolicyRuleServer(c)));
            }
            AnyOtherFullStateEventContent::PolicyRuleUser(FullStateEventContent::Original {
                content,
                prev_content,
            }) => {
                self.event_type("m.policy.rule.user".to_owned());
                let c = PolicyRuleUserContent::new(content.clone(), prev_content.clone());
                self.content(Some(TimelineEventContent::PolicyRuleUser(c)));
            }
            AnyOtherFullStateEventContent::RoomAliases(c) => {
                self.event_type("m.room.aliases".to_owned());
                let msg_content = match c {
                    FullStateEventContent::Original {
                        content,
                        prev_content,
                    } => {
                        if let Some(prev) = prev_content {
                            let mut result = vec![];
                            if let Some(old) = &prev.aliases {
                                if !do_vecs_match::<OwnedRoomAliasId>(old, &content.aliases) {
                                    result.push("changed aliases".to_owned());
                                }
                                if result.is_empty() {
                                    MsgContent::from_text("empty content".to_owned())
                                } else {
                                    MsgContent::from_text(result.join(", "))
                                }
                            } else {
                                MsgContent::from_text("added room aliases".to_owned())
                            }
                        } else {
                            MsgContent::from_text("added room aliases".to_owned())
                        }
                    }
                    FullStateEventContent::Redacted(r) => {
                        MsgContent::from_text("deleted room aliases".to_owned())
                    }
                };
                self.content(Some(TimelineEventContent::Message(msg_content)));
            }
            AnyOtherFullStateEventContent::RoomAvatar(FullStateEventContent::Original {
                content,
                prev_content,
            }) => {
                self.event_type("m.room.avatar".to_owned());
                let c = RoomAvatarContent::new(content.clone(), prev_content.clone());
                self.content(Some(TimelineEventContent::RoomAvatar(c)));
            }
            AnyOtherFullStateEventContent::RoomCanonicalAlias(c) => {
                self.event_type("m.room.canonical_alias".to_owned());
                let msg_content = match c {
                    FullStateEventContent::Original {
                        content,
                        prev_content,
                    } => {
                        if let Some(prev) = prev_content {
                            let mut result = vec![];
                            if prev.alias.ne(&content.alias) {
                                result.push("changed alias".to_owned());
                            }
                            if !do_vecs_match(&prev.alt_aliases, &content.alt_aliases) {
                                result.push("changed alt aliases".to_owned());
                            }
                            if result.is_empty() {
                                MsgContent::from_text("empty content".to_owned())
                            } else {
                                MsgContent::from_text(result.join(", "))
                            }
                        } else {
                            MsgContent::from_text("added room canonical alias".to_owned())
                        }
                    }
                    FullStateEventContent::Redacted(r) => {
                        MsgContent::from_text("deleted room canonical alias".to_owned())
                    }
                };
                self.content(Some(TimelineEventContent::Message(msg_content)));
            }
            AnyOtherFullStateEventContent::RoomCreate(FullStateEventContent::Original {
                content,
                prev_content,
            }) => {
                self.event_type("m.room.create".to_owned());
                let c = RoomCreateContent::new(content.clone(), prev_content.clone());
                self.content(Some(TimelineEventContent::RoomCreate(c)));
            }
            AnyOtherFullStateEventContent::RoomEncryption(FullStateEventContent::Original {
                content,
                prev_content,
            }) => {
                self.event_type("m.room.encryption".to_owned());
                let c = RoomEncryptionContent::new(content.clone(), prev_content.clone());
                self.content(Some(TimelineEventContent::RoomEncryption(c)));
            }
            AnyOtherFullStateEventContent::RoomGuestAccess(FullStateEventContent::Original {
                content,
                prev_content,
            }) => {
                self.event_type("m.room.guest_access".to_owned());
                let c = RoomGuestAccessContent::new(content.clone(), prev_content.clone());
                self.content(Some(TimelineEventContent::RoomGuestAccess(c)));
            }
            AnyOtherFullStateEventContent::RoomHistoryVisibility(
                FullStateEventContent::Original {
                    content,
                    prev_content,
                },
            ) => {
                self.event_type("m.room.history_visibility".to_owned());
                let c = RoomHistoryVisibilityContent::new(content.clone(), prev_content.clone());
                self.content(Some(TimelineEventContent::RoomHistoryVisibility(c)));
            }
            AnyOtherFullStateEventContent::RoomJoinRules(FullStateEventContent::Original {
                content,
                prev_content,
            }) => {
                self.event_type("m.room.join_rules".to_owned());
                let c = RoomJoinRulesContent::new(content.clone(), prev_content.clone());
                self.content(Some(TimelineEventContent::RoomJoinRules(c)));
            }
            AnyOtherFullStateEventContent::RoomName(FullStateEventContent::Original {
                content,
                prev_content,
            }) => {
                self.event_type("m.room.name".to_owned());
                let c = RoomNameContent::new(content.clone(), prev_content.clone());
                self.content(Some(TimelineEventContent::RoomName(c)));
            }
            AnyOtherFullStateEventContent::RoomPinnedEvents(FullStateEventContent::Original {
                content,
                prev_content,
            }) => {
                self.event_type("m.room.pinned_events".to_owned());
                let c = RoomPinnedEventsContent::new(content.clone(), prev_content.clone());
                self.content(Some(TimelineEventContent::RoomPinnedEvents(c)));
            }
            AnyOtherFullStateEventContent::RoomPowerLevels(FullStateEventContent::Original {
                content,
                prev_content,
            }) => {
                self.event_type("m.room.power_levels".to_owned());
                let c = RoomPowerLevelsContent::new(content.clone(), prev_content.clone());
                self.content(Some(TimelineEventContent::RoomPowerLevels(c)));
            }
            AnyOtherFullStateEventContent::RoomServerAcl(FullStateEventContent::Original {
                content,
                prev_content,
            }) => {
                self.event_type("m.room.server_acl".to_owned());
                let c = RoomServerAclContent::new(content.clone(), prev_content.clone());
                self.content(Some(TimelineEventContent::RoomServerAcl(c)));
            }
            AnyOtherFullStateEventContent::RoomThirdPartyInvite(c) => {
                self.event_type("m.room.third_party_invite".to_owned());
                let msg_content = match c {
                    FullStateEventContent::Original {
                        content,
                        prev_content,
                    } => {
                        if let Some(prev) = prev_content {
                            let mut result = vec![];
                            if let Some(display_name) = prev.display_name.clone() {
                                if display_name != content.display_name {
                                    result.push("changed display name of invite".to_owned());
                                }
                            } else {
                                result.push("added display name of invite".to_owned());
                            }
                            if let Some(key_validity_url) = prev.key_validity_url.clone() {
                                if key_validity_url != content.key_validity_url {
                                    result.push("changed key validity url of invite".to_owned());
                                }
                            } else {
                                result.push("added key validity url of invite".to_owned());
                            }
                            if let Some(public_key) = prev.public_key.clone() {
                                if public_key.ne(&content.public_key) {
                                    result.push("changed public key of invite".to_owned());
                                }
                            } else {
                                result.push("added public key of invite".to_owned());
                            }
                            if result.is_empty() {
                                MsgContent::from_text("empty content".to_owned())
                            } else {
                                MsgContent::from_text(result.join(", "))
                            }
                        } else {
                            MsgContent::from_text("added room third party invite".to_owned())
                        }
                    }
                    FullStateEventContent::Redacted(r) => {
                        MsgContent::from_text("deleted room history visibility".to_owned())
                    }
                };
                self.content(Some(TimelineEventContent::Message(msg_content)));
            }
            AnyOtherFullStateEventContent::RoomTombstone(FullStateEventContent::Original {
                content,
                prev_content,
            }) => {
                self.event_type("m.room.tombstone".to_owned());
                let c = RoomTombstoneContent::new(content.clone(), prev_content.clone());
                self.content(Some(TimelineEventContent::RoomTombstone(c)));
            }
            AnyOtherFullStateEventContent::RoomTopic(FullStateEventContent::Original {
                content,
                prev_content,
            }) => {
                self.event_type("m.room.topic".to_owned());
                let c = RoomTopicContent::new(content.clone(), prev_content.clone());
                self.content(Some(TimelineEventContent::RoomTopic(c)));
            }
            AnyOtherFullStateEventContent::SpaceChild(FullStateEventContent::Original {
                content,
                prev_content,
            }) => {
                self.event_type("m.space.child".to_owned());
                let state_key = state.state_key().to_owned();
                let c = SpaceChildContent::new(state_key, content.clone(), prev_content.clone());
                self.content(Some(TimelineEventContent::SpaceChild(c)));
            }
            AnyOtherFullStateEventContent::SpaceParent(FullStateEventContent::Original {
                content,
                prev_content,
            }) => {
                self.event_type("m.space.parent".to_owned());
                let state_key = state.state_key().to_owned();
                let c = SpaceParentContent::new(state_key, content.clone(), prev_content.clone());
                self.content(Some(TimelineEventContent::SpaceParent(c)));
            }
            _ => {}
        }
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct TimelineVirtualItem {
    event_type: String,
    desc: Option<String>,
}

impl From<&VirtualTimelineItem> for TimelineVirtualItem {
    fn from(value: &VirtualTimelineItem) -> TimelineVirtualItem {
        match value {
            VirtualTimelineItem::DateDivider(ts) => {
                let desc = if let Some(st) = ts.to_system_time() {
                    let dt: DateTime<Utc> = st.into();
                    Some(dt.format("%Y-%m-%d").to_string())
                } else {
                    None
                };
                TimelineVirtualItem {
                    event_type: "DayDivider".to_string(),
                    desc,
                }
            }
            VirtualTimelineItem::TimelineStart => TimelineVirtualItem {
                event_type: "TimelineStart".to_string(),
                desc: None,
            },
            VirtualTimelineItem::ReadMarker => TimelineVirtualItem {
                event_type: "ReadMarker".to_string(),
                desc: None,
            },
        }
    }
}

impl TimelineVirtualItem {
    pub fn event_type(&self) -> String {
        self.event_type.clone()
    }

    pub fn desc(&self) -> Option<String> {
        self.desc.clone()
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
#[allow(clippy::large_enum_variant)]
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
    pub(crate) fn new_event_item(event: &EventTimelineItem, my_id: OwnedUserId) -> Self {
        TimelineItem {
            content: TimelineItemContent::Event(TimelineEventItem::new(event, my_id)),
            unique_id: match event.identifier() {
                TimelineEventItemId::EventId(e) => e.to_string(),
                TimelineEventItemId::TransactionId(t) => t.to_string(),
            },
        }
    }

    pub fn is_virtual(&self) -> bool {
        match &self.content {
            TimelineItemContent::Event(content) => false,
            TimelineItemContent::Virtual(content) => true,
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
        let (item, user_id) = value;
        match item.kind() {
            TimelineItemKind::Event(event_item) => {
                TimelineItem::new_event_item(event_item, user_id)
            }
            TimelineItemKind::Virtual(virtual_item) => TimelineItem {
                content: TimelineItemContent::Virtual(TimelineVirtualItem::from(virtual_item)),
                unique_id: item.unique_id().0.clone(),
            },
        }
    }
}
