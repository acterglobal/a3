use super::room::Room;
use super::client::Client;
use crate::api::RUNTIME;
use effektio_core::{
    statics::default_effektio_group_states,
    ruma::{
        api::client::{
            account::register::v3::Request as RegistrationRequest,
            room::{
                create_room::v3::CreationContent, create_room::v3::Request as CreateRoomRequest,
                Visibility,
            },
            uiaa,
        },
        assign,
        room::RoomType,
        serde::Raw,
        OwnedRoomName, OwnedUserId, OwnedRoomId,
    }
};
use derive_builder::Builder;
use anyhow::Result;

pub struct Group {
    pub(crate) inner: Room,
}

impl std::ops::Deref for Group {
    type Target = Room;
    fn deref(&self) -> &Room {
        &self.inner
    }
}

#[derive(Builder, Default, Clone)]
pub struct CreateGroupSettings {
    #[builder(setter(strip_option))]
    name: Option<OwnedRoomName>,
    #[builder(default="Visibility::Private")]
    visibility: Visibility,
    #[builder(default="Vec::new()")]
    invites: Vec<OwnedUserId>,
}

// impl CreateGroupSettingsBuilder {
//     pub fn add_invite(&mut self, user_id: OwnedUserId) {
//         self.invites.get_or_insert_with(Vec::new).push(user_id);
//     }
// }

impl Client {
    pub async fn create_effektio_group(&self, settings: CreateGroupSettings) -> Result<OwnedRoomId> {
        let c = self.client.clone();
        RUNTIME
            .spawn(async move {
                let default_initial_states = default_effektio_group_states();

                Ok(c.create_room(assign!(CreateRoomRequest::new(), {
                    creation_content: Some(Raw::new(&assign!(CreationContent::new(), {
                        room_type: Some(RoomType::Space)
                    }))?),
                    initial_state: &default_initial_states,
                    is_direct: false,
                    invite: &settings.invites,
                    name: settings.name.as_ref().map(|x| x.as_ref()),
                    visibility: settings.visibility,
                }))
                .await?
                .room_id)
            }).await?
    }

}