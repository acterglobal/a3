use super::Space;
use crate::{Categories, CategoriesBuilder, RUNTIME};
use acter_core::events::{CategoriesStateEvent, CategoriesStateEventContent};
use anyhow::{bail, Result};
use matrix_sdk::deserialized_responses::SyncOrStrippedState;
use ruma_events::EventContent;

impl Space {
    pub async fn categories(&self, cat_type: String) -> Result<Categories> {
        if !self.inner.is_joined() {
            bail!("Unable to read categories of a space you didn't join");
        }
        let room = self.inner.room.clone();
        RUNTIME
            .spawn(async move {
                let inner = if let Some(raw_state) = room
                    .get_state_event_static_for_key::<CategoriesStateEventContent, _>(&cat_type)
                    .await?
                {
                    if let SyncOrStrippedState::Sync(ev) = raw_state.deserialize()? {
                        ev.as_original().map(|o| o.content.clone())
                    } else {
                        None
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
            bail!("Unable to read categories of a space you didn't join");
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
