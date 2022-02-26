#![warn(clippy::all)]
#![feature(vec_into_raw_parts)]
#![allow(unused, dead_code, clippy::transmutes_expressible_as_ptr_casts)]

pub use matrix_sdk;

mod api;
mod platform;
