use serde::{Deserialize, Serialize};

#[derive(Eq, PartialEq, Ord, PartialOrd, Hash, Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "strum", derive(strum::Display, strum::EnumString))]
#[cfg_attr(feature = "strum", strum(serialize_all = "snake_case"))]
#[repr(u8)]
pub enum ObjectListIndex {
    Attachments,
    Comments,
    Reactions,
    ReadReceipt,
    Rsvp,
    Tasks,
    Invites,
}
