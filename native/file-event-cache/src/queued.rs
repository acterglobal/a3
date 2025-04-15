use crate::EventCacheStore;
use async_trait::async_trait;
use matrix_sdk::{
    deserialized_responses::TimelineEvent,
    linked_chunk::Position,
    ruma::{events::relation::RelationType, EventId, OwnedEventId},
};
use matrix_sdk_base::{
    event_cache::{
        store::media::{IgnoreMediaRetentionPolicy, MediaRetentionPolicy},
        Event, Gap,
    },
    linked_chunk::{ChunkIdentifier, ChunkIdentifierGenerator, RawChunk, Update},
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

    async fn load_all_chunks(
        &self,
        room_id: &RoomId,
    ) -> Result<Vec<RawChunk<TimelineEvent, Gap>>, Self::Error> {
        let _handle = self
            .queue
            .acquire()
            .await
            .expect("We never close the semaphore");
        self.inner.load_all_chunks(room_id).await
    }

    async fn load_last_chunk(
        &self,
        room_id: &RoomId,
    ) -> Result<
        (
            Option<RawChunk<TimelineEvent, Gap>>,
            ChunkIdentifierGenerator,
        ),
        Self::Error,
    > {
        let _handle = self
            .queue
            .acquire()
            .await
            .expect("We never close the semaphore");
        self.inner.load_last_chunk(room_id).await
    }

    async fn load_previous_chunk(
        &self,
        room_id: &RoomId,
        before_chunk_identifier: ChunkIdentifier,
    ) -> Result<Option<RawChunk<TimelineEvent, Gap>>, Self::Error> {
        let _handle = self
            .queue
            .acquire()
            .await
            .expect("We never close the semaphore");
        self.inner
            .load_previous_chunk(room_id, before_chunk_identifier)
            .await
    }

    #[instrument(skip_all)]
    async fn add_media_content(
        &self,
        request: &MediaRequestParameters,
        content: Vec<u8>,
        ignore_policy: IgnoreMediaRetentionPolicy,
    ) -> Result<(), Self::Error> {
        let _handle = self
            .queue
            .acquire()
            .await
            .expect("We never close the semaphore");
        self.inner
            .add_media_content(request, content, ignore_policy)
            .await
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

    fn media_retention_policy(&self) -> MediaRetentionPolicy {
        self.inner.media_retention_policy()
    }

    async fn set_media_retention_policy(
        &self,
        policy: MediaRetentionPolicy,
    ) -> Result<(), Self::Error> {
        self.inner.set_media_retention_policy(policy).await
    }
    async fn set_ignore_media_retention_policy(
        &self,
        request: &MediaRequestParameters,
        ignore_policy: IgnoreMediaRetentionPolicy,
    ) -> Result<(), Self::Error> {
        self.inner
            .set_ignore_media_retention_policy(request, ignore_policy)
            .await
    }

    async fn clear_all_rooms_chunks(&self) -> Result<(), Self::Error> {
        self.inner.clear_all_rooms_chunks().await
    }

    async fn clean_up_media_cache(&self) -> Result<(), Self::Error> {
        self.inner.clean_up_media_cache().await
    }

    async fn filter_duplicated_events(
        &self,
        room_id: &RoomId,
        events: Vec<OwnedEventId>,
    ) -> Result<Vec<(OwnedEventId, Position)>, Self::Error> {
        self.inner.filter_duplicated_events(room_id, events).await
    }

    async fn find_event(
        &self,
        room_id: &RoomId,
        event_id: &EventId,
    ) -> Result<Option<TimelineEvent>, Self::Error> {
        self.inner.find_event(room_id, event_id).await
    }

    async fn find_event_relations(
        &self,
        room_id: &RoomId,
        event_id: &EventId,
        relation_types: Option<&[RelationType]>,
    ) -> Result<Vec<Event>, Self::Error> {
        self.inner.find_event_relations(room_id, event_id, relation_types).await
    }

    async fn save_event(
        &self,
        room_id: &RoomId,
        event: Event,
    ) -> Result<(), Self::Error> {
        self.inner.save_event(room_id, event).await
    }
}
