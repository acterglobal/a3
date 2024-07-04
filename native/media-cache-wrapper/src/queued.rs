use crate::MediaStore;
use async_trait::async_trait;
use deadqueue::limited::Queue;
use matrix_sdk_base::media::MediaRequest;
use ruma_common::MxcUri;
use tracing::instrument;

#[derive(Debug)]
pub struct QueuedMediaStore<T>
where
    T: MediaStore,
{
    inner: T,
    queue: Queue<()>,
}

impl<T> QueuedMediaStore<T>
where
    T: MediaStore,
{
    pub fn new(store: T, queue_size: usize) -> Self {
        QueuedMediaStore {
            inner: store,
            queue: Queue::new(queue_size),
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
        request: &MediaRequest,
        content: Vec<u8>,
    ) -> Result<(), Self::Error> {
        self.queue.push(()).await;
        let res = self.inner.add_media_content(request, content).await;
        if self.queue.try_pop().is_none() {
            tracing::warn!("More pop than pushed on add?");
        }
        res
    }

    #[instrument(skip_all)]
    async fn get_media_content(
        &self,
        request: &MediaRequest,
    ) -> Result<Option<Vec<u8>>, Self::Error> {
        self.queue.push(()).await;
        let res = self.inner.get_media_content(request).await;
        if self.queue.try_pop().is_none() {
            tracing::warn!("More pop than pushed on get?");
        }
        res
    }

    #[instrument(skip_all)]
    async fn remove_media_content(&self, request: &MediaRequest) -> Result<(), Self::Error> {
        self.queue.push(()).await;
        let res = self.inner.remove_media_content(request).await;
        if self.queue.try_pop().is_none() {
            tracing::warn!("More pop than pushed on remove?");
        }
        res
    }

    #[instrument(skip_all)]
    async fn remove_media_content_for_uri(&self, uri: &MxcUri) -> Result<(), Self::Error> {
        self.queue.push(()).await;
        let res = self.inner.remove_media_content_for_uri(uri).await;
        if self.queue.try_pop().is_none() {
            tracing::warn!("More pop than pushed on get?");
        }
        res
    }
}
