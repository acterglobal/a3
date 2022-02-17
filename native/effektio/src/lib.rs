#![feature(vec_into_raw_parts)]
#![allow(unused, dead_code, clippy::transmutes_expressible_as_ptr_casts)]

pub use matrix_sdk;

#[cfg(any(target_os = "android", target_os = "ios"))]
mod api;

#[cfg(target_os = "android")]
mod android;

#[cfg(target_os = "ios")]
mod ios;
