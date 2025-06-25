use serde::{Deserialize, Serialize};
use strum::{Display, EnumString};

#[derive(
    Eq, PartialEq, Ord, PartialOrd, Hash, Debug, Clone, Display, EnumString, Serialize, Deserialize,
)]
#[strum(serialize_all = "snake_case")]
#[repr(u8)]
#[serde(rename_all = "snake_case")]
pub enum SectionIndex {
    #[strum(serialize = "news", serialize = "boosts")]
    Boosts = 0,
    Calendar,
    Pins,
    Stories,
    Tasks,
}
