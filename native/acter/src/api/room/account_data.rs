use crate::RUNTIME;

use super::Room;
use acter_core::events::room::UserSettingsEventContent;
use anyhow::Result;
use tracing::error;
impl Room {
    pub(crate) async fn user_settings(&self) -> Result<UserSettingsEventContent> {
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                Ok(
                    match room
                        .account_data_static::<UserSettingsEventContent>()
                        .await?
                        .map(|r| r.deserialize())
                    {
                        Some(Ok(e)) => e.content,
                        Some(Err(error)) => {
                            error!(
                                ?error,
                                room_id = ?room.room_id(),
                                "Deserializing user settings failed"
                            );
                            Default::default()
                        }
                        _ => Default::default(),
                    },
                )
            })
            .await?
    }
    pub async fn user_has_seen_suggested(&self) -> Result<bool> {
        let user_settings = self.user_settings().await?;
        Ok(user_settings.has_seen_suggested)
    }

    pub async fn set_user_has_seen_suggested(&self, new_value: bool) -> Result<bool> {
        let mut user_settings = self.user_settings().await?;
        user_settings.has_seen_suggested = new_value;
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                room.set_account_data(user_settings).await?;
                Ok(true)
            })
            .await?
    }
}
