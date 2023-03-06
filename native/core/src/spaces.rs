use derive_builder::Builder;
use matrix_sdk::ruma::{
    api::client::room::{
        create_room::v3::{CreationContent, Request as CreateRoomRequest},
        Visibility,
    },
    assign,
    room::RoomType,
    serde::Raw,
    OwnedRoomId, OwnedUserId, UserId,
};
use serde::{Deserialize, Serialize};

use crate::{client::CoreClient, error::Result, statics::default_acter_space_states};

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

impl CoreClient {
    pub async fn create_acter_space(&self, settings: CreateSpaceSettings) -> Result<OwnedRoomId> {
        let initial_states = default_acter_space_states();

        Ok(self
            .client()
            .create_room(assign!(CreateRoomRequest::new(), {
                creation_content: Some(Raw::new(&assign!(CreationContent::new(), {
                    room_type: Some(RoomType::Space)
                }))?),
                initial_state: initial_states,
                is_direct: false,
                invite: settings.invites,
                room_alias_name: settings.alias,
                name: settings.name,
                visibility: settings.visibility,
            }))
            .await?
            .room_id()
            .to_owned())
    }
}
