use chrono::{DateTime, Utc};
use core::time::Duration;
use matrix_sdk::{deserialized_responses::SyncTimelineEvent, room::Room};
use matrix_sdk_ui::timeline::{
    EventSendState, EventTimelineItem, MembershipChange, TimelineItem, TimelineItemContent,
    TimelineItemKind, VirtualTimelineItem,
};
use ruma_common::{
    events::{
        call::{
            answer::{OriginalCallAnswerEvent, OriginalSyncCallAnswerEvent},
            candidates::{OriginalCallCandidatesEvent, OriginalSyncCallCandidatesEvent},
            hangup::{OriginalCallHangupEvent, OriginalSyncCallHangupEvent},
            invite::{OriginalCallInviteEvent, OriginalSyncCallInviteEvent},
        },
        key::verification::{
            accept::{
                AcceptMethod, OriginalKeyVerificationAcceptEvent,
                OriginalSyncKeyVerificationAcceptEvent,
            },
            cancel::{OriginalKeyVerificationCancelEvent, OriginalSyncKeyVerificationCancelEvent},
            done::{OriginalKeyVerificationDoneEvent, OriginalSyncKeyVerificationDoneEvent},
            key::{OriginalKeyVerificationKeyEvent, OriginalSyncKeyVerificationKeyEvent},
            mac::{OriginalKeyVerificationMacEvent, OriginalSyncKeyVerificationMacEvent},
            ready::{OriginalKeyVerificationReadyEvent, OriginalSyncKeyVerificationReadyEvent},
            start::{
                OriginalKeyVerificationStartEvent, OriginalSyncKeyVerificationStartEvent,
                StartMethod,
            },
            VerificationMethod,
        },
        policy::rule::{
            room::{OriginalPolicyRuleRoomEvent, OriginalSyncPolicyRuleRoomEvent},
            server::{OriginalPolicyRuleServerEvent, OriginalSyncPolicyRuleServerEvent},
            user::{OriginalPolicyRuleUserEvent, OriginalSyncPolicyRuleUserEvent},
        },
        reaction::{OriginalReactionEvent, OriginalSyncReactionEvent},
        room::{
            aliases::{OriginalRoomAliasesEvent, OriginalSyncRoomAliasesEvent},
            avatar::{OriginalRoomAvatarEvent, OriginalSyncRoomAvatarEvent},
            canonical_alias::{
                OriginalRoomCanonicalAliasEvent, OriginalSyncRoomCanonicalAliasEvent,
            },
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
                AudioInfo, FileInfo, MessageFormat, MessageType, OriginalRoomMessageEvent,
                OriginalSyncRoomMessageEvent, VideoInfo,
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
            ImageInfo, MediaSource,
        },
        space::{
            child::{OriginalSpaceChildEvent, OriginalSyncSpaceChildEvent},
            parent::{OriginalSpaceParentEvent, OriginalSyncSpaceParentEvent},
        },
        sticker::{OriginalStickerEvent, OriginalSyncStickerEvent},
        AnySyncMessageLikeEvent, AnySyncStateEvent, AnySyncTimelineEvent, SyncMessageLikeEvent,
        SyncStateEvent,
    },
    serde::Raw,
    OwnedEventId, OwnedRoomId, OwnedUserId,
};
use serde::{Deserialize, Serialize};
use std::{collections::HashMap, ops::Deref, sync::Arc};
use tracing::info;

use super::common::{
    AudioDesc, FileDesc, ImageDesc, LocationDesc, ReactionRecord, TextDesc, VideoDesc,
};

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct RoomEventItem {
    event_id: String,
    sender: String,
    origin_server_ts: u64,
    event_type: String,
    msg_type: Option<String>,
    text_desc: Option<TextDesc>,
    image_desc: Option<ImageDesc>,
    audio_desc: Option<AudioDesc>,
    video_desc: Option<VideoDesc>,
    file_desc: Option<FileDesc>,
    location_desc: Option<LocationDesc>,
    in_reply_to: Option<OwnedEventId>,
    reactions: HashMap<String, Vec<ReactionRecord>>,
    editable: bool,
}

impl RoomEventItem {
    fn new(event_id: String, sender: String, origin_server_ts: u64, event_type: String) -> Self {
        RoomEventItem {
            event_id,
            sender,
            origin_server_ts,
            event_type,
            msg_type: None,
            text_desc: None,
            image_desc: None,
            audio_desc: None,
            video_desc: None,
            file_desc: None,
            location_desc: None,
            in_reply_to: None,
            reactions: Default::default(),
            editable: false,
        }
    }

    pub fn event_id(&self) -> String {
        self.event_id.clone()
    }

    pub fn sender(&self) -> String {
        self.sender.clone()
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

    pub fn text_desc(&self) -> Option<TextDesc> {
        self.text_desc.clone()
    }

    pub(crate) fn set_text_desc(&mut self, value: TextDesc) {
        self.text_desc = Some(value);
    }

    pub fn image_desc(&self) -> Option<ImageDesc> {
        self.image_desc.clone()
    }

    pub(crate) fn set_image_desc(&mut self, value: ImageDesc) {
        self.image_desc = Some(value);
    }

    pub fn audio_desc(&self) -> Option<AudioDesc> {
        self.audio_desc.clone()
    }

    pub(crate) fn set_audio_desc(&mut self, value: AudioDesc) {
        self.audio_desc = Some(value);
    }

    pub fn video_desc(&self) -> Option<VideoDesc> {
        self.video_desc.clone()
    }

    pub(crate) fn set_video_desc(&mut self, value: VideoDesc) {
        self.video_desc = Some(value);
    }

    pub fn file_desc(&self) -> Option<FileDesc> {
        self.file_desc.clone()
    }

    pub(crate) fn set_file_desc(&mut self, value: FileDesc) {
        self.file_desc = Some(value);
    }

    pub fn location_desc(&self) -> Option<LocationDesc> {
        self.location_desc.clone()
    }

    pub(crate) fn set_location_desc(&mut self, value: LocationDesc) {
        self.location_desc = Some(value);
    }

    pub fn in_reply_to(&self) -> Option<String> {
        self.in_reply_to.as_ref().map(|x| x.to_string())
    }

    pub(crate) fn set_in_reply_to(&mut self, value: OwnedEventId) {
        self.in_reply_to = Some(value);
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

    pub(crate) fn call_answer_from_event(
        event: OriginalCallAnswerEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.call.answer".to_string(),
        );
        let text_desc = TextDesc::new(event.content.answer.sdp, None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn call_answer_from_sync_event(
        event: OriginalSyncCallAnswerEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.call.answer".to_string(),
        );
        let text_desc = TextDesc::new(event.content.answer.sdp, None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn call_candidates_from_event(
        event: OriginalCallCandidatesEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.call.candidates".to_string(),
        );
        let candidates = event
            .content
            .candidates
            .into_iter()
            .map(|x| x.candidate)
            .collect::<Vec<String>>()
            .join(", ");
        let text_desc = TextDesc::new(format!("changed candidates to {candidates}"), None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn call_candidates_from_sync_event(
        event: OriginalSyncCallCandidatesEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.call.candidates".to_string(),
        );
        let candidates = event
            .content
            .candidates
            .into_iter()
            .map(|x| x.candidate)
            .collect::<Vec<String>>()
            .join(", ");
        let text_desc = TextDesc::new(format!("changed candidates to {candidates}"), None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn call_hangup_from_event(
        event: OriginalCallHangupEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.call.hangup".to_string(),
        );
        let text_desc = TextDesc::new(
            format!("hangup this call because {}", event.content.reason),
            None,
        );
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn call_hangup_from_sync_event(
        event: OriginalSyncCallHangupEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.call.hangup".to_string(),
        );
        let text_desc = TextDesc::new(
            format!("hangup this call because {}", event.content.reason),
            None,
        );
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn call_invite_from_event(
        event: OriginalCallInviteEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.call.invite".to_string(),
        );
        let text_desc = TextDesc::new(event.content.offer.sdp, None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn call_invite_from_sync_event(
        event: OriginalSyncCallInviteEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.call.invite".to_string(),
        );
        let text_desc = TextDesc::new(event.content.offer.sdp, None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn policy_rule_room_from_event(
        event: OriginalPolicyRuleRoomEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.policy.rule.room".to_string(),
        );
        let body = format!(
            "recommended {} about {} because {}",
            event.content.0.recommendation, event.content.0.entity, event.content.0.reason,
        );
        let text_desc = TextDesc::new(body, None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn policy_rule_room_from_sync_event(
        event: OriginalSyncPolicyRuleRoomEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.policy.rule.room".to_string(),
        );
        let body = format!(
            "recommended {} about {} because {}",
            event.content.0.recommendation, event.content.0.entity, event.content.0.reason,
        );
        let text_desc = TextDesc::new(body, None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn policy_rule_server_from_event(
        event: OriginalPolicyRuleServerEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.policy.rule.server".to_string(),
        );
        let text_desc = TextDesc::new("changed policy rule server".to_string(), None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn policy_rule_server_from_sync_event(
        event: OriginalSyncPolicyRuleServerEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.policy.rule.server".to_string(),
        );
        let text_desc = TextDesc::new("changed policy rule server".to_string(), None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn policy_rule_user_from_event(
        event: OriginalPolicyRuleUserEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.policy.rule.user".to_string(),
        );
        let text_desc = TextDesc::new("changed policy rule user".to_string(), None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn policy_rule_user_from_sync_event(
        event: OriginalSyncPolicyRuleUserEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.policy.rule.user".to_string(),
        );
        let text_desc = TextDesc::new("changed policy rule user".to_string(), None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn reaction_from_event(event: OriginalReactionEvent, room_id: OwnedRoomId) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.reaction".to_string(),
        );
        let text_desc = TextDesc::new(format!("reacted by {}", event.content.relates_to.key), None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn reaction_from_sync_event(
        event: OriginalSyncReactionEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.reaction".to_string(),
        );
        let text_desc = TextDesc::new(format!("reacted by {}", event.content.relates_to.key), None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_aliases_from_event(
        event: OriginalRoomAliasesEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.aliases".to_string(),
        );
        let aliases = event
            .content
            .aliases
            .iter()
            .map(|x| x.to_string())
            .collect::<Vec<String>>()
            .join(", ");
        let text_desc = TextDesc::new(format!("changed room aliases to {aliases}"), None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_aliases_from_sync_event(
        event: OriginalSyncRoomAliasesEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.aliases".to_string(),
        );
        let aliases = event
            .content
            .aliases
            .iter()
            .map(|x| x.to_string())
            .collect::<Vec<String>>()
            .join(", ");
        let text_desc = TextDesc::new(format!("changed room aliases to {aliases}"), None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_avatar_from_event(
        event: OriginalRoomAvatarEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.avatar".to_string(),
        );
        let text_desc = TextDesc::new("changed room avatar".to_string(), None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_avatar_from_sync_event(
        event: OriginalSyncRoomAvatarEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.avatar".to_string(),
        );
        let text_desc = TextDesc::new("changed room avatar".to_string(), None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_canonical_alias_from_event(
        event: OriginalRoomCanonicalAliasEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.canonical_alias".to_string(),
        );
        let alt_aliases = event
            .content
            .alt_aliases
            .iter()
            .map(|x| x.to_string())
            .collect::<Vec<String>>()
            .join(", ");
        let text_desc = TextDesc::new(
            format!(
                "changed canonical aliases ({}) of room alias ({:?})",
                alt_aliases,
                event.content.alias.map(|x| x.to_string()),
            ),
            None,
        );
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_canonical_alias_from_sync_event(
        event: OriginalSyncRoomCanonicalAliasEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.canonical_alias".to_string(),
        );
        let alt_aliases = event
            .content
            .alt_aliases
            .iter()
            .map(|x| x.to_string())
            .collect::<Vec<String>>()
            .join(", ");
        let text_desc = TextDesc::new(
            format!(
                "changed canonical aliases ({}) of room alias ({:?})",
                alt_aliases,
                event.content.alias.map(|x| x.to_string()),
            ),
            None,
        );
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_create_from_event(
        event: OriginalRoomCreateEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.create".to_string(),
        );
        let text_desc = TextDesc::new("created this room".to_string(), None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_create_from_sync_event(
        event: OriginalSyncRoomCreateEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.create".to_string(),
        );
        let text_desc = TextDesc::new("created this room".to_string(), None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_encrypted_from_event(
        event: OriginalRoomEncryptedEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.encrypted".to_string(),
        );
        let scheme = match event.content.scheme {
            EncryptedEventScheme::MegolmV1AesSha2(s) => "MegolmV1AesSha2".to_string(),
            EncryptedEventScheme::OlmV1Curve25519AesSha2(s) => "OlmV1Curve25519AesSha2".to_string(),
            _ => "Unknown".to_string(),
        };
        let text_desc = TextDesc::new(format!("encrypted by {scheme}"), None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_encrypted_from_sync_event(
        event: OriginalSyncRoomEncryptedEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.encrypted".to_string(),
        );
        let scheme = match event.content.scheme {
            EncryptedEventScheme::MegolmV1AesSha2(s) => "MegolmV1AesSha2".to_string(),
            EncryptedEventScheme::OlmV1Curve25519AesSha2(s) => "OlmV1Curve25519AesSha2".to_string(),
            _ => "Unknown".to_string(),
        };
        let text_desc = TextDesc::new(format!("encrypted by {scheme}"), None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_encryption_from_event(
        event: OriginalRoomEncryptionEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.encryption".to_string(),
        );
        let text_desc = TextDesc::new(
            format!("changed encryption to {}", event.content.algorithm),
            None,
        );
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_encryption_from_sync_event(
        event: OriginalSyncRoomEncryptionEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.encryption".to_string(),
        );
        let text_desc = TextDesc::new(
            format!("changed encryption to {}", event.content.algorithm),
            None,
        );
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_guest_access_from_event(
        event: OriginalRoomGuestAccessEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.guest.access".to_string(),
        );
        let text_desc = TextDesc::new(
            format!(
                "changed room's guest access to {}",
                event.content.guest_access,
            ),
            None,
        );
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_guest_access_from_sync_event(
        event: OriginalSyncRoomGuestAccessEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.guest.access".to_string(),
        );
        let text_desc = TextDesc::new(
            format!(
                "changed room's guest access to {}",
                event.content.guest_access,
            ),
            None,
        );
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_history_visibility_from_event(
        event: OriginalRoomHistoryVisibilityEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.history_visibility".to_string(),
        );
        let text_desc = TextDesc::new(
            format!(
                "changed room's history visibility to {}",
                event.content.history_visibility,
            ),
            None,
        );
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_history_visibility_from_sync_event(
        event: OriginalSyncRoomHistoryVisibilityEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.history_visibility".to_string(),
        );
        let text_desc = TextDesc::new(
            format!(
                "changed room's history visibility to {}",
                event.content.history_visibility,
            ),
            None,
        );
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_join_rules_from_event(
        event: OriginalRoomJoinRulesEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.join.rules".to_string(),
        );
        let text_desc = TextDesc::new(
            format!(
                "changed room's join rules to {}",
                event.content.join_rule.as_str(),
            ),
            None,
        );
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_join_rules_from_sync_event(
        event: OriginalSyncRoomJoinRulesEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.join.rules".to_string(),
        );
        let text_desc = TextDesc::new(
            format!(
                "changed room's join rules to {}",
                event.content.join_rule.as_str(),
            ),
            None,
        );
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_member_from_event(
        event: OriginalRoomMemberEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.member".to_string(),
        );
        let fallback = match event.content.membership {
            MembershipState::Join => {
                event_item.set_msg_type("Joined".to_string());
                "joined".to_string()
            }
            MembershipState::Leave => {
                event_item.set_msg_type("Left".to_string());
                "left".to_string()
            }
            MembershipState::Ban => {
                event_item.set_msg_type("Banned".to_string());
                "banned".to_string()
            }
            MembershipState::Invite => {
                event_item.set_msg_type("Invited".to_string());
                "invited".to_string()
            }
            MembershipState::Knock => {
                event_item.set_msg_type("Knocked".to_string());
                "knocked".to_string()
            }
            _ => {
                event_item.set_msg_type("ProfileChanged".to_string());
                match (
                    &event.content.displayname,
                    &event.content.avatar_url,
                    event
                        .prev_content()
                        .map(|c| (c.avatar_url.as_ref(), c.displayname.as_ref()))
                        .unwrap_or_default(),
                ) {
                    (Some(display_name), Some(avatar_name), (Some(old), _)) => {
                        format!("Updated avatar & changed name to {old} -> {display_name}")
                    }
                    (Some(display_name), Some(avatar_name), (None, _)) => {
                        format!("Updated avatar & set name to {display_name}")
                    }
                    (Some(display_name), None, (Some(old), Some(_))) => {
                        format!("Changed name {old} -> {display_name}, removed avatar")
                    }
                    (Some(display_name), None, (None, Some(_))) => {
                        format!("Set name to {display_name}, removed avatar")
                    }
                    (Some(display_name), None, (Some(old), _)) => {
                        format!("Changed name {old} -> {display_name}")
                    }
                    (Some(display_name), None, (None, _)) => {
                        format!("Set name to {display_name}")
                    }
                    (None, Some(avatar), (None, _)) => "Updated avatar".to_string(),
                    (None, Some(avatar), (Some(_), _)) => {
                        "Removed name, updated avatar".to_string()
                    }
                    (None, None, (Some(_), Some(_))) => "Removed name and avatar".to_string(),
                    (None, None, (Some(_), None)) => "Removed name".to_string(),
                    (None, None, (None, Some(_))) => "Removed avatar".to_string(),
                    (None, None, (None, None)) => "Removed name".to_string(),
                }
            }
        };
        let text_desc = TextDesc::new(fallback, None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_member_from_sync_event(
        event: OriginalSyncRoomMemberEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.member".to_string(),
        );
        let fallback = match event.content.membership {
            MembershipState::Join => {
                event_item.set_msg_type("Joined".to_string());
                "joined".to_string()
            }
            MembershipState::Leave => {
                event_item.set_msg_type("Left".to_string());
                "left".to_string()
            }
            MembershipState::Ban => {
                event_item.set_msg_type("Banned".to_string());
                "banned".to_string()
            }
            MembershipState::Invite => {
                event_item.set_msg_type("Invited".to_string());
                "invited".to_string()
            }
            MembershipState::Knock => {
                event_item.set_msg_type("Knocked".to_string());
                "knocked".to_string()
            }
            _ => {
                event_item.set_msg_type("ProfileChanged".to_string());
                match (
                    &event.content.displayname,
                    &event.content.avatar_url,
                    event
                        .prev_content()
                        .map(|c| (c.avatar_url.as_ref(), c.displayname.as_ref()))
                        .unwrap_or_default(),
                ) {
                    (Some(display_name), Some(avatar_name), (Some(old), _)) => {
                        format!("Updated avatar & changed name to {old} -> {display_name}")
                    }
                    (Some(display_name), Some(avatar_name), (None, _)) => {
                        format!("Updated avatar & set name to {display_name}")
                    }
                    (Some(display_name), None, (Some(old), Some(_))) => {
                        format!("Changed name {old} -> {display_name}, removed avatar")
                    }
                    (Some(display_name), None, (None, Some(_))) => {
                        format!("Set name to {display_name}, removed avatar")
                    }
                    (Some(display_name), None, (Some(old), _)) => {
                        format!("Changed name {old} -> {display_name}")
                    }
                    (Some(display_name), None, (None, _)) => {
                        format!("Set name to {display_name}")
                    }
                    (None, Some(avatar), (None, _)) => "Updated avatar".to_string(),
                    (None, Some(avatar), (Some(_), _)) => {
                        "Removed name, updated avatar".to_string()
                    }
                    (None, None, (Some(_), Some(_))) => "Removed name and avatar".to_string(),
                    (None, None, (Some(_), None)) => "Removed name".to_string(),
                    (None, None, (None, Some(_))) => "Removed avatar".to_string(),
                    (None, None, (None, None)) => "Removed name".to_string(),
                }
            }
        };
        let text_desc = TextDesc::new(fallback, None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_message_from_event(
        event: OriginalRoomMessageEvent,
        room: Room,
        has_editable: bool,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.message".to_string(),
        );
        if (has_editable) {
            if let Some(user_id) = room.client().user_id() {
                if *user_id == event.sender {
                    event_item.set_editable(true);
                }
            }
        }
        event_item.set_msg_type(event.content.msgtype().to_string());
        let fallback = match event.content.msgtype.clone() {
            MessageType::Audio(content) => "sent an audio.".to_string(),
            MessageType::Emote(content) => content.body,
            MessageType::File(content) => "sent a file.".to_string(),
            MessageType::Image(content) => "sent an image.".to_string(),
            MessageType::Location(content) => content.body,
            MessageType::Notice(content) => content.body,
            MessageType::ServerNotice(content) => content.body,
            MessageType::Text(content) => content.body,
            MessageType::Video(content) => "sent a video.".to_string(),
            _ => "Unknown sync item".to_string(),
        };
        let mut text_desc = TextDesc::new(fallback, None);
        match event.content.msgtype {
            MessageType::Audio(content) => {
                if let Some(info) = &content.info {
                    let audio_desc =
                        AudioDesc::new(content.body.clone(), content.source.clone(), *info.clone());
                    event_item.set_audio_desc(audio_desc);
                }
            }
            MessageType::Emote(content) => {
                if let Some(formatted) = &content.formatted {
                    if formatted.format == MessageFormat::Html {
                        text_desc.set_formatted_body(Some(formatted.body.clone()));
                    }
                }
            }
            MessageType::File(content) => {
                if let Some(info) = &content.info {
                    let file_desc =
                        FileDesc::new(content.body.clone(), content.source.clone(), *info.clone());
                    event_item.set_file_desc(file_desc);
                }
            }
            MessageType::Image(content) => {
                if let Some(info) = &content.info {
                    let image_desc =
                        ImageDesc::new(content.body.clone(), content.source.clone(), *info.clone());
                    event_item.set_image_desc(image_desc);
                }
            }
            MessageType::Location(content) => {
                if let Some(info) = &content.info {
                    let mut location_desc =
                        LocationDesc::new(content.body.clone(), content.geo_uri.clone());
                    if let Some(thumbnail_source) = &info.thumbnail_source {
                        location_desc.set_thumbnail_source(thumbnail_source.clone());
                    }
                    if let Some(thumbnail_info) = &info.thumbnail_info {
                        location_desc.set_thumbnail_info(*thumbnail_info.clone());
                    }
                    event_item.set_location_desc(location_desc);
                }
            }
            MessageType::Text(content) => {
                if let Some(formatted) = &content.formatted {
                    if formatted.format == MessageFormat::Html {
                        text_desc.set_formatted_body(Some(formatted.body.clone()));
                    }
                }
            }
            MessageType::Video(content) => {
                if let Some(info) = &content.info {
                    let video_desc =
                        VideoDesc::new(content.body.clone(), content.source.clone(), *info.clone());
                    event_item.set_video_desc(video_desc);
                }
            }
            _ => {}
        }
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room.room_id().to_owned(), event_item)
    }

    pub(crate) fn room_message_from_sync_event(
        event: OriginalSyncRoomMessageEvent,
        room_id: OwnedRoomId,
        sent_by_me: bool,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.message".to_string(),
        );
        event_item.set_editable(sent_by_me);
        event_item.set_msg_type(event.content.msgtype().to_string());
        let fallback = match event.content.msgtype.clone() {
            MessageType::Audio(content) => "sent an audio.".to_string(),
            MessageType::Emote(content) => content.body,
            MessageType::File(content) => "sent a file.".to_string(),
            MessageType::Image(content) => "sent an image.".to_string(),
            MessageType::Location(content) => content.body,
            MessageType::Notice(content) => content.body,
            MessageType::ServerNotice(content) => content.body,
            MessageType::Text(content) => content.body,
            MessageType::Video(content) => "sent a video.".to_string(),
            _ => "Unknown sync item".to_string(),
        };
        let mut text_desc = TextDesc::new(fallback, None);
        match event.content.msgtype {
            MessageType::Audio(content) => {
                if let Some(info) = &content.info {
                    let audio_desc =
                        AudioDesc::new(content.body.clone(), content.source.clone(), *info.clone());
                    event_item.set_audio_desc(audio_desc);
                }
            }
            MessageType::Emote(content) => {
                if let Some(formatted) = &content.formatted {
                    if formatted.format == MessageFormat::Html {
                        text_desc.set_formatted_body(Some(formatted.body.clone()));
                    }
                }
            }
            MessageType::File(content) => {
                if let Some(info) = &content.info {
                    let file_desc =
                        FileDesc::new(content.body.clone(), content.source.clone(), *info.clone());
                    event_item.set_file_desc(file_desc);
                }
            }
            MessageType::Image(content) => {
                if let Some(info) = &content.info {
                    let image_desc =
                        ImageDesc::new(content.body.clone(), content.source.clone(), *info.clone());
                    event_item.set_image_desc(image_desc);
                }
            }
            MessageType::Location(content) => {
                if let Some(info) = &content.info {
                    let mut location_desc =
                        LocationDesc::new(content.body.clone(), content.geo_uri.clone());
                    if let Some(thumbnail_source) = &info.thumbnail_source {
                        location_desc.set_thumbnail_source(thumbnail_source.clone());
                    }
                    if let Some(thumbnail_info) = &info.thumbnail_info {
                        location_desc.set_thumbnail_info(*thumbnail_info.clone());
                    }
                    event_item.set_location_desc(location_desc);
                }
            }
            MessageType::Text(content) => {
                if let Some(formatted) = &content.formatted {
                    if formatted.format == MessageFormat::Html {
                        text_desc.set_formatted_body(Some(formatted.body.clone()));
                    }
                }
            }
            MessageType::Video(content) => {
                if let Some(info) = &content.info {
                    let video_desc =
                        VideoDesc::new(content.body.clone(), content.source.clone(), *info.clone());
                    event_item.set_video_desc(video_desc);
                }
            }
            _ => {}
        }
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_name_from_event(event: OriginalRoomNameEvent, room_id: OwnedRoomId) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.name".to_string(),
        );
        let body = match event.content.name {
            Some(name) => format!("changed name to {name}"),
            None => "changed name".to_string(),
        };
        let text_desc = TextDesc::new(body, None);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_name_from_sync_event(
        event: OriginalSyncRoomNameEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.name".to_string(),
        );
        let body = match event.content.name {
            Some(name) => format!("changed name to {name}"),
            None => "changed name".to_string(),
        };
        let text_desc = TextDesc::new(body, None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_pinned_events_from_event(
        event: OriginalRoomPinnedEventsEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.pinned_events".to_string(),
        );
        let text_desc = TextDesc::new(
            format!("pinned {} events", event.content.pinned.len()),
            None,
        );
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_pinned_events_from_sync_event(
        event: OriginalSyncRoomPinnedEventsEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.pinned_events".to_string(),
        );
        let text_desc = TextDesc::new(
            format!("pinned {} events", event.content.pinned.len()),
            None,
        );
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_power_levels_from_event(
        event: OriginalRoomPowerLevelsEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.power_levels".to_string(),
        );
        let users = event
            .content
            .users
            .iter()
            .map(|(user_id, value)| format!("power level of {user_id} to {value}"))
            .collect::<Vec<String>>()
            .join(", ");
        let text_desc = TextDesc::new(format!("changed {users}"), None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_power_levels_from_sync_event(
        event: OriginalSyncRoomPowerLevelsEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.power_levels".to_string(),
        );
        let users = event
            .content
            .users
            .iter()
            .map(|(user_id, value)| format!("power level of {user_id} to {value}"))
            .collect::<Vec<String>>()
            .join(", ");
        let text_desc = TextDesc::new(format!("changed {users}"), None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_redaction_from_event(
        event: RoomRedactionEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id().to_string(),
            event.sender().to_string(),
            event.origin_server_ts().get().into(),
            "m.room.redaction".to_string(),
        );
        let reason = event.as_original().and_then(|x| x.content.reason.clone());
        let body = match reason {
            Some(reason) => format!("deleted this item because {reason}"),
            None => "deleted this item".to_string(),
        };
        let text_desc = TextDesc::new(body, None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_redaction_from_sync_event(
        event: SyncRoomRedactionEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id().to_string(),
            event.sender().to_string(),
            event.origin_server_ts().get().into(),
            "m.room.redaction".to_string(),
        );
        let reason = event.as_original().and_then(|x| x.content.reason.clone());
        let body = match reason {
            Some(reason) => format!("deleted this item because {reason}"),
            None => "deleted this item".to_string(),
        };
        let text_desc = TextDesc::new(body, None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_server_acl_from_event(
        event: OriginalRoomServerAclEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.server_acl".to_string(),
        );
        let allow = event.content.allow.join(", ");
        let deny = event.content.deny.join(", ");
        let body = match (allow.is_empty(), deny.is_empty()) {
            (true, true) => format!("allowed {allow}, denied {deny}"),
            (true, false) => format!("allowed {allow}"),
            (false, true) => format!("denied {deny}"),
            (false, false) => "".to_string(),
        };
        let text_desc = TextDesc::new(body, None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_server_acl_from_sync_event(
        event: OriginalSyncRoomServerAclEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.server_acl".to_string(),
        );
        let allow = event.content.allow.join(", ");
        let deny = event.content.deny.join(", ");
        let body = match (allow.is_empty(), deny.is_empty()) {
            (true, true) => format!("allowed {allow}, denied {deny}"),
            (true, false) => format!("allowed {allow}"),
            (false, true) => format!("denied {deny}"),
            (false, false) => "".to_string(),
        };
        let text_desc = TextDesc::new(body, None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_third_party_invite_from_event(
        event: OriginalRoomThirdPartyInviteEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.third_party_invite".to_string(),
        );
        let text_desc = TextDesc::new(format!("invited {}", event.content.display_name), None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_third_party_invite_from_sync_event(
        event: OriginalSyncRoomThirdPartyInviteEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.third_party_invite".to_string(),
        );
        let text_desc = TextDesc::new(format!("invited {}", event.content.display_name), None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_tombstone_from_event(
        event: OriginalRoomTombstoneEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.tombstone".to_string(),
        );
        let text_desc = TextDesc::new(event.content.body, None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_tombstone_from_sync_event(
        event: OriginalSyncRoomTombstoneEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.tombstone".to_string(),
        );
        let text_desc = TextDesc::new(event.content.body, None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_topic_from_event(
        event: OriginalRoomTopicEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.topic".to_string(),
        );
        let text_desc = TextDesc::new(format!("changed topic to {}", event.content.topic), None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn room_topic_from_sync_event(
        event: OriginalSyncRoomTopicEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.room.topic".to_string(),
        );
        let text_desc = TextDesc::new(format!("changed topic to {}", event.content.topic), None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn space_child_from_event(
        event: OriginalSpaceChildEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.space.child".to_string(),
        );
        let body = match event.content.order {
            Some(order) => order,
            None => "".to_string(),
        };
        let text_desc = TextDesc::new(body, None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn space_child_from_sync_event(
        event: OriginalSyncSpaceChildEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.space.child".to_string(),
        );
        let body = match event.content.order {
            Some(order) => order,
            None => "".to_string(),
        };
        let text_desc = TextDesc::new(body, None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn space_parent_from_event(
        event: OriginalSpaceParentEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.space.parent".to_string(),
        );
        let body = match event.content.via {
            Some(via) => format!(
                "changed parent to {}",
                via.iter()
                    .map(|x| x.to_string())
                    .collect::<Vec<String>>()
                    .join(", "),
            ),
            None => "".to_string(),
        };
        let text_desc = TextDesc::new(body, None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn space_parent_from_sync_event(
        event: OriginalSyncSpaceParentEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.space.parent".to_string(),
        );
        let body = match event.content.via {
            Some(via) => format!(
                "changed parent to {}",
                via.iter()
                    .map(|x| x.to_string())
                    .collect::<Vec<String>>()
                    .join(", "),
            ),
            None => "".to_string(),
        };
        let text_desc = TextDesc::new(body, None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn sticker_from_event(event: OriginalStickerEvent, room_id: OwnedRoomId) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.sticker".to_string(),
        );
        let text_desc = TextDesc::new(event.content.body, None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn sticker_from_sync_event(
        event: OriginalSyncStickerEvent,
        room_id: OwnedRoomId,
    ) -> Self {
        let mut event_item = RoomEventItem::new(
            event.event_id.to_string(),
            event.sender.to_string(),
            event.origin_server_ts.get().into(),
            "m.sticker".to_string(),
        );
        let text_desc = TextDesc::new(event.content.body, None);
        event_item.set_text_desc(text_desc);
        RoomMessage::new_event_item(room_id, event_item)
    }

    pub(crate) fn from_timeline_event_item(event: &EventTimelineItem, room: Room) -> Self {
        let event_id = unique_identifier(event);
        let room_id = room.room_id().to_owned();
        let sender = event.sender().to_string();
        let origin_server_ts: u64 = event.timestamp().get().into();
        let client = room.client();
        let my_user_id = client.user_id();

        let event_item = match event.content() {
            TimelineItemContent::Message(msg) => {
                let msg_type = msg.msgtype();
                let mut result = RoomEventItem::new(
                    event_id,
                    sender,
                    origin_server_ts,
                    "m.room.message".to_string(),
                );
                result.set_msg_type(msg_type.msgtype().to_string());
                for (key, value) in event.reactions().iter() {
                    let records = value
                        .senders()
                        .map(|x| {
                            ReactionRecord::new(
                                x.sender_id.clone(),
                                x.timestamp,
                                my_user_id.map(|me| me == x.sender_id).unwrap_or_default(),
                            )
                        })
                        .collect::<Vec<ReactionRecord>>();
                    result.add_reaction(key.clone(), records);
                }
                let sent_by_me = my_user_id
                    .map(|me| me == event.sender())
                    .unwrap_or_default();
                let fallback = match msg_type {
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
                let mut text_desc = TextDesc::new(fallback, None);
                match msg_type {
                    MessageType::Text(content) => {
                        if let Some(formatted) = &content.formatted {
                            if formatted.format == MessageFormat::Html {
                                text_desc.set_formatted_body(Some(formatted.body.clone()));
                            }
                        }
                        if sent_by_me {
                            result.set_editable(true);
                        }
                    }
                    MessageType::Emote(content) => {
                        if let Some(formatted) = &content.formatted {
                            if formatted.format == MessageFormat::Html {
                                text_desc.set_formatted_body(Some(formatted.body.clone()));
                            }
                        }
                        if sent_by_me {
                            result.set_editable(true);
                        }
                    }
                    MessageType::Image(content) => {
                        if let Some(info) = &content.info {
                            let image_desc = ImageDesc::new(
                                content.body.clone(),
                                content.source.clone(),
                                *info.clone(),
                            );
                            result.set_image_desc(image_desc);
                        }
                    }
                    MessageType::Audio(content) => {
                        if let Some(info) = &content.info {
                            let audio_desc = AudioDesc::new(
                                content.body.clone(),
                                content.source.clone(),
                                *info.clone(),
                            );
                            result.set_audio_desc(audio_desc);
                        }
                    }
                    MessageType::Video(content) => {
                        if let Some(info) = &content.info {
                            let video_desc = VideoDesc::new(
                                content.body.clone(),
                                content.source.clone(),
                                *info.clone(),
                            );
                            result.set_video_desc(video_desc);
                        }
                    }
                    MessageType::File(content) => {
                        if let Some(info) = &content.info {
                            let file_desc = FileDesc::new(
                                content.body.clone(),
                                content.source.clone(),
                                *info.clone(),
                            );
                            result.set_file_desc(file_desc);
                        }
                    }
                    MessageType::Location(content) => {
                        if let Some(info) = &content.info {
                            let location_desc =
                                LocationDesc::new(content.body.clone(), content.geo_uri.clone());
                            result.set_location_desc(location_desc);
                        }
                    }
                    _ => {}
                }
                result.set_text_desc(text_desc);
                if let Some(in_reply_to) = msg.in_reply_to() {
                    result.set_in_reply_to(in_reply_to.clone().event_id);
                }
                result
            }
            TimelineItemContent::RedactedMessage => {
                info!("Edit event applies to a redacted message, discarding");
                RoomEventItem::new(
                    event_id,
                    sender,
                    origin_server_ts,
                    "m.room.redaction".to_string(),
                )
            }
            TimelineItemContent::Sticker(s) => {
                let mut result =
                    RoomEventItem::new(event_id, sender, origin_server_ts, "m.sticker".to_string());
                let content = s.content();
                let image_desc = ImageDesc::new(
                    content.body.clone(),
                    MediaSource::Plain(content.url.clone()),
                    content.info.clone(),
                );
                result.set_image_desc(image_desc);
                result
            }
            TimelineItemContent::UnableToDecrypt(encrypted_msg) => {
                info!("Edit event applies to event that couldn't be decrypted, discarding");
                RoomEventItem::new(
                    event_id,
                    sender,
                    origin_server_ts,
                    "m.room.encrypted".to_string(),
                )
            }
            TimelineItemContent::MembershipChange(m) => {
                info!("Edit event applies to a state event, discarding");
                let mut result = RoomEventItem::new(
                    event_id,
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
                let text_desc = TextDesc::new(fallback, None);
                result.set_text_desc(text_desc);
                result
            }
            TimelineItemContent::ProfileChange(p) => {
                info!("Edit event applies to a state event, discarding");
                let mut result = RoomEventItem::new(
                    event_id,
                    sender,
                    origin_server_ts,
                    "m.room.member".to_string(),
                );
                result.set_msg_type("ProfileChange".to_string());
                if let Some(change) = p.displayname_change() {
                    let text_desc = match (&change.old, &change.new) {
                        (Some(old), Some(new)) => {
                            TextDesc::new(format!("changed name {old} -> {new}"), None)
                        }
                        (None, Some(new)) => TextDesc::new(format!("set name to {new}"), None),
                        (Some(_), None) => TextDesc::new("removed name".to_string(), None),
                        (None, None) => {
                            //  why would that ever happen?
                            TextDesc::new("kept name unset".to_string(), None)
                        }
                    };
                    result.set_text_desc(text_desc);
                }
                if let Some(change) = p.avatar_url_change() {
                    if let Some(uri) = change.new.as_ref() {
                        let image_desc = ImageDesc::new(
                            "new_picture".to_string(),
                            MediaSource::Plain(uri.clone()),
                            ImageInfo::new(),
                        );
                        result.set_image_desc(image_desc);
                    }
                }
                result
            }
            TimelineItemContent::OtherState(s) => {
                info!("Edit event applies to a state event, discarding");
                RoomEventItem::new(
                    event_id,
                    sender,
                    origin_server_ts,
                    s.content().event_type().to_string(),
                )
            }
            TimelineItemContent::FailedToParseMessageLike { event_type, error } => {
                info!("Edit event applies to message that couldn't be parsed, discarding");
                RoomEventItem::new(event_id, sender, origin_server_ts, event_type.to_string())
            }
            TimelineItemContent::FailedToParseState {
                event_type,
                state_key,
                error,
            } => {
                info!("Edit event applies to state that couldn't be parsed, discarding");
                RoomEventItem::new(event_id, sender, origin_server_ts, event_type.to_string())
            }
        };
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
        self.event_item.as_ref().map(|e| e.event_id.clone())
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

pub(crate) fn sync_event_to_message(
    event: &Raw<AnySyncTimelineEvent>,
    room_id: OwnedRoomId,
) -> Option<RoomMessage> {
    log::debug!("raw sync event to message: {:?}", event);
    match event.deserialize() {
        Ok(s) => any_sync_event_to_message(s, room_id),
        Err(e) => {
            log::debug!("Parsing sync failed: $e");
            None
        }
    }
}
pub(crate) fn any_sync_event_to_message(
    event: AnySyncTimelineEvent,
    room_id: OwnedRoomId,
) -> Option<RoomMessage> {
    info!("sync event to message: {:?}", event);
    match event {
        AnySyncTimelineEvent::State(AnySyncStateEvent::PolicyRuleRoom(
            SyncStateEvent::Original(e),
        )) => Some(RoomMessage::policy_rule_room_from_sync_event(e, room_id)),
        AnySyncTimelineEvent::State(AnySyncStateEvent::PolicyRuleServer(
            SyncStateEvent::Original(e),
        )) => Some(RoomMessage::policy_rule_server_from_sync_event(e, room_id)),
        AnySyncTimelineEvent::State(AnySyncStateEvent::PolicyRuleUser(
            SyncStateEvent::Original(e),
        )) => Some(RoomMessage::policy_rule_user_from_sync_event(e, room_id)),
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomAliases(SyncStateEvent::Original(
            e,
        ))) => Some(RoomMessage::room_aliases_from_sync_event(e, room_id)),
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomAvatar(SyncStateEvent::Original(e))) => {
            Some(RoomMessage::room_avatar_from_sync_event(e, room_id))
        }
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomCanonicalAlias(
            SyncStateEvent::Original(e),
        )) => Some(RoomMessage::room_canonical_alias_from_sync_event(
            e, room_id,
        )),
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomCreate(SyncStateEvent::Original(e))) => {
            Some(RoomMessage::room_create_from_sync_event(e, room_id))
        }
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomEncryption(
            SyncStateEvent::Original(e),
        )) => Some(RoomMessage::room_encryption_from_sync_event(e, room_id)),
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomGuestAccess(
            SyncStateEvent::Original(e),
        )) => Some(RoomMessage::room_guest_access_from_sync_event(e, room_id)),
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomHistoryVisibility(
            SyncStateEvent::Original(e),
        )) => Some(RoomMessage::room_history_visibility_from_sync_event(
            e, room_id,
        )),
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomJoinRules(
            SyncStateEvent::Original(e),
        )) => Some(RoomMessage::room_join_rules_from_sync_event(e, room_id)),
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomMember(SyncStateEvent::Original(e))) => {
            Some(RoomMessage::room_member_from_sync_event(e, room_id))
        }
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomName(SyncStateEvent::Original(e))) => {
            Some(RoomMessage::room_name_from_sync_event(e, room_id))
        }
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomPinnedEvents(
            SyncStateEvent::Original(e),
        )) => Some(RoomMessage::room_pinned_events_from_sync_event(e, room_id)),
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomPowerLevels(
            SyncStateEvent::Original(e),
        )) => Some(RoomMessage::room_power_levels_from_sync_event(e, room_id)),
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomServerAcl(
            SyncStateEvent::Original(e),
        )) => Some(RoomMessage::room_server_acl_from_sync_event(e, room_id)),
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomThirdPartyInvite(
            SyncStateEvent::Original(e),
        )) => Some(RoomMessage::room_third_party_invite_from_sync_event(
            e, room_id,
        )),
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomTombstone(
            SyncStateEvent::Original(e),
        )) => Some(RoomMessage::room_tombstone_from_sync_event(e, room_id)),
        AnySyncTimelineEvent::State(AnySyncStateEvent::RoomTopic(SyncStateEvent::Original(e))) => {
            Some(RoomMessage::room_topic_from_sync_event(e, room_id))
        }
        AnySyncTimelineEvent::State(AnySyncStateEvent::SpaceChild(SyncStateEvent::Original(e))) => {
            Some(RoomMessage::space_child_from_sync_event(e, room_id))
        }
        AnySyncTimelineEvent::State(AnySyncStateEvent::SpaceParent(SyncStateEvent::Original(
            e,
        ))) => Some(RoomMessage::space_parent_from_sync_event(e, room_id)),
        AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::CallAnswer(
            SyncMessageLikeEvent::Original(a),
        )) => Some(RoomMessage::call_answer_from_sync_event(a, room_id)),
        AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::CallCandidates(
            SyncMessageLikeEvent::Original(c),
        )) => Some(RoomMessage::call_candidates_from_sync_event(c, room_id)),
        AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::CallHangup(
            SyncMessageLikeEvent::Original(h),
        )) => Some(RoomMessage::call_hangup_from_sync_event(h, room_id)),
        AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::CallInvite(
            SyncMessageLikeEvent::Original(i),
        )) => Some(RoomMessage::call_invite_from_sync_event(i, room_id)),
        AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::Reaction(
            SyncMessageLikeEvent::Original(r),
        )) => Some(RoomMessage::reaction_from_sync_event(r, room_id)),
        AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::RoomEncrypted(
            SyncMessageLikeEvent::Original(e),
        )) => Some(RoomMessage::room_encrypted_from_sync_event(e, room_id)),
        AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::RoomMessage(
            SyncMessageLikeEvent::Original(m),
        )) => Some(RoomMessage::room_message_from_sync_event(m, room_id, false)),
        AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::RoomRedaction(r)) => {
            Some(RoomMessage::room_redaction_from_sync_event(r, room_id))
        }
        AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::Sticker(
            SyncMessageLikeEvent::Original(s),
        )) => Some(RoomMessage::sticker_from_sync_event(s, room_id)),
        _ => None,
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

// this function was removed from EventTimelineItem so we clone that function
fn unique_identifier(event: &EventTimelineItem) -> String {
    if event.is_local_echo() {
        match event.send_state() {
            Some(EventSendState::Sent { event_id }) => event_id.to_string(),
            _ => event.transaction_id().unwrap().to_string(),
        }
    } else {
        event.event_id().unwrap().to_string()
    }
}
