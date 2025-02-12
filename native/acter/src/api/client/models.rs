// Model Access

use std::collections::{hash_map::Entry, HashMap};
use std::convert::TryFrom;

use acter_core::{
    models::{ActerModel, AnyActerModel},
    referencing::IndexKey,
};
use matrix_sdk::{Room, RoomState};
use ruma::{OwnedEventId, OwnedRoomId, RoomId};
use tracing::{trace, warn};

use crate::RUNTIME;
use anyhow::{bail, Result};

use super::Client;

impl Client {
    /// Get all the models with their corresponding room if the user has joined those rooms
    pub(crate) async fn model_with_room<T>(&self, model_id: OwnedEventId) -> Result<(T, Room)>
    where
        AnyActerModel: TryInto<T>,
        T: Send + 'static,
    {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let any = me.store().get(&model_id).await?;
                let Some(room) = me.get_room(any.room_id()) else {
                    bail!("Room not found");
                };
                if room.state() != RoomState::Joined {
                    bail!("Not part of the room (anymore)");
                }
                let Ok(model) = any.try_into() else {
                    bail!("Not the right model type");
                };

                Ok((model, room))
            })
            .await?
    }

    /// Get all the models with their corresponding room if the user has joined those rooms
    pub(crate) async fn models_of_list_with_room<T>(
        &self,
        key: IndexKey,
    ) -> Result<impl Iterator<Item = (T, Room)>>
    where
        AnyActerModel: TryInto<T>,
    {
        let me = self.clone();
        self.models_of_list_with_room_under_check(key, move |room_id| {
            let Some(room) = me.get_room(room_id) else {
                bail!("Room not found for model");
            };

            if room.state() != RoomState::Joined {
                bail!("Not part of this room")
            }
            Ok(room)
        })
        .await
    }

    /// Get all the models with their corresponding room if the user has joined those rooms
    pub(crate) async fn models_of_list_with_room_under_check<T, F>(
        &self,
        key: IndexKey,
        check: F,
    ) -> Result<impl Iterator<Item = (T, Room)>>
    where
        AnyActerModel: TryInto<T>,
        F: Fn(&RoomId) -> Result<Room> + Send + 'static,
    {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                Ok(me.store().get_list(&key).await?.filter_map(move |any| {
                    let room = match check(any.room_id()) {
                        Ok(r) => r,
                        Err(e) => {
                            warn!(error = ?e, "Room not found for model");
                            return None;
                        }
                    };
                    let model = match any.try_into() {
                        Err(e) => {
                            warn!(list=?key, "Could not parse model from list to target type");
                            return None;
                        }
                        Ok(m) => m,
                    };
                    Some((model, room.clone()))
                }))
            })
            .await?
    }
}
