use anyhow::{bail, Context, Result};
use matrix_sdk::{
    media::{MediaFormat, MediaThumbnailSize},
    room::RoomMember,
    ruma::{api::client::media::get_content_thumbnail::v3::Method, OwnedRoomId, OwnedUserId, UInt},
    Account, Client, DisplayName,
};

use super::{
    api::FfiBuffer,
    common::{OptionBuffer, OptionText},
    RUNTIME,
};

#[derive(Clone)]
pub struct UserProfile {
    account: Option<Account>,
    user_id: OwnedUserId,
    member: Option<RoomMember>,
}

impl UserProfile {
    pub(crate) fn from_account(account: Account, user_id: OwnedUserId) -> Self {
        UserProfile {
            account: Some(account),
            user_id,
            member: None,
        }
    }

    pub(crate) fn from_member(member: RoomMember) -> Self {
        UserProfile {
            account: None,
            user_id: member.user_id().to_owned(),
            member: Some(member),
        }
    }

    pub fn user_id(&self) -> OwnedUserId {
        self.user_id.clone()
    }

    pub async fn has_avatar(&self) -> Result<bool> {
        if let Some(account) = self.account.clone() {
            return RUNTIME
                .spawn(async move {
                    let url = account.get_avatar_url().await?;
                    Ok(url.is_some())
                })
                .await?;
        }
        if let Some(member) = self.member.clone() {
            return Ok(member.avatar_url().is_some());
        }
        Ok(false)
    }

    pub async fn get_avatar(&self) -> Result<OptionBuffer> {
        if let Some(account) = self.account.clone() {
            return RUNTIME
                .spawn(async move {
                    let buf = account.get_avatar(MediaFormat::File).await?;
                    Ok(OptionBuffer::new(buf))
                })
                .await?;
        }
        if let Some(member) = self.member.clone() {
            return RUNTIME
                .spawn(async move {
                    let buf = member.avatar(MediaFormat::File).await?;
                    Ok(OptionBuffer::new(buf))
                })
                .await?;
        }
        Ok(OptionBuffer::new(None))
    }

    pub async fn get_thumbnail(&self, width: u32, height: u32) -> Result<OptionBuffer> {
        if let Some(account) = self.account.clone() {
            return RUNTIME
                .spawn(async move {
                    let size = MediaThumbnailSize {
                        method: Method::Scale,
                        width: UInt::from(width),
                        height: UInt::from(height),
                    };
                    let buf = account.get_avatar(MediaFormat::Thumbnail(size)).await?;
                    Ok(OptionBuffer::new(buf))
                })
                .await?;
        }
        if let Some(member) = self.member.clone() {
            return RUNTIME
                .spawn(async move {
                    let size = MediaThumbnailSize {
                        method: Method::Scale,
                        width: UInt::from(width),
                        height: UInt::from(height),
                    };
                    let buf = member.avatar(MediaFormat::Thumbnail(size)).await?;
                    Ok(OptionBuffer::new(buf))
                })
                .await?;
        }
        Ok(OptionBuffer::new(None))
    }

    pub async fn get_display_name(&self) -> Result<OptionText> {
        if let Some(account) = self.account.clone() {
            return RUNTIME
                .spawn(async move {
                    let text = account.get_display_name().await?;
                    Ok(OptionText::new(text))
                })
                .await?;
        }
        if let Some(member) = self.member.clone() {
            let text = member.display_name().map(|x| x.to_string());
            return Ok(OptionText::new(text));
        }
        Ok(OptionText::new(None))
    }
}

#[derive(Clone)]
pub struct RoomProfile {
    client: Client,
    room_id: OwnedRoomId,
}

impl RoomProfile {
    pub(crate) fn new(client: Client, room_id: OwnedRoomId) -> Self {
        RoomProfile { client, room_id }
    }

    pub fn has_avatar(&self) -> Result<bool> {
        let room = self
            .client
            .get_room(&self.room_id)
            .context("Room not found")?;
        Ok(room.avatar_url().is_some())
    }

    pub async fn get_avatar(&self) -> Result<OptionBuffer> {
        let room = self
            .client
            .get_room(&self.room_id)
            .context("Room not found")?;
        RUNTIME
            .spawn(async move {
                let buf = room.avatar(MediaFormat::File).await?;
                Ok(OptionBuffer::new(buf))
            })
            .await?
    }

    pub async fn get_thumbnail(&self, width: u32, height: u32) -> Result<OptionBuffer> {
        let room = self
            .client
            .get_room(&self.room_id)
            .context("Room not found")?;
        RUNTIME
            .spawn(async move {
                let size = MediaThumbnailSize {
                    method: Method::Scale,
                    width: UInt::from(width),
                    height: UInt::from(height),
                };
                let buf = room.avatar(MediaFormat::Thumbnail(size)).await?;
                Ok(OptionBuffer::new(buf))
            })
            .await?
    }

    pub async fn get_display_name(&self) -> Result<OptionText> {
        let room = self
            .client
            .get_room(&self.room_id)
            .context("Room not found")?;
        RUNTIME
            .spawn(async move {
                let result = room.display_name().await?;
                match result {
                    DisplayName::Named(name) => Ok(OptionText::new(Some(name))),
                    DisplayName::Aliased(name) => Ok(OptionText::new(Some(name))),
                    DisplayName::Calculated(name) => Ok(OptionText::new(Some(name))),
                    DisplayName::EmptyWas(name) => Ok(OptionText::new(Some(name))),
                    DisplayName::Empty => Ok(OptionText::new(None)),
                }
            })
            .await?
    }
}
