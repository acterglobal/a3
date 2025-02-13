use matrix_sdk::ruma::{events::room::create::RoomCreateEventContent, OwnedEventId};

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
    RoomCreate(RoomCreateEventContent),
    RoomName(String),
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
            ActivityContent::RoomCreate(_) => "roomCreate".to_owned(),
            ActivityContent::RoomName(_) => "roomName".to_owned(),
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
        let AnyActerModel::RoomStatus(s) = mdl else {
            return Err(crate::Error::Custom(
                "Converting model into activity not yet supported".to_string(),
            ));
        };
        let meta = s.event_meta().clone();
        match s.inner {
            ActerSupportedRoomStatusEvents::MembershipChange(c) => {
                Ok(Self::new(meta, ActivityContent::MembershipChange(c)))
            }
            ActerSupportedRoomStatusEvents::RoomCreate(c) => {
                Ok(Self::new(meta, ActivityContent::RoomCreate(c)))
            }
            ActerSupportedRoomStatusEvents::RoomName(c) => {
                Ok(Self::new(meta, ActivityContent::RoomName(c)))
            }
        }
        // fallback for everything else for now
    }
}

impl CoreClient {
    pub async fn activity(&self, key: &OwnedEventId) -> crate::Result<Activity> {
        self.store.get(key).await?.try_into()
    }
}
