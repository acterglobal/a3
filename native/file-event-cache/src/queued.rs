use crate::EventCacheStore;
use async_trait::async_trait;
use matrix_sdk_base::{media::MediaRequest, ruma::MxcUri};
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

    #[instrument(skip_all)]
    async fn add_media_content(
        &self,
        request: &MediaRequest,
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
        request: &MediaRequest,
    ) -> Result<Option<Vec<u8>>, Self::Error> {
        let _handle = self
            .queue
            .acquire()
            .await
            .expect("We never close the semaphore");
        self.inner.get_media_content(request).await
    }

    #[instrument(skip_all)]
    async fn remove_media_content(&self, request: &MediaRequest) -> Result<(), Self::Error> {
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
        from: &MediaRequest,
        to: &MediaRequest,
    ) -> Result<(), Self::Error> {
        let _handle = self
            .queue
            .acquire()
            .await
            .expect("We never close the semaphore");
        self.inner.replace_media_key(from, to).await
    }
}
