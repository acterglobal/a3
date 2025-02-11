use matrix_sdk::ruma::{events::room::member::RoomMemberEventContent, OwnedEventId};

use crate::{
    client::CoreClient,
    models::{status::membership::MembershipChange, ActerSupportedRoomStatusEvents, AnyActerModel},
};

mod status;

#[derive(Clone, Debug)]
pub enum Activity {
    MembershipChange(RoomMemberEventContent, MembershipChange),
}

impl TryFrom<AnyActerModel> for Activity {
    type Error = crate::Error;

    fn try_from(mdl: AnyActerModel) -> Result<Self, Self::Error> {
        if let AnyActerModel::RoomStatus(s) = mdl {
            match s.inner {
                ActerSupportedRoomStatusEvents::MembershipChange(r, c) => {
                    return Ok(Self::MembershipChange(r, c))
                }
                ActerSupportedRoomStatusEvents::RoomCreate(_) => {}
            }
        };
        // fallback for everything else for now
        Err(crate::Error::Custom(
            "Converting model into activity not yet supported".to_string(),
        ))
    }
}

impl CoreClient {
    pub async fn activity(&self, key: &OwnedEventId) -> crate::Result<Activity> {
        self.store.get(key).await?.try_into()
    }
}
