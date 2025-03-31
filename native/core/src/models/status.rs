use matrix_sdk::ruma::{
    events::{
        room::member::MembershipChange as MChange, AnyStateEvent, AnyTimelineEvent, StateEvent,
    },
    OwnedEventId, OwnedMxcUri, OwnedUserId, UserId,
};
use serde::{Deserialize, Serialize};
use std::ops::Deref;

pub mod membership;
pub mod room_state;

use crate::{
    events::AnyActerEvent,
    referencing::{ExecuteReference, IndexKey},
};
use membership::Change;
use room_state::{
    OtherState, PolicyRuleRoomContent, PolicyRuleServerContent, PolicyRuleUserContent,
    RoomAliasesContent, RoomAvatarContent, RoomCanonicalAliasContent, RoomCreateContent,
    RoomEncryptionContent, RoomGuestAccessContent, RoomHistoryVisibilityContent,
    RoomJoinRulesContent, RoomNameContent, RoomPinnedEventsContent, RoomPowerLevelsContent,
    RoomServerAclContent, RoomThirdPartyInviteContent, RoomTombstoneContent, RoomTopicContent,
    SpaceChildContent, SpaceParentContent,
};

use super::{conversion::ParseError, ActerModel, Capability, EventMeta, Store};

#[derive(Clone, Debug, Deserialize, Serialize)]
pub enum ActerSupportedRoomStatusEvents {
    MembershipChange {
        user_id: OwnedUserId,
        change: Option<String>,
    },
    ProfileChange {
        user_id: OwnedUserId,
        display_name_change: Option<Change<Option<String>>>,
        avatar_url_change: Option<Change<Option<OwnedMxcUri>>>,
    },
    OtherState(OtherState),
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct RoomStatus {
    pub(crate) inner: ActerSupportedRoomStatusEvents,
    pub meta: EventMeta,
}

impl Deref for RoomStatus {
    type Target = ActerSupportedRoomStatusEvents;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl TryFrom<AnyStateEvent> for RoomStatus {
    type Error = ParseError;

    fn try_from(event: AnyStateEvent) -> Result<RoomStatus, ParseError> {
        let meta = EventMeta {
            event_id: event.event_id().to_owned(),
            room_id: event.room_id().to_owned(),
            sender: event.sender().to_owned(),
            origin_server_ts: event.origin_server_ts(),
            redacted: None,
        };
        let make_err = |event| {
            ParseError::UnsupportedEvent(AnyActerEvent::RegularTimelineEvent(
                AnyTimelineEvent::State(event),
            ))
        };
        match &event {
            AnyStateEvent::RoomMember(StateEvent::Original(inner)) => {
                let user_id = inner.state_key.clone();
                let membership_change = inner.content.membership_change(
                    inner.prev_content().map(|c| c.details()),
                    &inner.sender,
                    &user_id,
                );
                let inner_status = if let MChange::ProfileChanged {
                    displayname_change,
                    avatar_url_change,
                } = membership_change
                {
                    ActerSupportedRoomStatusEvents::ProfileChange {
                        user_id,
                        display_name_change: displayname_change.map(|c| Change {
                            new_val: c.new.map(ToOwned::to_owned),
                            old_val: c.old.map(ToOwned::to_owned),
                        }),
                        avatar_url_change: avatar_url_change.map(|c| Change {
                            new_val: c.new.map(ToOwned::to_owned),
                            old_val: c.old.map(ToOwned::to_owned),
                        }),
                    }
                } else {
                    let change = match membership_change {
                        MChange::None => "None",
                        MChange::Error => "Error",
                        MChange::Joined => "Joined",
                        MChange::Left => "Left",
                        MChange::Banned => "Banned",
                        MChange::Unbanned => "Unbanned",
                        MChange::Kicked => "Kicked",
                        MChange::Invited => "Invited",
                        MChange::KickedAndBanned => "KickedAndBanned",
                        MChange::InvitationAccepted => "InvitationAccepted",
                        MChange::InvitationRejected => "InvitationRejected",
                        MChange::InvitationRevoked => "InvitationRevoked",
                        MChange::Knocked => "Knocked",
                        MChange::KnockAccepted => "KnockAccepted",
                        MChange::KnockRetracted => "KnockRetracted",
                        MChange::KnockDenied => "KnockDenied",
                        MChange::ProfileChanged { .. } => unreachable!(),
                        _ => "NotImplemented",
                    };
                    ActerSupportedRoomStatusEvents::MembershipChange {
                        user_id,
                        change: Some(change.to_owned()),
                    }
                };
                Ok(RoomStatus {
                    inner: inner_status,
                    meta,
                })
            }
            AnyStateEvent::PolicyRuleRoom(StateEvent::Original(inner)) => {
                let c = PolicyRuleRoomContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::OtherState(OtherState::PolicyRuleRoom(
                        c,
                    )),
                    meta,
                })
            }
            AnyStateEvent::PolicyRuleServer(StateEvent::Original(inner)) => {
                let c = PolicyRuleServerContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::OtherState(
                        OtherState::PolicyRuleServer(c),
                    ),
                    meta,
                })
            }
            AnyStateEvent::PolicyRuleUser(StateEvent::Original(inner)) => {
                let c = PolicyRuleUserContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::OtherState(OtherState::PolicyRuleUser(
                        c,
                    )),
                    meta,
                })
            }
            AnyStateEvent::RoomAliases(StateEvent::Original(inner)) => {
                let c = RoomAliasesContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::OtherState(OtherState::RoomAliases(c)),
                    meta,
                })
            }
            AnyStateEvent::RoomAvatar(StateEvent::Original(inner)) => {
                let c = RoomAvatarContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::OtherState(OtherState::RoomAvatar(c)),
                    meta,
                })
            }
            AnyStateEvent::RoomCanonicalAlias(StateEvent::Original(inner)) => {
                let c = RoomCanonicalAliasContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::OtherState(
                        OtherState::RoomCanonicalAlias(c),
                    ),
                    meta,
                })
            }
            AnyStateEvent::RoomCreate(StateEvent::Original(inner)) => {
                let c = RoomCreateContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::OtherState(OtherState::RoomCreate(c)),
                    meta,
                })
            }
            AnyStateEvent::RoomEncryption(StateEvent::Original(inner)) => {
                let c = RoomEncryptionContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::OtherState(OtherState::RoomEncryption(
                        c,
                    )),
                    meta,
                })
            }
            AnyStateEvent::RoomGuestAccess(StateEvent::Original(inner)) => {
                let c = RoomGuestAccessContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::OtherState(OtherState::RoomGuestAccess(
                        c,
                    )),
                    meta,
                })
            }
            AnyStateEvent::RoomHistoryVisibility(StateEvent::Original(inner)) => {
                let c = RoomHistoryVisibilityContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::OtherState(
                        OtherState::RoomHistoryVisibility(c),
                    ),
                    meta,
                })
            }
            AnyStateEvent::RoomJoinRules(StateEvent::Original(inner)) => {
                let c = RoomJoinRulesContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::OtherState(OtherState::RoomJoinRules(c)),
                    meta,
                })
            }
            AnyStateEvent::RoomName(StateEvent::Original(inner)) => {
                let c = RoomNameContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::OtherState(OtherState::RoomName(c)),
                    meta,
                })
            }
            AnyStateEvent::RoomPinnedEvents(StateEvent::Original(inner)) => {
                let c = RoomPinnedEventsContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::OtherState(
                        OtherState::RoomPinnedEvents(c),
                    ),
                    meta,
                })
            }
            AnyStateEvent::RoomPowerLevels(StateEvent::Original(inner)) => {
                let c = RoomPowerLevelsContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::OtherState(OtherState::RoomPowerLevels(
                        c,
                    )),
                    meta,
                })
            }
            AnyStateEvent::RoomServerAcl(StateEvent::Original(inner)) => {
                let c = RoomServerAclContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::OtherState(OtherState::RoomServerAcl(c)),
                    meta,
                })
            }
            AnyStateEvent::RoomThirdPartyInvite(StateEvent::Original(inner)) => {
                let c = RoomThirdPartyInviteContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::OtherState(
                        OtherState::RoomThirdPartyInvite(c),
                    ),
                    meta,
                })
            }
            AnyStateEvent::RoomTombstone(StateEvent::Original(inner)) => {
                let c = RoomTombstoneContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::OtherState(OtherState::RoomTombstone(c)),
                    meta,
                })
            }
            AnyStateEvent::RoomTopic(StateEvent::Original(inner)) => {
                let c = RoomTopicContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::OtherState(OtherState::RoomTopic(c)),
                    meta,
                })
            }
            AnyStateEvent::SpaceChild(StateEvent::Original(inner)) => {
                let c = SpaceChildContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::OtherState(OtherState::SpaceChild(c)),
                    meta,
                })
            }
            AnyStateEvent::SpaceParent(StateEvent::Original(inner)) => {
                let c = SpaceParentContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::OtherState(OtherState::SpaceParent(c)),
                    meta,
                })
            }
            _ => Err(make_err(event)),
        }
    }
}

impl ActerModel for RoomStatus {
    fn indizes(&self, _user_id: &UserId) -> Vec<IndexKey> {
        vec![IndexKey::RoomHistory(self.meta.room_id.to_owned())]
    }

    fn event_meta(&self) -> &EventMeta {
        &self.meta
    }

    fn capabilities(&self) -> &[Capability] {
        &[]
    }

    fn belongs_to(&self) -> Option<Vec<OwnedEventId>> {
        // Do not trigger the parent to update, we have a manager
        None
    }

    async fn execute(self, store: &Store) -> crate::Result<Vec<ExecuteReference>> {
        store.save(self.into()).await
    }
}

// room state change
impl RoomStatus {
    pub fn policy_rule_room(&self) -> Option<PolicyRuleRoomContent> {
        if let ActerSupportedRoomStatusEvents::OtherState(OtherState::PolicyRuleRoom(c)) =
            &self.inner
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn policy_rule_server(&self) -> Option<PolicyRuleServerContent> {
        if let ActerSupportedRoomStatusEvents::OtherState(OtherState::PolicyRuleServer(c)) =
            &self.inner
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn policy_rule_user(&self) -> Option<PolicyRuleUserContent> {
        if let ActerSupportedRoomStatusEvents::OtherState(OtherState::PolicyRuleUser(c)) =
            &self.inner
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_aliases(&self) -> Option<RoomAliasesContent> {
        if let ActerSupportedRoomStatusEvents::OtherState(OtherState::RoomAliases(c)) = &self.inner
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_avatar(&self) -> Option<RoomAvatarContent> {
        if let ActerSupportedRoomStatusEvents::OtherState(OtherState::RoomAvatar(c)) = &self.inner {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_canonical_alias(&self) -> Option<RoomCanonicalAliasContent> {
        if let ActerSupportedRoomStatusEvents::OtherState(OtherState::RoomCanonicalAlias(c)) =
            &self.inner
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_create(&self) -> Option<RoomCreateContent> {
        if let ActerSupportedRoomStatusEvents::OtherState(OtherState::RoomCreate(c)) = &self.inner {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_encryption(&self) -> Option<RoomEncryptionContent> {
        if let ActerSupportedRoomStatusEvents::OtherState(OtherState::RoomEncryption(c)) =
            &self.inner
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_guest_access(&self) -> Option<RoomGuestAccessContent> {
        if let ActerSupportedRoomStatusEvents::OtherState(OtherState::RoomGuestAccess(c)) =
            &self.inner
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_history_visibility(&self) -> Option<RoomHistoryVisibilityContent> {
        if let ActerSupportedRoomStatusEvents::OtherState(OtherState::RoomHistoryVisibility(c)) =
            &self.inner
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_join_rules(&self) -> Option<RoomJoinRulesContent> {
        if let ActerSupportedRoomStatusEvents::OtherState(OtherState::RoomJoinRules(c)) =
            &self.inner
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_name(&self) -> Option<RoomNameContent> {
        if let ActerSupportedRoomStatusEvents::OtherState(OtherState::RoomName(c)) = &self.inner {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_pinned_events(&self) -> Option<RoomPinnedEventsContent> {
        if let ActerSupportedRoomStatusEvents::OtherState(OtherState::RoomPinnedEvents(c)) =
            &self.inner
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_power_levels(&self) -> Option<RoomPowerLevelsContent> {
        if let ActerSupportedRoomStatusEvents::OtherState(OtherState::RoomPowerLevels(c)) =
            &self.inner
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_server_acl(&self) -> Option<RoomServerAclContent> {
        if let ActerSupportedRoomStatusEvents::OtherState(OtherState::RoomServerAcl(c)) =
            &self.inner
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_third_party_invite(&self) -> Option<RoomThirdPartyInviteContent> {
        if let ActerSupportedRoomStatusEvents::OtherState(OtherState::RoomThirdPartyInvite(c)) =
            &self.inner
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_tombstone(&self) -> Option<RoomTombstoneContent> {
        if let ActerSupportedRoomStatusEvents::OtherState(OtherState::RoomTombstone(c)) =
            &self.inner
        {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn room_topic(&self) -> Option<RoomTopicContent> {
        if let ActerSupportedRoomStatusEvents::OtherState(OtherState::RoomTopic(c)) = &self.inner {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn space_child(&self) -> Option<SpaceChildContent> {
        if let ActerSupportedRoomStatusEvents::OtherState(OtherState::SpaceChild(c)) = &self.inner {
            Some(c.clone())
        } else {
            None
        }
    }

    pub fn space_parent(&self) -> Option<SpaceParentContent> {
        if let ActerSupportedRoomStatusEvents::OtherState(OtherState::SpaceParent(c)) = &self.inner
        {
            Some(c.clone())
        } else {
            None
        }
    }
}
