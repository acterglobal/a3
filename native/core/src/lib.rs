#![feature(trait_alias)]
#![feature(associated_type_defaults)]

pub mod config;
pub mod execution;
pub mod meta;
pub mod referencing;

#[cfg(any(test, feature = "testing"))]
pub mod mocks;
