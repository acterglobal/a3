use derive_builder::Builder;
use matrix_sdk::{
    room::Room,
    ruma::{
        api::client::room::{
            create_room::v3::{CreationContent, Request as CreateRoomRequest},
            Visibility,
        },
        assign,
        events::macros::EventContent,
        room::RoomType,
        serde::Raw,
        OwnedRoomId, OwnedUserId, UserId,
    },
};
use serde::{Deserialize, Serialize};
use strum::Display;
use tracing::error;

use crate::{
    client::CoreClient,
    error::Result,
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
}

impl CreateSpaceSettings {
    pub fn visibility(&mut self, value: String) {
        match value.as_str() {
            "Public" => {
                self.visibility = Visibility::Public;
            }
            "Private" => {
                self.visibility = Visibility::Private;
            }
            _ => {}
        }
    }

    pub fn add_invitee(&mut self, value: String) {
        if let Ok(user_id) = UserId::parse(value) {
            self.invites.push(user_id);
        }
    }

    pub fn alias(&mut self, value: String) {
        self.alias = Some(value);
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
    via: Vec<String>,
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
        self.via.clone()
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

#[derive(Clone, Debug, Deserialize, Serialize, EventContent)]
#[ruma_event(type = "m.space.child", kind = State, state_key_type = OwnedRoomId)]
struct SpaceChildStateEventContent {
    #[serde(default)]
    suggested: bool,

    #[serde(default, skip_serializing_if = "Option::is_none")]
    order: Option<String>,

    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    via: Vec<String>,
}

#[derive(Clone, Debug, Deserialize, Serialize, EventContent)]
#[ruma_event(type = "m.space.parent", kind = State, state_key_type = OwnedRoomId)]
struct SpaceParentStateEventContent {
    #[serde(default)]
    canonical: bool,

    #[serde(default, skip_serializing_if = "Vec::is_empty")]
    via: Vec<String>,
}

impl CoreClient {
    pub async fn create_acter_space(&self, settings: CreateSpaceSettings) -> Result<OwnedRoomId> {
        let content = &assign!(CreationContent::new(), {
            room_type: Some(RoomType::Space),
        });
        let initial_states = default_acter_space_states();
        let room_id = self
            .client()
            .create_room(assign!(CreateRoomRequest::new(), {
                creation_content: Some(Raw::new(content)?),
                initial_state: initial_states,
                is_direct: false,
                invite: settings.invites,
                room_alias_name: settings.alias,
                name: settings.name,
                visibility: settings.visibility,
            }))
            .await?
            .room_id()
            .to_owned();
        Ok(room_id)
    }

    // calculate the space relationships in accordance with:
    // https://spec.matrix.org/v1.6/client-server-api/#mspacechild-relationship
    pub async fn space_relations(&self, room: &Room) -> Result<SpaceRelations> {
        let mut main_parent: Option<SpaceRelation> = None;
        let mut parents = Vec::new();
        let mut children = Vec::new();

        let parents_events: Vec<Raw<SyncSpaceParentStateEvent>> =
            room.get_state_events_static().await?;

        let children_events: Vec<Raw<SyncSpaceChildStateEvent>> =
            room.get_state_events_static().await?;

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

            let Some(original) = ev.as_original() else {
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

            let Some(original) = ev.as_original() else {
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
