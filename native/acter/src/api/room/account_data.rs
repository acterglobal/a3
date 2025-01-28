use acter_core::{events::room::UserSettingsEventContent, referencing::ExecuteReference};
use anyhow::Result;
use futures::{Stream, StreamExt};
use ruma::events::StaticEventContent;
use tokio::sync::broadcast::Receiver;
use tokio_stream::wrappers::BroadcastStream;
use tracing::error;

use crate::RUNTIME;

use super::Room;

pub struct UserRoomSettings {
    inner: UserSettingsEventContent,
    room: Room,
}

impl UserRoomSettings {
    fn new(room: Room, inner: UserSettingsEventContent) -> Self {
        Self { room, inner }
    }

    pub fn has_seen_suggested(&self) -> bool {
        self.inner.has_seen_suggested
    }

    pub async fn set_has_seen_suggested(&self, new_value: bool) -> Result<bool> {
        let mut user_settings = self.inner.clone();
        user_settings.has_seen_suggested = new_value;
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                room.set_account_data(user_settings).await?;
                Ok(true)
            })
            .await?
    }

    pub fn subscribe_stream(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.subscribe()).map(|f| true)
    }

    pub fn subscribe(&self) -> Receiver<()> {
        self.room.subscribe(ExecuteReference::RoomAccountData(
            self.room.room_id().to_owned(),
            UserSettingsEventContent::TYPE.into(),
        ))
    }
}

impl Room {
    pub async fn user_settings(&self) -> Result<UserRoomSettings> {
        let room = self.clone();
        RUNTIME
            .spawn(async move {
                Ok(UserRoomSettings::new(
                    room.clone(),
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
                ))
            })
            .await?
    }
}
