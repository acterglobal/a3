use serde::{Deserialize, Serialize};

#[derive(Eq, PartialEq, Ord, PartialOrd, Hash, Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "strum", derive(strum::Display, strum::EnumString))]
#[cfg_attr(feature = "strum", strum(serialize_all = "snake_case"))]
pub enum RoomParam {
    LatestMessage,
}

#[cfg(not(feature = "strum"))]
impl core::fmt::Display for RoomParam {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "{}",
            match self {
                RoomParam::LatestMessage => "latest_message",
            }
        )
    }
}
