use matrix_sdk_base::ruma::{
    events::room::member::MembershipChange as RumaMembershipChange, OwnedUserId,
};
use matrix_sdk_ui::timeline::{MembershipChange as SdkMembershipChange, RoomMembershipChange};
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct MembershipChange {
    user_id: OwnedUserId,
    change: String,
}

impl TryFrom<&RoomMembershipChange> for MembershipChange {
    type Error = ();

    fn try_from(value: &RoomMembershipChange) -> Result<Self, Self::Error> {
        let change = match value.change() {
            Some(SdkMembershipChange::Joined) => "joined",
            Some(SdkMembershipChange::Left) => "left",
            Some(SdkMembershipChange::Banned) => "banned",
            Some(SdkMembershipChange::Unbanned) => "unbanned",
            Some(SdkMembershipChange::Kicked) => "kicked",
            Some(SdkMembershipChange::Invited) => "invited",
            Some(SdkMembershipChange::KickedAndBanned) => "kickedAndBanned",
            Some(SdkMembershipChange::InvitationAccepted) => "invitationAccepted",
            Some(SdkMembershipChange::InvitationRejected) => "invitationRejected",
            Some(SdkMembershipChange::InvitationRevoked) => "invitationRevoked",
            Some(SdkMembershipChange::Knocked) => "knocked",
            Some(SdkMembershipChange::KnockAccepted) => "knockAccepted",
            Some(SdkMembershipChange::KnockRetracted) => "knockRetracted",
            Some(SdkMembershipChange::KnockDenied) => "knockDenied",
            Some(SdkMembershipChange::None)
            | Some(SdkMembershipChange::Error)
            | Some(SdkMembershipChange::NotImplemented)
            | None => {
                return Err(());
            }
        };
        Ok(MembershipChange {
            user_id: value.user_id().to_owned(),
            change: change.to_owned(),
        })
    }
}

impl TryFrom<(RumaMembershipChange<'_>, OwnedUserId)> for MembershipChange {
    type Error = ();

    fn try_from(value: (RumaMembershipChange<'_>, OwnedUserId)) -> Result<Self, Self::Error> {
        let (content, user_id) = value;
        let change = match content {
            RumaMembershipChange::Joined => "joined",
            RumaMembershipChange::Left => "left",
            RumaMembershipChange::Banned => "banned",
            RumaMembershipChange::Unbanned => "unbanned",
            RumaMembershipChange::Kicked => "kicked",
            RumaMembershipChange::Invited => "invited",
            RumaMembershipChange::KickedAndBanned => "kickedAndBanned",
            RumaMembershipChange::InvitationAccepted => "invitationAccepted",
            RumaMembershipChange::InvitationRejected => "invitationRejected",
            RumaMembershipChange::InvitationRevoked => "invitationRevoked",
            RumaMembershipChange::Knocked => "knocked",
            RumaMembershipChange::KnockAccepted => "knockAccepted",
            RumaMembershipChange::KnockRetracted => "knockRetracted",
            RumaMembershipChange::KnockDenied => "knockDenied",
            RumaMembershipChange::ProfileChanged { .. } => unreachable!(),
            RumaMembershipChange::None
            | RumaMembershipChange::Error
            | RumaMembershipChange::NotImplemented
            | _ => {
                return Err(());
            }
        };
        Ok(MembershipChange {
            user_id,
            change: change.to_owned(),
        })
    }
}

impl MembershipChange {
    pub fn user_id(&self) -> OwnedUserId {
        self.user_id.clone()
    }

    pub fn change(&self) -> String {
        self.change.clone()
    }
}
