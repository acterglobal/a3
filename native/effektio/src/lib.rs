#![feature(vec_into_raw_parts)]
#![allow(unused)]
#![warn(clippy::all)]

pub use matrix_sdk;

#[cfg(target_os = "android")]
mod api;

#[cfg(target_os = "android")]
mod android;