use anyhow::bail;
use chrono::{DateTime, Utc};
use derive_builder::Builder;
use indexmap::IndexMap;
use matrix_sdk::{room::Room, send_queue::SendHandle};
use matrix_sdk_base::ruma::{
    events::{receipt::Receipt, room::message::MessageType},
    OwnedEventId, OwnedTransactionId, OwnedUserId,
};
use matrix_sdk_ui::timeline::{
    EventSendState as SdkEventSendState, EventTimelineItem, MembershipChange, TimelineEventItemId,
    TimelineItem, TimelineItemContent, TimelineItemKind, VirtualTimelineItem,
};
use ruma::TransactionId;
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
                        "banned".to_string()
                    }
                    Some(MembershipChange::Unbanned) => {
                        me.msg_type(Some("Unbanned".to_string()));
                        "unbanned".to_string()
                    }
                    Some(MembershipChange::Kicked) => {
                        me.msg_type(Some("Kicked".to_string()));
                        "kicked".to_string()
                    }
                    Some(MembershipChange::Invited) => {
                        me.msg_type(Some("Invited".to_string()));
                        "invited".to_string()
                    }
                    Some(MembershipChange::KickedAndBanned) => {
                        me.msg_type(Some("KickedAndBanned".to_string()));
                        "kicked and banned".to_string()
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
                        "knocked".to_string()
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
                            MsgContent::from_text(format!("changed name {old} -> {new}"))
                        }
                        (None, Some(new)) => MsgContent::from_text(format!("set name to {new}")),
                        (Some(_), None) => MsgContent::from_text("removed name".to_string()),
                        (None, None) => {
                            // why would that ever happen?
                            MsgContent::from_text("kept name unset".to_string())
                        }
                    };
                    me.msg_content(Some(msg_content));
                }
                if let Some(change) = p.avatar_url_change() {
                    if let Some(uri) = change.new.as_ref() {
                        let msg_content =
                            MsgContent::from_image("new_picture".to_string(), uri.clone());
                        me.msg_content(Some(msg_content));
                    }
                }
            }
            TimelineItemContent::OtherState(s) => {
                info!("Edit event applies to a state event");
                me.event_type(s.content().event_type().to_string());
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

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct RoomVirtualItem {
    event_type: String,
    desc: Option<String>,
}

impl RoomVirtualItem {
    pub(crate) fn new(event: &VirtualTimelineItem) -> Self {
        match event {
            VirtualTimelineItem::DayDivider(ts) => {
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
