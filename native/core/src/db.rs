use matrix_sdk_base::store::StoreConfig;
use matrix_sdk_sqlite::{OpenStoreError, SqliteCryptoStore, SqliteStateStore};

use std::path::Path;

/// Create a [`StoreConfig`] with an opened [`SqliteStateStore`] in the given
/// directory and using the given passphrase. If the `crypto-store` feature is
/// enabled, a [`SqliteCryptoStore`] with the same parameters is also opened.
pub async fn make_default_store_config(
    path: &Path,
    passphrase: Option<&str>,
) -> Result<StoreConfig, OpenStoreError> {
    let state_store = SqliteStateStore::open(path, passphrase).await?;
    let config = StoreConfig::new().state_store(state_store);
    let crypto_store = SqliteCryptoStore::open(path, passphrase).await?;
    Ok(config.crypto_store(crypto_store))
}
