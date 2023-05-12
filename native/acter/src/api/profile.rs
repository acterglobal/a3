use anyhow::{bail, Result};
use log::info;
use matrix_sdk::{
    media::{MediaFormat, MediaRequest, MediaThumbnailSize},
    ruma::{
        api::client::{
            media::get_content_thumbnail::v3::Method,
            profile::get_profile::v3::Request as GetProfileRequest,
        },
        events::room::MediaSource,
        OwnedMxcUri, OwnedRoomId, OwnedUserId, UInt,
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
    pub(crate) fn new(
        client: Client,
        user_id: OwnedUserId,
        avatar_url: Option<OwnedMxcUri>,
        display_name: Option<String>,
    ) -> Self {
        UserProfile {
            client,
            user_id,
            avatar_url,
            display_name,
        }
    }

    pub(crate) async fn fetch(&mut self) -> Result<()> {
        // use low-level api request so that non-member can see member in room
        let client = self.client.clone();
        let user_id = self.user_id.clone();
        let request = GetProfileRequest::new(user_id);
        let response = client.send(request, None).await?;
        self.avatar_url = response.avatar_url;
        self.display_name = response.displayname;
        Ok(())
    }

    pub fn user_id(&self) -> OwnedUserId {
        self.user_id.clone()
    }

    pub fn has_avatar(&self) -> bool {
        self.avatar_url.is_some()
    }

    pub async fn get_avatar(&self) -> Result<FfiBuffer<u8>> {
        let client = self.client.clone();
        let Some(avatar_url) = self.avatar_url.clone() else {
            bail!("No User Profile found");
        };
        RUNTIME
            .spawn(async move {
                let request = MediaRequest {
                    source: MediaSource::Plain(avatar_url),
                    format: MediaFormat::File,
                };
                if let Ok(result) = client.media().get_media_content(&request, true).await {
                    return Ok(FfiBuffer::new(result));
                }
                // sometimes fetching failed, i don't know that reason
                log::warn!("Could not get media content from user profile");
                Ok(FfiBuffer::new(vec![]))
            })
            .await?
    }

    pub async fn get_thumbnail(&self, width: u32, height: u32) -> Result<FfiBuffer<u8>> {
        let client = self.client.clone();
        let avatar_url = self.avatar_url.clone().unwrap();
        RUNTIME
            .spawn(async move {
                let size = MediaThumbnailSize {
                    method: Method::Scale,
                    width: UInt::from(width),
                    height: UInt::from(height),
                };
                let request = MediaRequest {
                    source: MediaSource::Plain(avatar_url),
                    format: MediaFormat::Thumbnail(size),
                };
                if let Ok(result) = client.media().get_media_content(&request, true).await {
                    return Ok(FfiBuffer::new(result));
                }
                // sometimes fetching failed, i don't know that reason
                info!("Could not get media content from user profile");
                Ok(FfiBuffer::new(vec![]))
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
                let request = MediaRequest {
                    source: MediaSource::Plain(avatar_url),
                    format: MediaFormat::File,
                };
                if let Ok(result) = client.media().get_media_content(&request, true).await {
                    return Ok(FfiBuffer::new(result));
                }
                // sometimes fetching failed, i don't know that reason
                info!("Could not get media content from room profile");
                Ok(FfiBuffer::new(vec![]))
            })
            .await?
    }

    pub async fn get_thumbnail(&self, width: u32, height: u32) -> Result<FfiBuffer<u8>> {
        let client = self.client.clone();
        let avatar_url = self.avatar_url.clone().unwrap();
        RUNTIME
            .spawn(async move {
                let size = MediaThumbnailSize {
                    method: Method::Scale,
                    width: UInt::from(width),
                    height: UInt::from(height),
                };
                let request = MediaRequest {
                    source: MediaSource::Plain(avatar_url),
                    format: MediaFormat::Thumbnail(size),
                };
                if let Ok(result) = client.media().get_media_content(&request, true).await {
                    return Ok(FfiBuffer::new(result));
                }
                // sometimes fetching failed, i don't know that reason
                info!("Could not get media content from room profile");
                Ok(FfiBuffer::new(vec![]))
            })
            .await?
    }

    pub fn get_display_name(&self) -> Option<String> {
        self.display_name.clone()
    }
}
