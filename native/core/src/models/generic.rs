use std::ops::Deref;

use matrix_sdk::ruma::{
    events::{
        room::{
            create::RoomCreateEventContent,
            member::{MembershipChange, RoomMemberEventContent},
        },
        AnyStateEvent, AnyTimelineEvent, StateEvent,
    },
    OwnedEventId, UserId,
};
use serde::{Deserialize, Serialize};

use crate::{
    events::AnyActerEvent,
    referencing::{ExecuteReference, IndexKey},
};

use super::{conversion::ParseError, ActerModel, Capability, EventMeta, Store};

#[derive(Clone, Debug, Deserialize, Serialize)]
pub enum ActerSupportedRoomStatusEvents {
    RoomCreate(RoomCreateEventContent),
    MemberInvited(RoomMemberEventContent),
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
        match &event {
            AnyStateEvent::RoomCreate(StateEvent::Original(inner)) => Ok(RoomStatus {
                inner: ActerSupportedRoomStatusEvents::RoomCreate(inner.content.clone()),
                meta,
            }),
            AnyStateEvent::RoomMember(StateEvent::Original(inner)) => {
                match inner.membership_change() {
                    MembershipChange::Invited => Ok(RoomStatus {
                        inner: ActerSupportedRoomStatusEvents::MemberInvited(inner.content.clone()),
                        meta,
                    }),
                    _ => Err(Self::Error::UnsupportedEvent(
                        AnyActerEvent::RegularTimelineEvent(AnyTimelineEvent::State(event)),
                    )),
                }
            }
            _ => Err(Self::Error::UnsupportedEvent(
                AnyActerEvent::RegularTimelineEvent(AnyTimelineEvent::State(event)),
            )),
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
