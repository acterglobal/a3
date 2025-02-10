use async_trait::async_trait;
use base64ct::{Base64UrlUnpadded, Encoding};
use core::fmt::Debug;
use matrix_sdk_base::{
    event_cache::{
        store::{EventCacheStore, EventCacheStoreError},
        Event, Gap,
    },
    linked_chunk::{RawChunk, Update},
    media::{MediaRequestParameters, UniqueKey},
    ruma::{MxcUri, RoomId},
    StateStore,
};
use matrix_sdk_store_encryption::StoreCipher;
use serde::{Deserialize, Serialize};
use std::{fs, path::PathBuf, time::Duration};
use tracing::instrument;

#[cfg(feature = "queued")]
mod queued;

#[cfg(feature = "queued")]
pub use queued::QueuedEventCacheStore;

pub struct FileEventCacheStore<T> {
    cache_dir: PathBuf,
    store_cipher: StoreCipher,
    inner: T,
}

impl<T> Debug for FileEventCacheStore<T> {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("FileEventCacheStore")
            .field("cache_dir", &self.cache_dir)
            .finish()
    }
}

impl<T> FileEventCacheStore<T> {
    pub fn with_store_cipher(
        cache_dir: PathBuf,
        store_cipher: StoreCipher,
        inner: T,
    ) -> FileEventCacheStore<T> {
        FileEventCacheStore {
            cache_dir,
            store_cipher,
            inner,
        }
    }

    fn encode_value(&self, value: Vec<u8>) -> Result<Vec<u8>, EventCacheStoreError> {
        let encoded = self
            .store_cipher
            .encrypt_value_data(value)
            .map_err(EventCacheStoreError::backend)?;
        rmp_serde::to_vec_named(&encoded).map_err(EventCacheStoreError::backend)
    }

    fn decode_value(&self, value: &[u8]) -> Result<Vec<u8>, EventCacheStoreError> {
        let encrypted = rmp_serde::from_slice(value).map_err(EventCacheStoreError::backend)?;
        self.store_cipher
            .decrypt_value_data(encrypted)
            .map_err(EventCacheStoreError::backend)
    }

    fn encode_key(&self, key: impl AsRef<[u8]>) -> String {
        Base64UrlUnpadded::encode_string(&self.store_cipher.hash_key("ext_media", key.as_ref()))
    }
}

#[derive(Serialize, Deserialize)]
struct LeaveLockInfo {
    holder: String,
    expiration: Duration,
}

#[async_trait]
impl<T> EventCacheStore for FileEventCacheStore<T>
where
    T: EventCacheStore,
{
    type Error = EventCacheStoreError;

    async fn try_take_leased_lock(
        &self,
        lease_duration_ms: u32,
        key: &str,
        holder: &str,
    ) -> Result<bool, Self::Error> {
        self.inner
            .try_take_leased_lock(lease_duration_ms, key, holder)
            .await
            .map_err(|e| e.into())
    }

    async fn handle_linked_chunk_updates(
        &self,
        room_id: &RoomId,
        updates: Vec<Update<Event, Gap>>,
    ) -> Result<(), Self::Error> {
        self.inner
            .handle_linked_chunk_updates(room_id, updates)
            .await
            .map_err(|e| e.into())
    }

    async fn reload_linked_chunk(
        &self,
        room_id: &RoomId,
    ) -> Result<Vec<RawChunk<Event, Gap>>, Self::Error> {
        self.inner
            .reload_linked_chunk(room_id)
            .await
            .map_err(|e| e.into())
    }

    async fn clear_all_rooms_chunks(&self) -> Result<(), Self::Error> {
        self.inner
            .clear_all_rooms_chunks()
            .await
            .map_err(|e| e.into())
    }

    #[instrument(skip_all)]
    async fn add_media_content(
        &self,
        request: &MediaRequestParameters,
        content: Vec<u8>,
    ) -> Result<(), Self::Error> {
        let base_filename = self.encode_key(request.source.unique_key());
        let data = self
            .encode_value(content)
            .map_err(|e| EventCacheStoreError::Backend(Box::new(e)))?;
        fs::write(self.cache_dir.join(base_filename), data)
            .map_err(|e| EventCacheStoreError::Backend(Box::new(e)))?;
        Ok(())
    }

    #[instrument(skip_all)]
    async fn get_media_content(
        &self,
        request: &MediaRequestParameters,
    ) -> Result<Option<Vec<u8>>, Self::Error> {
        let base_filename = self.encode_key(request.source.unique_key());
        fs::read(self.cache_dir.join(base_filename))
            .ok()
            .map(|data| self.decode_value(&data))
            .transpose()
    }

    async fn get_media_content_for_uri(
        &self,
        uri: &MxcUri,
    ) -> Result<Option<Vec<u8>>, Self::Error> {
        let base_filename = self.encode_key(uri);
        fs::read(self.cache_dir.join(base_filename))
            .ok()
            .map(|data| self.decode_value(&data))
            .transpose()
    }

    #[instrument(skip_all)]
    async fn remove_media_content(
        &self,
        request: &MediaRequestParameters,
    ) -> Result<(), Self::Error> {
        let base_filename = self.encode_key(request.source.unique_key());
        fs::remove_file(self.cache_dir.join(base_filename))
            .map_err(|e| EventCacheStoreError::Backend(Box::new(e)))?;
        Ok(())
    }

    #[instrument(skip_all)]
    async fn remove_media_content_for_uri(&self, uri: &MxcUri) -> Result<(), Self::Error> {
        let base_filename = self.encode_key(uri);
        fs::remove_file(self.cache_dir.join(base_filename))
            .map_err(|e| EventCacheStoreError::Backend(Box::new(e)))?;
        Ok(())
    }

    #[instrument(skip_all)]
    async fn replace_media_key(
        &self,
        from: &MediaRequestParameters,
        to: &MediaRequestParameters,
    ) -> Result<(), Self::Error> {
        let from_filename = self.encode_key(from.source.unique_key());
        let to_filename = self.encode_key(to.source.unique_key());
        fs::rename(from_filename, to_filename)
            .map_err(|e| EventCacheStoreError::Backend(Box::new(e)))?;
        Ok(())
    }
}

#[cfg(feature = "queued")]
pub async fn wrap_with_file_cache_and_limits<T, S>(
    state_store: &S,
    event_cache_store: T,
    cache_path: PathBuf,
    passphrase: &str,
    queue_size: usize,
) -> Result<QueuedEventCacheStore<FileEventCacheStore<T>>, EventCacheStoreError>
where
    S: StateStore + Sync + Send,
    T: EventCacheStore + Sync + Send,
{
    let cached =
        wrap_with_file_cache_inner(state_store, event_cache_store, cache_path, passphrase).await?;
    Ok(QueuedEventCacheStore::new(cached, queue_size))
}

pub async fn wrap_with_file_cache<T, S>(
    state_store: &S,
    event_cache_store: T,
    cache_path: PathBuf,
    passphrase: &str,
) -> Result<FileEventCacheStore<T>, EventCacheStoreError>
where
    S: StateStore + Sync + Send,
    T: EventCacheStore + Sync + Send,
{
    wrap_with_file_cache_inner(state_store, event_cache_store, cache_path, passphrase).await
}

async fn wrap_with_file_cache_inner<T, S>(
    state_store: &S,
    event_cache_store: T,
    cache_path: PathBuf,
    passphrase: &str,
) -> Result<FileEventCacheStore<T>, EventCacheStoreError>
where
    S: StateStore + Sync + Send,
    T: EventCacheStore + Sync + Send,
{
    let cipher = if let Some(enc_key) = state_store
        .get_custom_value(b"ext_media_key")
        .await
        .map_err(|e| EventCacheStoreError::backend(e.into()))?
    {
        StoreCipher::import(passphrase, &enc_key)?
    } else {
        let cipher = StoreCipher::new()?;
        let key = cipher.export(passphrase)?;
        state_store
            .set_custom_value_no_read(b"ext_media_key", key)
            .await
            .map_err(|e| EventCacheStoreError::backend(e.into()))?;
        cipher
    };

    fs::create_dir_all(cache_path.as_path())
        .map_err(|e| EventCacheStoreError::Backend(Box::new(e)))?;

    Ok(FileEventCacheStore::with_store_cipher(
        cache_path,
        cipher,
        event_cache_store,
    ))
}

#[cfg(test)]
mod tests {
    use super::*;
    use anyhow::Result;
    use matrix_sdk_base::{
        media::MediaFormat,
        ruma::{events::room::MediaSource, OwnedMxcUri},
    };
    use matrix_sdk_sqlite::{SqliteEventCacheStore, SqliteStateStore};
    use matrix_sdk_test::async_test;
    use uuid::Uuid;

    fn fake_mr(id: &str) -> MediaRequestParameters {
        MediaRequestParameters {
            source: MediaSource::Plain(OwnedMxcUri::from(id)),
            format: MediaFormat::File,
        }
    }

    #[async_test]
    async fn test_it_works() -> Result<()> {
        let cache_dir = tempfile::tempdir()?;
        let cipher = StoreCipher::new()?;
        let cache = SqliteEventCacheStore::open(cache_dir.path(), None).await?;
        let fmc = FileEventCacheStore::with_store_cipher(cache_dir.into_path(), cipher, cache);
        let some_content = "this is some content";
        fmc.add_media_content(&fake_mr("my_id"), some_content.into())
            .await?;
        assert_eq!(
            fmc.get_media_content(&fake_mr("my_id")).await?,
            Some(some_content.into())
        );

        Ok(())
    }

    #[async_test]
    async fn test_it_works_after_restart() -> Result<()> {
        let cache_dir = tempfile::tempdir()?;
        let passphrase = "this is a secret passphrase";
        let some_content = "this is some content";
        let my_item_id = "my_id";
        let enc_key = {
            // first media cache
            let cipher = StoreCipher::new()?;
            let export = cipher.export(passphrase)?;
            let cache = SqliteEventCacheStore::open(cache_dir.path(), Some(passphrase)).await?;
            let fmc = FileEventCacheStore::with_store_cipher(
                cache_dir.path().to_path_buf(),
                cipher,
                cache,
            );
            fmc.add_media_content(&fake_mr(my_item_id), some_content.into())
                .await?;
            assert_eq!(
                fmc.get_media_content(&fake_mr(my_item_id)).await?,
                Some(some_content.into())
            );
            export
        };

        // second media cache
        let cipher = StoreCipher::import(passphrase, &enc_key)?;
        let cache = SqliteEventCacheStore::open(cache_dir.path(), Some(passphrase)).await?;
        let fmc =
            FileEventCacheStore::with_store_cipher(cache_dir.path().to_path_buf(), cipher, cache);
        assert_eq!(
            fmc.get_media_content(&fake_mr(my_item_id)).await?,
            Some(some_content.into())
        );

        Ok(())
    }

    #[async_test]
    async fn test_with_sqlite_store() -> Result<()> {
        let db_path = tempfile::tempdir()?;
        let cache_dir = tempfile::tempdir()?;
        let passphrase = Uuid::new_v4().to_string();
        let some_content = "this is some content";
        let my_item_id = "my_id";
        {
            // as a block means we are closing things up
            let db = SqliteStateStore::open(db_path.path(), Some(&passphrase)).await?;
            let cache = SqliteEventCacheStore::open(cache_dir.path(), Some(&passphrase)).await?;
            let outer =
                wrap_with_file_cache(&db, cache, cache_dir.path().to_path_buf(), &passphrase)
                    .await?;
            // first media cache
            outer
                .add_media_content(&fake_mr(my_item_id), some_content.into())
                .await?;
            assert_eq!(
                outer.get_media_content(&fake_mr(my_item_id)).await?,
                Some(some_content.into())
            );
        };

        // second media cache
        let db = SqliteStateStore::open(db_path, Some(&passphrase)).await?;

        let cache = SqliteEventCacheStore::open(cache_dir.path(), Some(&passphrase)).await?;
        let outer =
            wrap_with_file_cache(&db, cache, cache_dir.path().to_path_buf(), &passphrase).await?;
        // first media cache
        outer
            .add_media_content(&fake_mr(my_item_id), some_content.into())
            .await?;
        assert_eq!(
            outer.get_media_content(&fake_mr(my_item_id)).await?,
            Some(some_content.into())
        );

        Ok(())
    }
}
