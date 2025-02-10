use crate::EventCacheStore;
use async_trait::async_trait;
use matrix_sdk_base::{
    event_cache::{Event, Gap},
    linked_chunk::{RawChunk, Update},
    media::MediaRequestParameters,
    ruma::{MxcUri, RoomId},
};
use std::sync::Arc;
use tokio::sync::Semaphore;
use tracing::instrument;

#[derive(Debug)]
pub struct QueuedEventCacheStore<T>
where
    T: EventCacheStore,
{
    inner: T,
    queue: Arc<Semaphore>,
}

impl<T> QueuedEventCacheStore<T>
where
    T: EventCacheStore,
{
    pub fn new(store: T, queue_size: usize) -> Self {
        QueuedEventCacheStore {
            inner: store,
            queue: Arc::new(Semaphore::new(queue_size)),
        }
    }
}

#[async_trait]
impl<T> EventCacheStore for QueuedEventCacheStore<T>
where
    T: EventCacheStore,
{
    type Error = T::Error;

    async fn try_take_leased_lock(
        &self,
        lease_duration_ms: u32,
        key: &str,
        holder: &str,
    ) -> Result<bool, Self::Error> {
        let _handle = self
            .queue
            .acquire()
            .await
            .expect("We never close the semaphore");
        self.inner
            .try_take_leased_lock(lease_duration_ms, key, holder)
            .await
    }

    async fn handle_linked_chunk_updates(
        &self,
        room_id: &RoomId,
        updates: Vec<Update<Event, Gap>>,
    ) -> Result<(), Self::Error> {
        let _handle = self
            .queue
            .acquire()
            .await
            .expect("We never close the semaphore");
        self.inner
            .handle_linked_chunk_updates(room_id, updates)
            .await
    }

    async fn reload_linked_chunk(
        &self,
        room_id: &RoomId,
    ) -> Result<Vec<RawChunk<Event, Gap>>, Self::Error> {
        let _handle = self
            .queue
            .acquire()
            .await
            .expect("We never close the semaphore");
        self.inner
            .reload_linked_chunk(room_id)
            .await
    }

    async fn clear_all_rooms_chunks(&self) -> Result<(), Self::Error> {
        self.inner.clear_all_rooms_chunks().await?;
        Ok(())
    }

    #[instrument(skip_all)]
    async fn add_media_content(
        &self,
        request: &MediaRequestParameters,
        content: Vec<u8>,
    ) -> Result<(), Self::Error> {
        let _handle = self
            .queue
            .acquire()
            .await
            .expect("We never close the semaphore");
        self.inner.add_media_content(request, content).await
    }

    #[instrument(skip_all)]
    async fn get_media_content(
        &self,
        request: &MediaRequestParameters,
    ) -> Result<Option<Vec<u8>>, Self::Error> {
        let _handle = self
            .queue
            .acquire()
            .await
            .expect("We never close the semaphore");
        self.inner.get_media_content(request).await
    }
    #[instrument(skip_all)]
    async fn get_media_content_for_uri(
        &self,
        uri: &MxcUri,
    ) -> Result<Option<Vec<u8>>, Self::Error> {
        let _handle = self
            .queue
            .acquire()
            .await
            .expect("We never close the semaphore");
        self.inner.get_media_content_for_uri(uri).await
    }

    #[instrument(skip_all)]
    async fn remove_media_content(
        &self,
        request: &MediaRequestParameters,
    ) -> Result<(), Self::Error> {
        let _handle = self
            .queue
            .acquire()
            .await
            .expect("We never close the semaphore");
        self.inner.remove_media_content(request).await
    }

    #[instrument(skip_all)]
    async fn remove_media_content_for_uri(&self, uri: &MxcUri) -> Result<(), Self::Error> {
        let _handle = self
            .queue
            .acquire()
            .await
            .expect("We never close the semaphore");
        self.inner.remove_media_content_for_uri(uri).await
    }

    #[instrument(skip_all)]
    async fn replace_media_key(
        &self,
        from: &MediaRequestParameters,
        to: &MediaRequestParameters,
    ) -> Result<(), Self::Error> {
        let _handle = self
            .queue
            .acquire()
            .await
            .expect("We never close the semaphore");
        self.inner.replace_media_key(from, to).await
    }
}
