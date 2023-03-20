use acter_core::util::{DateTime, Utc};
use core::time::Duration;
use log::info;
use matrix_sdk::{
    deserialized_responses::SyncTimelineEvent,
    room::{
        timeline::{
            EventTimelineItem, MemberProfileChange, MembershipChange, TimelineDetails,
            TimelineItem, TimelineItemContent, VirtualTimelineItem,
        },
        Room,
    },
    ruma::{
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
                cancel::{
                    OriginalKeyVerificationCancelEvent, OriginalSyncKeyVerificationCancelEvent,
                },
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
                    EncryptedEventScheme, OriginalRoomEncryptedEvent,
                    OriginalSyncRoomEncryptedEvent,
                },
                encryption::{OriginalRoomEncryptionEvent, OriginalSyncRoomEncryptionEvent},
                guest_access::{OriginalRoomGuestAccessEvent, OriginalSyncRoomGuestAccessEvent},
                history_visibility::{
                    OriginalRoomHistoryVisibilityEvent, OriginalSyncRoomHistoryVisibilityEvent,
                },
                join_rules::{OriginalRoomJoinRulesEvent, OriginalSyncRoomJoinRulesEvent},
                member::{MembershipState, OriginalRoomMemberEvent, OriginalSyncRoomMemberEvent},
                message::{
                    MessageFormat, MessageType, OriginalRoomMessageEvent,
                    OriginalSyncRoomMessageEvent,
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
                ImageInfo, MediaSource, ThumbnailInfo,
            },
            space::{
                child::{OriginalSpaceChildEvent, OriginalSyncSpaceChildEvent},
                parent::{OriginalSpaceParentEvent, OriginalSyncSpaceParentEvent},
            },
            sticker::{OriginalStickerEvent, OriginalSyncStickerEvent},
            AnySyncMessageLikeEvent, AnySyncStateEvent, AnySyncTimelineEvent, SyncMessageLikeEvent,
            SyncStateEvent,
        },
        OwnedEventId, OwnedUserId,
    },
};
use std::{collections::HashMap, sync::Arc};

#[derive(Clone, Debug)]
pub struct RoomEventItem {
    event_id: String,
    sender: String,
    origin_server_ts: u64,
    event_type: String,
    sub_type: Option<String>,
    text_desc: Option<TextDesc>,
    image_desc: Option<ImageDesc>,
    video_desc: Option<VideoDesc>,
    file_desc: Option<FileDesc>,
    in_reply_to: Option<OwnedEventId>,
    reactions: HashMap<String, ReactionDesc>,
    is_editable: bool,
}

impl RoomEventItem {
    #[allow(clippy::too_many_arguments)]
    fn new(
        event_id: String,
        sender: String,
        origin_server_ts: u64,
        event_type: String,
        sub_type: Option<String>,
        text_desc: Option<TextDesc>,
        image_desc: Option<ImageDesc>,
        video_desc: Option<VideoDesc>,
        file_desc: Option<FileDesc>,
        in_reply_to: Option<OwnedEventId>,
        reactions: HashMap<String, ReactionDesc>,
        is_editable: bool,
    ) -> Self {
        RoomEventItem {
            event_id,
            sender,
            origin_server_ts,
            event_type,
            sub_type,
            text_desc,
            image_desc,
            video_desc,
            file_desc,
            in_reply_to,
            reactions,
            is_editable,
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

    pub fn sub_type(&self) -> Option<String> {
        self.sub_type.clone()
    }

    pub fn text_desc(&self) -> Option<TextDesc> {
        self.text_desc.clone()
    }

    pub fn image_desc(&self) -> Option<ImageDesc> {
        self.image_desc.clone()
    }

    pub fn video_desc(&self) -> Option<VideoDesc> {
        self.video_desc.clone()
    }

    pub fn file_desc(&self) -> Option<FileDesc> {
        self.file_desc.clone()
    }

    pub fn in_reply_to(&self) -> Option<String> {
        self.in_reply_to.as_ref().map(|x| x.to_string())
    }

    pub fn reaction_keys(&self) -> Vec<String> {
        self.reactions.keys().cloned().collect()
    }

    pub fn reaction_desc(&self, key: String) -> Option<ReactionDesc> {
        if self.reactions.contains_key(&key) {
            Some(self.reactions[&key].clone())
        } else {
            None
        }
    }

    pub fn is_editable(&self) -> bool {
        self.is_editable
    }
}

#[derive(Clone, Debug)]
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

#[derive(Clone, Debug)]
pub struct RoomMessage {
    item_type: String,
    room_id: String,
    event_item: Option<RoomEventItem>,
    virtual_item: Option<RoomVirtualItem>,
}

impl RoomMessage {
    fn new(
        item_type: String,
        room_id: String,
        event_item: Option<RoomEventItem>,
        virtual_item: Option<RoomVirtualItem>,
    ) -> Self {
        RoomMessage {
            item_type,
            room_id,
            event_item,
            virtual_item,
        }
    }

    pub(crate) fn call_answer_from_event(event: OriginalCallAnswerEvent, room: &Room) -> Self {
        let text_desc = TextDesc {
            body: event.content.answer.sdp,
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.call.answer".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn call_answer_from_sync_event(
        event: OriginalSyncCallAnswerEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: event.content.answer.sdp,
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.call.answer".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn call_candidates_from_event(
        event: OriginalCallCandidatesEvent,
        room: &Room,
    ) -> Self {
        let candidates = event
            .content
            .candidates
            .into_iter()
            .map(|x| x.candidate)
            .collect::<Vec<String>>()
            .join(", ");
        let text_desc = TextDesc {
            body: format!("changed candidates to {candidates}"),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.call.candidates".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn call_candidates_from_sync_event(
        event: OriginalSyncCallCandidatesEvent,
        room: &Room,
    ) -> Self {
        let candidates = event
            .content
            .candidates
            .into_iter()
            .map(|x| x.candidate)
            .collect::<Vec<String>>()
            .join(", ");
        let text_desc = TextDesc {
            body: format!("changed candidates to {candidates}"),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.call.candidates".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn call_hangup_from_event(event: OriginalCallHangupEvent, room: &Room) -> Self {
        let text_desc = event.content.reason.map(|x| TextDesc {
            body: format!("hangup this call because {x}"),
            formatted_body: None,
        });
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.call.hangup".to_string(),
                None,
                text_desc,
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn call_hangup_from_sync_event(
        event: OriginalSyncCallHangupEvent,
        room: &Room,
    ) -> Self {
        let text_desc = event.content.reason.map(|x| TextDesc {
            body: format!("hangup this call because {x}"),
            formatted_body: None,
        });
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.call.hangup".to_string(),
                None,
                text_desc,
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn call_invite_from_event(event: OriginalCallInviteEvent, room: &Room) -> Self {
        let text_desc = TextDesc {
            body: event.content.offer.sdp,
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.call.invite".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn call_invite_from_sync_event(
        event: OriginalSyncCallInviteEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: event.content.offer.sdp,
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.call.invite".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn key_verification_accept_from_event(
        event: OriginalKeyVerificationAcceptEvent,
        room: &Room,
    ) -> Self {
        let body = if let AcceptMethod::SasV1(content) = event.content.method {
            format!(
                "accepted verification with {}",
                content.message_authentication_code,
            )
        } else {
            "accepted verification".to_string()
        };
        let text_desc = TextDesc {
            body,
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.key.verification.accept".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn key_verification_accept_from_sync_event(
        event: OriginalSyncKeyVerificationAcceptEvent,
        room: &Room,
    ) -> Self {
        let body = if let AcceptMethod::SasV1(content) = event.content.method {
            format!(
                "accepted verification with {}",
                content.message_authentication_code,
            )
        } else {
            "accepted verification".to_string()
        };
        let text_desc = TextDesc {
            body,
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.key.verification.accept".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn key_verification_cancel_from_event(
        event: OriginalKeyVerificationCancelEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: format!("canceled verification because {}", event.content.reason),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.key.verification.cancel".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn key_verification_cancel_from_sync_event(
        event: OriginalSyncKeyVerificationCancelEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: format!("canceled verification because {}", event.content.reason),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.key.verification.cancel".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn key_verification_done_from_event(
        event: OriginalKeyVerificationDoneEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: "done verification".to_string(),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.key.verification.done".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn key_verification_done_from_sync_event(
        event: OriginalSyncKeyVerificationDoneEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: "done verification".to_string(),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.key.verification.done".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn key_verification_key_from_event(
        event: OriginalKeyVerificationKeyEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: "sent ephemeral public key for device".to_string(),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.key.verification.key".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn key_verification_key_from_sync_event(
        event: OriginalSyncKeyVerificationKeyEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: "sent ephemeral public key for device".to_string(),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.key.verification.key".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn key_verification_mac_from_event(
        event: OriginalKeyVerificationMacEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: "sent MAC of device's key".to_string(),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.key.verification.mac".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn key_verification_mac_from_sync_event(
        event: OriginalSyncKeyVerificationMacEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: "sent MAC of device's key".to_string(),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.key.verification.mac".to_string(),
                None,
                None,
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn key_verification_ready_from_event(
        event: OriginalKeyVerificationReadyEvent,
        room: &Room,
    ) -> Self {
        let methods = event
            .content
            .methods
            .iter()
            .map(|x| match x {
                VerificationMethod::SasV1 => "SasV1".to_string(),
                VerificationMethod::QrCodeScanV1 => "QrCodeScanV1".to_string(),
                VerificationMethod::QrCodeShowV1 => "QrCodeShowV1".to_string(),
                VerificationMethod::ReciprocateV1 => "ReciprocateV1".to_string(),
                _ => "Unknown".to_string(),
            })
            .collect::<Vec<String>>()
            .join(", ");
        let text_desc = TextDesc {
            body: format!("ready verification with {methods}"),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.key.verification.ready".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn key_verification_ready_from_sync_event(
        event: OriginalSyncKeyVerificationReadyEvent,
        room: &Room,
    ) -> Self {
        let methods = event
            .content
            .methods
            .iter()
            .map(|x| match x {
                VerificationMethod::SasV1 => "SasV1".to_string(),
                VerificationMethod::QrCodeScanV1 => "QrCodeScanV1".to_string(),
                VerificationMethod::QrCodeShowV1 => "QrCodeShowV1".to_string(),
                VerificationMethod::ReciprocateV1 => "ReciprocateV1".to_string(),
                _ => "Unknown".to_string(),
            })
            .collect::<Vec<String>>()
            .join(", ");
        let text_desc = TextDesc {
            body: format!("ready verification with {methods}"),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.key.verification.ready".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn key_verification_start_from_event(
        event: OriginalKeyVerificationStartEvent,
        room: &Room,
    ) -> Self {
        let method = match event.content.method {
            StartMethod::SasV1(s) => "SasV1".to_string(),
            StartMethod::ReciprocateV1(s) => "ReciprocateV1".to_string(),
            _ => "Unknown".to_string(),
        };
        let text_desc = TextDesc {
            body: format!("started verification with {method}"),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.key.verification.start".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn key_verification_start_from_sync_event(
        event: OriginalSyncKeyVerificationStartEvent,
        room: &Room,
    ) -> Self {
        let method = match event.content.method {
            StartMethod::SasV1(s) => "SasV1".to_string(),
            StartMethod::ReciprocateV1(s) => "ReciprocateV1".to_string(),
            _ => "Unknown".to_string(),
        };
        let text_desc = TextDesc {
            body: format!("started verification with {method}"),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.key.verification.start".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn policy_rule_room_from_event(
        event: OriginalPolicyRuleRoomEvent,
        room: &Room,
    ) -> Self {
        let body = format!(
            "recommended {} about {} because {}",
            event.content.0.recommendation, event.content.0.entity, event.content.0.reason,
        );
        let text_desc = TextDesc {
            body,
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.policy.rule.room".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn policy_rule_room_from_sync_event(
        event: OriginalSyncPolicyRuleRoomEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: "changed policy rule room".to_string(),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.policy.rule.room".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn policy_rule_server_from_event(
        event: OriginalPolicyRuleServerEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: "changed policy rule server".to_string(),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.policy.rule.server".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn policy_rule_server_from_sync_event(
        event: OriginalSyncPolicyRuleServerEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: "changed policy rule server".to_string(),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.policy.rule.server".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn policy_rule_user_from_event(
        event: OriginalPolicyRuleUserEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: "changed policy rule user".to_string(),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.policy.rule.user".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn policy_rule_user_from_sync_event(
        event: OriginalSyncPolicyRuleUserEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: "changed policy rule user".to_string(),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.policy.rule.user".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn reaction_from_event(event: OriginalReactionEvent, room: &Room) -> Self {
        let text_desc = TextDesc {
            body: format!("reacted by {}", event.content.relates_to.key),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.reaction".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn reaction_from_sync_event(event: OriginalSyncReactionEvent, room: &Room) -> Self {
        let text_desc = TextDesc {
            body: format!("reacted by {}", event.content.relates_to.key),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.reaction".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_aliases_from_event(event: OriginalRoomAliasesEvent, room: &Room) -> Self {
        let aliases = event
            .content
            .aliases
            .iter()
            .map(|x| x.to_string())
            .collect::<Vec<String>>()
            .join(", ");
        let text_desc = TextDesc {
            body: format!("changed room aliases to {aliases}"),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.aliases".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_aliases_from_sync_event(
        event: OriginalSyncRoomAliasesEvent,
        room: &Room,
    ) -> Self {
        let aliases = event
            .content
            .aliases
            .iter()
            .map(|x| x.to_string())
            .collect::<Vec<String>>()
            .join(", ");
        let text_desc = TextDesc {
            body: format!("changed room aliases to {aliases}"),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.aliases".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_avatar_from_event(event: OriginalRoomAvatarEvent, room: &Room) -> Self {
        let text_desc = TextDesc {
            body: "changed room avatar".to_string(),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.avatar".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_avatar_from_sync_event(
        event: OriginalSyncRoomAvatarEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: "changed room avatar".to_string(),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.avatar".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_canonical_alias_from_event(
        event: OriginalRoomCanonicalAliasEvent,
        room: &Room,
    ) -> Self {
        let alt_aliases = event
            .content
            .alt_aliases
            .iter()
            .map(|x| x.to_string())
            .collect::<Vec<String>>()
            .join(", ");
        let text_desc = TextDesc {
            body: format!(
                "changed canonical aliases ({}) of room alias ({:?})",
                alt_aliases,
                event.content.alias.map(|x| x.to_string()),
            ),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.canonical.alias".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_canonical_alias_from_sync_event(
        event: OriginalSyncRoomCanonicalAliasEvent,
        room: &Room,
    ) -> Self {
        let alt_aliases = event
            .content
            .alt_aliases
            .iter()
            .map(|x| x.to_string())
            .collect::<Vec<String>>()
            .join(", ");
        let text_desc = TextDesc {
            body: format!(
                "changed canonical aliases ({}) of room alias ({:?})",
                alt_aliases,
                event.content.alias.map(|x| x.to_string()),
            ),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.canonical.alias".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_create_from_event(event: OriginalRoomCreateEvent, room: &Room) -> Self {
        let text_desc = TextDesc {
            body: "created this room".to_string(),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.create".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_create_from_sync_event(
        event: OriginalSyncRoomCreateEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: "created this room".to_string(),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.create".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_encrypted_from_event(
        event: OriginalRoomEncryptedEvent,
        room: &Room,
    ) -> Self {
        let scheme = match event.content.scheme {
            EncryptedEventScheme::MegolmV1AesSha2(s) => "MegolmV1AesSha2".to_string(),
            EncryptedEventScheme::OlmV1Curve25519AesSha2(s) => "OlmV1Curve25519AesSha2".to_string(),
            _ => "Unknown".to_string(),
        };
        let text_desc = TextDesc {
            body: format!("encrypted by {scheme}"),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.encrypted".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_encrypted_from_sync_event(
        event: OriginalSyncRoomEncryptedEvent,
        room: &Room,
    ) -> Self {
        let scheme = match event.content.scheme {
            EncryptedEventScheme::MegolmV1AesSha2(s) => "MegolmV1AesSha2".to_string(),
            EncryptedEventScheme::OlmV1Curve25519AesSha2(s) => "OlmV1Curve25519AesSha2".to_string(),
            _ => "Unknown".to_string(),
        };
        let text_desc = TextDesc {
            body: format!("encrypted by {scheme}"),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.encrypted".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_encryption_from_event(
        event: OriginalRoomEncryptionEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: format!("changed encryption to {}", event.content.algorithm),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.encryption".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_encryption_from_sync_event(
        event: OriginalSyncRoomEncryptionEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: format!("changed encryption to {}", event.content.algorithm),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.encryption".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_guest_access_from_event(
        event: OriginalRoomGuestAccessEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: format!(
                "changed room's guest access to {}",
                event.content.guest_access,
            ),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.guest.access".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_guest_access_from_sync_event(
        event: OriginalSyncRoomGuestAccessEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: format!(
                "changed room's guest access to {}",
                event.content.guest_access,
            ),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.guest.access".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_history_visibility_from_event(
        event: OriginalRoomHistoryVisibilityEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: format!(
                "changed room's history visibility to {}",
                event.content.history_visibility,
            ),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.history.visibility".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_history_visibility_from_sync_event(
        event: OriginalSyncRoomHistoryVisibilityEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: format!(
                "changed room's history visibility to {}",
                event.content.history_visibility,
            ),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.history.visibility".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_join_rules_from_event(
        event: OriginalRoomJoinRulesEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: format!(
                "changed room's join rules to {}",
                event.content.join_rule.as_str(),
            ),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.join.rules".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_join_rules_from_sync_event(
        event: OriginalSyncRoomJoinRulesEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: format!(
                "changed room's join rules to {}",
                event.content.join_rule.as_str(),
            ),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.join.rules".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_member_from_event(event: OriginalRoomMemberEvent, room: &Room) -> Self {
        let (sub_type, fallback) = match event.content.membership {
            MembershipState::Join => (Some("Joined".to_string()), "joined".to_string()),
            MembershipState::Leave => (Some("Left".to_string()), "left".to_string()),
            MembershipState::Ban => (Some("Banned".to_string()), "banned".to_string()),
            MembershipState::Invite => (Some("Invited".to_string()), "invited".to_string()),
            MembershipState::Knock => (Some("Knocked".to_string()), "knocked".to_string()),
            _ => {
                if let Some(new_name) = event.clone().content.displayname {
                    let mut old_name = None;
                    if let Some(content) = event.prev_content() {
                        if let Some(ref name) = content.displayname {
                            old_name = Some(name.clone());
                        }
                    }
                    (
                        Some("ProfileChanged".to_string()),
                        format!("changed display name from {:?} to {}", old_name, new_name),
                    )
                } else if let Some(new_url) = event.clone().content.avatar_url {
                    let mut old_url = None;
                    if let Some(content) = event.prev_content() {
                        if let Some(ref url) = content.avatar_url {
                            old_url = Some(url.clone());
                        }
                    }
                    (
                        Some("ProfileChanged".to_string()),
                        format!("changed avatar url from {:?} to {:?}", old_url, new_url),
                    )
                } else {
                    (None, "unknown error".to_string())
                }
            }
        };
        let text_desc = TextDesc {
            body: fallback,
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.member".to_string(),
                sub_type,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_member_from_sync_event(
        event: OriginalSyncRoomMemberEvent,
        room: &Room,
    ) -> Self {
        let (sub_type, fallback) = match event.content.membership {
            MembershipState::Join => (Some("Joined".to_string()), "joined".to_string()),
            MembershipState::Leave => (Some("Left".to_string()), "left".to_string()),
            MembershipState::Ban => (Some("Banned".to_string()), "banned".to_string()),
            MembershipState::Invite => (Some("Invited".to_string()), "invited".to_string()),
            MembershipState::Knock => (Some("Knocked".to_string()), "knocked".to_string()),
            _ => {
                if let Some(new_name) = event.clone().content.displayname {
                    let mut old_name = None;
                    if let Some(content) = event.prev_content() {
                        if let Some(ref name) = content.displayname {
                            old_name = Some(name.clone());
                        }
                    }
                    (
                        Some("ProfileChanged".to_string()),
                        format!("changed display name from {:?} to {}", old_name, new_name),
                    )
                } else if let Some(new_url) = event.clone().content.avatar_url {
                    let mut old_url = None;
                    if let Some(content) = event.prev_content() {
                        if let Some(ref url) = content.avatar_url {
                            old_url = Some(url.clone());
                        }
                    }
                    (
                        Some("ProfileChanged".to_string()),
                        format!("changed avatar url from {:?} to {:?}", old_url, new_url),
                    )
                } else {
                    (None, "unknown error".to_string())
                }
            }
        };
        let text_desc = TextDesc {
            body: fallback,
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.member".to_string(),
                sub_type,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_message_from_event(
        event: OriginalRoomMessageEvent,
        room: &Room,
        has_editable: bool,
    ) -> Self {
        let mut sent_by_me = false;
        if (has_editable) {
            if let Some(user_id) = room.client().user_id() {
                if *user_id == event.sender {
                    sent_by_me = true;
                }
            }
        }
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
        let mut text_desc = TextDesc {
            body: fallback,
            formatted_body: None,
        };
        let mut image_desc = None;
        let mut video_desc = None;
        let mut file_desc = None;
        match event.content.msgtype.clone() {
            MessageType::Text(content) => {
                if let Some(formatted) = &content.formatted {
                    if formatted.format == MessageFormat::Html {
                        text_desc.set_formatted_body(Some(formatted.body.clone()));
                    }
                }
            }
            MessageType::Emote(content) => {}
            MessageType::Image(content) => {
                image_desc = content.info.as_ref().map(|info| ImageDesc {
                    name: content.body.clone(),
                    mimetype: info.mimetype.clone(),
                    size: info.size.map(u64::from),
                    width: info.width.map(u64::from),
                    height: info.height.map(u64::from),
                    thumbnail_info: info.thumbnail_info.to_owned().map(|x| *x),
                    thumbnail_source: info.thumbnail_source.clone(),
                });
            }
            MessageType::Video(content) => {
                video_desc = content.info.as_ref().map(|info| VideoDesc {
                    name: content.body.clone(),
                    mimetype: info.mimetype.clone(),
                    size: info.size.map(u64::from),
                    width: info.width.map(u64::from),
                    height: info.height.map(u64::from),
                    blurhash: info.blurhash.clone(),
                    duration: info.duration,
                    thumbnail_info: info.thumbnail_info.to_owned().map(|x| *x),
                    thumbnail_source: info.thumbnail_source.clone(),
                });
            }
            MessageType::File(content) => {
                file_desc = content.info.as_ref().map(|info| FileDesc {
                    name: content.body.clone(),
                    mimetype: info.mimetype.clone(),
                    size: info.size.map(u64::from),
                    thumbnail_info: info.thumbnail_info.to_owned().map(|x| *x),
                    thumbnail_source: info.thumbnail_source.clone(),
                });
            }
            _ => {}
        }
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.message".to_string(),
                Some(event.content.msgtype().to_string()),
                Some(text_desc),
                image_desc,
                video_desc,
                file_desc,
                None,
                Default::default(),
                sent_by_me,
            )),
            None,
        )
    }

    pub(crate) fn room_message_from_sync_event(
        event: OriginalSyncRoomMessageEvent,
        room: &Room,
        has_editable: bool,
    ) -> Self {
        let mut sent_by_me = false;
        if (has_editable) {
            if let Some(user_id) = room.client().user_id() {
                if *user_id == event.sender {
                    sent_by_me = true;
                }
            }
        }
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
        let mut text_desc = TextDesc {
            body: fallback,
            formatted_body: None,
        };
        let mut image_desc = None;
        let mut video_desc = None;
        let mut file_desc = None;
        match event.content.msgtype.clone() {
            MessageType::Text(content) => {
                if let Some(formatted) = &content.formatted {
                    if formatted.format == MessageFormat::Html {
                        text_desc.set_formatted_body(Some(formatted.body.clone()));
                    }
                }
            }
            MessageType::Emote(content) => {}
            MessageType::Image(content) => {
                image_desc = content.info.as_ref().map(|info| ImageDesc {
                    name: content.body.clone(),
                    mimetype: info.mimetype.clone(),
                    size: info.size.map(u64::from),
                    width: info.width.map(u64::from),
                    height: info.height.map(u64::from),
                    thumbnail_info: info.thumbnail_info.to_owned().map(|x| *x),
                    thumbnail_source: info.thumbnail_source.clone(),
                });
            }
            MessageType::Video(content) => {
                video_desc = content.info.as_ref().map(|info| VideoDesc {
                    name: content.body.clone(),
                    mimetype: info.mimetype.clone(),
                    size: info.size.map(u64::from),
                    width: info.width.map(u64::from),
                    height: info.height.map(u64::from),
                    blurhash: info.blurhash.clone(),
                    duration: info.duration,
                    thumbnail_info: info.thumbnail_info.to_owned().map(|x| *x),
                    thumbnail_source: info.thumbnail_source.clone(),
                });
            }
            MessageType::File(content) => {
                file_desc = content.info.as_ref().map(|info| FileDesc {
                    name: content.body.clone(),
                    mimetype: info.mimetype.clone(),
                    size: info.size.map(u64::from),
                    thumbnail_info: info.thumbnail_info.to_owned().map(|x| *x),
                    thumbnail_source: info.thumbnail_source.clone(),
                });
            }
            _ => {}
        }
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.message".to_string(),
                Some(event.content.msgtype().to_string()),
                Some(text_desc),
                image_desc,
                video_desc,
                file_desc,
                None,
                Default::default(),
                sent_by_me,
            )),
            None,
        )
    }

    pub(crate) fn room_name_from_event(event: OriginalRoomNameEvent, room: &Room) -> Self {
        let text_desc = TextDesc {
            body: match event.content.name {
                Some(name) => format!("changed name to {name}"),
                None => "changed name".to_string(),
            },
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.name".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_name_from_sync_event(event: OriginalSyncRoomNameEvent, room: &Room) -> Self {
        let text_desc = TextDesc {
            body: match event.content.name {
                Some(name) => format!("changed name to {name}"),
                None => "changed name".to_string(),
            },
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.name".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_pinned_events_from_event(
        event: OriginalRoomPinnedEventsEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: format!("pinned {} events", event.content.pinned.len()),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.pinned.events".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_pinned_events_from_sync_event(
        event: OriginalSyncRoomPinnedEventsEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: format!("pinned {} events", event.content.pinned.len()),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.pinned.events".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_power_levels_from_event(
        event: OriginalRoomPowerLevelsEvent,
        room: &Room,
    ) -> Self {
        let users = event
            .content
            .users
            .iter()
            .map(|(user_id, value)| format!("power level of {user_id} to {value}"))
            .collect::<Vec<String>>()
            .join(", ");
        let text_desc = TextDesc {
            body: format!("changed {users}"),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.power.levels".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_power_levels_from_sync_event(
        event: OriginalSyncRoomPowerLevelsEvent,
        room: &Room,
    ) -> Self {
        let users = event
            .content
            .users
            .iter()
            .map(|(user_id, value)| format!("power level of {user_id} to {value}"))
            .collect::<Vec<String>>()
            .join(", ");
        let text_desc = TextDesc {
            body: format!("changed {users}"),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.power.levels".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_redaction_from_event(event: RoomRedactionEvent, room: &Room) -> Self {
        let mut reason = None;
        if let Some(ev) = event.as_original() {
            reason = ev.content.reason.clone();
        }
        let text_desc = TextDesc {
            body: match reason {
                Some(reason) => format!("deleted this item because {reason}"),
                None => "deleted this item".to_string(),
            },
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id().to_string(),
                event.sender().to_string(),
                event.origin_server_ts().get().into(),
                "m.room.redaction".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_redaction_from_sync_event(
        event: SyncRoomRedactionEvent,
        room: &Room,
    ) -> Self {
        let mut reason = None;
        if let Some(ev) = event.as_original() {
            reason = ev.content.reason.clone();
        }
        let text_desc = TextDesc {
            body: match reason {
                Some(reason) => format!("deleted this item because {reason}"),
                None => "deleted this item".to_string(),
            },
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id().to_string(),
                event.sender().to_string(),
                event.origin_server_ts().get().into(),
                "m.room.redaction".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_server_acl_from_event(
        event: OriginalRoomServerAclEvent,
        room: &Room,
    ) -> Self {
        let allow = event.content.allow.join(", ");
        let deny = event.content.deny.join(", ");
        let text_desc = TextDesc {
            body: match (allow.is_empty(), deny.is_empty()) {
                (true, true) => format!("allowed {allow}, denied {deny}"),
                (true, false) => format!("allowed {allow}"),
                (false, true) => format!("denied {deny}"),
                (false, false) => "".to_string(),
            },
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.server.acl".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_server_acl_from_sync_event(
        event: OriginalSyncRoomServerAclEvent,
        room: &Room,
    ) -> Self {
        let allow = event.content.allow.join(", ");
        let deny = event.content.deny.join(", ");
        let text_desc = TextDesc {
            body: match (allow.is_empty(), deny.is_empty()) {
                (true, true) => format!("allowed {allow}, denied {deny}"),
                (true, false) => format!("allowed {allow}"),
                (false, true) => format!("denied {deny}"),
                (false, false) => "".to_string(),
            },
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.server.acl".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_third_party_invite_from_event(
        event: OriginalRoomThirdPartyInviteEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: format!("invited {}", event.content.display_name),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.third.party.invite".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_third_party_invite_from_sync_event(
        event: OriginalSyncRoomThirdPartyInviteEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: format!("invited {}", event.content.display_name),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.third.party.invite".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_tombstone_from_event(
        event: OriginalRoomTombstoneEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: event.content.body,
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.tombstone".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_tombstone_from_sync_event(
        event: OriginalSyncRoomTombstoneEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: event.content.body,
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.tombstone".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_topic_from_event(event: OriginalRoomTopicEvent, room: &Room) -> Self {
        let text_desc = TextDesc {
            body: format!("changed topic to {}", event.content.topic),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.topic".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn room_topic_from_sync_event(
        event: OriginalSyncRoomTopicEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: format!("changed topic to {}", event.content.topic),
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.room.topic".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn space_child_from_event(event: OriginalSpaceChildEvent, room: &Room) -> Self {
        let text_desc = TextDesc {
            body: match event.content.order {
                Some(order) => order,
                None => "".to_string(),
            },
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.space.child".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn space_child_from_sync_event(
        event: OriginalSyncSpaceChildEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: match event.content.order {
                Some(order) => order,
                None => "".to_string(),
            },
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.space.child".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn space_parent_from_event(event: OriginalSpaceParentEvent, room: &Room) -> Self {
        let text_desc = TextDesc {
            body: match event.content.via {
                Some(via) => format!(
                    "changed parent to {}",
                    via.iter()
                        .map(|x| x.to_string())
                        .collect::<Vec<String>>()
                        .join(", "),
                ),
                None => "".to_string(),
            },
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.space.parent".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn space_parent_from_sync_event(
        event: OriginalSyncSpaceParentEvent,
        room: &Room,
    ) -> Self {
        let text_desc = TextDesc {
            body: match event.content.via {
                Some(via) => format!(
                    "changed parent to {}",
                    via.iter()
                        .map(|x| x.to_string())
                        .collect::<Vec<String>>()
                        .join(", "),
                ),
                None => "".to_string(),
            },
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.space.parent".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn sticker_from_event(event: OriginalStickerEvent, room: &Room) -> Self {
        let text_desc = TextDesc {
            body: event.content.body,
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.sticker".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn sticker_from_sync_event(event: OriginalSyncStickerEvent, room: &Room) -> Self {
        let text_desc = TextDesc {
            body: event.content.body,
            formatted_body: None,
        };
        RoomMessage::new(
            "event".to_string(),
            room.room_id().to_string(),
            Some(RoomEventItem::new(
                event.event_id.to_string(),
                event.sender.to_string(),
                event.origin_server_ts.get().into(),
                "m.sticker".to_string(),
                None,
                Some(text_desc),
                None,
                None,
                None,
                None,
                Default::default(),
                false,
            )),
            None,
        )
    }

    pub(crate) fn from_timeline_event_item(event: &EventTimelineItem, room: Room) -> Self {
        let event_id = event.unique_identifier();
        let room_id = room.room_id().to_string();
        let sender = event.sender().to_string();
        let origin_server_ts: u64 = event.timestamp().get().into();
        let mut reactions: HashMap<String, ReactionDesc> = HashMap::new();
        if let Some(evt) = event.as_remote() {
            for (key, value) in evt.reactions().iter() {
                let senders: Vec<OwnedUserId> = value.senders().map(|x| x.to_owned()).collect();
                let description = ReactionDesc::new(senders.len() as u64, senders);
                reactions.insert(key.clone(), description);
            }
        }

        let event_item = match event.content() {
            TimelineItemContent::Message(msg) => {
                let mut sent_by_me = false;
                if let Some(user_id) = room.client().user_id() {
                    if user_id == event.sender() {
                        sent_by_me = true;
                    }
                }
                let sub_type = msg.msgtype();
                let fallback = match sub_type {
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
                let mut text_desc = TextDesc {
                    body: fallback,
                    formatted_body: None,
                };
                let mut image_desc = None;
                let mut video_desc = None;
                let mut file_desc = None;
                let mut is_editable = false;
                match sub_type {
                    MessageType::Text(content) => {
                        if let Some(formatted) = &content.formatted {
                            if formatted.format == MessageFormat::Html {
                                text_desc.set_formatted_body(Some(formatted.body.clone()));
                            }
                        }
                        if sent_by_me {
                            is_editable = true;
                        }
                    }
                    MessageType::Emote(content) => {
                        if sent_by_me {
                            is_editable = true;
                        }
                    }
                    MessageType::Image(content) => {
                        image_desc = content.info.as_ref().map(|info| ImageDesc {
                            name: content.body.clone(),
                            mimetype: info.mimetype.clone(),
                            size: info.size.map(u64::from),
                            width: info.width.map(u64::from),
                            height: info.height.map(u64::from),
                            thumbnail_info: info.thumbnail_info.to_owned().map(|x| *x),
                            thumbnail_source: info.thumbnail_source.clone(),
                        });
                    }
                    MessageType::Video(content) => {
                        video_desc = content.info.as_ref().map(|info| VideoDesc {
                            name: content.body.clone(),
                            mimetype: info.mimetype.clone(),
                            size: info.size.map(u64::from),
                            width: info.width.map(u64::from),
                            height: info.height.map(u64::from),
                            blurhash: info.blurhash.clone(),
                            duration: info.duration,
                            thumbnail_info: info.thumbnail_info.to_owned().map(|x| *x),
                            thumbnail_source: info.thumbnail_source.clone(),
                        });
                    }
                    MessageType::File(content) => {
                        file_desc = content.info.as_ref().map(|info| FileDesc {
                            name: content.body.clone(),
                            mimetype: info.mimetype.clone(),
                            size: info.size.map(u64::from),
                            thumbnail_info: info.thumbnail_info.to_owned().map(|x| *x),
                            thumbnail_source: info.thumbnail_source.clone(),
                        });
                    }
                    _ => {}
                }
                let mut replied_to_id = None;
                if let Some(in_reply_to) = msg.in_reply_to() {
                    replied_to_id = Some(in_reply_to.clone().event_id);
                }
                RoomEventItem::new(
                    event_id,
                    sender,
                    origin_server_ts,
                    "m.room.message".to_string(),
                    Some(sub_type.msgtype().to_string()),
                    Some(text_desc),
                    image_desc,
                    video_desc,
                    file_desc,
                    replied_to_id,
                    reactions,
                    is_editable,
                )
            }
            TimelineItemContent::RedactedMessage => {
                info!("Edit event applies to a redacted message, discarding");
                RoomEventItem::new(
                    event_id,
                    sender,
                    origin_server_ts,
                    "m.room.redaction".to_string(),
                    None,
                    None,
                    None,
                    None,
                    None,
                    None,
                    Default::default(),
                    false,
                )
            }
            TimelineItemContent::Sticker(s) => {
                let content = s.content();
                let image_desc = ImageDesc {
                    name: content.body.clone(),
                    mimetype: content.info.mimetype.clone(),
                    size: content.info.size.map(u64::from),
                    width: content.info.width.map(u64::from),
                    height: content.info.height.map(u64::from),
                    thumbnail_info: content.info.thumbnail_info.to_owned().map(|x| *x),
                    thumbnail_source: content.info.thumbnail_source.clone(),
                };
                RoomEventItem::new(
                    event_id,
                    sender,
                    origin_server_ts,
                    "m.sticker".to_string(),
                    None,
                    None,
                    Some(image_desc),
                    None,
                    None,
                    None,
                    Default::default(),
                    false,
                )
            }
            TimelineItemContent::UnableToDecrypt(encrypted_msg) => {
                info!("Edit event applies to event that couldn't be decrypted, discarding");
                RoomEventItem::new(
                    event_id,
                    sender,
                    origin_server_ts,
                    "m.room.encrypted".to_string(),
                    None,
                    None,
                    None,
                    None,
                    None,
                    None,
                    Default::default(),
                    false,
                )
            }
            TimelineItemContent::MembershipChange(m) => {
                info!("Edit event applies to a state event, discarding");
                let (sub_type, fallback) = match m.change() {
                    Some(MembershipChange::None) => (
                        Some("None".to_string()),
                        "not changed membership".to_string(),
                    ),
                    Some(MembershipChange::Error) => (
                        Some("Error".to_string()),
                        "error in membership change".to_string(),
                    ),
                    Some(MembershipChange::Joined) => {
                        (Some("Joined".to_string()), "joined".to_string())
                    }
                    Some(MembershipChange::Left) => (Some("Left".to_string()), "left".to_string()),
                    Some(MembershipChange::Banned) => {
                        (Some("Banned".to_string()), "banned".to_string())
                    }
                    Some(MembershipChange::Unbanned) => {
                        (Some("Unbanned".to_string()), "unbanned".to_string())
                    }
                    Some(MembershipChange::Kicked) => {
                        (Some("Kicked".to_string()), "kicked".to_string())
                    }
                    Some(MembershipChange::Invited) => {
                        (Some("Invited".to_string()), "invited".to_string())
                    }
                    Some(MembershipChange::KickedAndBanned) => (
                        Some("KickedAndBanned".to_string()),
                        "kicked and banned".to_string(),
                    ),
                    Some(MembershipChange::InvitationAccepted) => (
                        Some("InvitationAccepted".to_string()),
                        "accepted invitation".to_string(),
                    ),
                    Some(MembershipChange::InvitationRejected) => (
                        Some("InvitationRejected".to_string()),
                        "rejected invitation".to_string(),
                    ),
                    Some(MembershipChange::InvitationRevoked) => (
                        Some("InvitationRevoked".to_string()),
                        "revoked invitation".to_string(),
                    ),
                    Some(MembershipChange::Knocked) => {
                        (Some("Knocked".to_string()), "knocked".to_string())
                    }
                    Some(MembershipChange::KnockAccepted) => (
                        Some("KnockAccepted".to_string()),
                        "accepted knock".to_string(),
                    ),
                    Some(MembershipChange::KnockRetracted) => (
                        Some("KnockRetracted".to_string()),
                        "retracted knock".to_string(),
                    ),
                    Some(MembershipChange::KnockDenied) => {
                        (Some("KnockDenied".to_string()), "denied knock".to_string())
                    }
                    Some(MembershipChange::NotImplemented) => (
                        Some("NotImplemented".to_string()),
                        "not implemented change".to_string(),
                    ),
                    _ => (None, "unknown error".to_string()),
                };
                let text_desc = TextDesc {
                    body: fallback,
                    formatted_body: None,
                };
                RoomEventItem::new(
                    event_id,
                    sender,
                    origin_server_ts,
                    "m.room.member".to_string(),
                    sub_type,
                    Some(text_desc),
                    None,
                    None,
                    None,
                    None,
                    Default::default(),
                    false,
                )
            }
            TimelineItemContent::ProfileChange(p) => {
                info!("Edit event applies to a state event, discarding");
                let (text_desc, image_desc) = if let Some(change) = p.displayname_change() {
                    let text_desc = TextDesc {
                        body: format!(
                            "changed display name from {:?} to {:?}",
                            change.old.clone(),
                            change.new.clone(),
                        ),
                        formatted_body: None,
                    };
                    (Some(text_desc), None)
                } else if let Some(change) = p.avatar_url_change() {
                    let text_desc = TextDesc {
                        body: format!(
                            "changed avatar url from {:?} to {:?}",
                            change.old.clone(),
                            change.new.clone(),
                        ),
                        formatted_body: None,
                    };
                    let image_desc = ImageDesc {
                        name: "new_picture".to_string(),
                        mimetype: None,
                        size: None,
                        width: None,
                        height: None,
                        thumbnail_info: None,
                        thumbnail_source: change.new.clone().map(MediaSource::Plain),
                    };
                    (Some(text_desc), Some(image_desc))
                } else {
                    (None, None)
                };
                RoomEventItem::new(
                    event_id,
                    sender,
                    origin_server_ts,
                    "m.room.member".to_string(),
                    Some("ProfileChange".to_string()),
                    text_desc,
                    image_desc,
                    None,
                    None,
                    None,
                    Default::default(),
                    false,
                )
            }
            TimelineItemContent::OtherState(s) => {
                info!("Edit event applies to a state event, discarding");
                RoomEventItem::new(
                    event_id,
                    sender,
                    origin_server_ts,
                    s.content().event_type().to_string(),
                    None,
                    None,
                    None,
                    None,
                    None,
                    None,
                    Default::default(),
                    false,
                )
            }
            TimelineItemContent::FailedToParseMessageLike { event_type, error } => {
                info!("Edit event applies to message that couldn't be parsed, discarding");
                RoomEventItem::new(
                    event_id,
                    sender,
                    origin_server_ts,
                    event_type.to_string(),
                    None,
                    None,
                    None,
                    None,
                    None,
                    None,
                    Default::default(),
                    false,
                )
            }
            TimelineItemContent::FailedToParseState {
                event_type,
                state_key,
                error,
            } => {
                info!("Edit event applies to state that couldn't be parsed, discarding");
                RoomEventItem::new(
                    event_id,
                    sender,
                    origin_server_ts,
                    event_type.to_string(),
                    None,
                    None,
                    None,
                    None,
                    None,
                    None,
                    Default::default(),
                    false,
                )
            }
        };
        RoomMessage::new("event".to_string(), room_id, Some(event_item), None)
    }

    pub(crate) fn from_timeline_virtual_item(event: &VirtualTimelineItem, room: Room) -> Self {
        let room_id = room.room_id().to_string();
        match event {
            VirtualTimelineItem::DayDivider(ts) => {
                let desc = if let Some(st) = ts.to_system_time() {
                    let dt: DateTime<Utc> = st.into();
                    Some(dt.format("%Y-%m-%d").to_string())
                } else {
                    None
                };
                RoomMessage::new(
                    "virtual".to_string(),
                    room_id,
                    None,
                    Some(RoomVirtualItem::new("DayDivider".to_string(), desc)),
                )
            }
            VirtualTimelineItem::LoadingIndicator => RoomMessage::new(
                "virtual".to_string(),
                room_id,
                None,
                Some(RoomVirtualItem::new("LoadingIndicator".to_string(), None)),
            ),
            VirtualTimelineItem::ReadMarker => RoomMessage::new(
                "virtual".to_string(),
                room_id,
                None,
                Some(RoomVirtualItem::new("ReadMarker".to_string(), None)),
            ),
            VirtualTimelineItem::TimelineStart => RoomMessage::new(
                "virtual".to_string(),
                room_id,
                None,
                Some(RoomVirtualItem::new("TimelineStart".to_string(), None)),
            ),
        }
    }

    pub fn item_type(&self) -> String {
        self.item_type.clone()
    }

    pub fn room_id(&self) -> String {
        self.room_id.clone()
    }

    pub fn event_item(&self) -> Option<RoomEventItem> {
        self.event_item.clone()
    }

    pub(crate) fn set_event_item(&mut self, event_item: Option<RoomEventItem>) {
        self.event_item = event_item;
    }

    pub fn virtual_item(&self) -> Option<RoomVirtualItem> {
        self.virtual_item.clone()
    }
}

#[derive(Clone, Debug)]
pub struct TextDesc {
    body: String,
    formatted_body: Option<String>,
}

impl TextDesc {
    pub fn body(&self) -> String {
        self.body.clone()
    }

    pub(crate) fn set_body(&mut self, text: String) {
        self.body = text;
    }

    pub fn formatted_body(&self) -> Option<String> {
        self.formatted_body.clone()
    }

    pub(crate) fn set_formatted_body(&mut self, text: Option<String>) {
        self.formatted_body = text;
    }
}

#[derive(Clone, Debug)]
pub struct ImageDesc {
    name: String,
    mimetype: Option<String>,
    size: Option<u64>,
    width: Option<u64>,
    height: Option<u64>,
    thumbnail_info: Option<ThumbnailInfo>,
    thumbnail_source: Option<MediaSource>,
}

impl ImageDesc {
    pub fn new(name: String, info: ImageInfo) -> Self {
        ImageDesc {
            name,
            mimetype: info.mimetype,
            size: info.size.map(u64::from),
            width: info.width.map(u64::from),
            height: info.height.map(u64::from),
            thumbnail_info: info.thumbnail_info.to_owned().map(|x| *x),
            thumbnail_source: info.thumbnail_source,
        }
    }
    pub fn name(&self) -> String {
        self.name.clone()
    }

    pub fn mimetype(&self) -> Option<String> {
        self.mimetype.clone()
    }

    pub fn size(&self) -> Option<u64> {
        self.size
    }

    pub fn width(&self) -> Option<u64> {
        self.width
    }

    pub fn height(&self) -> Option<u64> {
        self.height
    }

    pub fn thumbnail_mimetype(&self) -> Option<String> {
        match &self.thumbnail_info {
            Some(thumbnail_info) => thumbnail_info.mimetype.clone(),
            None => None,
        }
    }

    pub fn thumbnail_size(&self) -> Option<u64> {
        match &self.thumbnail_info {
            Some(thumbnail_info) => thumbnail_info.size.map(u64::from),
            None => None,
        }
    }

    pub fn thumbnail_width(&self) -> Option<u64> {
        match &self.thumbnail_info {
            Some(thumbnail_info) => thumbnail_info.width.map(u64::from),
            None => None,
        }
    }

    pub fn thumbnail_height(&self) -> Option<u64> {
        match &self.thumbnail_info {
            Some(thumbnail_info) => thumbnail_info.height.map(u64::from),
            None => None,
        }
    }

    pub fn thumbnail_source(&self) -> Option<MediaSource> {
        self.thumbnail_source.clone()
    }
}

#[derive(Clone, Debug)]
pub struct VideoDesc {
    name: String,
    mimetype: Option<String>,
    size: Option<u64>,
    width: Option<u64>,
    height: Option<u64>,
    blurhash: Option<String>,
    duration: Option<Duration>,
    thumbnail_info: Option<ThumbnailInfo>,
    thumbnail_source: Option<MediaSource>,
}

impl VideoDesc {
    pub fn name(&self) -> String {
        self.name.clone()
    }

    pub fn mimetype(&self) -> Option<String> {
        self.mimetype.clone()
    }

    pub fn size(&self) -> Option<u64> {
        self.size
    }

    pub fn width(&self) -> Option<u64> {
        self.width
    }

    pub fn height(&self) -> Option<u64> {
        self.height
    }

    pub fn blurhash(&self) -> Option<String> {
        self.blurhash.clone()
    }

    pub fn duration(&self) -> Option<u64> {
        self.duration.map(|x| x.as_secs())
    }

    pub fn thumbnail_mimetype(&self) -> Option<String> {
        match &self.thumbnail_info {
            Some(thumbnail_info) => thumbnail_info.mimetype.clone(),
            None => None,
        }
    }

    pub fn thumbnail_size(&self) -> Option<u64> {
        match &self.thumbnail_info {
            Some(thumbnail_info) => thumbnail_info.size.map(u64::from),
            None => None,
        }
    }

    pub fn thumbnail_width(&self) -> Option<u64> {
        match &self.thumbnail_info {
            Some(thumbnail_info) => thumbnail_info.width.map(u64::from),
            None => None,
        }
    }

    pub fn thumbnail_height(&self) -> Option<u64> {
        match &self.thumbnail_info {
            Some(thumbnail_info) => thumbnail_info.height.map(u64::from),
            None => None,
        }
    }

    pub fn thumbnail_source(&self) -> Option<MediaSource> {
        self.thumbnail_source.clone()
    }
}

#[derive(Clone, Debug)]
pub struct FileDesc {
    name: String,
    mimetype: Option<String>,
    size: Option<u64>,
    thumbnail_info: Option<ThumbnailInfo>,
    thumbnail_source: Option<MediaSource>,
}

impl FileDesc {
    pub fn name(&self) -> String {
        self.name.clone()
    }

    pub fn mimetype(&self) -> Option<String> {
        self.mimetype.clone()
    }

    pub fn size(&self) -> Option<u64> {
        self.size
    }

    pub fn thumbnail_mimetype(&self) -> Option<String> {
        match &self.thumbnail_info {
            Some(thumbnail_info) => thumbnail_info.mimetype.clone(),
            None => None,
        }
    }

    pub fn thumbnail_size(&self) -> Option<u64> {
        match &self.thumbnail_info {
            Some(thumbnail_info) => thumbnail_info.size.map(u64::from),
            None => None,
        }
    }

    pub fn thumbnail_width(&self) -> Option<u64> {
        match &self.thumbnail_info {
            Some(thumbnail_info) => thumbnail_info.width.map(u64::from),
            None => None,
        }
    }

    pub fn thumbnail_height(&self) -> Option<u64> {
        match &self.thumbnail_info {
            Some(thumbnail_info) => thumbnail_info.height.map(u64::from),
            None => None,
        }
    }

    pub fn thumbnail_source(&self) -> Option<MediaSource> {
        self.thumbnail_source.clone()
    }
}

#[derive(Clone, Debug)]
pub struct ReactionDesc {
    count: u64,
    senders: Vec<OwnedUserId>,
}

impl ReactionDesc {
    pub(crate) fn new(count: u64, senders: Vec<OwnedUserId>) -> Self {
        ReactionDesc { count, senders }
    }

    pub fn count(&self) -> u64 {
        self.count
    }

    pub fn senders(&self) -> Vec<String> {
        self.senders.iter().map(|x| x.to_string()).collect()
    }
}

pub(crate) fn sync_event_to_message(ev: SyncTimelineEvent, room: Room) -> Option<RoomMessage> {
    info!("sync event to message: {:?}", ev);
    let room_id = room.room_id().to_string();
    let mut reactions: HashMap<String, ReactionDesc> = HashMap::new();

    match ev.event.deserialize() {
        Ok(AnySyncTimelineEvent::State(AnySyncStateEvent::PolicyRuleRoom(
            SyncStateEvent::Original(e),
        ))) => {
            return Some(RoomMessage::policy_rule_room_from_sync_event(e, &room));
        }
        Ok(AnySyncTimelineEvent::State(AnySyncStateEvent::PolicyRuleServer(
            SyncStateEvent::Original(e),
        ))) => {
            return Some(RoomMessage::policy_rule_server_from_sync_event(e, &room));
        }
        Ok(AnySyncTimelineEvent::State(AnySyncStateEvent::PolicyRuleUser(
            SyncStateEvent::Original(e),
        ))) => {
            return Some(RoomMessage::policy_rule_user_from_sync_event(e, &room));
        }
        Ok(AnySyncTimelineEvent::State(AnySyncStateEvent::RoomAliases(
            SyncStateEvent::Original(e),
        ))) => {
            return Some(RoomMessage::room_aliases_from_sync_event(e, &room));
        }
        Ok(AnySyncTimelineEvent::State(AnySyncStateEvent::RoomAvatar(
            SyncStateEvent::Original(e),
        ))) => {
            return Some(RoomMessage::room_avatar_from_sync_event(e, &room));
        }
        Ok(AnySyncTimelineEvent::State(AnySyncStateEvent::RoomCanonicalAlias(
            SyncStateEvent::Original(e),
        ))) => {
            return Some(RoomMessage::room_canonical_alias_from_sync_event(e, &room));
        }
        Ok(AnySyncTimelineEvent::State(AnySyncStateEvent::RoomCreate(
            SyncStateEvent::Original(e),
        ))) => {
            return Some(RoomMessage::room_create_from_sync_event(e, &room));
        }
        Ok(AnySyncTimelineEvent::State(AnySyncStateEvent::RoomEncryption(
            SyncStateEvent::Original(e),
        ))) => {
            return Some(RoomMessage::room_encryption_from_sync_event(e, &room));
        }
        Ok(AnySyncTimelineEvent::State(AnySyncStateEvent::RoomGuestAccess(
            SyncStateEvent::Original(e),
        ))) => {
            return Some(RoomMessage::room_guest_access_from_sync_event(e, &room));
        }
        Ok(AnySyncTimelineEvent::State(AnySyncStateEvent::RoomHistoryVisibility(
            SyncStateEvent::Original(e),
        ))) => {
            return Some(RoomMessage::room_history_visibility_from_sync_event(
                e, &room,
            ));
        }
        Ok(AnySyncTimelineEvent::State(AnySyncStateEvent::RoomJoinRules(
            SyncStateEvent::Original(e),
        ))) => {
            return Some(RoomMessage::room_join_rules_from_sync_event(e, &room));
        }
        Ok(AnySyncTimelineEvent::State(AnySyncStateEvent::RoomMember(
            SyncStateEvent::Original(e),
        ))) => {
            return Some(RoomMessage::room_member_from_sync_event(e, &room));
        }
        Ok(AnySyncTimelineEvent::State(AnySyncStateEvent::RoomName(SyncStateEvent::Original(
            e,
        )))) => {
            return Some(RoomMessage::room_name_from_sync_event(e, &room));
        }
        Ok(AnySyncTimelineEvent::State(AnySyncStateEvent::RoomPinnedEvents(
            SyncStateEvent::Original(e),
        ))) => {
            return Some(RoomMessage::room_pinned_events_from_sync_event(e, &room));
        }
        Ok(AnySyncTimelineEvent::State(AnySyncStateEvent::RoomPowerLevels(
            SyncStateEvent::Original(e),
        ))) => {
            return Some(RoomMessage::room_power_levels_from_sync_event(e, &room));
        }
        Ok(AnySyncTimelineEvent::State(AnySyncStateEvent::RoomServerAcl(
            SyncStateEvent::Original(e),
        ))) => {
            return Some(RoomMessage::room_server_acl_from_sync_event(e, &room));
        }
        Ok(AnySyncTimelineEvent::State(AnySyncStateEvent::RoomThirdPartyInvite(
            SyncStateEvent::Original(e),
        ))) => {
            return Some(RoomMessage::room_third_party_invite_from_sync_event(
                e, &room,
            ));
        }
        Ok(AnySyncTimelineEvent::State(AnySyncStateEvent::RoomTombstone(
            SyncStateEvent::Original(e),
        ))) => {
            return Some(RoomMessage::room_tombstone_from_sync_event(e, &room));
        }
        Ok(AnySyncTimelineEvent::State(AnySyncStateEvent::RoomTopic(
            SyncStateEvent::Original(e),
        ))) => {
            return Some(RoomMessage::room_topic_from_sync_event(e, &room));
        }
        Ok(AnySyncTimelineEvent::State(AnySyncStateEvent::SpaceChild(
            SyncStateEvent::Original(e),
        ))) => {
            return Some(RoomMessage::space_child_from_sync_event(e, &room));
        }
        Ok(AnySyncTimelineEvent::State(AnySyncStateEvent::SpaceParent(
            SyncStateEvent::Original(e),
        ))) => {
            return Some(RoomMessage::space_parent_from_sync_event(e, &room));
        }
        Ok(AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::CallAnswer(
            SyncMessageLikeEvent::Original(a),
        ))) => {
            return Some(RoomMessage::call_answer_from_sync_event(a, &room));
        }
        Ok(AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::CallCandidates(
            SyncMessageLikeEvent::Original(c),
        ))) => {
            return Some(RoomMessage::call_candidates_from_sync_event(c, &room));
        }
        Ok(AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::CallHangup(
            SyncMessageLikeEvent::Original(h),
        ))) => {
            return Some(RoomMessage::call_hangup_from_sync_event(h, &room));
        }
        Ok(AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::CallInvite(
            SyncMessageLikeEvent::Original(i),
        ))) => {
            return Some(RoomMessage::call_invite_from_sync_event(i, &room));
        }
        Ok(AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::KeyVerificationAccept(
            SyncMessageLikeEvent::Original(a),
        ))) => {
            return Some(RoomMessage::key_verification_accept_from_sync_event(
                a, &room,
            ));
        }
        Ok(AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::KeyVerificationCancel(
            SyncMessageLikeEvent::Original(c),
        ))) => {
            return Some(RoomMessage::key_verification_cancel_from_sync_event(
                c, &room,
            ));
        }
        Ok(AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::KeyVerificationDone(
            SyncMessageLikeEvent::Original(d),
        ))) => {
            return Some(RoomMessage::key_verification_done_from_sync_event(d, &room));
        }
        Ok(AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::KeyVerificationKey(
            SyncMessageLikeEvent::Original(k),
        ))) => {
            return Some(RoomMessage::key_verification_key_from_sync_event(k, &room));
        }
        Ok(AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::KeyVerificationMac(
            SyncMessageLikeEvent::Original(m),
        ))) => {
            return Some(RoomMessage::key_verification_mac_from_sync_event(m, &room));
        }
        Ok(AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::KeyVerificationReady(
            SyncMessageLikeEvent::Original(r),
        ))) => {
            return Some(RoomMessage::key_verification_ready_from_sync_event(
                r, &room,
            ));
        }
        Ok(AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::KeyVerificationStart(
            SyncMessageLikeEvent::Original(s),
        ))) => {
            return Some(RoomMessage::key_verification_start_from_sync_event(
                s, &room,
            ));
        }
        Ok(AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::Reaction(
            SyncMessageLikeEvent::Original(r),
        ))) => {
            return Some(RoomMessage::reaction_from_sync_event(r, &room));
        }
        Ok(AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::RoomEncrypted(
            SyncMessageLikeEvent::Original(e),
        ))) => {
            return Some(RoomMessage::room_encrypted_from_sync_event(e, &room));
        }
        Ok(AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::RoomMessage(
            SyncMessageLikeEvent::Original(m),
        ))) => {
            return Some(RoomMessage::room_message_from_sync_event(m, &room, false));
        }
        Ok(AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::RoomRedaction(r))) => {
            return Some(RoomMessage::room_redaction_from_sync_event(r, &room));
        }
        Ok(AnySyncTimelineEvent::MessageLike(AnySyncMessageLikeEvent::Sticker(
            SyncMessageLikeEvent::Original(s),
        ))) => {
            return Some(RoomMessage::sticker_from_sync_event(s, &room));
        }
        _ => {}
    }
    None
}

pub(crate) fn timeline_item_to_message(item: Arc<TimelineItem>, room: Room) -> RoomMessage {
    match item.as_ref() {
        TimelineItem::Event(event_item) => RoomMessage::from_timeline_event_item(event_item, room),
        TimelineItem::Virtual(virtual_item) => {
            RoomMessage::from_timeline_virtual_item(virtual_item, room)
        }
    }
}
