#![warn(clippy::all)]
#![feature(vec_into_raw_parts)]
#![allow(unused, dead_code, clippy::transmutes_expressible_as_ptr_casts)]

pub use matrix_sdk;

pub mod api;
pub mod platform;

#[cfg(feature = "cbindgen")]
pub mod api_generated;
