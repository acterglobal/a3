#![warn(clippy::all)]

pub use matrix_sdk;
pub use matrix_sdk::ruma;

pub mod error;
pub mod events;
pub mod executor;
pub mod models;
pub mod statics;
pub mod store;
pub mod support;
pub use error::{Error, Result};
pub use support::RestoreToken;
pub mod util;

#[cfg(feature = "with-mocks")]
pub mod mocks {
    pub use super::models::mocks::*;
}
