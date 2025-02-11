use acter_core::{activities::Activity as CoreActivity, models::ActerModel, referencing::IndexKey};
use futures::{FutureExt, Stream, StreamExt};
use ruma::{EventId, OwnedEventId, OwnedRoomId, RoomId};
use tokio::sync::broadcast::Receiver;
use tokio_stream::wrappers::BroadcastStream;

use super::{Client, RUNTIME};

#[derive(Clone, Debug)]
pub struct Activity {
    inner: CoreActivity,
    client: Client,
}

impl Activity {
    #[cfg(any(test, feature = "testing"))]
    pub fn inner(&self) -> CoreActivity {
        self.inner.clone()
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
                    me.client
                        .store()
                        .get_list(&me.index)
                        .await?
                        .filter_map(|a| {
                            let event_id = a.event_id().to_string();
                            CoreActivity::try_from(a).map(|_| event_id).ok()
                        })
                        .skip(offset as usize)
                        .take(limit as usize)
                        .collect(),
                )
            })
            .await?
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
