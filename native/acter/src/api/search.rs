use anyhow::Result;
use matrix_sdk::media::MediaRequestParameters;
use matrix_sdk_base::ruma::{
    api::client::directory::get_public_rooms_filtered,
    assign,
    directory::{Filter, PublicRoomJoinRule, PublicRoomsChunk, RoomNetwork, RoomTypeFilter},
    events::room::MediaSource,
    room::RoomType,
    OwnedMxcUri, OwnedRoomAliasId, OwnedRoomId, ServerName,
};

use super::{client::Client, RUNTIME};

use crate::{OptionBuffer, ThumbnailSize};

pub struct PublicSearchResultItem {
    chunk: PublicRoomsChunk,
    client: Client,
}

impl PublicSearchResultItem {
    pub fn name(&self) -> Option<String> {
        self.chunk.name.clone()
    }

    pub fn topic(&self) -> Option<String> {
        self.chunk.topic.clone()
    }

    pub fn world_readable(&self) -> bool {
        self.chunk.world_readable
    }

    pub fn guest_can_join(&self) -> bool {
        self.chunk.guest_can_join
    }

    pub fn canonical_alias(&self) -> Option<OwnedRoomAliasId> {
        self.chunk.canonical_alias.clone()
    }

    pub fn canonical_alias_str(&self) -> Option<String> {
        self.chunk.canonical_alias.as_ref().map(|a| a.to_string())
    }

    pub fn num_joined_members(&self) -> u64 {
        self.chunk.num_joined_members.into()
    }

    pub fn room_id(&self) -> OwnedRoomId {
        self.chunk.room_id.clone()
    }

    pub fn room_id_str(&self) -> String {
        self.chunk.room_id.to_string()
    }

    pub fn avatar_url(&self) -> Option<OwnedMxcUri> {
        self.chunk.avatar_url.clone()
    }

    pub fn avatar_url_str(&self) -> Option<String> {
        self.chunk.avatar_url.as_ref().map(|a| a.to_string())
    }

    pub fn has_avatar(&self) -> bool {
        self.chunk.avatar_url.is_some()
    }

    pub async fn get_avatar(&self, thumb_size: Option<Box<ThumbnailSize>>) -> Result<OptionBuffer> {
        let Some(url) = self.chunk.avatar_url.clone() else {
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

    pub fn join_rule(&self) -> PublicRoomJoinRule {
        self.chunk.join_rule.clone()
    }

    pub fn join_rule_str(&self) -> String {
        match self.chunk.join_rule {
            PublicRoomJoinRule::Public => "Public".to_owned(),
            PublicRoomJoinRule::Knock => "Knock".to_owned(),
            _ => "unknown".to_owned(),
        }
    }

    pub fn room_type(&self) -> Option<RoomType> {
        self.chunk.room_type.clone()
    }

    pub fn room_type_str(&self) -> String {
        match self.chunk.room_type {
            None => "Chat".to_owned(),
            Some(RoomType::Space) => "Space".to_owned(),
            Some(RoomType::_Custom(_)) => "Custom".to_string(),
            _ => "unknown".to_owned(),
        }
    }
}

pub struct PublicSearchResult {
    resp: get_public_rooms_filtered::v3::Response,
    client: Client,
}

impl PublicSearchResult {
    pub fn next_batch(&self) -> Option<String> {
        self.resp.next_batch.clone()
    }

    pub fn prev_batch(&self) -> Option<String> {
        self.resp.prev_batch.clone()
    }

    pub fn total_room_count_estimate(&self) -> Option<u64> {
        self.resp.total_room_count_estimate.map(u64::from)
    }

    pub fn chunks(&self) -> Vec<PublicSearchResultItem> {
        self.resp
            .chunk
            .iter()
            .map(|chunk| PublicSearchResultItem {
                chunk: chunk.clone(),
                client: self.client.clone(),
            })
            .collect()
    }
}

// public API
impl Client {
    pub async fn search_public_room(
        &self,
        search_term: Option<String>,
        server: Option<String>,
        filter_only: Option<String>,
        since: Option<String>,
    ) -> Result<PublicSearchResult> {
        let filter = filter_only.and_then(|s| match s.to_lowercase().as_str() {
            "spaces" => Some(RoomTypeFilter::Space),
            "chats" => Some(RoomTypeFilter::Default),
            _ => None,
        });
        self.search_public(search_term, server, since, filter).await
    }
}

// internal API
impl Client {
    pub(crate) async fn search_public(
        &self,
        search_term: Option<String>,
        server: Option<String>,
        since: Option<String>,
        filter_only: Option<RoomTypeFilter>,
    ) -> Result<PublicSearchResult> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let mut filter = Filter::new();
                filter.generic_search_term = search_term;
                if let Some(f) = filter_only {
                    filter.room_types = vec![f];
                }

                let room_network = RoomNetwork::Matrix;
                let server = if let Some(name) = server {
                    let server_name = ServerName::parse(name)?;
                    Some(server_name)
                } else {
                    None
                };
                let request = assign!(get_public_rooms_filtered::v3::Request::new(), {
                    since,
                    filter,
                    server,
                    room_network,
                });
                let resp = me.core.client().public_rooms_filtered(request).await?;
                Ok(PublicSearchResult { resp, client: me })
            })
            .await?
    }
}
