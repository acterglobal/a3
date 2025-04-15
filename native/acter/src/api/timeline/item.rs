use acter_core::{
    models::status::{MembershipContent, ProfileContent},
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
    AnyOtherFullStateEventContent, EventSendState as SdkEventSendState, EventTimelineItem, MsgLikeContent, MsgLikeKind, OtherState, TimelineEventItemId, TimelineItem as SdkTimelineItem, TimelineItemContent as SdkTimelineItemContent, TimelineItemKind, VirtualTimelineItem
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
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
            SdkTimelineItemContent::MsgLike(msg_like) => match &msg_like.kind {
                    MsgLikeKind::Message(msg) => {
                        me.event_type("m.room.message".to_owned());
                        let msg_type = msg.msgtype();
                        me.msg_type(Some(msg_type.msgtype().to_string()));
                        me.content(TimelineEventContent::try_from(msg_type).ok());
                    if let Some(in_reply_to) = &msg_like.in_reply_to {
                        me.in_reply_to(Some(in_reply_to.event_id.clone()));
                    }
                    me.edited(msg.is_edited());
                }
                MsgLikeKind::Redacted => {
                    info!("Edit event applies to a redacted message");
                    me.event_type("m.room.redaction".to_string());
                }
                MsgLikeKind::Sticker(s) => {
                    me.event_type("m.sticker".to_string());
                    // FIXME: proper sticker support needed
                    // me.msg_content(Some(MsgContent::from(s.content())));
                }
                MsgLikeKind::UnableToDecrypt(encrypted_msg) => {
                    info!("Edit event applies to event that couldn’t be decrypted");
                    me.event_type("m.room.encrypted".to_string());
                }

                MsgLikeKind::Poll(s) => {
                    info!("Edit event applies to a poll state");
                    me.event_type("m.poll.start".to_string());
                    if let Some(fallback) = s.fallback_text() {
                        let msg_content = MsgContent::from_text(fallback);
                        me.content(Some(TimelineEventContent::Message(msg_content)));
                    }
                }
            },
            SdkTimelineItemContent::MembershipChange(m) => {
                info!("Edit event applies to membership change event");
                me.event_type("MembershipChange".to_string());
                if let Ok(content) = MembershipContent::try_from(m) {
                    me.content(Some(TimelineEventContent::MembershipChange(content)));
                }
            }
            SdkTimelineItemContent::ProfileChange(p) => {
                info!("Edit event applies to profile change event");
                me.event_type("ProfileChange".to_string());
                let content = ProfileContent::from(p);
                me.content(Some(TimelineEventContent::ProfileChange(content)));
            }

            SdkTimelineItemContent::OtherState(s) => {
                info!("Edit event applies to a state event");
                me.handle_other_state(s);
            }

            SdkTimelineItemContent::FailedToParseMessageLike { event_type, error } => {
                info!("Edit event applies to message that couldn’t be parsed");
                me.event_type(event_type.to_string());
            }
            SdkTimelineItemContent::FailedToParseState {
                event_type,
                state_key,
                error,
            } => {
                info!("Edit event applies to state that couldn’t be parsed");
                me.event_type(event_type.to_string());
            }
            SdkTimelineItemContent::CallInvite => {
                me.event_type("m.call_invite".to_owned());
            }
            SdkTimelineItemContent::CallNotify => {
                me.event_type("m.call_notify".to_owned());
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
        self.event_type.clone()
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

    pub fn in_reply_to(&self) -> Option<String> {
        self.in_reply_to.as_ref().map(ToString::to_string)
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
            AnyOtherFullStateEventContent::PolicyRuleRoom(c) => {
                self.event_type("m.policy.rule.room".to_owned());
                let msg_content = match c {
                    FullStateEventContent::Original {
                        content,
                        prev_content,
                    } => {
                        let PolicyRuleRoomEventContent(cur) = content;
                        if let Some(PossiblyRedactedPolicyRuleRoomEventContent(prev)) = prev_content
                        {
                            let mut result = vec![];
                            if let Some(entity) = prev.entity.clone() {
                                if entity != cur.entity {
                                    result.push("changed entity".to_owned());
                                }
                            } else {
                                result.push("added entity".to_owned());
                            }
                            if let Some(reason) = prev.reason.clone() {
                                if reason != cur.reason {
                                    result.push("changed reason".to_owned());
                                }
                            } else {
                                result.push("added reason".to_owned());
                            }
                            if let Some(recommendation) = prev.recommendation.clone() {
                                if recommendation.ne(&cur.recommendation) {
                                    result.push("changed recommendation".to_owned());
                                }
                            } else {
                                result.push("added recommendation".to_owned());
                            }
                            if result.is_empty() {
                                MsgContent::from_text("empty content".to_owned())
                            } else {
                                MsgContent::from_text(result.join(", "))
                            }
                        } else {
                            MsgContent::from_text("added policy room rule".to_owned())
                        }
                    }
                    FullStateEventContent::Redacted(r) => {
                        MsgContent::from_text("deleted policy room rule".to_owned())
                    }
                };
                self.content(Some(TimelineEventContent::Message(msg_content)));
            }
            AnyOtherFullStateEventContent::PolicyRuleServer(c) => {
                self.event_type("m.policy.rule.server".to_owned());
                let msg_content = match c {
                    FullStateEventContent::Original {
                        content,
                        prev_content,
                    } => {
                        let PolicyRuleServerEventContent(cur) = content;
                        if let Some(PossiblyRedactedPolicyRuleServerEventContent(prev)) =
                            prev_content
                        {
                            let mut result = vec![];
                            if let Some(entity) = prev.entity.clone() {
                                if entity != cur.entity {
                                    result.push("changed entity".to_owned());
                                }
                            } else {
                                result.push("added entity".to_owned());
                            }
                            if let Some(reason) = prev.reason.clone() {
                                if reason != cur.reason {
                                    result.push("changed reason".to_owned());
                                }
                            } else {
                                result.push("added reason".to_owned());
                            }
                            if let Some(recommendation) = prev.recommendation.clone() {
                                if recommendation.ne(&cur.recommendation) {
                                    result.push("changed recommendation".to_owned());
                                }
                            } else {
                                result.push("added recommendation".to_owned());
                            }
                            if result.is_empty() {
                                MsgContent::from_text("empty content".to_owned())
                            } else {
                                MsgContent::from_text(result.join(", "))
                            }
                        } else {
                            MsgContent::from_text("added policy server rule".to_owned())
                        }
                    }
                    FullStateEventContent::Redacted(r) => {
                        MsgContent::from_text("deleted policy server rule".to_owned())
                    }
                };
                self.content(Some(TimelineEventContent::Message(msg_content)));
            }
            AnyOtherFullStateEventContent::PolicyRuleUser(c) => {
                self.event_type("m.policy.rule.user".to_owned());
                let msg_content = match c {
                    FullStateEventContent::Original {
                        content,
                        prev_content,
                    } => {
                        let PolicyRuleUserEventContent(cur) = content;
                        if let Some(PossiblyRedactedPolicyRuleUserEventContent(prev)) = prev_content
                        {
                            let mut result = vec![];
                            if let Some(entity) = prev.entity.clone() {
                                if entity != cur.entity {
                                    result.push("changed entity".to_owned());
                                }
                            } else {
                                result.push("added entity".to_owned());
                            }
                            if let Some(reason) = prev.reason.clone() {
                                if reason != cur.reason {
                                    result.push("changed reason".to_owned());
                                }
                            } else {
                                result.push("added reason".to_owned());
                            }
                            if let Some(recommendation) = prev.recommendation.clone() {
                                if recommendation.ne(&cur.recommendation) {
                                    result.push("changed recommendation".to_owned());
                                }
                            } else {
                                result.push("added recommendation".to_owned());
                            }
                            if result.is_empty() {
                                MsgContent::from_text("empty content".to_owned())
                            } else {
                                MsgContent::from_text(result.join(", "))
                            }
                        } else {
                            MsgContent::from_text("added policy user rule".to_owned())
                        }
                    }
                    FullStateEventContent::Redacted(r) => {
                        MsgContent::from_text("deleted policy user rule".to_owned())
                    }
                };
                self.content(Some(TimelineEventContent::Message(msg_content)));
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
            AnyOtherFullStateEventContent::RoomAvatar(c) => {
                self.event_type("m.room.avatar".to_owned());
                let msg_content = match c {
                    FullStateEventContent::Original {
                        content,
                        prev_content,
                    } => {
                        if let Some(prev) = prev_content {
                            let mut result = vec![];
                            if prev.url.ne(&content.url) {
                                result.push("changed url".to_owned());
                            }
                            match (prev.info.clone(), content.info.clone()) {
                                (Some(old), Some(cur)) => {
                                    if old.blurhash != cur.blurhash {
                                        result.push("changed info blurhash".to_owned());
                                    }
                                    if old.height != cur.height {
                                        result.push("changed info height".to_owned());
                                    }
                                    if old.mimetype != cur.mimetype {
                                        result.push("changed info mimetype".to_owned());
                                    }
                                    if old.size != cur.size {
                                        result.push("changed info size".to_owned());
                                    }
                                    match (old.thumbnail_info, cur.thumbnail_info) {
                                        (Some(old_info), Some(cur_info)) => {
                                            if old_info.height != cur_info.height {
                                                result.push(
                                                    "changed info thumbnail height".to_owned(),
                                                );
                                            }
                                            if old_info.height != cur_info.height {
                                                result.push(
                                                    "changed info thumbnail height".to_owned(),
                                                );
                                            }
                                            if old_info.mimetype != cur_info.mimetype {
                                                result.push(
                                                    "changed info thumbnail mimetype".to_owned(),
                                                );
                                            }
                                            if old_info.size != cur_info.size {
                                                result
                                                    .push("changed info thumbnail size".to_owned());
                                            }
                                            if old_info.width != cur_info.width {
                                                result.push(
                                                    "changed info thumbnail width".to_owned(),
                                                );
                                            }
                                        }
                                        (Some(old_info), None) => {
                                            result.push("removed info thumbnail info".to_owned());
                                        }
                                        (None, Some(cur_info)) => {
                                            result.push("added info thumbnail info".to_owned());
                                        }
                                        (None, None) => {}
                                    }
                                    if old.thumbnail_url != cur.thumbnail_url {
                                        result.push("changed info thumbnail url".to_owned());
                                    }
                                    if old.width != cur.width {
                                        result.push("changed info width".to_owned());
                                    }
                                }
                                (Some(old), None) => {
                                    result.push("removed info".to_owned());
                                }
                                (None, Some(cur)) => {
                                    result.push("added info".to_owned());
                                }
                                (None, None) => {}
                            }
                            if result.is_empty() {
                                MsgContent::from_text("empty content".to_owned())
                            } else {
                                MsgContent::from_text(result.join(", "))
                            }
                        } else {
                            MsgContent::from_text("added room avatar".to_owned())
                        }
                    }
                    FullStateEventContent::Redacted(r) => {
                        MsgContent::from_text("deleted room avatar".to_owned())
                    }
                };
                self.content(Some(TimelineEventContent::Message(msg_content)));
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
            AnyOtherFullStateEventContent::RoomCreate(c) => {
                self.event_type("m.room.create".to_owned());
                let msg_content = match c {
                    FullStateEventContent::Original {
                        content,
                        prev_content,
                    } => {
                        if let Some(prev) = prev_content {
                            let mut result = vec![];
                            if prev.federate != content.federate {
                                result.push("changed federate".to_owned());
                            }
                            match (prev.predecessor.clone(), content.predecessor.clone()) {
                                (Some(old), Some(cur)) => {
                                    if old.event_id != cur.event_id || old.room_id != cur.room_id {
                                        result.push("changed predecessor".to_owned());
                                    }
                                }
                                (Some(old), None) => {
                                    result.push("removed predecessor".to_owned());
                                }
                                (None, Some(cur)) => {
                                    result.push("added predecessor".to_owned());
                                }
                                (None, None) => {}
                            }
                            if prev.room_type != content.room_type {
                                result.push("changed room type".to_owned());
                            }
                            if prev.room_version != content.room_version {
                                result.push("changed room version".to_owned());
                            }
                            if result.is_empty() {
                                MsgContent::from_text("empty content".to_owned())
                            } else {
                                MsgContent::from_text(result.join(", "))
                            }
                        } else {
                            MsgContent::from_text("added room create".to_owned())
                        }
                    }
                    FullStateEventContent::Redacted(r) => {
                        MsgContent::from_text("deleted room create".to_owned())
                    }
                };
                self.content(Some(TimelineEventContent::Message(msg_content)));
            }
            AnyOtherFullStateEventContent::RoomEncryption(c) => {
                self.event_type("m.room.encryption".to_owned());
                let msg_content = match c {
                    FullStateEventContent::Original {
                        content,
                        prev_content,
                    } => {
                        if let Some(prev) = prev_content {
                            let mut result = vec![];
                            if let Some(algorithm) = prev.algorithm.clone() {
                                if algorithm.ne(&content.algorithm) {
                                    result.push("changed algorithm".to_owned());
                                }
                            } else {
                                result.push("added algorithm".to_owned());
                            }
                            if prev.rotation_period_ms != content.rotation_period_ms {
                                result.push("changed rotation period ms".to_owned());
                            }
                            if prev.rotation_period_msgs != content.rotation_period_msgs {
                                result.push("changed rotation period msgs".to_owned());
                            }
                            if result.is_empty() {
                                MsgContent::from_text("empty content".to_owned())
                            } else {
                                MsgContent::from_text(result.join(", "))
                            }
                        } else {
                            MsgContent::from_text("added room encryption".to_owned())
                        }
                    }
                    FullStateEventContent::Redacted(r) => {
                        MsgContent::from_text("deleted room encryption".to_owned())
                    }
                };
                self.content(Some(TimelineEventContent::Message(msg_content)));
            }
            AnyOtherFullStateEventContent::RoomGuestAccess(c) => {
                self.event_type("m.room.guest_access".to_owned());
                let msg_content = match c {
                    FullStateEventContent::Original {
                        content,
                        prev_content,
                    } => {
                        if let Some(prev) = prev_content {
                            let mut result = vec![];
                            if let Some(old) = &prev.guest_access {
                                if old.ne(&content.guest_access) {
                                    result.push("changed room guest access".to_owned());
                                }
                            } else {
                                result.push("added room guest access".to_owned());
                            }
                            if result.is_empty() {
                                MsgContent::from_text("empty content".to_owned())
                            } else {
                                MsgContent::from_text(result.join(", "))
                            }
                        } else {
                            MsgContent::from_text("added room guest access".to_owned())
                        }
                    }
                    FullStateEventContent::Redacted(r) => {
                        MsgContent::from_text("deleted room guess access".to_owned())
                    }
                };
                self.content(Some(TimelineEventContent::Message(msg_content)));
            }
            AnyOtherFullStateEventContent::RoomHistoryVisibility(c) => {
                self.event_type("m.room.history_visibility".to_owned());
                let msg_content = match c {
                    FullStateEventContent::Original {
                        content,
                        prev_content,
                    } => {
                        if let Some(prev) = prev_content {
                            let mut result = vec![];
                            if prev.history_visibility.ne(&content.history_visibility) {
                                result.push(format!(
                                    "changed '{}' -> '{}'",
                                    prev.history_visibility.as_str(),
                                    &content.history_visibility.as_str()
                                ));
                            }
                            if result.is_empty() {
                                MsgContent::from_text("empty content".to_owned())
                            } else {
                                MsgContent::from_text(result.join(", "))
                            }
                        } else {
                            MsgContent::from_text(content.history_visibility.as_str().to_owned())
                        }
                    }
                    FullStateEventContent::Redacted(r) => {
                        MsgContent::from_text("deleted room history visibility".to_owned())
                    }
                };
                self.content(Some(TimelineEventContent::Message(msg_content)));
            }
            AnyOtherFullStateEventContent::RoomJoinRules(c) => {
                self.event_type("m.room.join_rules".to_owned());
                let msg_content = match c {
                    FullStateEventContent::Original {
                        content,
                        prev_content,
                    } => {
                        if let Some(old) = prev_content {
                            let mut result = vec![];
                            if old.join_rule.ne(&content.join_rule) {
                                result.push(format!(
                                    "changed '{}' -> '{}'",
                                    old.join_rule.as_str(),
                                    &content.join_rule.as_str()
                                ));
                            }
                            if result.is_empty() {
                                MsgContent::from_text("empty content".to_owned())
                            } else {
                                MsgContent::from_text(result.join(", "))
                            }
                        } else {
                            MsgContent::from_text(content.join_rule.as_str().to_owned())
                        }
                    }
                    FullStateEventContent::Redacted(r) => {
                        MsgContent::from_text("deleted room join rule".to_owned())
                    }
                };
                self.content(Some(TimelineEventContent::Message(msg_content)));
            }
            AnyOtherFullStateEventContent::RoomName(c) => {
                self.event_type("m.room.name".to_owned());
                let msg_content = match c {
                    FullStateEventContent::Original {
                        content,
                        prev_content,
                    } => {
                        let cur = content.name.clone();
                        if let Some(prev) = prev_content {
                            let mut result = vec![];
                            if let Some(old) = prev.name.clone() {
                                if old != content.name {
                                    result.push(format!("changed '{}' -> '{}'", old, content.name));
                                }
                            } else {
                                result.push(format!("set name to '{}'", content.name));
                            }
                            if result.is_empty() {
                                MsgContent::from_text("empty content".to_owned())
                            } else {
                                MsgContent::from_text(result.join(", "))
                            }
                        } else {
                            MsgContent::from_text(content.name.to_owned())
                        }
                    }
                    FullStateEventContent::Redacted(r) => {
                        MsgContent::from_text("deleted room name".to_owned())
                    }
                };
                self.content(Some(TimelineEventContent::Message(msg_content)));
            }
            AnyOtherFullStateEventContent::RoomPinnedEvents(c) => {
                self.event_type("m.room.pinned_events".to_owned());
                let msg_content = match c {
                    FullStateEventContent::Original {
                        content,
                        prev_content,
                    } => {
                        if let Some(prev) = prev_content {
                            let mut result = vec![];
                            if let Some(pinned) = prev.pinned.clone() {
                                if !do_vecs_match::<OwnedEventId>(&pinned, &content.pinned) {
                                    result.push("changed room pinned events".to_owned());
                                }
                            } else {
                                result.push("added room pinned events".to_owned());
                            }
                            if result.is_empty() {
                                MsgContent::from_text("empty content".to_owned())
                            } else {
                                MsgContent::from_text(result.join(", "))
                            }
                        } else {
                            MsgContent::from_text("added room pinned events".to_owned())
                        }
                    }
                    FullStateEventContent::Redacted(r) => {
                        MsgContent::from_text("deleted room pinned events".to_owned())
                    }
                };
                self.content(Some(TimelineEventContent::Message(msg_content)));
            }
            AnyOtherFullStateEventContent::RoomPowerLevels(c) => {
                self.event_type("m.room.power_levels".to_owned());
                let msg_content = match c {
                    FullStateEventContent::Original {
                        content,
                        prev_content,
                    } => {
                        if let Some(prev) = prev_content {
                            let mut result = vec![];
                            if prev.ban != content.ban {
                                result.push("changed ban level".to_owned());
                            }
                            if prev.events.ne(&content.events) {
                                result.push("changed events level".to_owned());
                            }
                            if prev.events_default != content.events_default {
                                result.push("changed events default level".to_owned());
                            }
                            if prev.invite != content.invite {
                                result.push("changed invite level".to_owned());
                            }
                            if prev.kick != content.kick {
                                result.push("changed kick level".to_owned());
                            }
                            if prev.notifications.room != content.notifications.room {
                                result.push("changed notifications level".to_owned());
                            }
                            if prev.redact != content.redact {
                                result.push("changed redact level".to_owned());
                            }
                            if prev.state_default != content.state_default {
                                result.push("changed state default level".to_owned());
                            }
                            if prev.users.ne(&content.users) {
                                result.push("changed users levels".to_owned());
                            }
                            if prev.users_default != content.users_default {
                                result.push("changed users default level".to_owned());
                            }
                            if result.is_empty() {
                                MsgContent::from_text("empty content".to_owned())
                            } else {
                                MsgContent::from_text(result.join(", "))
                            }
                        } else {
                            MsgContent::from_text("added room power levels".to_owned())
                        }
                    }
                    FullStateEventContent::Redacted(r) => {
                        MsgContent::from_text("deleted room power levels".to_owned())
                    }
                };
                self.content(Some(TimelineEventContent::Message(msg_content)));
            }
            AnyOtherFullStateEventContent::RoomServerAcl(c) => {
                self.event_type("m.room.server_acl".to_owned());
                let msg_content = match c {
                    FullStateEventContent::Original {
                        content,
                        prev_content,
                    } => {
                        if let Some(prev) = prev_content {
                            let mut result = vec![];
                            if !do_vecs_match::<String>(&prev.allow, &content.allow) {
                                result.push("changed allow list".to_owned());
                            }
                            if prev.allow_ip_literals != content.allow_ip_literals {
                                result.push("changed allow ip literals".to_owned());
                            }
                            if !do_vecs_match::<String>(&prev.deny, &content.deny) {
                                result.push("changed deny list".to_owned());
                            }
                            if result.is_empty() {
                                MsgContent::from_text("empty content".to_owned())
                            } else {
                                MsgContent::from_text(result.join(", "))
                            }
                        } else {
                            MsgContent::from_text("added room server acl".to_owned())
                        }
                    }
                    FullStateEventContent::Redacted(r) => {
                        MsgContent::from_text("deleted room server acl".to_owned())
                    }
                };
                self.content(Some(TimelineEventContent::Message(msg_content)));
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
            AnyOtherFullStateEventContent::RoomTombstone(c) => {
                self.event_type("m.room.tombstone".to_owned());
                let msg_content = match c {
                    FullStateEventContent::Original {
                        content,
                        prev_content,
                    } => {
                        if let Some(prev) = prev_content {
                            let mut result = vec![];
                            if let Some(body) = prev.body.clone() {
                                if body != content.body {
                                    result
                                        .push(format!("changed '{}' -> '{}'", body, content.body));
                                }
                            } else {
                                result.push(content.body.to_owned());
                            }
                            if let Some(replacement_room) = prev.replacement_room.clone() {
                                if replacement_room != content.replacement_room {
                                    result.push("changed tombstone replacement room".to_owned());
                                }
                            } else {
                                result.push("added tombstone replacement room".to_owned());
                            }
                            if result.is_empty() {
                                MsgContent::from_text("empty content".to_owned())
                            } else {
                                MsgContent::from_text(result.join(", "))
                            }
                        } else {
                            MsgContent::from_text(content.body.to_owned())
                        }
                    }
                    FullStateEventContent::Redacted(r) => {
                        MsgContent::from_text("deleted room tombstone".to_owned())
                    }
                };
                self.content(Some(TimelineEventContent::Message(msg_content)));
            }
            AnyOtherFullStateEventContent::RoomTopic(c) => {
                self.event_type("m.room.topic".to_owned());
                let msg_content = match c {
                    FullStateEventContent::Original {
                        content,
                        prev_content,
                    } => {
                        if let Some(prev) = prev_content {
                            let mut result = vec![];
                            if let Some(topic) = prev.topic.clone() {
                                if topic != content.topic {
                                    result.push(format!(
                                        "changed '{}' -> '{}'",
                                        topic, content.topic
                                    ));
                                }
                            } else {
                                result.push(content.topic.to_owned());
                            }
                            if result.is_empty() {
                                MsgContent::from_text("empty content".to_owned())
                            } else {
                                MsgContent::from_text(result.join(", "))
                            }
                        } else {
                            MsgContent::from_text(content.topic.to_owned())
                        }
                    }
                    FullStateEventContent::Redacted(r) => {
                        MsgContent::from_text("deleted room topic".to_owned())
                    }
                };
                self.content(Some(TimelineEventContent::Message(msg_content)));
            }
            AnyOtherFullStateEventContent::SpaceChild(c) => {
                self.event_type("m.space.child".to_owned());
                let msg_content = match c {
                    FullStateEventContent::Original {
                        content,
                        prev_content,
                    } => {
                        if let Some(prev) = prev_content {
                            let mut result = vec![];
                            match (prev.order.clone(), content.order.clone()) {
                                (Some(old), Some(cur)) => {
                                    if old != cur {
                                        result.push("changed order of space child".to_owned());
                                    }
                                }
                                (Some(old), None) => {
                                    result.push("removed order of space child".to_owned());
                                }
                                (None, Some(cur)) => {
                                    result.push("added order of space child".to_owned());
                                }
                                (None, None) => {}
                            }
                            if prev.suggested != content.suggested {
                                result.push("changed suggested of space child".to_owned());
                            }
                            if let Some(via) = prev.via.clone() {
                                if !do_vecs_match(&via, &content.via) {
                                    result.push("changed via of space child".to_owned());
                                }
                            } else {
                                result.push("added via of space child".to_owned());
                            }
                            if result.is_empty() {
                                MsgContent::from_text("empty content".to_owned())
                            } else {
                                MsgContent::from_text(result.join(", "))
                            }
                        } else {
                            MsgContent::from_text("added space child".to_owned())
                        }
                    }
                    FullStateEventContent::Redacted(r) => {
                        MsgContent::from_text("deleted space child".to_owned())
                    }
                };
                self.content(Some(TimelineEventContent::Message(msg_content)));
            }
            AnyOtherFullStateEventContent::SpaceParent(c) => {
                self.event_type("m.space.parent".to_owned());
                let msg_content = match c {
                    FullStateEventContent::Original {
                        content,
                        prev_content,
                    } => {
                        if let Some(prev) = prev_content {
                            let mut result = vec![];
                            if prev.canonical != content.canonical {
                                result.push("changed canonical of space parent".to_owned());
                            }
                            if let Some(via) = prev.via.clone() {
                                if !do_vecs_match(&via, &content.via) {
                                    result.push("changed via of space parent".to_owned());
                                }
                            } else {
                                result.push("added via of space parent".to_owned());
                            }
                            if result.is_empty() {
                                MsgContent::from_text("empty content".to_owned())
                            } else {
                                MsgContent::from_text(result.join(", "))
                            }
                        } else {
                            MsgContent::from_text("added space parent".to_owned())
                        }
                    }
                    FullStateEventContent::Redacted(r) => {
                        MsgContent::from_text("deleted space parent".to_owned())
                    }
                };
                self.content(Some(TimelineEventContent::Message(msg_content)));
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
            VirtualTimelineItem::TimelineStart => {
                TimelineVirtualItem {
                    event_type: "TimelineStart".to_string(),
                    desc: None,
                }
            }
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
