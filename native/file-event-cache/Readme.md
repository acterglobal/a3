# Matrix Rust Sdk File Event Cache

A secure and privacy preserving file-storage implementation for the Matrix SDK Event Cache.

This is particularly useful for cases like mobile when using the sqlite store as this allows you to separate out the important sqlite store and encryption keys in the users document directory while allowing for any media downloaded to be stored separately in the cache directory that can be cleared safely. Thus allowing the end user to clear the cache and free up massive storage space without touching anything important or potentially dangerous.

**The minimum supported Rust version is 1.70.0.**

## Installation

```
cargo add matrix-sdk-store-file-event-cache
```

## Usage

To use the store, just wrap your existing store with the `wrap_with_file_cache` function. This is a helper that will use the provided store to keep a consistent `StoreCipher` available for you. That also means it will only work for the same path when you keep using the same store.

**Example** (check the embedded tests for more details)

```rust
        // assuming this is all set up:
        let db_path = tempfile::tempdir()?;
        let cache_dir = tempfile::tempdir()?;
        let passphrase = Uuid::new_v4().to_string();
        let state_store = SqliteStateStore::open(db_path, Some(&passphrase)).await?;

        let filecache = matrix_sdk_store_file_event_cache::wrap_with_file_cache(&state_store, cache_dir.path().to_path_buf(), &passphrase).await?;

        // implements matrix_sdk_store::EventCacheStore
        // use as regular state store before.P
        filecache
            .add_media_content(&fake_mr(my_item_id), some_content.into())
            .await?;
```

## Safety

Files as well as the file path to store the files under are encrypted by the provided default implementation of `FileEventCache`. You _must_ provide a properly setup store cipher for that to work. Using the `wrap_with_file_cache`-helper function that will all be taken care of for you.

Because the data is store specific, the files stored will also be specific to the stores used. If you have multiple stores, you can not reuse the same files. Theoretically the store file name creation should not clash but to avoid that problem altogether (as it will be hard to detect if that was the cause), we recommend keeping the data store in separate directories for each store.

## Compatibility

This is 100% backwards compatible with the `matrix-sdk-store-media-cache-wrapper` file implementation. Passing the proper state store

The test suite is run against using `matrix-sdk-sqlite` `SqliteStore`. Though there is no reason to believe it shouldn’t work with any store implementing the `StateStore`-interface, this is the only one it has been tested with successfully.

This is part of [Acter](https://acter.global), which we are providing regular releases of for iOS, Android and Linux, MacOS & Windows, supporting at least the latest stable release. This crate is included in that and thus constantly tested for these environments.

## Features

### `queued`

This now offers new default-on feature `queued` which exposes a new `QueuedFileEventCache`, a wrapper that allows you to enforce the number of concurrent requests to made. This is particularly useful on devices where many concurrent open files might be an issue (looking at you, iOS).

To use it just switch your call of `wrap_with_file_cache` with the newly exposed `wrap_with_file_cache_and_limits`, which has an one additional `usize` parameter with which you can limit the number of concurrent requests done or pending at the same time.

## License

This crate is provided as is under either MIT OR Apache-2.0 . Copyright Benjamin Kampmann & Acter Contributors 2023.
