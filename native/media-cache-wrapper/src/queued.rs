use crate::MediaStore;
use async_trait::async_trait;
use matrix_sdk_base::{media::MediaRequestParameters, ruma::MxcUri};
use std::sync::Arc;
use tokio::sync::Semaphore;
use tracing::instrument;

#[derive(Debug)]
pub struct QueuedMediaStore<T>
where
    T: MediaStore,
{
    inner: T,
    queue: Arc<Semaphore>,
}

impl<T> QueuedMediaStore<T>
where
    T: MediaStore,
{
    pub fn new(store: T, queue_size: usize) -> Self {
        QueuedMediaStore {
            inner: store,
            queue: Arc::new(Semaphore::new(queue_size)),
        }
    }
}

#[async_trait]
impl<T> MediaStore for QueuedMediaStore<T>
where
    T: MediaStore,
{
    type Error = T::Error;

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
}
