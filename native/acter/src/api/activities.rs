use std::ops::Deref;

pub use acter_core::activities::object::ActivityObject;
use acter_core::{
    activities::Activity as CoreActivity,
    models::{status::membership::MembershipChange as CoreMembershipChange, ActerModel},
    referencing::IndexKey,
};
use futures::{FutureExt, Stream, StreamExt};
use matrix_sdk::ruma::{EventId, OwnedEventId, OwnedRoomId, RoomId};
use tokio::sync::broadcast::Receiver;
use tokio_stream::wrappers::BroadcastStream;

use super::{Client, RUNTIME};

use acter_core::activities::ActivityContent;
#[derive(Clone, Debug)]
pub struct MembershipChange(CoreMembershipChange);

impl MembershipChange {
    pub fn user_id_str(&self) -> String {
        self.0.user_id.to_string()
    }
    pub fn display_name(&self) -> Option<String> {
        self.0.display_name.clone()
    }
    pub fn avatar_url(&self) -> Option<String> {
        self.0.avatar_url.as_ref().map(|a| a.to_string())
    }
    pub fn reason(&self) -> Option<String> {
        self.0.reason.clone()
    }
}

#[derive(Clone, Debug)]
pub struct Activity {
    inner: CoreActivity,
    client: Client,
}

impl Activity {
    pub fn content(&self) -> &ActivityContent {
        self.inner.content()
    }

    pub fn membership_change(&self) -> Option<MembershipChange> {
        self.inner.membership_change().map(MembershipChange)
    }

    pub fn sender_id_str(&self) -> String {
        self.inner.event_meta().sender.to_string()
    }

    pub fn origin_server_ts(&self) -> u64 {
        self.inner.event_meta().origin_server_ts.get().into()
    }

    pub fn room_id_str(&self) -> String {
        self.inner.event_meta().room_id.to_string()
    }

    pub fn event_id_str(&self) -> String {
        self.inner.event_meta().event_id.to_string()
    }
}

impl Deref for Activity {
    type Target = CoreActivity;

    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

#[derive(Debug, Clone)]
pub struct Activities {
    index: IndexKey,
    client: Client,
}

impl Activities {
    pub async fn get_ids(&self, offset: u32, limit: u32) -> anyhow::Result<Vec<String>> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                anyhow::Ok(
                    me.iter()
                        .await?
                        .map(|e| e.event_meta().event_id.to_string())
                        .skip(offset as usize)
                        .take(limit as usize)
                        .collect()
                        .await,
                )
            })
            .await?
    }

    pub async fn iter(&self) -> anyhow::Result<impl Stream<Item = CoreActivity> + '_> {
        let store = self.client.store();
        Ok(
            futures::stream::iter(self.client.store().get_list(&self.index).await?)
                .filter_map(|a| async { CoreActivity::for_acter_model(store, a).await.ok() }),
        )
    }

    pub fn subscribe_stream(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.subscribe()).map(|f| true)
    }

    pub fn subscribe(&self) -> Receiver<()> {
        self.client.subscribe(self.index.clone())
    }
}

impl Client {
    pub async fn activity(&self, key: String) -> anyhow::Result<Activity> {
        let ev_id = EventId::parse(key)?;
        let client = self.clone();

        Ok(RUNTIME
            .spawn(async move {
                client
                    .core
                    .activity(&ev_id)
                    .await
                    .map(|inner| Activity { inner, client })
            })
            .await??)
    }

    pub fn activities_for_room(&self, room_id: String) -> anyhow::Result<Activities> {
        Ok(Activities {
            index: IndexKey::RoomHistory(RoomId::parse(room_id)?),
            client: self.clone(),
        })
    }
    pub fn activities_for_obj(&self, object_id: String) -> anyhow::Result<Activities> {
        Ok(Activities {
            index: IndexKey::ObjectHistory(EventId::parse(object_id)?),
            client: self.clone(),
        })
    }
}
