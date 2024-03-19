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

/// This is only used for serialize
#[allow(clippy::trivially_copy_pass_by_ref)]
pub(crate) fn is_zero(num: &u32) -> bool {
    *num == 0
}

/// This is only used for serialize
#[allow(clippy::trivially_copy_pass_by_ref)]
pub(crate) fn is_false(val: &bool) -> bool {
    !(*val)
}
