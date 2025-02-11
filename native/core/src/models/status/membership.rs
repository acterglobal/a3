use matrix_sdk::ruma::{
    events::room::member::MembershipChange as RumaMembershipChange, OwnedMxcUri,
};
use serde::{Deserialize, Serialize};

/// A simple representation of a change, containing old and new data.
#[derive(Clone, Debug, Serialize, Deserialize)]
#[allow(clippy::exhaustive_structs)]
pub struct Change<T> {
    /// The old data.
    pub old: T,

    /// The new data.
    pub new: T,
}

/// Translation of the membership change in `m.room.member` event.
#[derive(Clone, Debug, Serialize, Deserialize)]
pub enum MembershipChange {
    /// User joined the room.
    Joined,

    /// User left the room.
    Left,

    /// User was banned.
    Banned,

    /// User was unbanned.
    Unbanned,

    /// User was kicked.
    Kicked,

    /// User was invited.
    Invited,

    /// User was kicked and banned.
    KickedAndBanned,

    /// User accepted the invite.
    InvitationAccepted,

    /// User rejected the invite.
    InvitationRejected,

    /// User had their invite revoked.
    InvitationRevoked,

    /// User knocked.
    Knocked,

    /// User had their knock accepted.
    KnockAccepted,

    /// User retracted their knock.
    KnockRetracted,

    /// User had their knock denied.
    KnockDenied,

    /// `displayname` or `avatar_url` changed.
    ProfileChanged {
        /// The details of the displayname change, if applicable.
        displayname_change: Option<Change<Option<String>>>,

        /// The details of the avatar url change, if applicable.
        avatar_url_change: Option<Change<Option<OwnedMxcUri>>>,
    },
}

impl TryFrom<RumaMembershipChange<'_>> for MembershipChange {
    type Error = ();

    fn try_from(value: RumaMembershipChange<'_>) -> Result<Self, ()> {
        Ok(match value {
            RumaMembershipChange::Banned => MembershipChange::Banned,
            RumaMembershipChange::Joined => MembershipChange::Joined,
            RumaMembershipChange::Left => MembershipChange::Left,
            RumaMembershipChange::Unbanned => MembershipChange::Unbanned,
            RumaMembershipChange::Kicked => MembershipChange::Kicked,
            RumaMembershipChange::Invited => MembershipChange::Invited,
            RumaMembershipChange::KickedAndBanned => MembershipChange::KickedAndBanned,
            RumaMembershipChange::InvitationAccepted => MembershipChange::InvitationAccepted,
            RumaMembershipChange::InvitationRejected => MembershipChange::InvitationRejected,
            RumaMembershipChange::InvitationRevoked => MembershipChange::InvitationRevoked,
            RumaMembershipChange::Knocked => MembershipChange::Knocked,
            RumaMembershipChange::KnockAccepted => MembershipChange::KnockAccepted,
            RumaMembershipChange::KnockRetracted => MembershipChange::KnockRetracted,
            RumaMembershipChange::KnockDenied => MembershipChange::KnockDenied,
            RumaMembershipChange::ProfileChanged {
                displayname_change,
                avatar_url_change,
            } => MembershipChange::ProfileChanged {
                displayname_change: displayname_change.map(|c| Change {
                    old: c.old.map(ToOwned::to_owned),
                    new: c.new.map(ToOwned::to_owned),
                }),
                avatar_url_change: avatar_url_change.map(|c| Change {
                    old: c.old.map(ToOwned::to_owned),
                    new: c.new.map(ToOwned::to_owned),
                }),
            },
            RumaMembershipChange::None
            | RumaMembershipChange::Error
            | RumaMembershipChange::NotImplemented
            | _ => return Err(()),
        })
    }
}

impl MembershipChange {
    pub fn as_str(&self) -> &'static str {
        match self {
            MembershipChange::Joined => "joined",
            MembershipChange::Left => "left",
            MembershipChange::Banned => "banned",
            MembershipChange::Unbanned => "unbanned",
            MembershipChange::Kicked => "kicked",
            MembershipChange::Invited => "invited",
            MembershipChange::KickedAndBanned => "kickedAndBanned",
            MembershipChange::InvitationAccepted => "invitationAccepted",
            MembershipChange::InvitationRejected => "invitationRejected",
            MembershipChange::InvitationRevoked => "invitationRevoked",
            MembershipChange::Knocked => "knocked",
            MembershipChange::KnockAccepted => "knockAccepted",
            MembershipChange::KnockRetracted => "knockRetraced",
            MembershipChange::KnockDenied => "knockDenied",
            MembershipChange::ProfileChanged { .. } => "profileChanged",
        }
    }
}
