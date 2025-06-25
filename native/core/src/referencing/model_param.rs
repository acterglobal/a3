use serde::{Deserialize, Serialize};
use strum::{Display, EnumString};

#[derive(
    Eq, PartialEq, Ord, PartialOrd, Hash, Debug, Clone, Display, EnumString, Serialize, Deserialize,
)]
#[strum(serialize_all = "snake_case")]
pub enum ModelParam {
    CommentsStats,
    AttachmentsStats,
    ReactionStats,
    RsvpStats,
    #[strum(to_string = "read_receipts")]
    ReadReceiptsStats,
    #[strum(to_string = "invites")]
    InviteStats,
}
