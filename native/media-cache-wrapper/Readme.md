# Matrix SDK Store Media Cache Wrapper

This is a secure and privacy preserving file-storage based wrapper for any Matrix SDK store: rather than using the default storage mechanism for media downloaded this wrapper around the store will use the provided target path.

This is particularly useful for cases like mobile when using the sqlite store as this allows you to separate out the important sqlite store and encryption keys in the users document directory while allowing for any media downloaded to be stored separately in the cache directory that can be cleared safely. Thus allowing the end user to clear the cache and free up massive storage space without touching anything important or potentially dangerous.

**The minimum supported Rust version is 1.70.0.**

## Installation

```
cargo add matrix-sdk-store-media-cache-wrapper
```

## Usage

To use the store, just wrap your existing store with the `wrap_with_file_cache` function. This is a helper that will use the provided store to keep a consistent `StoreCipher` available for you. That also means it will only work for the same path when you keep using the same store.

**Example** (check the embedded tests for more details)

```rust
        // assuming this is all set up:
        let db_path = tempfile::tempdir()?;
        let cache_dir = tempfile::tempdir()?;
        let passphrase = Uuid::new_v4().to_string();
        let db = SqliteStateStore::open(db_path, Some(&passphrase)).await?;

        let outer = matrix_sdk_store_media_cache_wrapper::wrap_with_file_cache(db, cache_dir.path().to_path_buf(), &passphrase).await?;

        // implements matrix_sdk_store::StateStore
        // use as regular state store before.P
        outer
            .add_media_content(&fake_mr(my_item_id), some_content.into())
            .await?;
```

## Safety

Files as well as the file path to store the files under are encrypted by the provided default implementation of `FileCacheMediaStore`. You _must_ provide a properly setup store cipher for that to work. Using the `wrap_with_file_cache`-helper function that will all be taken care of for you.

Because the data is store specific, the files stored will also be specific to the stores used. If you have multiple stores, you can not reuse the same files. Theoretically the store file name creation should not clash but to avoid that problem altogether (as it will be hard to detect if that was the cause), we recommend keeping the data store in separate directories for each store.

## Compatibility

The test suite is run against using `matrix-sdk-sqlite` `SqliteStore`. Though there is no reason to believe it shouldn't work with any store implementing the `StateStore`-interface, this is the only one it has been tested with successfully.

This is part of [Acter](https://acter.global), which we are providing regular releases of for iOS, Android and Linux, MacOS & Windows, supporting at least the latest stable release. This crate is included in that and thus constantly tested for these environments.

## License

This crate is provided as is under either MIT OR Apache-2.0 . Copyright Benjamin Kampmann & Acter Contributors 2023.
