#![warn(clippy::all)]
#![allow(incomplete_features)] // needed for `async_fn_in_trait`
#![feature(slice_as_chunks)]
#![feature(async_fn_in_trait)]

pub use matrix_sdk;
pub use matrix_sdk::ruma;

pub mod client;
pub mod error;
pub mod events;
pub mod executor;
pub mod models;
pub mod spaces;
pub mod statics;
pub mod store;
pub mod support;

pub use error::{Error, Result};
pub use support::{CustomAuthSession, RestoreToken};

#[cfg(feature = "templates")]
pub mod templates;
pub mod util;
