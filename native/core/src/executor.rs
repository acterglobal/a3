use matrix_sdk_base::{deserialized_responses::SyncRoomEvent, store::StateStore};
use crate::events::AnyEffektioMessageLikeEvent;
use ruma::{OwnedEventId, OwnedRoomId};

#[derive(Clone, Debug)]
#[allow(dead_code)]
pub struct Executor<'a> {
    store: &'a dyn StateStore,
}

impl<'a> Executor<'a> {
    pub fn new(store: &'a dyn StateStore) -> Self {
        Executor { store }
    }

    pub async fn apply(&self, event: &SyncRoomEvent) -> anyhow::Result<Option<OwnedEventId>> {
        let effektio_event: AnyEffektioMessageLikeEvent = event.try_into()?;

        match effektio_event {
            AnyEffektioMessageLikeEvent::Dev(n) => {
                
            }
        }

        Ok(None)
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use super::super::events::{NewsEvent, NewsEventDevContent};
    use ruma::{room_id, event_id};
    use matrix_sdk_base::store::MemoryStore;

    fn new_executor<'a>(store: &'a MemoryStore) -> Executor<'a> {
        Executor::new(store)
    }

    #[tokio::test]
    async fn smoke_test() {
        let store = MemoryStore::default();
        let exec = new_executor(&store);
    }


    #[tokio::test]
    async fn news_event() {
        let store = MemoryStore::default();
        let exec = new_executor(&store);
        let json = serde_json::json!({
            "event": {
                "content": {
                    "contents": [ {
                        "type": "text",
                        "body": "This is an important news"
                    }],
                },
                "room_id": "!whatev:example.org",
                "event_id": "$12345-asdf",
                "origin_server_ts": 1u64,
                "sender": "@someone:example.org",
                "type": "org.effektio.news.dev",
                "unsigned": {
                    "age": 85u64
                }
            }
        });

        let sync_room = serde_json::from_value::<SyncRoomEvent>(json).unwrap();
        assert_eq!(exec.apply(&sync_room).await.unwrap().unwrap(),
            event_id!("$12345-asdf").to_owned())

    }
}