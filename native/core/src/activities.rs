use matrix_sdk::ruma::OwnedEventId;

use crate::{
    client::CoreClient,
    models::{status::membership::MembershipChange, ActerSupportedRoomStatusEvents, AnyActerModel},
};

pub mod status;

#[derive(Clone, Debug)]
pub enum Activity {
    MembershipChange(MembershipChange),
}

impl Activity {
    pub fn type_str(&self) -> String {
        match self {
            Activity::MembershipChange(c) => c.as_str().to_owned(),
        }
    }

    pub fn membership_change(&self) -> Option<MembershipChange> {
        #[allow(irrefutable_let_patterns)]
        let Activity::MembershipChange(c) = self
        else {
            return None;
        };
        Some(c.clone())
    }
}

impl TryFrom<AnyActerModel> for Activity {
    type Error = crate::Error;

    fn try_from(mdl: AnyActerModel) -> Result<Self, Self::Error> {
        if let AnyActerModel::RoomStatus(s) = mdl {
            match s.inner {
                ActerSupportedRoomStatusEvents::MembershipChange(c) => {
                    return Ok(Self::MembershipChange(c))
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
