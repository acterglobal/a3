pub use chrono::{DateTime, Utc};

use serde::{Deserialize, Deserializer};

/// Any value that is present is considered Some value, including null.
/// from https://github.com/serde-rs/serde/issues/984#issuecomment-314143738
pub fn deserialize_some<'de, T, D>(deserializer: D) -> Result<Option<T>, D::Error>
where
    T: Deserialize<'de>,
    D: Deserializer<'de>,
{
    Deserialize::deserialize(deserializer).map(Some)
}
