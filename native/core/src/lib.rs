#![warn(clippy::all)]

pub use matrix_sdk;
pub use matrix_sdk::ruma;

pub mod events;
pub mod models;
pub mod statics;
pub mod support;
pub use support::RestoreToken;

#[cfg(feature = "with-mocks")]
pub mod mocks {
    pub use super::models::mocks::*;
}
