#![feature(trait_alias)]
#![feature(associated_type_defaults)]

pub mod execution;
pub mod meta;
pub mod referencing;
pub mod store;
pub mod traits;

pub mod executor;

#[cfg(any(test, feature = "testing"))]
pub mod mocks;
