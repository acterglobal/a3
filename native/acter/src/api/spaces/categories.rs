use acter_core::events::CategoriesStateEventContent;
use anyhow::{bail, Result};
use matrix_sdk_base::{deserialized_responses::RawSyncOrStrippedState, ruma::events::EventContent};
use tracing::warn;

use crate::{Categories, CategoriesBuilder, RUNTIME};

use super::Space;

impl Space {
    pub async fn categories(&self, cat_type: String) -> Result<Categories> {
        if !self.inner.is_joined() {
            bail!("Unable to read categories of a space you didn’t join");
        }
        let room = self.inner.room.clone();
        RUNTIME
            .spawn(async move {
                let inner = if let Some(RawSyncOrStrippedState::Sync(raw_state)) = room
                    .get_state_event_static_for_key::<CategoriesStateEventContent, _>(&cat_type)
                    .await?
                {
                    match raw_state
                        .get_field::<CategoriesStateEventContent>("content") {
                            Ok(u) => u,
                            Err(error) => {
                                warn!(room_id=?room.room_id(), ?raw_state, ?error, "Failed to deserialize categories.");
                                None
                            }
                        }
                } else {
                    None
                };
                Ok(Categories::new(inner))
            })
            .await?
    }
    pub async fn set_categories(
        &self,
        cat_type: String,
        builder: Box<CategoriesBuilder>,
    ) -> Result<bool> {
        let state_event = (*builder).build();
        if !self.inner.is_joined() {
            bail!("Unable to read categories of a space you didn’t join");
        }
        let room = self.inner.room.clone();
        let user_id = self.client.user_id()?;
        RUNTIME
            .spawn(async move {
                if (!room
                    .can_user_send_state(&user_id, state_event.event_type())
                    .await?)
                {
                    return Ok(false);
                }
                room.send_state_event_for_key(&cat_type, state_event)
                    .await?;
                Ok(true)
            })
            .await?
    }
}
