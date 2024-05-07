use ruma::OwnedRoomId;
use ruma_events::{room::redaction::OriginalRoomRedactionEvent, UnsignedRoomRedactionEvent};
use scc::hash_map::{Entry, HashMap};
use std::sync::Arc;
use tokio::sync::broadcast::{channel, Receiver, Sender};
use tracing::{error, trace, trace_span, warn};

use crate::{
    models::{ActerModel, AnyActerModel, EventMeta, RedactedActerModel},
    store::Store,
    Error, Result,
};

#[derive(Clone, Debug)]
pub struct Executor {
    store: Store,
    notifiers: Arc<HashMap<String, Sender<()>>>,
}

impl Executor {
    pub async fn new(store: Store) -> Result<Self> {
        Ok(Executor {
            store,
            notifiers: Default::default(),
        })
    }

    pub fn store(&self) -> &Store {
        &self.store
    }

    pub fn subscribe(&self, key: String) -> Receiver<()> {
        match self.notifiers.entry(key) {
            Entry::Occupied(mut o) => {
                let sender = o.get_mut();
                if sender.receiver_count() == 0 {
                    // replace the existing channel to reopen
                    let (sender, receiver) = channel(1);
                    o.insert(sender);
                    receiver
                } else {
                    sender.subscribe()
                }
            }
            Entry::Vacant(v) => {
                let (sender, receiver) = channel(1);
                v.insert_entry(sender);
                receiver
            }
        }
    }

    pub async fn wait_for(&self, key: String) -> Result<AnyActerModel> {
        let mut subscribe = self.subscribe(key.clone());
        let Ok(model) = self.store.get(&key).await else {
            if let Err(e) = subscribe.recv().await {
                error!(key, "Receiving pong failed: {e}");
            }
            return self.store.get(&key).await;
        };

        Ok(model)
    }

    pub fn notify(&self, mut keys: Vec<String>) -> u32 {
        let mut counter = 0u32;
        keys.dedup();
        trace!(?keys, "notify");
        for key in keys {
            let span = trace_span!("Asked to notify", key = key);
            let _enter = span.enter();
            if let Entry::Occupied(o) = self.notifiers.entry(key) {
                let v = o.get();
                if v.receiver_count() == 0 {
                    trace!("No listeners. removing");
                    let _ = o.remove();
                    continue;
                }
                trace!("Broadcasting");
                if let Err(error) = v.send(()) {
                    trace!(?error, "Notifying failed. No receivers. Clearing");
                    // we have overflow activated, this only fails because it has been closed
                    let _ = o.remove();
                } else {
                    counter = counter.checked_add(1).unwrap_or(u32::MAX);
                }
            } else {
                trace!("No one to notify");
            }
        }
        counter
    }

    pub async fn handle(&self, model: AnyActerModel) -> Result<()> {
        let event_id = model.event_id().to_string();
        trace!(?event_id, ?model, "handle");
        match model.execute(&self.store).await {
            Err(error) => {
                error!(?event_id, ?error, "handling failed");
                Err(error)
            }
            Ok(keys) => {
                trace!(?event_id, "handling done");
                self.notify(keys);
                Ok(())
            }
        }
    }

    pub async fn clear_room(&self, room_id: &OwnedRoomId) -> Result<()> {
        let keys = self.store.clear_room(room_id).await?;
        self.notify(keys);
        Ok(())
    }

    pub async fn redact(
        &self,
        model_type: String,
        event_meta: EventMeta,
        reason: UnsignedRoomRedactionEvent,
    ) -> Result<()> {
        trace!(event_id=?event_meta.event_id, ?model_type, "asked to redact");
        match self.store.get(event_meta.event_id.as_str()).await {
            Ok(model) => {
                trace!("previous model found. overwriting");
                let redacted = RedactedActerModel::new(
                    model_type.to_owned(),
                    model.indizes(self.store.user_id()),
                    event_meta,
                    reason.into(),
                );
                self.notify(model.redact(&self.store, redacted).await?);
            }
            Err(Error::ModelNotFound(_)) => {
                trace!("no model found, storing redaction model");
                let redacted = RedactedActerModel::new(
                    model_type.to_owned(),
                    vec![],
                    event_meta,
                    reason.into(),
                );
                self.notify(redacted.execute(&self.store).await?);
            }
            Err(error) => return Err(error),
        }
        Ok(())
    }

    pub async fn live_redact(&self, event: OriginalRoomRedactionEvent) -> Result<()> {
        let Some(meta) = EventMeta::for_redacted_source(&event) else {
            warn!(?event, "Redaction didn't contain any target. skipping.");
            return Ok(());
        };

        match self.store.get(meta.event_id.as_str()).await {
            Ok(model) => {
                trace!("redacting model live");
                let redacted = RedactedActerModel::new(
                    model.model_type().to_owned(),
                    model.indizes(self.store.user_id()),
                    meta,
                    event.into(),
                );
                self.notify(model.redact(&self.store, redacted).await?);
            }
            Err(Error::ModelNotFound(_)) => {
                trace!("no model found");
                self.notify(vec![meta.event_id.to_string()]);
            }
            Err(error) => return Err(error),
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::{
        events::{comments::CommentEventContent, BelongsTo},
        models::{Comment, TestModelBuilder},
    };
    use matrix_sdk::Client;
    use matrix_sdk_base::store::{MemoryStore, StoreConfig};
    use ruma_common::{api::MatrixVersion, event_id, user_id};
    use ruma_events::room::message::TextMessageEventContent;

    async fn fresh_executor() -> Result<Executor> {
        let config = StoreConfig::default().state_store(MemoryStore::new());
        let client = Client::builder()
            .homeserver_url("http://localhost")
            .server_versions([MatrixVersion::V1_5])
            .store_config(config)
            .build()
            .await
            .unwrap();

        let store = Store::new_with_auth(client, user_id!("@test:example.org").to_owned()).await?;
        Executor::new(store).await
    }

    #[tokio::test]
    async fn smoke_test() -> Result<()> {
        let _ = env_logger::try_init();
        let _ = fresh_executor().await?;
        Ok(())
    }

    #[tokio::test]
    async fn subscribe_simle_model() -> Result<()> {
        let _ = env_logger::try_init();
        let executor = fresh_executor().await?;
        let model = TestModelBuilder::default().simple().build().unwrap();
        let model_id = model.event_id();
        let sub = executor.subscribe(model_id.to_string());
        assert!(sub.is_empty(), "Already received an event");

        executor.handle(model.into()).await?;
        assert!(!sub.is_empty(), "No subscription event found");

        Ok(())
    }

    #[tokio::test]
    async fn subscribe_referenced_model() -> Result<()> {
        let _ = env_logger::try_init();
        let executor = fresh_executor().await?;
        let model = TestModelBuilder::default().simple().build().unwrap();
        let model_id = model.event_id().to_owned();
        let mut sub = executor.subscribe(model_id.to_string());
        assert!(sub.is_empty());

        executor.handle(model.into()).await?;
        assert!(sub.recv().await.is_ok()); // we have one
        assert!(sub.is_empty());

        let child = TestModelBuilder::default()
            .simple()
            .belongs_to(vec![model_id.to_string()])
            .event_id(event_id!("$advf93m").to_owned())
            .build()
            .unwrap();

        executor.handle(child.into()).await?;

        assert!(sub.recv().await.is_ok()); // we have one
        assert!(sub.is_empty());
        Ok(())
    }

    #[tokio::test]
    async fn subscribe_models_index() -> Result<()> {
        let _ = env_logger::try_init();
        let executor = fresh_executor().await?;
        let model = TestModelBuilder::default().simple().build().unwrap();
        let parent_id = model.event_id().to_owned();
        let parent_idx = format!("{parent_id}:custom");
        let mut sub = executor.subscribe(parent_idx.clone());
        assert!(sub.is_empty());

        executor.handle(model.into()).await?;
        assert!(sub.is_empty());

        let child = TestModelBuilder::default()
            .simple()
            .belongs_to(vec![parent_id.to_string()])
            .event_id(event_id!("$advf93m").to_owned())
            .indizes(vec![parent_idx.clone()])
            .build()
            .unwrap();

        executor.handle(child.into()).await?;

        assert!(sub.recv().await.is_ok()); // we have one
        assert!(sub.is_empty());
        Ok(())
    }

    #[tokio::test]
    async fn subscribe_models_comments_index() -> Result<()> {
        let _ = env_logger::try_init();
        let executor = fresh_executor().await?;
        let model = TestModelBuilder::default().simple().build().unwrap();
        let parent_id = model.event_id().to_owned();
        let parent_idx = Comment::index_for(&parent_id);
        let mut sub = executor.subscribe(parent_idx.clone());
        assert!(sub.is_empty());

        executor.handle(model.into()).await?;
        assert!(sub.is_empty());

        let comment = Comment {
            inner: CommentEventContent {
                content: TextMessageEventContent::plain("First"),
                on: BelongsTo {
                    event_id: parent_id,
                },
                reply_to: None,
            },
            meta: TestModelBuilder::fake_meta(),
        };

        executor.handle(comment.into()).await?;

        assert!(sub.recv().await.is_ok()); // we have one
        assert!(sub.is_empty());
        Ok(())
    }

    #[tokio::test]
    async fn wait_for_simple_model() -> Result<()> {
        let _ = env_logger::try_init();
        let executor = fresh_executor().await?;
        let model = TestModelBuilder::default().simple().build().unwrap();
        let model_id = model.event_id().to_string();
        // nothing in the store
        assert!(executor.store().get(&model_id).await.is_err());

        let waiter = executor.wait_for(model_id);
        executor.handle(model.clone().into()).await?;

        let new_model = waiter.await?;

        let AnyActerModel::TestModel(inner_model) = new_model else {
            panic!("Not a test model");
        };

        assert_eq!(inner_model, model);
        Ok(())
    }
}
