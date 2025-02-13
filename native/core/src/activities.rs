use matrix_sdk::ruma::OwnedEventId;

use crate::{
    client::CoreClient,
    models::{
        status::membership::MembershipChange, ActerModel, ActerSupportedRoomStatusEvents,
        AnyActerModel, EventMeta,
    },
};

pub mod status;

#[derive(Clone, Debug)]
pub enum ActivityContent {
    MembershipChange(MembershipChange),
}

#[derive(Clone, Debug)]
pub struct Activity {
    inner: ActivityContent,
    meta: EventMeta,
}

impl Activity {
    fn new(meta: EventMeta, inner: ActivityContent) -> Self {
        Self { meta, inner }
    }
    pub fn content(&self) -> &ActivityContent {
        &self.inner
    }

    pub fn type_str(&self) -> String {
        match &self.inner {
            ActivityContent::MembershipChange(c) => c.as_str().to_owned(),
        }
    }

    pub fn membership_change(&self) -> Option<MembershipChange> {
        #[allow(irrefutable_let_patterns)]
        let ActivityContent::MembershipChange(c) = &self.inner
        else {
            return None;
        };
        Some(c.clone())
    }

    pub fn event_meta(&self) -> &EventMeta {
        &self.meta
    }
}

impl TryFrom<AnyActerModel> for Activity {
    type Error = crate::Error;

    fn try_from(mdl: AnyActerModel) -> Result<Self, Self::Error> {
        if let AnyActerModel::RoomStatus(s) = mdl {
            let meta = s.event_meta().clone();
            match s.inner {
                ActerSupportedRoomStatusEvents::MembershipChange(c) => {
                    return Ok(Self::new(meta, ActivityContent::MembershipChange(c)))
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
