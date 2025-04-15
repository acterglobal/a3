use matrix_sdk::ruma::{
    events::{
        room::{create::RoomCreateEventContent, member::MembershipChange as MChange},
        AnyStateEvent, AnyTimelineEvent, StateEvent,
    },
    OwnedEventId, UserId,
};
use serde::{Deserialize, Serialize};
use std::ops::Deref;

mod membership;
mod profile;

use crate::{
    events::AnyActerEvent,
    referencing::{ExecuteReference, IndexKey},
};
pub use membership::MembershipContent;
pub use profile::{Change, ProfileContent};

use super::{conversion::ParseError, ActerModel, Capability, EventMeta, Store};

#[derive(Clone, Debug, Deserialize, Serialize)]
pub enum ActerSupportedRoomStatusEvents {
    MembershipChange(MembershipContent),
    ProfileChange(ProfileContent),
    RoomCreate(RoomCreateEventContent),
    RoomName(String),
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
            AnyStateEvent::RoomCreate(StateEvent::Original(inner)) => Ok(RoomStatus {
                inner: ActerSupportedRoomStatusEvents::RoomCreate(inner.content.clone()),
                meta,
            }),
            AnyStateEvent::RoomName(StateEvent::Original(inner)) => Ok(RoomStatus {
                inner: ActerSupportedRoomStatusEvents::RoomName(inner.content.name.clone()),
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
