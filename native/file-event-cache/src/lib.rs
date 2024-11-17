use async_trait::async_trait;
use base64ct::{Base64UrlUnpadded, Encoding};
use core::fmt::Debug;
use matrix_sdk::media::{MediaRequestParameters, UniqueKey};
use matrix_sdk_base::{
    event_cache::store::{EventCacheStore, EventCacheStoreError},
    ruma::MxcUri,
    StateStore,
};
use matrix_sdk_store_encryption::StoreCipher;
use serde::{Deserialize, Serialize};
use std::{
    fs,
    path::PathBuf,
    time::{Duration, Instant},
};
use tracing::instrument;

#[cfg(feature = "queued")]
mod queued;

#[cfg(feature = "queued")]
pub use queued::QueuedEventCacheStore;

pub struct FileEventCacheStore {
    cache_dir: PathBuf,
    store_cipher: StoreCipher,
}

impl Debug for FileEventCacheStore {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        f.debug_struct("FileEventCacheStore")
            .field("cache_dir", &self.cache_dir)
            .finish()
    }
}

impl FileEventCacheStore {
    pub fn with_store_cipher(cache_dir: PathBuf, store_cipher: StoreCipher) -> FileEventCacheStore {
        FileEventCacheStore {
            cache_dir,
            store_cipher,
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
impl EventCacheStore for FileEventCacheStore {
    type Error = EventCacheStoreError;

    async fn try_take_leased_lock(
        &self,
        lease_duration_ms: u32,
        key: &str,
        holder: &str,
    ) -> Result<bool, Self::Error> {
        let now = Instant::now();
        let base_filename = self.encode_key(format!("leave-lock-{key}"));
        let full_name = self.cache_dir.join(base_filename.clone());
        if fs::exists(&full_name).map_err(EventCacheStoreError::backend)? {
            if let Some(current_lock) = fs::read(&full_name)
                .ok()
                .map(|data| self.decode_value(&data))
                .transpose()?
                .map(|v| serde_json::from_slice::<LeaveLockInfo>(&v))
                .transpose()
                .map_err(EventCacheStoreError::backend)?
            {
                if current_lock.expiration > now.elapsed() && current_lock.holder.as_str() != holder
                {
                    // there is an active lock and it has another holder, we have to decline.
                    return Ok(false);
                }
            }
        }
        let expiration = now + Duration::from_millis(lease_duration_ms.into());

        // not yet or we want to update the field, so let's do that
        let new_lease = LeaveLockInfo {
            expiration: expiration.elapsed(),
            holder: holder.to_owned(),
        };
        fs::write(
            full_name,
            self.encode_value(
                serde_json::to_vec(&new_lease).map_err(EventCacheStoreError::backend)?,
            )?,
        )
        .map_err(EventCacheStoreError::backend)?;
        Ok(true)
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
pub async fn wrap_with_file_cache_and_limits<T>(
    state_store: &T,
    cache_path: PathBuf,
    passphrase: &str,
    queue_size: usize,
) -> Result<QueuedEventCacheStore<FileEventCacheStore>, EventCacheStoreError>
where
    T: StateStore + Sync + Send,
{
    let cached = wrap_with_file_cache_inner(state_store, cache_path, passphrase).await?;
    Ok(QueuedEventCacheStore::new(cached, queue_size))
}

pub async fn wrap_with_file_cache<T>(
    state_store: &T,
    cache_path: PathBuf,
    passphrase: &str,
) -> Result<FileEventCacheStore, EventCacheStoreError>
where
    T: StateStore + Sync + Send,
{
    wrap_with_file_cache_inner(state_store, cache_path, passphrase).await
}

async fn wrap_with_file_cache_inner<T>(
    state_store: &T,
    cache_path: PathBuf,
    passphrase: &str,
) -> Result<FileEventCacheStore, EventCacheStoreError>
where
    T: StateStore + Sync + Send,
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

    Ok(FileEventCacheStore::with_store_cipher(cache_path, cipher))
}

#[cfg(test)]
mod tests {
    use super::*;
    use anyhow::Result;
    use matrix_sdk_base::{
        media::MediaFormat,
        ruma::{events::room::MediaSource, OwnedMxcUri},
    };
    use matrix_sdk_sqlite::SqliteStateStore;
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
        let fmc = FileEventCacheStore::with_store_cipher(cache_dir.into_path(), cipher);
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
            let fmc =
                FileEventCacheStore::with_store_cipher(cache_dir.path().to_path_buf(), cipher);
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
        let fmc = FileEventCacheStore::with_store_cipher(cache_dir.path().to_path_buf(), cipher);
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
            let outer =
                wrap_with_file_cache(&db, cache_dir.path().to_path_buf(), &passphrase).await?;
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
        let outer = wrap_with_file_cache(&db, cache_dir.path().to_path_buf(), &passphrase).await?;
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
