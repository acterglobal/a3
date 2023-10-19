use anyhow::Result;
use matrix_sdk::ruma::{
    api::client::directory::get_public_rooms_filtered::v3::{
        Request as FilteredRequest, Response as FilteredResponse,
    },
    assign,
    directory::{Filter, PublicRoomJoinRule, PublicRoomsChunk, RoomNetwork, RoomTypeFilter},
    room::RoomType,
    OwnedMxcUri, OwnedRoomAliasId, OwnedRoomId, OwnedServerName,
};
use tracing::{error, trace};

use super::{client::Client, RUNTIME};

pub struct PublicSearchResultItem {
    chunk: PublicRoomsChunk,
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

    pub fn num_joined_members(&self) -> u32 {
        let count = u64::from(self.chunk.num_joined_members);
        if count > u32::MAX as u64 {
            panic!("count of joined members overflowed");
        }
        count as u32
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
            Some(RoomType::Space) => "Space".to_owned(),
            Some(RoomType::_Custom(_)) => "Custom".to_string(),
            _ => "unknown".to_owned(),
        }
    }
}

pub struct PublicSearchResult {
    resp: FilteredResponse,
}

impl PublicSearchResult {
    pub fn next_batch(&self) -> Option<String> {
        self.resp.next_batch.clone()
    }

    pub fn prev_batch(&self) -> Option<String> {
        self.resp.prev_batch.clone()
    }

    pub fn total_room_count_estimate(&self) -> Option<u32> {
        self.resp.total_room_count_estimate.map(|x| {
            let count = u64::from(x);
            if count > u32::MAX as u64 {
                panic!("count of total rooms overflowed");
            }
            count as u32
        })
    }

    pub fn chunks(&self) -> Vec<PublicSearchResultItem> {
        self.resp
            .chunk
            .iter()
            .map(|chunk| PublicSearchResultItem {
                chunk: chunk.clone(),
            })
            .collect()
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
        let c = self.clone();
        RUNTIME
            .spawn(async move {
                let mut filter = Filter::new();
                filter.generic_search_term = search_term;
                if let Some(f) = filter_only {
                    filter.room_types = vec![f];
                }

                let room_network = RoomNetwork::Matrix;
                let server = if let Some(name) = server {
                    Some(OwnedServerName::try_from(name.as_str())?)
                } else {
                    None
                };
                let request = assign!(FilteredRequest::new(), {
                    since,
                    filter,
                    server,
                    room_network,
                });
                let resp = c.public_rooms_filtered(request).await?;
                Ok(PublicSearchResult { resp })
            })
            .await?
    }
}
