use serde::{Deserialize, Serialize};

#[derive(Eq, PartialEq, Ord, PartialOrd, Hash, Debug, Clone, Serialize, Deserialize)]
#[cfg_attr(feature = "strum", derive(strum::Display, strum::EnumString))]
#[cfg_attr(feature = "strum", strum(serialize_all = "snake_case"))]
pub enum ModelParam {
    CommentsStats,
    AttachmentsStats,
    ReactionStats,
    RsvpStats,
    #[cfg_attr(feature = "strum", strum(to_string = "read_receipts"))]
    ReadReceiptsStats,
    #[cfg_attr(feature = "strum", strum(to_string = "invites"))]
    InviteStats,
}

#[cfg(not(feature = "strum"))]
impl core::fmt::Display for ModelParam {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        write!(
            f,
            "{}",
            match self {
                ModelParam::CommentsStats => "comments_stats",
                ModelParam::AttachmentsStats => "attachments_stats",
                ModelParam::ReactionStats => "reaction_stats",
                ModelParam::RsvpStats => "rsvp_stats",
                ModelParam::ReadReceiptsStats => "read_receipts_stats",
                ModelParam::InviteStats => "invite_stats",
            }
        )
    }
}
