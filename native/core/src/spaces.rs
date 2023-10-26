use derive_builder::Builder;
use matrix_sdk::{
    room::Room,
    ruma::{
        api::client::room::{create_room, Visibility},
        assign,
    },
};
use ruma_common::{
    room::RoomType, serde::Raw, MxcUri, OwnedRoomId, OwnedServerName, OwnedUserId, RoomId, UserId,
};
use ruma_events::{
    room::{
        avatar::{ImageInfo, InitialRoomAvatarEvent, RoomAvatarEventContent},
        join_rules::{AllowRule, InitialRoomJoinRulesEvent, RoomJoinRulesEventContent},
    },
    space::{child::SpaceChildEventContent, parent::SpaceParentEventContent},
    InitialStateEvent,
};
use serde::{Deserialize, Serialize};
use std::path::PathBuf;
use strum::Display;
use tracing::error;

use crate::{
    client::CoreClient,
    error::{Error, Result},
    statics::{default_acter_space_states, PURPOSE_FIELD, PURPOSE_FIELD_DEV, PURPOSE_TEAM_VALUE},
};

/// Calculate whether we may consider this an acter space
pub async fn is_acter_space(room: &Room) -> bool {
    if !room.is_space() {
        return false;
    }
    if let Ok(Some(_)) = room
        .get_state_event(PURPOSE_FIELD.into(), PURPOSE_TEAM_VALUE)
        .await
    {
        true
    } else {
        let evt = room
            .get_state_event(PURPOSE_FIELD_DEV.into(), PURPOSE_TEAM_VALUE)
            .await;
        matches!(evt, Ok(Some(_)))
    }
}

fn space_visibilty_default() -> Visibility {
    Visibility::Private
}

#[derive(Builder, Default, Deserialize, Serialize, Clone)]
pub struct CreateSpaceSettings {
    #[builder(setter(strip_option))]
    name: Option<String>,

    #[builder(default = "Visibility::Private")]
    #[serde(default = "space_visibilty_default")]
    visibility: Visibility,

    #[builder(default = "Vec::new()")]
    #[serde(default)]
    invites: Vec<OwnedUserId>,

    #[builder(setter(strip_option), default)]
    alias: Option<String>,

    #[builder(setter(strip_option), default)]
    topic: Option<String>,

    #[builder(setter(strip_option), default)]
    avatar_uri: Option<String>,

    #[builder(setter(strip_option), default)]
    parent: Option<OwnedRoomId>,
}

// helper for built-in setters
impl CreateSpaceSettingsBuilder {
    pub fn set_name(&mut self, value: String) {
        self.name(value);
    }

    pub fn set_visibility(&mut self, value: String) {
        match value.as_str() {
            "Public" => {
                self.visibility(Visibility::Public);
            }
            "Private" => {
                self.visibility(Visibility::Private);
            }
            _ => {}
        }
    }

    pub fn add_invitee(&mut self, value: String) -> Result<()> {
        if let Ok(user_id) = UserId::parse(value) {
            if let Some(mut invites) = self.invites.clone() {
                invites.push(user_id);
                self.invites = Some(invites);
            } else {
                self.invites = Some(vec![user_id]);
            }
        }
        Ok(())
    }

    pub fn set_alias(&mut self, value: String) {
        self.alias(value);
    }

    pub fn set_topic(&mut self, value: String) {
        self.topic(value);
    }

    pub fn set_avatar_uri(&mut self, value: String) {
        self.avatar_uri(value);
    }

    pub fn set_parent(&mut self, value: String) {
        if let Ok(parent) = RoomId::parse(value) {
            self.parent(parent);
        }
    }
}

#[derive(Clone, Debug, Default, Display)]
pub enum RelationTargetType {
    #[default]
    Unknown,
    ChatRoom,
    Space,
    ActerSpace,
}

#[derive(Debug, Clone)]
pub struct SpaceRelation {
    room_id: OwnedRoomId,
    suggested: bool,
    target_type: RelationTargetType,
    via: Vec<OwnedServerName>,
}

impl SpaceRelation {
    pub fn suggested(&self) -> bool {
        self.suggested
    }

    pub fn room_id(&self) -> OwnedRoomId {
        self.room_id.clone()
    }

    pub fn target_type(&self) -> String {
        self.target_type.to_string()
    }

    pub fn via(&self) -> Vec<String> {
        self.via.iter().map(|x| x.to_string()).collect()
    }
}

#[derive(Clone, Debug)]
pub struct SpaceRelations {
    main_parent: Option<SpaceRelation>,
    other_parents: Vec<SpaceRelation>,
    children: Vec<SpaceRelation>,
}

impl SpaceRelations {
    pub fn main_parent(&self) -> Option<SpaceRelation> {
        self.main_parent.clone()
    }

    pub fn other_parents(&self) -> Vec<SpaceRelation> {
        self.other_parents.clone()
    }

    pub fn children(&self) -> Vec<SpaceRelation> {
        self.children.clone()
    }
}

impl CoreClient {
    pub async fn create_acter_space(&self, settings: CreateSpaceSettings) -> Result<OwnedRoomId> {
        let client = self.client();
        let content = assign!(create_room::v3::CreationContent::new(), {
            room_type: Some(RoomType::Space),
        });
        let CreateSpaceSettings {
            name,
            visibility,
            invites,
            alias,
            topic,
            avatar_uri, // remote or local
            parent,
        } = settings;
        let mut initial_states = default_acter_space_states();

        if let Some(avatar_uri) = avatar_uri {
            let uri = Box::<MxcUri>::from(avatar_uri.as_str());
            let avatar_content = if uri.is_valid() {
                // remote uri
                assign!(RoomAvatarEventContent::new(), {
                    url: Some((*uri).to_owned()),
                })
            } else {
                // local uri
                let path = PathBuf::from(avatar_uri);
                let guess = mime_guess::from_path(path.clone());
                let content_type = guess.first().expect("MIME type should be given");
                let buf = std::fs::read(path).expect("File should be read");
                let upload_resp = client.media().upload(&content_type, buf).await?;

                let info = assign!(ImageInfo::new(), {
                    blurhash: upload_resp.blurhash,
                    mimetype: Some(content_type.to_string()),
                });
                assign!(RoomAvatarEventContent::new(), {
                    url: Some(upload_resp.content_uri),
                    info: Some(Box::new(info)),
                })
            };
            initial_states.push(InitialRoomAvatarEvent::new(avatar_content).to_raw_any());
        };

        if let Some(parent) = parent {
            let Some(Ok(homeserver)) = client.homeserver().host_str().map(|h|h.try_into()) else {
                return Err(Error::HomeserverMissesHostname);
            };
            let parent_event = InitialStateEvent::<SpaceParentEventContent> {
                content: assign!(SpaceParentEventContent::new(vec![homeserver]), {
                    canonical: true,
                }),
                state_key: parent.clone(),
            };
            initial_states.push(parent_event.to_raw_any());
            // if we have a parent, by default we allow access to the subspace.
            let join_rule =
                InitialRoomJoinRulesEvent::new(RoomJoinRulesEventContent::restricted(vec![
                    AllowRule::room_membership(parent),
                ]));
            initial_states.push(join_rule.to_raw_any());
        };

        let request = assign!(create_room::v3::Request::new(), {
            creation_content: Some(Raw::new(&content)?),
            initial_state: initial_states,
            is_direct: false,
            invite: invites,
            room_alias_name: alias,
            name,
            visibility,
            topic,
        });
        let room = client.create_room(request).await?;
        Ok(room.room_id().to_owned())
    }

    // calculate the space relationships in accordance with:
    // https://spec.matrix.org/v1.6/client-server-api/#mspacechild-relationship
    pub async fn space_relations(&self, room: &Room) -> Result<SpaceRelations> {
        let mut main_parent: Option<SpaceRelation> = None;
        let mut parents = Vec::new();
        let mut children = Vec::new();

        let parents_events = room
            .get_state_events_static::<SpaceParentEventContent>()
            .await?;

        let children_events = room
            .get_state_events_static::<SpaceChildEventContent>()
            .await?;

        for raw in parents_events {
            let ev = match raw.deserialize() {
                Ok(e) => e,
                Err(error) => {
                    error!(
                        room_id = ?room.room_id(),
                        ?error,
                        "Parsing parent event failed"
                    );
                    continue;
                }
            };

            let Some(original) = ev.as_sync().and_then(|x| x.as_original()) else {
                // FIXME: handle redactions
                continue
            };

            let target = ev.state_key();
            let target_type = if let Some(parent) = self.client().get_room(target) {
                if !parent.is_space() {
                    RelationTargetType::ChatRoom
                } else if is_acter_space(&parent).await {
                    RelationTargetType::ActerSpace
                } else {
                    RelationTargetType::Space
                }
            } else {
                RelationTargetType::Unknown
            };

            let me = SpaceRelation {
                target_type,
                room_id: target.to_owned(),
                suggested: false,
                via: original.content.via.clone(),
            };

            if original.content.canonical {
                if let Some(prev_canonical) = main_parent.take() {
                    // maybe replacing according to spec
                    if me.room_id < prev_canonical.room_id {
                        main_parent = Some(me);
                        parents.push(prev_canonical);
                    } else {
                        main_parent = Some(prev_canonical);
                        parents.push(me);
                    }
                } else {
                    main_parent = Some(me);
                    continue;
                }
            } else {
                parents.push(me);
            }
        }

        for raw in children_events {
            let ev = match raw.deserialize() {
                Ok(e) => e,
                Err(error) => {
                    error!(
                        room_id = ?room.room_id(),
                        ?error,
                        "Parsing parent event failed"
                    );
                    continue;
                }
            };

            let Some(original) = ev.as_sync().and_then(|x| x.as_original()) else {
                // FIXME: handle redactions
                continue
            };

            let target = ev.state_key();
            let target_type = if let Some(child) = self.client().get_room(target) {
                if !child.is_space() {
                    RelationTargetType::ChatRoom
                } else if is_acter_space(&child).await {
                    RelationTargetType::ActerSpace
                } else {
                    RelationTargetType::Space
                }
            } else {
                RelationTargetType::Unknown
            };

            let order = original
                .content
                .order
                .clone()
                .unwrap_or_else(|| target.to_string());
            let me = SpaceRelation {
                target_type,
                room_id: target.to_owned(),
                suggested: original.content.suggested,
                via: original.content.via.clone(),
            };
            children.push((order, me))
        }

        children.sort_by_key(|(x, _)| x.to_owned());

        Ok(SpaceRelations {
            main_parent,
            other_parents: parents,
            children: children.into_iter().map(|(_, c)| c).collect(),
        })
    }
}
