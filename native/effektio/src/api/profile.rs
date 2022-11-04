use anyhow::{bail, Result};
use log::info;
use matrix_sdk::{
    media::{MediaFormat, MediaRequest},
    ruma::{
        api::client::profile::get_profile::v3::Request as GetProfileRequest,
        events::room::MediaSource, OwnedMxcUri, OwnedRoomId, OwnedUserId, RoomId, UserId,
    },
    Client,
};

use super::{api::FfiBuffer, RUNTIME};

#[derive(Clone)]
pub struct UserProfile {
    client: Client,
    user_id: OwnedUserId,
    avatar_url: Option<OwnedMxcUri>,
    display_name: Option<String>,
}

impl UserProfile {
    pub(crate) fn new(client: Client, user_id: OwnedUserId) -> Self {
        UserProfile {
            client,
            user_id,
            avatar_url: None,
            display_name: None,
        }
    }

    pub(crate) async fn fetch(&mut self) -> Result<()> {
        // use low-level api request so that non-member can see member in room
        let client = self.client.clone();
        let user_id = self.user_id.clone();
        let req = GetProfileRequest::new(&user_id);
        let res = client.send(req, None).await?;
        self.avatar_url = res.avatar_url;
        self.display_name = res.displayname;
        Ok(())
    }

    pub fn has_avatar(&self) -> bool {
        self.avatar_url.is_some()
    }

    pub async fn get_avatar(&self) -> Result<FfiBuffer<u8>> {
        let client = self.client.clone();
        let avatar_url = self.avatar_url.clone().unwrap();
        RUNTIME
            .spawn(async move {
                let req = MediaRequest {
                    source: MediaSource::Plain(avatar_url),
                    format: MediaFormat::File,
                };
                if let Ok(res) = client.media().get_media_content(&req, true).await {
                    return Ok(FfiBuffer::new(res));
                }
                bail!("Could not get media content from user profile");
            })
            .await?
    }

    pub fn get_display_name(&self) -> Option<String> {
        self.display_name.clone()
    }
}

#[derive(Clone)]
pub struct RoomProfile {
    client: Client,
    room_id: OwnedRoomId,
    avatar_url: Option<OwnedMxcUri>,
    display_name: Option<String>,
}

impl RoomProfile {
    pub(crate) fn new(client: Client, room_id: OwnedRoomId) -> Self {
        RoomProfile {
            client,
            room_id,
            avatar_url: None,
            display_name: None,
        }
    }

    pub(crate) async fn fetch(&mut self) -> Result<()> {
        let client = self.client.clone();
        let room_id = self.room_id.clone();
        let room = client.get_room(&room_id).unwrap();
        if let Some(url) = room.avatar_url() {
            self.avatar_url = Some(url);
        }
        self.display_name = Some(room.display_name().await?.to_string());
        Ok(())
    }

    pub fn has_avatar(&self) -> bool {
        self.avatar_url.is_some()
    }

    pub async fn get_avatar(&self) -> Result<FfiBuffer<u8>> {
        let client = self.client.clone();
        let avatar_url = self.avatar_url.clone().unwrap();
        RUNTIME
            .spawn(async move {
                let req = MediaRequest {
                    source: MediaSource::Plain(avatar_url),
                    format: MediaFormat::File,
                };
                if let Ok(res) = client.media().get_media_content(&req, true).await {
                    return Ok(FfiBuffer::new(res));
                }
                bail!("Could not get media content from room profile");
            })
            .await?
    }

    pub fn get_display_name(&self) -> Option<String> {
        self.display_name.clone()
    }
}
