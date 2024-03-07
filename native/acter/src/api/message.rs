use chrono::{DateTime, Utc};
use matrix_sdk::room::Room;
use matrix_sdk_ui::timeline::{
    EventSendState as SdkEventSendState, EventTimelineItem, MembershipChange, TimelineItem,
    TimelineItemContent, TimelineItemKind, VirtualTimelineItem,
};
use ruma_common::{serde::Raw, OwnedEventId, OwnedRoomId, OwnedTransactionId, OwnedUserId};
use ruma_events::{
    call::{
        answer::{OriginalCallAnswerEvent, OriginalSyncCallAnswerEvent},
        candidates::{OriginalCallCandidatesEvent, OriginalSyncCallCandidatesEvent},
        hangup::{OriginalCallHangupEvent, OriginalSyncCallHangupEvent},
        invite::{OriginalCallInviteEvent, OriginalSyncCallInviteEvent},
    },
    policy::rule::{
        room::{OriginalPolicyRuleRoomEvent, OriginalSyncPolicyRuleRoomEvent},
        server::{OriginalPolicyRuleServerEvent, OriginalSyncPolicyRuleServerEvent},
        user::{OriginalPolicyRuleUserEvent, OriginalSyncPolicyRuleUserEvent},
    },
    reaction::{OriginalReactionEvent, OriginalSyncReactionEvent},
    receipt::Receipt,
    room::{
        aliases::{OriginalRoomAliasesEvent, OriginalSyncRoomAliasesEvent},
        avatar::{OriginalRoomAvatarEvent, OriginalSyncRoomAvatarEvent},
        canonical_alias::{OriginalRoomCanonicalAliasEvent, OriginalSyncRoomCanonicalAliasEvent},
        create::{OriginalRoomCreateEvent, OriginalSyncRoomCreateEvent},
        encrypted::{
            EncryptedEventScheme, OriginalRoomEncryptedEvent, OriginalSyncRoomEncryptedEvent,
        },
        encryption::{OriginalRoomEncryptionEvent, OriginalSyncRoomEncryptionEvent},
        guest_access::{OriginalRoomGuestAccessEvent, OriginalSyncRoomGuestAccessEvent},
        history_visibility::{
            OriginalRoomHistoryVisibilityEvent, OriginalSyncRoomHistoryVisibilityEvent,
        },
        join_rules::{OriginalRoomJoinRulesEvent, OriginalSyncRoomJoinRulesEvent},
        member::{MembershipState, OriginalRoomMemberEvent, OriginalSyncRoomMemberEvent},
        message::{
            MessageType, OriginalRoomMessageEvent, OriginalSyncRoomMessageEvent, Relation,
            RoomMessageEvent,
        },
        name::{OriginalRoomNameEvent, OriginalSyncRoomNameEvent},
        pinned_events::{OriginalRoomPinnedEventsEvent, OriginalSyncRoomPinnedEventsEvent},
        power_levels::{OriginalRoomPowerLevelsEvent, OriginalSyncRoomPowerLevelsEvent},
        redaction::{RoomRedactionEvent, SyncRoomRedactionEvent},
        server_acl::{OriginalRoomServerAclEvent, OriginalSyncRoomServerAclEvent},
        third_party_invite::{
            OriginalRoomThirdPartyInviteEvent, OriginalSyncRoomThirdPartyInviteEvent,
        },
        tombstone::{OriginalRoomTombstoneEvent, OriginalSyncRoomTombstoneEvent},
        topic::{OriginalRoomTopicEvent, OriginalSyncRoomTopicEvent},
    },
    space::{
        child::{OriginalSpaceChildEvent, OriginalSyncSpaceChildEvent},
        parent::{OriginalSpaceParentEvent, OriginalSyncSpaceParentEvent},
    },
    sticker::{OriginalStickerEvent, OriginalSyncStickerEvent},
    AnySyncMessageLikeEvent, AnySyncStateEvent, AnySyncTimelineEvent, SyncMessageLikeEvent,
    SyncStateEvent,
};
use serde::{Deserialize, Serialize};
use std::{collections::HashMap, ops::Deref, sync::Arc};
use tracing::info;

use super::common::{MsgContent, ReactionRecord};

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct EventSendState {
    state: String,
    error: Option<String>,
    event_id: Option<OwnedEventId>,
}

impl EventSendState {
    fn new(inner: &SdkEventSendState) -> Self {
        let (state, error, event_id) = match inner {
            SdkEventSendState::NotSentYet => ("NotSentYet".to_string(), None, None),
            SdkEventSendState::Cancelled => ("Cancelled".to_string(), None, None),
            SdkEventSendState::SendingFailed { error } => (
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
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct RoomEventItem {
    evt_id: Option<OwnedEventId>,
    txn_id: Option<OwnedTransactionId>,
    sender: OwnedUserId,
    send_state: Option<EventSendState>,
    origin_server_ts: u64,
    event_type: String,
    msg_type: Option<String>,
    msg_content: Option<MsgContent>,
    in_reply_to: Option<OwnedEventId>,
    read_receipts: HashMap<String, Receipt>,
    reactions: HashMap<String, Vec<ReactionRecord>>,
    editable: bool,
    edited: bool,
}

impl RoomEventItem {
    fn new(
        evt_id: Option<OwnedEventId>,
        txn_id: Option<OwnedTransactionId>,
        sender: OwnedUserId,
        origin_server_ts: u64,
        event_type: String,
    ) -> Self {
        RoomEventItem {
            evt_id,
            txn_id,
            sender,
            send_state: None,
            origin_server_ts,
            event_type,
            msg_type: None,
            msg_content: None,
            in_reply_to: None,
            read_receipts: Default::default(),
            reactions: Default::default(),
            editable: false,
            edited: false,
        }
    }

    #[cfg(feature = "testing")]
    #[doc(hidden)]
    pub fn evt_id(&self) -> Option<OwnedEventId> {
        self.evt_id.clone()
    }

    pub fn unique_id(&self) -> String {
        if let Some(evt_id) = &self.evt_id {
            return evt_id.to_string();
        }
        self.txn_id
            .clone()
            .expect("Either event id or transaction id should be available")
            .to_string()
    }

    pub fn sender(&self) -> String {
        self.sender.to_string()
    }

    fn set_send_state(&mut self, send_state: &SdkEventSendState) {
        self.send_state = Some(EventSendState::new(send_state));
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

    pub(crate) fn set_msg_type(&mut self, value: String) {
        self.msg_type = Some(value);
    }

    pub fn msg_content(&self) -> Option<MsgContent> {
        self.msg_content.clone()
    }

    pub(crate) fn set_msg_content(&mut self, value: MsgContent) {
        self.msg_content = Some(value);
    }

    pub fn in_reply_to(&self) -> Option<String> {
        self.in_reply_to.as_ref().map(|x| x.to_string())
    }

    pub(crate) fn set_in_reply_to(&mut self, value: OwnedEventId) {
        self.in_reply_to = Some(value);
    }

    pub(crate) fn add_receipt(&mut self, seen_by: String, receipt: Receipt) {
        self.read_receipts.insert(seen_by, receipt);
    }

    pub fn read_users(&self) -> Vec<String> {
        // don't use cloned().
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

    pub(crate) fn add_reaction(&mut self, key: String, records: Vec<ReactionRecord>) {
        self.reactions.insert(key, records);
    }

    pub fn reaction_keys(&self) -> Vec<String> {
        // don't use cloned().
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

    pub(crate) fn set_editable(&mut self, value: bool) {
        self.editable = value;
    }

    pub fn was_edited(&self) -> bool {
        self.edited
    }

    pub(crate) fn set_edited(&mut self, value: bool) {
        self.edited = value;
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct RoomVirtualItem {
    event_type: String,
    desc: Option<String>,
}

impl RoomVirtualItem {
    pub(crate) fn new(event_type: String, desc: Option<String>) -> Self {
        RoomVirtualItem { event_type, desc }
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
    room_id: OwnedRoomId,
    event_item: Option<RoomEventItem>,
    virtual_item: Option<RoomVirtualItem>,
}

impl RoomMessage {
    fn new_event_item(room_id: OwnedRoomId, event_item: RoomEventItem) -> Self {
        RoomMessage {
            item_type: "event".to_string(),
            room_id,
            event_item: Some(event_item),
            virtual_item: None,
        }
    }

    fn new_virtual_item(room_id: OwnedRoomId, virtual_item: RoomVirtualItem) -> Self {
        RoomMessage {
            item_type: "virtual".to_string(),
            room_id,
            event_item: None,
            virtual_item: Some(virtual_item),
        }
    }

    pub(crate) fn from_timeline_event_item(event: &EventTimelineItem, room: Room) -> Self {
        let mut evt_id = None;
        let mut txn_id = None;
        if event.is_local_echo() {
            if let Some(SdkEventSendState::Sent { event_id }) = event.send_state() {
                evt_id = Some((*event_id).clone());
            } else {
                txn_id = event.transaction_id().map(|x| (*x).to_owned());
            }
        } else {
            evt_id = event.event_id().map(|x| (*x).to_owned());
        }

        let room_id = room.room_id().to_owned();
        let sender = event.sender().to_owned();
        let origin_server_ts: u64 = event.timestamp().get().into();
        let client = room.client();
        let my_id = client.user_id();

        let mut event_item = match event.content() {
            TimelineItemContent::Message(msg) => {
                let msg_type = msg.msgtype();
                let mut result = RoomEventItem::new(
                    evt_id,
                    txn_id,
                    sender,
                    origin_server_ts,
                    "m.room.message".to_string(),
                );
                result.set_msg_type(msg_type.msgtype().to_string());
                for (seen_by, receipt) in event.read_receipts().iter() {
                    result.add_receipt(seen_by.to_string(), receipt.clone());
                }
                for (key, reaction) in event.reactions().iter() {
                    let records = reaction
                        .senders()
                        .map(|x| {
                            ReactionRecord::new(
                                x.sender_id.clone(),
                                x.timestamp,
                                my_id.map(|me| me == x.sender_id).unwrap_or_default(),
                            )
                        })
                        .collect::<Vec<ReactionRecord>>();
                    result.add_reaction(key.clone(), records);
                }
                let sent_by_me = my_id.map(|me| me == event.sender()).unwrap_or_default();
                let mut fallback = match msg_type {
                    MessageType::Audio(content) => "sent an audio.".to_string(),
                    MessageType::Emote(content) => content.body.clone(),
                    MessageType::File(content) => "sent a file.".to_string(),
                    MessageType::Image(content) => "sent an image.".to_string(),
                    MessageType::Location(content) => content.body.clone(),
                    MessageType::Notice(content) => content.body.clone(),
                    MessageType::ServerNotice(content) => content.body.clone(),
                    MessageType::Text(content) => content.body.clone(),
                    MessageType::Video(content) => "sent a video.".to_string(),
                    _ => "Unknown timeline item".to_string(),
                };
                if let Some(json) = event.latest_edit_json() {
                    if let Ok(event_content) = json.deserialize_as::<RoomMessageEvent>() {
                        if let Some(original) = event_content.as_original() {
                            fallback = match &original.content.msgtype {
                                MessageType::Audio(content) => "sent an audio.".to_string(),
                                MessageType::Emote(content) => content.body.clone(),
                                MessageType::File(content) => "sent a file.".to_string(),
                                MessageType::Image(content) => "sent an image.".to_string(),
                                MessageType::Location(content) => content.body.clone(),
                                MessageType::Notice(content) => content.body.clone(),
                                MessageType::ServerNotice(content) => content.body.clone(),
                                MessageType::Text(content) => content.body.clone(),
                                MessageType::Video(content) => "sent a video.".to_string(),
                                _ => "Unknown timeline item".to_string(),
                            };
                        }
                    }
                }
                match msg_type {
                    MessageType::Text(content) => {
                        let msg_content = MsgContent::from(content);
                        result.set_msg_content(msg_content);
                        if sent_by_me {
                            result.set_editable(true);
                        }
                    }
                    MessageType::Emote(content) => {
                        let msg_content = MsgContent::from(content);
                        result.set_msg_content(msg_content);
                        if sent_by_me {
                            result.set_editable(true);
                        }
                    }
                    MessageType::Image(content) => {
                        let msg_content = MsgContent::from(content);
                        result.set_msg_content(msg_content);
                    }
                    MessageType::Audio(content) => {
                        let msg_content = MsgContent::from(content);
                        result.set_msg_content(msg_content);
                    }
                    MessageType::Video(content) => {
                        let msg_content = MsgContent::from(content);
                        result.set_msg_content(msg_content);
                    }
                    MessageType::File(content) => {
                        let msg_content = MsgContent::from(content);
                        result.set_msg_content(msg_content);
                    }
                    MessageType::Location(content) => {
                        let msg_content = MsgContent::from(content);
                        result.set_msg_content(msg_content);
                    }
                    _ => {}
                }
                if let Some(json) = event.latest_edit_json() {
                    if let Ok(event_content) = json.deserialize_as::<RoomMessageEvent>() {
                        if let Some(original) = event_content.as_original() {
                            match &original.content.msgtype {
                                MessageType::Text(content) => {
                                    let msg_content = MsgContent::from(content);
                                    result.set_msg_content(msg_content);
                                }
                                MessageType::Emote(content) => {
                                    let msg_content = MsgContent::from(content);
                                    result.set_msg_content(msg_content);
                                }
                                MessageType::Image(content) => {
                                    let msg_content = MsgContent::from(content);
                                    result.set_msg_content(msg_content);
                                }
                                MessageType::Audio(content) => {
                                    let msg_content = MsgContent::from(content);
                                    result.set_msg_content(msg_content);
                                }
                                MessageType::Video(content) => {
                                    let msg_content = MsgContent::from(content);
                                    result.set_msg_content(msg_content);
                                }
                                MessageType::File(content) => {
                                    let msg_content = MsgContent::from(content);
                                    result.set_msg_content(msg_content);
                                }
                                MessageType::Location(content) => {
                                    let msg_content = MsgContent::from(content);
                                    result.set_msg_content(msg_content);
                                }
                                _ => {}
                            }
                        }
                    }
                }
                if result.msg_content.is_none() {
                    let msg_content = MsgContent::from_text(fallback);
                    result.set_msg_content(msg_content);
                }
                if let Some(in_reply_to) = msg.in_reply_to() {
                    result.set_in_reply_to(in_reply_to.clone().event_id);
                }
                if msg.is_edited() {
                    result.set_edited(true);
                }
                result
            }
            TimelineItemContent::RedactedMessage => {
                info!("Edit event applies to a redacted message, discarding");
                RoomEventItem::new(
                    evt_id,
                    txn_id,
                    sender,
                    origin_server_ts,
                    "m.room.redaction".to_string(),
                )
            }
            TimelineItemContent::Sticker(s) => {
                let mut result = RoomEventItem::new(
                    evt_id,
                    txn_id,
                    sender,
                    origin_server_ts,
                    "m.sticker".to_string(),
                );
                let msg_content = MsgContent::from(s.content());
                result.set_msg_content(msg_content);
                result
            }
            TimelineItemContent::UnableToDecrypt(encrypted_msg) => {
                info!("Edit event applies to event that couldn't be decrypted, discarding");
                RoomEventItem::new(
                    evt_id,
                    txn_id,
                    sender,
                    origin_server_ts,
                    "m.room.encrypted".to_string(),
                )
            }
            TimelineItemContent::MembershipChange(m) => {
                info!("Edit event applies to a state event, discarding");
                let mut result = RoomEventItem::new(
                    evt_id,
                    txn_id,
                    sender,
                    origin_server_ts,
                    "m.room.member".to_string(),
                );
                let fallback = match m.change() {
                    Some(MembershipChange::None) => {
                        result.set_msg_type("None".to_string());
                        "not changed membership".to_string()
                    }
                    Some(MembershipChange::Error) => {
                        result.set_msg_type("Error".to_string());
                        "error in membership change".to_string()
                    }
                    Some(MembershipChange::Joined) => {
                        result.set_msg_type("Joined".to_string());
                        "joined".to_string()
                    }
                    Some(MembershipChange::Left) => {
                        result.set_msg_type("Left".to_string());
                        "left".to_string()
                    }
                    Some(MembershipChange::Banned) => {
                        result.set_msg_type("Banned".to_string());
                        "banned".to_string()
                    }
                    Some(MembershipChange::Unbanned) => {
                        result.set_msg_type("Unbanned".to_string());
                        "unbanned".to_string()
                    }
                    Some(MembershipChange::Kicked) => {
                        result.set_msg_type("Kicked".to_string());
                        "kicked".to_string()
                    }
                    Some(MembershipChange::Invited) => {
                        result.set_msg_type("Invited".to_string());
                        "invited".to_string()
                    }
                    Some(MembershipChange::KickedAndBanned) => {
                        result.set_msg_type("KickedAndBanned".to_string());
                        "kicked and banned".to_string()
                    }
                    Some(MembershipChange::InvitationAccepted) => {
                        result.set_msg_type("InvitationAccepted".to_string());
                        "accepted invitation".to_string()
                    }
                    Some(MembershipChange::InvitationRejected) => {
                        result.set_msg_type("InvitationRejected".to_string());
                        "rejected invitation".to_string()
                    }
                    Some(MembershipChange::InvitationRevoked) => {
                        result.set_msg_type("InvitationRevoked".to_string());
                        "revoked invitation".to_string()
                    }
                    Some(MembershipChange::Knocked) => {
                        result.set_msg_type("Knocked".to_string());
                        "knocked".to_string()
                    }
                    Some(MembershipChange::KnockAccepted) => {
                        result.set_msg_type("KnockAccepted".to_string());
                        "accepted knock".to_string()
                    }
                    Some(MembershipChange::KnockRetracted) => {
                        result.set_msg_type("KnockRetracted".to_string());
                        "retracted knock".to_string()
                    }
                    Some(MembershipChange::KnockDenied) => {
                        result.set_msg_type("KnockDenied".to_string());
                        "denied knock".to_string()
                    }
                    Some(MembershipChange::NotImplemented) => {
                        result.set_msg_type("NotImplemented".to_string());
                        "not implemented change".to_string()
                    }
                    None => "unknown error".to_string(),
                };
                let msg_content = MsgContent::from_text(fallback);
                result.set_msg_content(msg_content);
                result
            }
            TimelineItemContent::ProfileChange(p) => {
                info!("Edit event applies to a state event, discarding");
                let mut result = RoomEventItem::new(
                    evt_id,
                    txn_id,
                    sender,
                    origin_server_ts,
                    "m.room.member".to_string(),
                );
                result.set_msg_type("ProfileChange".to_string());
                if let Some(change) = p.displayname_change() {
                    let msg_content = match (&change.old, &change.new) {
                        (Some(old), Some(new)) => {
                            MsgContent::from_text(format!("changed name {old} -> {new}"))
                        }
                        (None, Some(new)) => MsgContent::from_text(format!("set name to {new}")),
                        (Some(_), None) => MsgContent::from_text("removed name".to_string()),
                        (None, None) => {
                            // why would that ever happen?
                            MsgContent::from_text("kept name unset".to_string())
                        }
                    };
                    result.set_msg_content(msg_content);
                }
                if let Some(change) = p.avatar_url_change() {
                    if let Some(uri) = change.new.as_ref() {
                        let msg_content =
                            MsgContent::from_image("new_picture".to_string(), uri.clone());
                        result.set_msg_content(msg_content);
                    }
                }
                result
            }
            TimelineItemContent::OtherState(s) => {
                info!("Edit event applies to a state event, discarding");
                RoomEventItem::new(
                    evt_id,
                    txn_id,
                    sender,
                    origin_server_ts,
                    s.content().event_type().to_string(),
                )
            }
            TimelineItemContent::FailedToParseMessageLike { event_type, error } => {
                info!("Edit event applies to message that couldn't be parsed, discarding");
                RoomEventItem::new(
                    evt_id,
                    txn_id,
                    sender,
                    origin_server_ts,
                    event_type.to_string(),
                )
            }
            TimelineItemContent::FailedToParseState {
                event_type,
                state_key,
                error,
            } => {
                info!("Edit event applies to state that couldn't be parsed, discarding");
                RoomEventItem::new(
                    evt_id,
                    txn_id,
                    sender,
                    origin_server_ts,
                    event_type.to_string(),
                )
            }
            TimelineItemContent::Poll(s) => {
                info!("Edit event applies to a poll state, discarding");
                let mut result = RoomEventItem::new(
                    evt_id,
                    txn_id,
                    sender,
                    origin_server_ts,
                    "m.poll.start".to_string(),
                );
                if let Some(fallback) = s.fallback_text() {
                    let msg_content = MsgContent::from_text(fallback);
                    result.set_msg_content(msg_content);
                }
                result
            }
            TimelineItemContent::CallInvite => RoomEventItem::new(
                evt_id,
                txn_id,
                sender,
                origin_server_ts,
                "m.call_invite".to_owned(),
            ),
        };
        if event.is_local_echo() {
            if let Some(send_state) = event.send_state() {
                event_item.set_send_state(send_state)
            }
        }
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn from_timeline_virtual_item(event: &VirtualTimelineItem, room: Room) -> Self {
        let room_id = room.room_id().to_owned();
        match event {
            VirtualTimelineItem::DayDivider(ts) => {
                let desc = if let Some(st) = ts.to_system_time() {
                    let dt: DateTime<Utc> = st.into();
                    Some(dt.format("%Y-%m-%d").to_string())
                } else {
                    None
                };
                let virtual_item = RoomVirtualItem::new("DayDivider".to_string(), desc);
                RoomMessage::new_virtual_item(room_id, virtual_item)
            }
            VirtualTimelineItem::ReadMarker => {
                let virtual_item = RoomVirtualItem::new("ReadMarker".to_string(), None);
                RoomMessage::new_virtual_item(room_id, virtual_item)
            }
        }
    }

    pub fn item_type(&self) -> String {
        self.item_type.clone()
    }

    pub fn room_id(&self) -> OwnedRoomId {
        self.room_id.clone()
    }

    pub fn event_item(&self) -> Option<RoomEventItem> {
        self.event_item.clone()
    }

    pub(crate) fn event_id(&self) -> Option<String> {
        self.event_item.as_ref().map(|e| e.unique_id())
    }

    pub(crate) fn event_type(&self) -> String {
        self.event_item
            .as_ref()
            .map(|e| e.event_type())
            .unwrap_or_else(|| "virtual".to_owned()) // if we can't find it, it is because we are a virtual event
    }

    pub(crate) fn origin_server_ts(&self) -> Option<u64> {
        self.event_item.as_ref().map(|e| e.origin_server_ts())
    }

    pub(crate) fn set_event_item(&mut self, event_item: Option<RoomEventItem>) {
        self.event_item = event_item;
    }

    pub fn virtual_item(&self) -> Option<RoomVirtualItem> {
        self.virtual_item.clone()
    }
}

impl From<(Arc<TimelineItem>, Room)> for RoomMessage {
    fn from(v: (Arc<TimelineItem>, Room)) -> RoomMessage {
        let (item, room) = v;

        match item.deref().deref() {
            TimelineItemKind::Event(event_item) => {
                RoomMessage::from_timeline_event_item(event_item, room)
            }
            TimelineItemKind::Virtual(virtual_item) => {
                RoomMessage::from_timeline_virtual_item(virtual_item, room)
            }
        }
    }
}
impl From<(EventTimelineItem, Room)> for RoomMessage {
    fn from(v: (EventTimelineItem, Room)) -> RoomMessage {
        let (event_item, room) = v;
        RoomMessage::from_timeline_event_item(&event_item, room)
    }
}
