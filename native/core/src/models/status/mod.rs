use matrix_sdk::ruma::{
    events::{
        room::{
            member::MembershipChange as MChange, name::RoomNameEventContent,
            topic::RoomTopicEventContent,
        },
        AnyStateEvent, AnyTimelineEvent, StateEvent,
    },
    OwnedEventId, UserId,
};
use serde::{Deserialize, Serialize};
use std::ops::Deref;

mod membership;
mod profile;
mod room_state;

use crate::{
    events::AnyActerEvent,
    referencing::{ExecuteReference, IndexKey},
};
pub use membership::MembershipContent;
pub use profile::{Change, ProfileContent};
pub use room_state::{
    PolicyRuleRoomContent, PolicyRuleServerContent, PolicyRuleUserContent, RoomAvatarContent,
    RoomCreateContent, RoomEncryptionContent, RoomGuestAccessContent, RoomHistoryVisibilityContent,
    RoomJoinRulesContent,
};

use super::{conversion::ParseError, ActerModel, Capability, EventMeta, Store};

#[derive(Clone, Debug, Deserialize, Serialize)]
pub enum ActerSupportedRoomStatusEvents {
    MembershipChange(MembershipContent),
    ProfileChange(ProfileContent),
    PolicyRuleRoom(PolicyRuleRoomContent),
    PolicyRuleServer(PolicyRuleServerContent),
    PolicyRuleUser(PolicyRuleUserContent),
    RoomAvatar(RoomAvatarContent),
    RoomCreate(RoomCreateContent),
    RoomEncryption(RoomEncryptionContent),
    RoomGuestAccess(RoomGuestAccessContent),
    RoomHistoryVisibility(RoomHistoryVisibilityContent),
    RoomJoinRules(RoomJoinRulesContent),
    RoomName(RoomNameEventContent),
    RoomTopic(RoomTopicEventContent),
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
            AnyStateEvent::RoomName(StateEvent::Original(inner)) => Ok(RoomStatus {
                inner: ActerSupportedRoomStatusEvents::RoomName(inner.content.clone()),
                meta,
            }),
            AnyStateEvent::RoomTopic(StateEvent::Original(inner)) => Ok(RoomStatus {
                inner: ActerSupportedRoomStatusEvents::RoomTopic(inner.content.clone()),
                meta,
            }),
            AnyStateEvent::RoomMember(StateEvent::Original(inner)) => {
                let membership_change = inner.content.membership_change(
                    inner.prev_content().map(|c| c.details()),
                    &inner.sender,
                    &inner.state_key,
                );
                let inner_status = if let MChange::ProfileChanged {
                    displayname_change,
                    avatar_url_change,
                } = membership_change
                {
                    let content = ProfileContent::new(
                        inner.state_key.clone(),
                        displayname_change.map(|c| Change {
                            new_val: c.new.map(ToOwned::to_owned),
                            old_val: c.old.map(ToOwned::to_owned),
                        }),
                        avatar_url_change.map(|c| Change {
                            new_val: c.new.map(ToOwned::to_owned),
                            old_val: c.old.map(ToOwned::to_owned),
                        }),
                    );
                    ActerSupportedRoomStatusEvents::ProfileChange(content)
                } else if let Ok(content) =
                    MembershipContent::try_from((membership_change, inner.state_key.clone()))
                {
                    ActerSupportedRoomStatusEvents::MembershipChange(content)
                } else {
                    return Err(make_err(event));
                };
                Ok(RoomStatus {
                    inner: inner_status,
                    meta,
                })
            }
            AnyStateEvent::PolicyRuleRoom(StateEvent::Original(inner)) => {
                let content = PolicyRuleRoomContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::PolicyRuleRoom(content),
                    meta,
                })
            }
            AnyStateEvent::PolicyRuleServer(StateEvent::Original(inner)) => {
                let content = PolicyRuleServerContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::PolicyRuleServer(content),
                    meta,
                })
            }
            AnyStateEvent::PolicyRuleUser(StateEvent::Original(inner)) => {
                let content = PolicyRuleUserContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::PolicyRuleUser(content),
                    meta,
                })
            }
            AnyStateEvent::RoomAvatar(StateEvent::Original(inner)) => {
                let content = RoomAvatarContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::RoomAvatar(content),
                    meta,
                })
            }
            AnyStateEvent::RoomCreate(StateEvent::Original(inner)) => {
                let content = RoomCreateContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::RoomCreate(content),
                    meta,
                })
            }
            AnyStateEvent::RoomEncryption(StateEvent::Original(inner)) => {
                let content = RoomEncryptionContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::RoomEncryption(content),
                    meta,
                })
            }
            AnyStateEvent::RoomGuestAccess(StateEvent::Original(inner)) => {
                let content = RoomGuestAccessContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::RoomGuestAccess(content),
                    meta,
                })
            }
            AnyStateEvent::RoomHistoryVisibility(StateEvent::Original(inner)) => {
                let content = RoomHistoryVisibilityContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::RoomHistoryVisibility(content),
                    meta,
                })
            }
            AnyStateEvent::RoomJoinRules(StateEvent::Original(inner)) => {
                let content = RoomJoinRulesContent::new(
                    inner.content.clone(),
                    inner.unsigned.prev_content.clone(),
                );
                Ok(RoomStatus {
                    inner: ActerSupportedRoomStatusEvents::RoomJoinRules(content),
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
