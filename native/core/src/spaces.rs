use derive_builder::Builder;
use matrix_sdk::{
    room::Room,
    ruma::{events::room::join_rules::JoinRule, Int},
};
use matrix_sdk_base::{
    ruma::{
        api::client::room::{create_room, Visibility},
        assign,
        events::{
            room::{
                avatar::{ImageInfo, InitialRoomAvatarEvent, RoomAvatarEventContent},
                join_rules::{AllowRule, InitialRoomJoinRulesEvent, RoomJoinRulesEventContent},
            },
            space::{child::SpaceChildEventContent, parent::SpaceParentEventContent},
            InitialStateEvent,
        },
        room::RoomType,
        serde::Raw,
        MxcUri, OwnedRoomId, OwnedServerName, OwnedUserId, RoomId, ServerName, UserId,
    },
    RoomState,
};
use serde::Deserialize;
use std::path::PathBuf;
use strum::Display;
use tracing::{error, trace};
mod permissions;
pub use permissions::{new_app_permissions_builder, AppPermissionsBuilder};

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

#[derive(Builder, Default, Clone, Deserialize)]
pub struct CreateSpaceSettings {
    #[builder(setter(strip_option))]
    name: Option<String>,

    #[builder(default = "Visibility::Private")]
    #[serde(default = "space_visibilty_default")]
    visibility: Visibility,

    #[builder(setter(strip_option), default)]
    #[serde(default)]
    join_rule: Option<String>,

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

    #[builder(default)]
    #[serde(default)]
    permissions: AppPermissionsBuilder,
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
    #[allow(clippy::boxed_local)]
    pub fn set_permissions(&mut self, value: Box<AppPermissionsBuilder>) {
        self.permissions(*value);
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
        self.via
            .iter()
            .map(ToString::to_string)
            .collect::<Vec<String>>()
    }
}

#[derive(Clone, Debug)]
pub struct SpaceRelations {
    main_parent: Option<SpaceRelation>,
    other_parents: Vec<SpaceRelation>,
    pub children: Vec<SpaceRelation>,
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
            permissions: permissions_builder,
            join_rule,
        } = settings;
        let mut initial_states = default_acter_space_states();
        // the space app settings as configured
        let (settings, mut permissions) = permissions_builder.unpack();
        initial_states.push(InitialStateEvent::new(settings).to_raw_any());
        // ensure that as the creator we are having the max power level
        permissions.users.insert(
            client
                .user_id()
                .expect("The client must be logged in")
                .to_owned(),
            Int::from(100),
        );

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
                let content_type = guess.first().expect("don't know mime type");
                let buf = std::fs::read(path)?;
                let response = client.media().upload(&content_type, buf, None).await?;

                let info = assign!(ImageInfo::new(), {
                    blurhash: response.blurhash,
                    mimetype: Some(content_type.to_string()),
                });
                assign!(RoomAvatarEventContent::new(), {
                    url: Some(response.content_uri),
                    info: Some(Box::new(info)),
                })
            };
            initial_states.push(InitialRoomAvatarEvent::new(avatar_content).to_raw_any());
        };
        let join_rule_lowered = join_rule.as_ref().map(|x| x.to_lowercase());

        let join_rule_ev = InitialRoomJoinRulesEvent::new(match join_rule_lowered.as_deref() {
            // if we have a parent, by default we allow access to the subspace.
            None | Some("restricted") => {
                if let Some(ref parent) = parent {
                    RoomJoinRulesEventContent::restricted(vec![AllowRule::room_membership(
                        parent.clone(),
                    )])
                } else {
                    RoomJoinRulesEventContent::new(JoinRule::Invite)
                }
            }
            Some("knockrestricted") => {
                if let Some(ref parent) = parent {
                    RoomJoinRulesEventContent::knock_restricted(vec![AllowRule::room_membership(
                        parent.clone(),
                    )])
                } else {
                    RoomJoinRulesEventContent::new(JoinRule::Knock)
                }
            }
            Some("knock") => RoomJoinRulesEventContent::new(JoinRule::Knock),
            Some("public") => RoomJoinRulesEventContent::new(JoinRule::Public),
            _ => RoomJoinRulesEventContent::new(JoinRule::Invite),
        });

        trace!(
            ?join_rule_ev,
            ?join_rule_lowered,
            "creating space with join rule"
        );

        initial_states.push(join_rule_ev.to_raw_any());

        if let Some(parent) = parent {
            let Some(Ok(homeserver)) = client.homeserver().host_str().map(ServerName::parse) else {
                return Err(Error::HomeserverMissesHostname);
            };
            let parent_event = InitialStateEvent::<SpaceParentEventContent> {
                content: assign!(SpaceParentEventContent::new(vec![homeserver]), {
                    canonical: true,
                }),
                state_key: parent.clone(),
            };
            initial_states.push(parent_event.to_raw_any());
        }

        let request = assign!(create_room::v3::Request::new(), {
            creation_content: Some(Raw::new(&content)?),
            power_level_content_override: Some(Raw::new(&permissions)?),
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
                continue;
            };

            let target = ev.state_key();
            let target_type = match self.client().get_room(target) {
                Some(parent) => {
                    if !parent.is_space() {
                        RelationTargetType::ChatRoom
                    } else if is_acter_space(&parent).await {
                        RelationTargetType::ActerSpace
                    } else {
                        RelationTargetType::Space
                    }
                }
                None => RelationTargetType::Unknown,
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
                continue;
            };

            let target = ev.state_key();
            let target_type = match self.client().get_room(target) {
                Some(child) => {
                    if !matches!(child.state(), RoomState::Joined) {
                        // we count rooms we are not currently in as unknown
                        RelationTargetType::Unknown
                    } else if !child.is_space() {
                        RelationTargetType::ChatRoom
                    } else if is_acter_space(&child).await {
                        RelationTargetType::ActerSpace
                    } else {
                        RelationTargetType::Space
                    }
                }
                None => RelationTargetType::Unknown,
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
