#![warn(clippy::all)]

pub use matrix_sdk;

#[cfg(target_os = "android")]
mod api;

#[cfg(target_os = "android")]
mod android;
