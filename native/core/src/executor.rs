use matrix_sdk_base::{deserialized_responses::SyncRoomEvent, store::StateStore};
use ruma::{OwnedEventId, OwnedRoomId};

#[derive(Clone, Debug)]
#[allow(dead_code)]
pub struct Executor<'a> {
    store: &'a dyn StateStore,
    room_id: OwnedRoomId,
}

impl<'a> Executor<'a> {
    pub fn new(store: &'a dyn StateStore, room_id: OwnedRoomId) -> Self {
        Executor { store, room_id }
    }

    pub async fn apply(&self, _event: &SyncRoomEvent) -> anyhow::Result<Option<OwnedEventId>> {
        Ok(None)
    }
}
