use acter_core::models;
use anyhow::Result;
use futures::stream::StreamExt;
use matrix_sdk::room::Room;
use matrix_sdk_base::ruma::OwnedEventId;
use tokio::sync::broadcast::Receiver;
use tokio_stream::{wrappers::BroadcastStream, Stream};

use super::{client::Client, RUNTIME};

#[derive(Clone, Debug)]
pub struct ReadReceiptsManager {
    client: Client,
    room: Room,
    event_id: OwnedEventId,
    inner: models::ReadReceiptsManager,
}

impl ReadReceiptsManager {
    pub(crate) async fn new(
        client: Client,
        room: Room,
        event_id: OwnedEventId,
    ) -> Result<ReadReceiptsManager> {
        RUNTIME
            .spawn(async move {
                let inner =
                    models::ReadReceiptsManager::from_store_and_event_id(client.store(), &event_id)
                        .await;
                Ok(ReadReceiptsManager {
                    client,
                    room,
                    event_id,
                    inner,
                })
            })
            .await?
    }

    pub async fn reload(&self) -> Result<ReadReceiptsManager> {
        ReadReceiptsManager::new(
            self.client.clone(),
            self.room.clone(),
            self.event_id.clone(),
        )
        .await
    }

    pub fn update_key(&self) -> String {
        self.inner.update_key()
    }

    pub async fn announce_read(&self) -> Result<bool> {
        let room = self.room.clone();
        let event = self.inner.construct_read_event();

        RUNTIME
            .spawn(async move {
                room.send(event).await?;
                Ok(true)
            })
            .await?
    }

    pub fn read_count(&self) -> u32 {
        self.inner.stats.total_views
    }

    pub fn read_by_me(&self) -> bool {
        self.inner.stats.user_has_read
    }

    pub fn subscribe_stream(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.subscribe()).map(|f| true)
    }

    pub fn subscribe(&self) -> Receiver<()> {
        self.client.subscribe(self.update_key())
    }
}
