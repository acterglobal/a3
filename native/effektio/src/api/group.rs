use anyhow::{bail, Result};
use derive_builder::Builder;
use effektio_core::{
    ruma::{
        api::client::room::{
            create_room::v3::{CreationContent, Request as CreateRoomRequest},
            Visibility,
        },
        assign,
        room::RoomType,
        serde::Raw,
        OwnedRoomAliasId, OwnedRoomId, OwnedUserId,
    },
    statics::default_effektio_group_states,
};

use super::{
    client::{divide_rooms_from_common, Client},
    room::Room,
    RUNTIME,
};

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
    name: Option<String>,
    #[builder(default = "Visibility::Private")]
    visibility: Visibility,
    #[builder(default = "Vec::new()")]
    invites: Vec<OwnedUserId>,
    #[builder(setter(strip_option))]
    alias: Option<String>,
}

// impl CreateGroupSettingsBuilder {
//     pub fn add_invite(&mut self, user_id: OwnedUserId) {
//         self.invites.get_or_insert_with(Vec::new).push(user_id);
//     }
// }

impl Client {
    pub async fn create_effektio_group(
        &self,
        settings: CreateGroupSettings,
    ) -> Result<OwnedRoomId> {
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let initial_states = default_effektio_group_states();
                let request = assign!(CreateRoomRequest::new(), {
                    creation_content: Some(Raw::new(&assign!(CreationContent::new(), {
                        room_type: Some(RoomType::Space)
                    }))?),
                    initial_state: &initial_states,
                    is_direct: false,
                    invite: &settings.invites,
                    room_alias_name: settings.alias.as_deref(),
                    name: settings.name.as_ref().map(|x| x.as_ref()),
                    visibility: settings.visibility,
                });
                let response = client.create_room(request).await?;
                Ok(response.room_id)
            })
            .await?
    }

    pub async fn groups(&self) -> Result<Vec<Group>> {
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let (groups, convos) = divide_rooms_from_common(client).await;
                Ok(groups)
            })
            .await?
    }

    pub async fn get_group(&self, alias_or_id: String) -> Result<Group> {
        if let Ok(room_id) = OwnedRoomId::try_from(alias_or_id.clone()) {
            match self.get_room(&room_id) {
                Some(room) => Ok(Group {
                    inner: Room {
                        room,
                        client: self.client.clone(),
                    },
                }),
                None => bail!("Room not found"),
            }
        } else if let Ok(alias_id) = OwnedRoomAliasId::try_from(alias_or_id) {
            for group in self.groups().await?.into_iter() {
                if let Some(group_alias) = group.inner.room.canonical_alias() {
                    if group_alias == alias_id {
                        return Ok(group);
                    }
                }
            }
            bail!("Room with alias not found")
        } else {
            bail!("Neither roomId nor alias provided")
        }
    }
}
