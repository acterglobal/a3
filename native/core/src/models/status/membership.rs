use matrix_sdk::ruma::{
    events::room::member::MembershipChange as RumaMembershipChange, OwnedMxcUri, OwnedUserId,
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
pub enum MembershipChangeType {
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

impl TryFrom<RumaMembershipChange<'_>> for MembershipChangeType {
    type Error = ();

    fn try_from(value: RumaMembershipChange<'_>) -> Result<Self, ()> {
        Ok(match value {
            RumaMembershipChange::Banned => MembershipChangeType::Banned,
            RumaMembershipChange::Joined => MembershipChangeType::Joined,
            RumaMembershipChange::Left => MembershipChangeType::Left,
            RumaMembershipChange::Unbanned => MembershipChangeType::Unbanned,
            RumaMembershipChange::Kicked => MembershipChangeType::Kicked,
            RumaMembershipChange::Invited => MembershipChangeType::Invited,
            RumaMembershipChange::KickedAndBanned => MembershipChangeType::KickedAndBanned,
            RumaMembershipChange::InvitationAccepted => MembershipChangeType::InvitationAccepted,
            RumaMembershipChange::InvitationRejected => MembershipChangeType::InvitationRejected,
            RumaMembershipChange::InvitationRevoked => MembershipChangeType::InvitationRevoked,
            RumaMembershipChange::Knocked => MembershipChangeType::Knocked,
            RumaMembershipChange::KnockAccepted => MembershipChangeType::KnockAccepted,
            RumaMembershipChange::KnockRetracted => MembershipChangeType::KnockRetracted,
            RumaMembershipChange::KnockDenied => MembershipChangeType::KnockDenied,
            RumaMembershipChange::ProfileChanged {
                displayname_change,
                avatar_url_change,
            } => MembershipChangeType::ProfileChanged {
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

impl MembershipChangeType {
    pub fn as_str(&self) -> &'static str {
        match self {
            MembershipChangeType::Joined => "joined",
            MembershipChangeType::Left => "left",
            MembershipChangeType::Banned => "banned",
            MembershipChangeType::Unbanned => "unbanned",
            MembershipChangeType::Kicked => "kicked",
            MembershipChangeType::Invited => "invited",
            MembershipChangeType::KickedAndBanned => "kickedAndBanned",
            MembershipChangeType::InvitationAccepted => "invitationAccepted",
            MembershipChangeType::InvitationRejected => "invitationRejected",
            MembershipChangeType::InvitationRevoked => "invitationRevoked",
            MembershipChangeType::Knocked => "knocked",
            MembershipChangeType::KnockAccepted => "knockAccepted",
            MembershipChangeType::KnockRetracted => "knockRetraced",
            MembershipChangeType::KnockDenied => "knockDenied",
            MembershipChangeType::ProfileChanged { .. } => "profileChanged",
        }
    }
}

#[derive(Clone, Debug, Serialize, Deserialize)]
pub struct MembershipChange {
    pub user_id: OwnedUserId,
    pub display_name: Option<String>,
    pub avatar_url: Option<OwnedMxcUri>,
    pub reason: Option<String>,
    pub change: MembershipChangeType,
}

impl MembershipChange {
    pub fn as_str(&self) -> &'static str {
        self.change.as_str()
    }
}
