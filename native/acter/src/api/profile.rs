use anyhow::Result;
use matrix_sdk::{
    media::{MediaFormat, MediaRequestParameters},
    room::RoomMember,
    Client, Room,
};
use matrix_sdk_base::ruma::{
    api::client::user_directory::search_users, events::room::MediaSource, OwnedRoomId, OwnedUserId,
};

use super::{
    common::{OptionBuffer, OptionString, ThumbnailSize},
    RUNTIME,
};

#[derive(Clone)]
pub struct PublicProfile {
    inner: search_users::v3::User,
    client: Client,
}

impl PublicProfile {
    pub fn new(inner: search_users::v3::User, client: Client) -> Self {
        PublicProfile { inner, client }
    }

    pub fn user_id(&self) -> OwnedUserId {
        self.inner.user_id.clone()
    }

    pub(crate) async fn avatar(&self, format: MediaFormat) -> Result<Option<Vec<u8>>> {
        let Some(url) = self.inner.avatar_url.as_ref() else {
            return Ok(None);
        };
        let request = MediaRequestParameters {
            source: MediaSource::Plain(url.to_owned()),
            format,
        };
        let buf = self
            .client
            .media()
            .get_media_content(&request, true)
            .await?;
        Ok(Some(buf))
    }
}

#[derive(Clone)]
pub enum UserProfile {
    Member((RoomMember, Vec<String>)),
    PublicProfile(PublicProfile),
}

impl UserProfile {
    pub(crate) fn from_member(member: RoomMember) -> Self {
        UserProfile::with_shared_rooms(member, Default::default())
    }

    pub(crate) fn with_shared_rooms(member: RoomMember, shared_rooms: Vec<String>) -> Self {
        UserProfile::Member((member, shared_rooms))
    }

    pub(crate) fn from_search(public_profile: PublicProfile) -> Self {
        UserProfile::PublicProfile(public_profile)
    }

    pub fn user_id(&self) -> OwnedUserId {
        match self {
            UserProfile::Member((m, _v)) => m.user_id().to_owned(),
            UserProfile::PublicProfile(p) => p.user_id(),
        }
    }

    pub fn has_avatar(&self) -> bool {
        match self {
            UserProfile::Member((member, _v)) => member.avatar_url().is_some(),
            UserProfile::PublicProfile(public_profile) => public_profile.inner.avatar_url.is_some(),
        }
    }

    pub async fn get_avatar(&self, thumb_size: Option<Box<ThumbnailSize>>) -> Result<OptionBuffer> {
        let format = ThumbnailSize::parse_into_media_format(thumb_size);

        Ok(OptionBuffer::new(match self {
            UserProfile::Member((member, _v)) => {
                let member = member.clone();
                RUNTIME
                    .spawn(async move { member.avatar(format).await })
                    .await??
            }
            UserProfile::PublicProfile(public_profile) => {
                let public_profile = public_profile.clone();
                RUNTIME
                    .spawn(async move { public_profile.avatar(format).await })
                    .await??
            }
        }))
    }

    pub fn shared_rooms(&self) -> Vec<String> {
        match self {
            UserProfile::Member((_, rooms)) => rooms.clone(),
            _ => vec![],
        }
    }

    pub fn display_name(&self) -> Option<String> {
        match self {
            UserProfile::Member((member, _v)) => member.display_name().map(|x| x.to_string()),
            UserProfile::PublicProfile(public_profile) => public_profile.inner.display_name.clone(),
        }
    }
}
