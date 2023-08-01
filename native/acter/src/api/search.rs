pub use acter_core::spaces::{
    CreateSpaceSettings, CreateSpaceSettingsBuilder, RelationTargetType, SpaceRelation,
    SpaceRelations,
};
use acter_core::{
    executor::Executor, models::AnyActerModel, spaces::is_acter_space,
    statics::default_acter_space_states, templates::Engine,
};
use anyhow::{bail, Context, Result};
use futures::stream::StreamExt;
use matrix_sdk::{
    deserialized_responses::EncryptionInfo,
    event_handler::{Ctx, EventHandlerHandle},
    room::{Messages, MessagesOptions, Room as SdkRoom},
    ruma::{
        api::client::state::send_state_event::v3::Request as SendStateEventRequest,
        events::{
            space::child::SpaceChildEventContent, AnyStateEventContent, MessageLikeEvent,
            StateEventType,
        },
        serde::Raw,
        OwnedRoomAliasId, OwnedRoomId, OwnedUserId,
    },
    Client as SdkClient,
};
use ruma::{
    assign, directory::PublicRoomJoinRule, room::RoomType, OwnedMxcUri, OwnedRoomOrAliasId,
    OwnedServerName,
};
use serde::{Deserialize, Serialize};
use std::ops::Deref;
use tokio::sync::broadcast::Receiver;
use tracing::{error, trace};

use super::{
    client::{devide_spaces_from_convos, Client, SpaceFilter, SpaceFilterBuilder},
    room::{Member, Room},
    RUNTIME,
};

pub struct PublicSearchResultItem {
    chunk: ruma::directory::PublicRoomsChunk,
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
    resp: ruma::api::client::directory::get_public_rooms_filtered::v3::Response,
}

impl PublicSearchResult {
    pub fn next_batch(&self) -> Option<String> {
        self.resp.next_batch.clone()
    }
    pub fn prev_batch(&self) -> Option<String> {
        self.resp.prev_batch.clone()
    }
    pub fn total_room_count_estimate(&self) -> Option<u64> {
        self.resp.total_room_count_estimate.map(Into::into)
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
        filter_only: Option<ruma::directory::RoomTypeFilter>,
    ) -> Result<PublicSearchResult> {
        let c = self.clone();
        RUNTIME
            .spawn(async move {
                let mut filter = ruma::directory::Filter::new();
                filter.generic_search_term = search_term;
                if let Some(f) = filter_only {
                    filter.room_types = vec![f];
                }

                let room_network = ruma::directory::RoomNetwork::Matrix;
                let server = if let Some(name) = server { Some(OwnedServerName::try_from(name.as_str())?) } else { None };
                let request = assign!(ruma::api::client::directory::get_public_rooms_filtered::v3::Request::new(), { since, filter, server, room_network});
                let resp = c.public_rooms_filtered(request).await?;
                Ok(PublicSearchResult { resp })
            })
            .await?
    }
}
