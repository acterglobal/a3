use anyhow::bail;
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
    AnyOtherFullStateEventContent, EventSendState as SdkEventSendState, EventTimelineItem,
    MembershipChange, OtherState, TimelineEventItemId, TimelineItem, TimelineItemContent,
    TimelineItemKind, VirtualTimelineItem,
};
use serde::{Deserialize, Serialize};
use std::sync::Arc;
use tracing::info;

use super::{
    common::{MsgContent, ReactionRecord},
    RUNTIME,
};

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

    pub async fn abort(&self) -> anyhow::Result<bool> {
        let Some(handle) = self.send_handle.clone() else {
            bail!("No send handle found");
        };

        RUNTIME
            .spawn(async move { Ok(handle.abort().await?) })
            .await?
    }
}

#[derive(Clone, Debug, Serialize, Deserialize, Builder)]
#[builder(derive(Debug))]
pub struct RoomEventItem {
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
    msg_content: Option<MsgContent>,
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

impl RoomEventItem {
    pub(crate) fn new(event: &EventTimelineItem, my_id: OwnedUserId) -> Self {
        let mut me = RoomEventItemBuilder::default();

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
                    .map(|(u, group)| {
                        (
                            u.to_string(),
                            group
                                .iter()
                                .map(|(e, r)| {
                                    ReactionRecord::new(e.clone(), r.timestamp, *e == my_id)
                                })
                                .collect::<Vec<_>>(),
                        )
                    })
                    .collect(),
            )
            .editable(event.is_editable()); // which means _images_ can't be edited right now ... but that is probably fine

        match event.content() {
            TimelineItemContent::Message(msg) => {
                me.event_type("m.room.message".to_owned());
                let msg_type = msg.msgtype();
                me.msg_type(Some(msg_type.msgtype().to_string()));
                me.msg_content(match msg_type {
                    MessageType::Text(content) => Some(MsgContent::from(content)),
                    MessageType::Emote(content) => Some(MsgContent::from(content)),
                    MessageType::Image(content) => Some(MsgContent::from(content)),
                    MessageType::Audio(content) => Some(MsgContent::from(content)),
                    MessageType::Video(content) => Some(MsgContent::from(content)),
                    MessageType::File(content) => Some(MsgContent::from(content)),
                    MessageType::Location(content) => Some(MsgContent::from(content)),
                    MessageType::Notice(content) => Some(MsgContent::from(content)),
                    MessageType::ServerNotice(content) => Some(MsgContent::from(content)),
                    _ => None,
                });
                if let Some(in_reply_to) = msg.in_reply_to() {
                    me.in_reply_to(Some(in_reply_to.clone().event_id));
                }
                me.edited(msg.is_edited());
            }
            TimelineItemContent::RedactedMessage => {
                info!("Edit event applies to a redacted message");
                me.event_type("m.room.redaction".to_string());
            }
            TimelineItemContent::Sticker(s) => {
                me.event_type("m.sticker".to_string());
                // FIXME: proper sticker support needed
                // me.msg_content(Some(MsgContent::from(s.content())));
            }
            TimelineItemContent::UnableToDecrypt(encrypted_msg) => {
                info!("Edit event applies to event that couldn’t be decrypted");
                me.event_type("m.room.encrypted".to_string());
            }
            TimelineItemContent::MembershipChange(m) => {
                info!("Edit event applies to a state event");
                me.event_type("m.room.member".to_string());
                let fallback = match m.change() {
                    Some(MembershipChange::None) => {
                        me.msg_type(Some("None".to_string()));
                        "not changed membership".to_string()
                    }
                    Some(MembershipChange::Error) => {
                        me.msg_type(Some("Error".to_string()));
                        "error in membership change".to_string()
                    }
                    Some(MembershipChange::Joined) => {
                        me.msg_type(Some("Joined".to_string()));
                        "joined".to_string()
                    }
                    Some(MembershipChange::Left) => {
                        me.msg_type(Some("Left".to_string()));
                        "left".to_string()
                    }
                    Some(MembershipChange::Banned) => {
                        me.msg_type(Some("Banned".to_string()));
                        m.user_id().to_string()
                    }
                    Some(MembershipChange::Unbanned) => {
                        me.msg_type(Some("Unbanned".to_string()));
                        m.user_id().to_string()
                    }
                    Some(MembershipChange::Kicked) => {
                        me.msg_type(Some("Kicked".to_string()));
                        m.user_id().to_string()
                    }
                    Some(MembershipChange::Invited) => {
                        me.msg_type(Some("Invited".to_string()));
                        m.user_id().to_string()
                    }
                    Some(MembershipChange::KickedAndBanned) => {
                        me.msg_type(Some("KickedAndBanned".to_string()));
                        m.user_id().to_string()
                    }
                    Some(MembershipChange::InvitationAccepted) => {
                        me.msg_type(Some("InvitationAccepted".to_string()));
                        "accepted invitation".to_string()
                    }
                    Some(MembershipChange::InvitationRejected) => {
                        me.msg_type(Some("InvitationRejected".to_string()));
                        "rejected invitation".to_string()
                    }
                    Some(MembershipChange::InvitationRevoked) => {
                        me.msg_type(Some("InvitationRevoked".to_string()));
                        "revoked invitation".to_string()
                    }
                    Some(MembershipChange::Knocked) => {
                        me.msg_type(Some("Knocked".to_string()));
                        m.user_id().to_string()
                    }
                    Some(MembershipChange::KnockAccepted) => {
                        me.msg_type(Some("KnockAccepted".to_string()));
                        "accepted knock".to_string()
                    }
                    Some(MembershipChange::KnockRetracted) => {
                        me.msg_type(Some("KnockRetracted".to_string()));
                        "retracted knock".to_string()
                    }
                    Some(MembershipChange::KnockDenied) => {
                        me.msg_type(Some("KnockDenied".to_string()));
                        "denied knock".to_string()
                    }
                    Some(MembershipChange::NotImplemented) => {
                        me.msg_type(Some("NotImplemented".to_string()));
                        "not implemented change".to_string()
                    }
                    None => "unknown error".to_string(),
                };
                let msg_content = MsgContent::from_text(fallback);
                me.msg_content(Some(msg_content));
            }
            TimelineItemContent::ProfileChange(p) => {
                info!("Edit event applies to a state event");
                me.event_type("ProfileChange".to_string());
                if let Some(change) = p.displayname_change() {
                    let msg_content = match (&change.old, &change.new) {
                        (Some(old), Some(new)) => {
                            me.msg_type(Some(("ChangedDisplayName").to_string()));
                            MsgContent::from_text(format!("{old} -> {new}"))
                        }
                        (None, Some(new)) => {
                            me.msg_type(Some(("SetDisplayName").to_string()));
                            MsgContent::from_text(new.to_string())
                        }
                        (Some(_), None) => {
                            me.msg_type(Some(("RemoveDisplayName").to_string()));
                            MsgContent::from_text("removed display name".to_string())
                        }
                        (None, None) => {
                            // why would that ever happen?
                            MsgContent::from_text("kept name unset".to_string())
                        }
                    };
                    me.msg_content(Some(msg_content));
                }
                if let Some(change) = p.avatar_url_change() {
                    if let Some(uri) = change.new.as_ref() {
                        me.msg_type(Some(("ChangeProfileAvatar").to_string()));
                        let msg_content = MsgContent::from_image(
                            "updated profile avatar".to_string(),
                            uri.clone(),
                        );
                        me.msg_content(Some(msg_content));
                    }
                }
            }

            TimelineItemContent::OtherState(s) => {
                info!("Edit event applies to a state event");
                me.handle_other_state(s);
            }

            TimelineItemContent::FailedToParseMessageLike { event_type, error } => {
                info!("Edit event applies to message that couldn’t be parsed");
                me.event_type(event_type.to_string());
            }
            TimelineItemContent::FailedToParseState {
                event_type,
                state_key,
                error,
            } => {
                info!("Edit event applies to state that couldn’t be parsed");
                me.event_type(event_type.to_string());
            }
            TimelineItemContent::Poll(s) => {
                info!("Edit event applies to a poll state");
                me.event_type("m.poll.start".to_string());
                if let Some(fallback) = s.fallback_text() {
                    let msg_content = MsgContent::from_text(fallback);
                    me.msg_content(Some(msg_content));
                }
            }
            TimelineItemContent::CallInvite => {
                me.event_type("m.call_invite".to_owned());
            }
            TimelineItemContent::CallNotify => {
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

    pub fn msg_content(&self) -> Option<MsgContent> {
        self.msg_content.clone()
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

impl RoomEventItemBuilder {
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
                self.msg_content(Some(msg_content));
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
                self.msg_content(Some(msg_content));
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
                self.msg_content(Some(msg_content));
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
                self.msg_content(Some(msg_content));
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
                self.msg_content(Some(msg_content));
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
                self.msg_content(Some(msg_content));
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
                self.msg_content(Some(msg_content));
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
                self.msg_content(Some(msg_content));
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
                self.msg_content(Some(msg_content));
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
                                result.push("changed room history visibility".to_owned());
                            }
                            if result.is_empty() {
                                MsgContent::from_text("empty content".to_owned())
                            } else {
                                MsgContent::from_text(result.join(", "))
                            }
                        } else {
                            MsgContent::from_text("added room history visibility".to_owned())
                        }
                    }
                    FullStateEventContent::Redacted(r) => {
                        MsgContent::from_text("deleted room history visibility".to_owned())
                    }
                };
                self.msg_content(Some(msg_content));
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
                                result.push("changed room join rule".to_owned());
                            }
                            if result.is_empty() {
                                MsgContent::from_text("empty content".to_owned())
                            } else {
                                MsgContent::from_text(result.join(", "))
                            }
                        } else {
                            MsgContent::from_text("added room join rule".to_owned())
                        }
                    }
                    FullStateEventContent::Redacted(r) => {
                        MsgContent::from_text("deleted room join rule".to_owned())
                    }
                };
                self.msg_content(Some(msg_content));
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
                                    result.push("changed room name".to_owned());
                                }
                            } else {
                                result.push("added room name".to_owned())
                            }
                            if result.is_empty() {
                                MsgContent::from_text("empty content".to_owned())
                            } else {
                                MsgContent::from_text(result.join(", "))
                            }
                        } else {
                            MsgContent::from_text("added room name".to_owned())
                        }
                    }
                    FullStateEventContent::Redacted(r) => {
                        MsgContent::from_text("deleted room name".to_owned())
                    }
                };
                self.msg_content(Some(msg_content));
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
                self.msg_content(Some(msg_content));
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
                            MsgContent::from_text("added room history visibility".to_owned())
                        }
                    }
                    FullStateEventContent::Redacted(r) => {
                        MsgContent::from_text("deleted room history visibility".to_owned())
                    }
                };
                self.msg_content(Some(msg_content));
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
                self.msg_content(Some(msg_content));
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
                self.msg_content(Some(msg_content));
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
                                    result.push("changed tombstone body".to_owned());
                                }
                            } else {
                                result.push("added tombstone body".to_owned());
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
                            MsgContent::from_text("added room tombstone".to_owned())
                        }
                    }
                    FullStateEventContent::Redacted(r) => {
                        MsgContent::from_text("deleted room tombstone".to_owned())
                    }
                };
                self.msg_content(Some(msg_content));
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
                                    result.push("changed room topic".to_owned());
                                }
                            } else {
                                result.push("added room topic".to_owned());
                            }
                            if result.is_empty() {
                                MsgContent::from_text("empty content".to_owned())
                            } else {
                                MsgContent::from_text(result.join(", "))
                            }
                        } else {
                            MsgContent::from_text("added room topic".to_owned())
                        }
                    }
                    FullStateEventContent::Redacted(r) => {
                        MsgContent::from_text("deleted room topic".to_owned())
                    }
                };
                self.msg_content(Some(msg_content));
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
                self.msg_content(Some(msg_content));
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
                self.msg_content(Some(msg_content));
            }
            _ => {}
        }
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct RoomVirtualItem {
    event_type: String,
    desc: Option<String>,
}

impl RoomVirtualItem {
    pub(crate) fn new(event: &VirtualTimelineItem) -> Self {
        match event {
            VirtualTimelineItem::DateDivider(ts) => {
                let desc = if let Some(st) = ts.to_system_time() {
                    let dt: DateTime<Utc> = st.into();
                    Some(dt.format("%Y-%m-%d").to_string())
                } else {
                    None
                };
                RoomVirtualItem {
                    event_type: "DayDivider".to_string(),
                    desc,
                }
            }
            VirtualTimelineItem::ReadMarker => RoomVirtualItem {
                event_type: "ReadMarker".to_string(),
                desc: None,
            },
        }
    }

    pub fn event_type(&self) -> String {
        self.event_type.clone()
    }

    pub fn desc(&self) -> Option<String> {
        self.desc.clone()
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct RoomMessage {
    item_type: String,
    event_item: Option<RoomEventItem>,
    virtual_item: Option<RoomVirtualItem>,
    unique_id: String,
}

impl RoomMessage {
    pub(crate) fn new_event_item(my_id: OwnedUserId, event: &EventTimelineItem) -> Self {
        RoomMessage {
            item_type: "event".to_string(),
            event_item: Some(RoomEventItem::new(event, my_id)),
            unique_id: match event.identifier() {
                TimelineEventItemId::EventId(e) => e.to_string(),
                TimelineEventItemId::TransactionId(t) => t.to_string(),
            },
            virtual_item: None,
        }
    }

    pub(crate) fn new_virtual_item(event: &VirtualTimelineItem, unique_id: String) -> Self {
        RoomMessage {
            item_type: "virtual".to_string(),
            event_item: None,
            unique_id,
            virtual_item: Some(RoomVirtualItem::new(event)),
        }
    }

    pub fn item_type(&self) -> String {
        self.item_type.clone()
    }

    pub fn event_item(&self) -> Option<RoomEventItem> {
        self.event_item.clone()
    }

    pub(crate) fn event_id(&self) -> Option<String> {
        match &self.event_item {
            Some(RoomEventItem {
                event_id: Some(event_id),
                ..
            }) => Some(event_id.to_string()),
            _ => None,
        }
    }

    pub fn unique_id(&self) -> String {
        self.unique_id.clone()
    }

    pub(crate) fn event_type(&self) -> String {
        self.event_item
            .as_ref()
            .map(|e| e.event_type())
            .unwrap_or_else(|| "virtual".to_owned()) // if we can’t find it, it is because we are a virtual event
    }

    pub(crate) fn origin_server_ts(&self) -> Option<u64> {
        self.event_item.as_ref().map(|e| e.origin_server_ts())
    }

    pub fn virtual_item(&self) -> Option<RoomVirtualItem> {
        self.virtual_item.clone()
    }
}

impl From<(Arc<TimelineItem>, OwnedUserId)> for RoomMessage {
    fn from(v: (Arc<TimelineItem>, OwnedUserId)) -> RoomMessage {
        let (item, user_id) = v;
        let unique_id = item.unique_id();
        match item.kind() {
            TimelineItemKind::Event(event_item) => RoomMessage::new_event_item(user_id, event_item),
            TimelineItemKind::Virtual(virtual_item) => {
                RoomMessage::new_virtual_item(virtual_item, unique_id.0.clone())
            }
        }
    }
}

fn do_vecs_match<T: PartialEq>(a: &[T], b: &[T]) -> bool {
    let matching = a.iter().zip(b.iter()).filter(|&(a, b)| a == b).count();
    matching == a.len() && matching == b.len()
}
