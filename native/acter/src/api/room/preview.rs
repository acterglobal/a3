use anyhow::Result;
use matrix_sdk::{
    media::MediaRequestParameters, room_preview::RoomPreview as SdkRoomPreview,
    Client as SdkClient, RoomState,
};
use ruma::{
    events::room::MediaSource, room::RoomType, space::SpaceRoomJoinRule, OwnedServerName,
    RoomOrAliasId, ServerName,
};

use crate::{api::utils::VecStringBuilder, OptionBuffer, ThumbnailSize, RUNTIME};

pub struct RoomPreview {
    inner: SdkRoomPreview,
    client: SdkClient,
}

impl RoomPreview {
    pub fn room_id_str(&self) -> String {
        self.inner.room_id.to_string()
    }

    pub fn name(&self) -> Option<String> {
        self.inner.name.clone()
    }

    pub fn topic(&self) -> Option<String> {
        self.inner.topic.clone()
    }

    pub fn avatar_url_str(&self) -> Option<String> {
        self.inner.avatar_url.as_ref().map(|s| s.to_string())
    }

    pub fn has_avatar(&self) -> bool {
        self.inner.avatar_url.is_some()
    }

    pub fn canonical_alias_str(&self) -> Option<String> {
        self.inner.canonical_alias.as_ref().map(|s| s.to_string())
    }

    pub fn room_type_str(&self) -> String {
        match self.inner.room_type {
            None => "Chat".to_owned(),
            Some(RoomType::Space) => "Space".to_owned(),
            _ => "unknown".to_owned(),
        }
    }

    pub fn join_rule(&self) -> SpaceRoomJoinRule {
        self.inner.join_rule.clone()
    }

    pub fn num_joined_members(&self) -> u64 {
        self.inner.num_joined_members
    }

    // pub fn num_active_members(&self) -> Option<u64> {
    //     self.inner.num_active_members.clone()
    // }

    pub fn is_direct(&self) -> Option<bool> {
        self.inner.is_direct
    }

    pub fn is_world_readable(&self) -> bool {
        self.inner.is_world_readable
    }

    pub fn state(&self) -> Option<RoomState> {
        self.inner.state
    }

    pub fn state_str(&self) -> String {
        match self.inner.state {
            None => "unknown".to_string(),
            Some(RoomState::Invited) => "invited".to_string(),
            Some(RoomState::Joined) => "joined".to_string(),
            Some(RoomState::Left) => "left".to_string(),
            Some(RoomState::Knocked) => "knocked".to_string(),
        }
    }

    pub fn join_rule_str(&self) -> String {
        match self.inner.join_rule {
            SpaceRoomJoinRule::Invite => "Invite".to_owned(),
            SpaceRoomJoinRule::Private => "Private".to_owned(),
            SpaceRoomJoinRule::Public => "Public".to_owned(),
            SpaceRoomJoinRule::Knock => "Knock".to_owned(),
            SpaceRoomJoinRule::Restricted => "Restricted".to_owned(),
            SpaceRoomJoinRule::KnockRestricted => "KnockRestricted".to_owned(),
            _ => "unknown".to_owned(),
        }
    }

    pub fn room_type(&self) -> Option<RoomType> {
        self.inner.room_type.clone()
    }
    pub async fn avatar(&self, thumb_size: Option<Box<ThumbnailSize>>) -> Result<OptionBuffer> {
        let Some(url) = self.inner.avatar_url.clone() else {
            return Ok(OptionBuffer::new(None));
        };

        let client = self.client.clone();
        let format = ThumbnailSize::parse_into_media_format(thumb_size);
        RUNTIME
            .spawn(async move {
                let request = MediaRequestParameters {
                    source: MediaSource::Plain(url),
                    format,
                };
                let buf = client.media().get_media_content(&request, true).await?;
                Ok(OptionBuffer::new(Some(buf)))
            })
            .await?
    }
}

impl crate::Client {
    pub async fn room_preview(
        &self,
        room_id_or_alias: String,
        server_names: Box<VecStringBuilder>,
    ) -> Result<RoomPreview> {
        let client = self.core.client().clone();
        let room_id = RoomOrAliasId::parse(room_id_or_alias)?;
        let servers = (*server_names)
            .0
            .into_iter()
            .map(ServerName::parse)
            .collect::<Result<Vec<OwnedServerName>, matrix_sdk::IdParseError>>()?;

        RUNTIME
            .spawn(async move {
                let inner = client.get_room_preview(&room_id, servers).await?;
                Ok(RoomPreview { inner, client })
            })
            .await?
    }
}
