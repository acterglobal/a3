#![warn(clippy::all)]
#![allow(refining_impl_trait)] // we are using enum_dispatch and need this for now
#![allow(async_fn_in_trait)]
#![feature(trait_alias)]

pub use matrix_sdk;
pub use matrix_sdk::ruma;

pub mod activities;
pub mod client;
pub mod config;
pub mod error;
pub mod events;
pub mod executor;
pub mod models;
pub mod push;
pub mod referencing;
pub mod share_link;
pub mod spaces;
pub mod statics;
pub mod store;
pub mod super_invites;
pub mod support;

pub use error::{Error, Result};
pub use support::{CustomAuthSession, RestoreToken};

#[cfg(feature = "templates")]
pub mod templates;
pub mod util;
