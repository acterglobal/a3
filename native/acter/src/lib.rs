#![recursion_limit = "1024"]
#![warn(clippy::all)]
#![feature(vec_into_raw_parts)]
#![feature(box_into_inner)]
#![allow(
    unused,
    dead_code,
    clippy::boxed_local,
    clippy::transmutes_expressible_as_ptr_casts
)]

#[rustfmt::skip]
#[cfg(feature = "uniffi")]
uniffi::include_scaffolding!("acter");

pub use matrix_sdk;
pub use matrix_sdk_ui;

pub mod api;
pub mod platform;

#[rustfmt::skip]
#[cfg(feature = "cbindgen")]
pub mod api_generated;

#[cfg(feature = "testing")]
pub mod testing;

pub use api::*;
