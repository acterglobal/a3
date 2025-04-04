use std::collections::BTreeMap;

use anyhow::Result;
use matrix_sdk::{room::RoomMember, RoomMemberships};
use matrix_sdk_base::{
    media::MediaRequestParameters,
    ruma::{
        api::client::directory::get_public_rooms_filtered,
        assign,
        directory::{Filter, PublicRoomJoinRule, PublicRoomsChunk, RoomNetwork, RoomTypeFilter},
        events::room::MediaSource,
        room::RoomType,
        OwnedMxcUri, OwnedRoomAliasId, OwnedRoomId, OwnedUserId, RoomId, ServerName,
    },
    RoomDisplayName, RoomState,
};
use ruma::api::client::user_directory::search_users;

use super::{client::Client, profile::PublicProfile, UserProfile, RUNTIME};

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
        self.chunk.canonical_alias.as_ref().map(ToString::to_string)
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
        self.chunk.avatar_url.as_ref().map(ToString::to_string)
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

struct SearchedUser {
    inner: search_users::v3::User,
}

impl SearchedUser {
    pub fn user_id_str(&self) -> String {
        self.inner.user_id.to_string()
    }
}
/// external API
impl Client {
    pub async fn search_users(&self, search_term: String) -> Result<Vec<UserProfile>> {
        let client = self.core.client().clone();
        RUNTIME
            .spawn(async move {
                let resp = client.search_users(&search_term, 30).await?;
                let user_profiles = resp
                    .results
                    .into_iter()
                    .map(|inner| PublicProfile::new(inner, client.clone()))
                    .map(UserProfile::from_search)
                    .collect();
                Ok(user_profiles)
            })
            .await?
    }

    pub async fn suggested_users(&self, room_name: Option<String>) -> Result<Vec<UserProfile>> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                // get member list of target room
                let local_members = if let Some(room_name) = room_name {
                    if let Some(room) = me.core.client().get_room(&RoomId::parse(room_name)?) {
                        room.members(RoomMemberships::all())
                            .await?
                            .iter()
                            .map(|x| x.user_id().to_owned())
                            .collect::<Vec<OwnedUserId>>()
                    } else {
                        // but we always ignore ourselves
                        vec![me.user_id()?]
                    }
                } else {
                    // but we always ignore ourselves
                    vec![me.user_id()?]
                };
                // iterate my rooms to get user list
                let mut profiles: BTreeMap<OwnedUserId, (RoomMember, Vec<String>)> =
                    Default::default();
                for room in me.rooms().iter().filter(|r| r.are_members_synced()) {
                    let members = room.members(RoomMemberships::ACTIVE).await?;
                    let room_id = room.room_id().to_string();
                    for member in members.into_iter() {
                        let user_id = member.user_id().to_owned();
                        // exclude user that belongs to target room
                        if local_members.contains(&user_id) {
                            continue;
                        }
                        profiles
                            .entry(user_id)
                            .and_modify(|(m, rooms)| {
                                rooms.push(room_id.clone());
                            })
                            .or_insert_with(|| (member, vec![room_id.clone()]));
                    }
                }
                let mut found_profiles = profiles
                    .into_values()
                    .map(|(m, rooms)| UserProfile::with_shared_rooms(m, rooms))
                    .collect::<Vec<_>>();

                found_profiles.sort_by_cached_key(|a| -(a.shared_rooms().len() as i64)); // reverse sort

                Ok(found_profiles)
            })
            .await?
    }
}
