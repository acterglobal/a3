use serde::{Deserialize, Serialize};
use strum::{Display, EnumString};

#[derive(
    Eq, PartialEq, Ord, PartialOrd, Hash, Debug, Clone, Display, EnumString, Serialize, Deserialize,
)]
#[strum(serialize_all = "snake_case")]
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
