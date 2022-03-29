use serde::{Serialize, Deserialize, de::{DeserializeOwned, Deserializer}}; // 1.0.136
use anyhow::Result;
use std::fmt::Debug;

/// Describing the state transiiton that action can produce.
pub trait Transition: Serialize + DeserializeOwned + Debug {
    type Action: Clone + Serialize + DeserializeOwned + Debug;

    // Apply the given action on the object
    fn transition(&mut self, action: Self::Action) -> Result<()>;
}