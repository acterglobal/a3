use acter_core::{events, models::News, ruma::OwnedEventId};
use anyhow::{bail, Context, Result};

#[cfg(feature = "with-mocks")]
use acter_core::mocks::gen_mock_news;
use futures_signals::signal::Mutable;
use matrix_sdk::{room::Joined, Client as MatrixClient};
use std::{
    ffi::OsStr,
    fs::File,
    path::PathBuf, // FIXME: make these optional for wasm
};

use super::{client::Client, group::Group, RUNTIME};

impl Client {
    #[cfg(feature = "with-mocks")]
    pub async fn latest_news(&self) -> Result<Vec<News>> {
        Ok(gen_mock_news())
    }
}
