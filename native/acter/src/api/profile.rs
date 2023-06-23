use anyhow::{bail, Context, Result};
use log::info;
use matrix_sdk::{
    media::{MediaFormat, MediaThumbnailSize},
    room::RoomMember,
    ruma::{api::client::media::get_content_thumbnail::v3::Method, OwnedRoomId, OwnedUserId, UInt},
    Account, Client, DisplayName,
};

use super::{api::FfiBuffer, RUNTIME};

pub struct DispName {
    text: Option<String>,
}

impl DispName {
    pub fn text(&self) -> Option<String> {
        self.text.clone()
    }
}

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
                    let url = account
                        .get_avatar_url()
                        .await
                        .context("Couldn't get avatar url")?;
                    Ok(url.is_some())
                })
                .await?;
        }
        if let Some(member) = self.member.clone() {
            return Ok(member.avatar_url().is_some());
        }
        Ok(false)
    }

    pub async fn get_avatar(&self) -> Result<FfiBuffer<u8>> {
        if let Some(account) = self.account.clone() {
            return RUNTIME
                .spawn(async move {
                    let result = account
                        .get_avatar(MediaFormat::File)
                        .await
                        .context("Couldn't get avatar from account")?;
                    match result {
                        Some(result) => Ok(FfiBuffer::new(result)),
                        None => Ok(FfiBuffer::new(vec![])),
                    }
                })
                .await?;
        }
        if let Some(member) = self.member.clone() {
            return RUNTIME
                .spawn(async move {
                    let result = member
                        .avatar(MediaFormat::File)
                        .await
                        .context("Couldn't get avatar from account")?;
                    match result {
                        Some(result) => Ok(FfiBuffer::new(result)),
                        None => Ok(FfiBuffer::new(vec![])),
                    }
                })
                .await?;
        }
        Ok(FfiBuffer::new(vec![]))
    }

    pub async fn get_thumbnail(&self, width: u32, height: u32) -> Result<FfiBuffer<u8>> {
        if let Some(account) = self.account.clone() {
            return RUNTIME
                .spawn(async move {
                    let size = MediaThumbnailSize {
                        method: Method::Scale,
                        width: UInt::from(width),
                        height: UInt::from(height),
                    };
                    let result = account
                        .get_avatar(MediaFormat::Thumbnail(size))
                        .await
                        .context("Couldn't get avatar from account")?;
                    match result {
                        Some(result) => Ok(FfiBuffer::new(result)),
                        None => Ok(FfiBuffer::new(vec![])),
                    }
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
                    let result = member
                        .avatar(MediaFormat::Thumbnail(size))
                        .await
                        .context("Couldn't get avatar from account")?;
                    match result {
                        Some(result) => Ok(FfiBuffer::new(result)),
                        None => Ok(FfiBuffer::new(vec![])),
                    }
                })
                .await?;
        }
        Ok(FfiBuffer::new(vec![]))
    }

    pub async fn get_display_name(&self) -> Result<DispName> {
        if let Some(account) = self.account.clone() {
            return RUNTIME
                .spawn(async move {
                    let text = account.get_display_name().await?;
                    info!("get_display_name: {:?}", text);
                    Ok(DispName { text })
                })
                .await?;
        }
        if let Some(member) = self.member.clone() {
            let text = member.display_name().map(|x| x.to_string());
            return Ok(DispName { text });
        }
        Ok(DispName { text: None })
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
            .context("couldn't get room from client")?;
        Ok(room.avatar_url().is_some())
    }

    pub async fn get_avatar(&self) -> Result<FfiBuffer<u8>> {
        let room = self
            .client
            .get_room(&self.room_id)
            .context("couldn't get room from client")?;
        RUNTIME
            .spawn(async move {
                let result = room
                    .avatar(MediaFormat::File)
                    .await
                    .context("Couldn't get avatar from room")?;
                match result {
                    Some(result) => Ok(FfiBuffer::new(result)),
                    None => Ok(FfiBuffer::new(vec![])),
                }
            })
            .await?
    }

    pub async fn get_thumbnail(&self, width: u32, height: u32) -> Result<FfiBuffer<u8>> {
        let room = self
            .client
            .get_room(&self.room_id)
            .context("couldn't get room from client")?;
        RUNTIME
            .spawn(async move {
                let size = MediaThumbnailSize {
                    method: Method::Scale,
                    width: UInt::from(width),
                    height: UInt::from(height),
                };
                let result = room
                    .avatar(MediaFormat::Thumbnail(size))
                    .await
                    .context("Couldn't get avatar from room")?;
                match result {
                    Some(result) => Ok(FfiBuffer::new(result)),
                    None => Ok(FfiBuffer::new(vec![])),
                }
            })
            .await?
    }

    pub async fn get_display_name(&self) -> Result<DispName> {
        let room = self
            .client
            .get_room(&self.room_id)
            .context("couldn't get room from client")?;
        RUNTIME
            .spawn(async move {
                let result = room
                    .display_name()
                    .await
                    .context("Couldn't get display name from room")?;
                match result {
                    DisplayName::Named(name) => Ok(DispName { text: Some(name) }),
                    DisplayName::Aliased(name) => Ok(DispName { text: Some(name) }),
                    DisplayName::Calculated(name) => Ok(DispName { text: Some(name) }),
                    DisplayName::EmptyWas(name) => Ok(DispName { text: Some(name) }),
                    DisplayName::Empty => Ok(DispName { text: None }),
                }
            })
            .await?
    }
}
