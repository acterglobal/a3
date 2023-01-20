#![warn(clippy::all)]
#![feature(vec_into_raw_parts)]
#![feature(async_closure)]
#![feature(box_into_inner)]
#![allow(unused, dead_code, clippy::transmutes_expressible_as_ptr_casts)]

pub use matrix_sdk;

pub mod api;
pub mod platform;

#[rustfmt::skip]
#[cfg(feature = "cbindgen")]
pub mod api_generated;

#[cfg(feature = "testing")]
pub mod testing;

pub use api::*;
