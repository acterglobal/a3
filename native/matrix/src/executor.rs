use matrix_sdk::ruma::OwnedEventId;
use matrix_sdk_base::ruma::{
    events::{room::redaction::OriginalRoomRedactionEvent, UnsignedRoomRedactionEvent},
    OwnedRoomId,
};
use scc::hash_map::{Entry, HashMap};
use std::sync::Arc;
use tokio::sync::broadcast::{channel, Receiver, Sender};
use tracing::{error, info, trace, trace_span, warn};

use crate::{
    models::{
        event_meta_for_redacted_source, ActerModel, AnyActerModel, EventMeta, RedactedActerModel,
    },
    referencing::ExecuteReference,
    store::Store,
    Error, Result,
};

#[derive(Clone, Debug)]
pub struct Executor {
    store: Store,
    notifiers: Arc<HashMap<ExecuteReference, Sender<()>>>,
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

    pub fn subscribe<K: Into<ExecuteReference>>(&self, key: K) -> Receiver<()> {
        match self.notifiers.entry(key.into()) {
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

    pub async fn wait_for(&self, key: OwnedEventId) -> Result<AnyActerModel> {
        let mut subscribe = self.subscribe(ExecuteReference::Model(key.clone()));
        let Ok(model) = self.store.get(&key).await else {
            if let Err(e) = subscribe.recv().await {
                error!(event_id=?key, "Receiving pong failed: {e}");
            }
            return self.store.get(&key).await;
        };

        Ok(model)
    }

    pub fn notify(&self, mut keys: Vec<ExecuteReference>) -> u32 {
        let mut counter = 0u32;
        keys.dedup();
        trace!(?keys, "notify");
        for key in keys {
            let span = trace_span!("Asked to notify", key = ?key);
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
                info!("******************** executor handled: {:?}", &keys);
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
        let event_id = event_meta.event_id.clone();
        trace!(event_id=?event_id, ?model_type, "asked to redact");

        match self.store.get(&event_id).await {
            Ok(AnyActerModel::RedactedActerModel(_)) => {
                info!(?event_id, "live redacted: Already redacted");
            }
            Ok(model) => {
                trace!("previous model found. overwriting");
                let redacted = RedactedActerModel::new(model_type, event_meta, reason.into());
                let keys = model.redact(&self.store, redacted).await?;
                info!("******************** found model redacted: {:?}", &keys);
                self.notify(keys);
            }
            Err(Error::ModelNotFound(_)) => {
                trace!("no model found, storing redaction model");
                let redacted = RedactedActerModel::new(model_type, event_meta, reason.into());
                let keys = redacted.execute(&self.store).await?;
                info!("******************** not found redacted: {:?}", &keys);
                self.notify(keys);
            }
            Err(error) => return Err(error),
        }
        Ok(())
    }

    pub async fn live_redact(&self, event: OriginalRoomRedactionEvent) -> Result<()> {
        let Some(meta) = event_meta_for_redacted_source(&event) else {
            warn!(?event, "Redaction didn’t contain any target. skipping.");
            return Ok(());
        };

        let event_id = meta.event_id.clone();

        match self.store.get(&event_id).await {
            Ok(AnyActerModel::RedactedActerModel(_)) => {
                info!(?event_id, "live redacted: Already redacted");
            }
            Ok(model) => {
                trace!("live redacted: model found");
                let redacted =
                    RedactedActerModel::new(model.model_type().to_owned(), meta, event.into());
                let keys = model.redact(&self.store, redacted).await?;
                info!(?event_id, "live redacted: {:?}", &keys);
                self.notify(keys);
            }
            Err(Error::ModelNotFound(_)) => {
                info!(?event_id, "live redaction: not found");
                self.notify(vec![ExecuteReference::Model(event_id)]);
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
        referencing::{IndexKey, IntoExecuteReference, ObjectListIndex},
    };
    use matrix_sdk::Client;
    use matrix_sdk_base::{
        ruma::{
            api::MatrixVersion, event_id, events::room::message::TextMessageEventContent, user_id,
        },
        store::{MemoryStore, StoreConfig},
    };
    use serde_json::{from_value, json};

    async fn fresh_executor() -> Result<Executor> {
        let config = StoreConfig::new("tests".to_owned()).state_store(MemoryStore::new());
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
    async fn subscribe_simple_model() -> Result<()> {
        let _ = env_logger::try_init();
        let executor = fresh_executor().await?;
        let model = TestModelBuilder::default().simple().build().unwrap();
        let model_id = model.event_id();
        let sub = executor.subscribe(IntoExecuteReference::into(model_id));
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
        let mut sub = executor.subscribe(IntoExecuteReference::into(model_id.clone()));
        assert!(sub.is_empty());

        executor.handle(model.into()).await?;
        assert!(sub.recv().await.is_ok()); // we have one
        assert!(sub.is_empty());

        let child = TestModelBuilder::default()
            .simple()
            .belongs_to(vec![model_id.clone()])
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
        let parent_idx = IndexKey::ObjectList(parent_id.clone(), ObjectListIndex::Attachments);
        let mut sub = executor.subscribe(IntoExecuteReference::into(parent_idx.clone()));
        assert!(sub.is_empty());

        executor.handle(model.into()).await?;
        assert!(sub.is_empty());

        let child = TestModelBuilder::default()
            .simple()
            .belongs_to(vec![parent_id.clone()])
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
        let parent_idx = Comment::index_for(parent_id.clone());
        let mut sub = executor.subscribe(IntoExecuteReference::into(parent_idx.clone()));
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
        let model_id = model.event_id().to_owned();
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

    #[tokio::test]
    async fn double_redact_model() -> Result<()> {
        let _ = env_logger::try_init();
        let executor = fresh_executor().await?;
        let model = TestModelBuilder::default().simple().build().unwrap();
        let model_id = model.event_id().to_owned();
        // nothing in the store
        assert!(executor.store().get(&model_id).await.is_err());

        let waiter = executor.wait_for(model_id.clone());
        executor.handle(model.clone().into()).await?;

        let new_model = waiter.await?;

        let AnyActerModel::TestModel(inner_model) = new_model else {
            panic!("Not a test model");
        };

        assert_eq!(inner_model, model);

        // now let’s redact this model;

        let redaction: UnsignedRoomRedactionEvent = from_value(json!({
            "event_id" : format!("{model_id}:redacted"),
            "sender": "@someone:example.org",
            "origin_server_ts": 123456,
            "content": { "redacts" : model_id, },
        }))?;

        executor
            .redact(
                "test_model".to_owned(),
                model.event_meta().clone(),
                redaction,
            )
            .await?;

        let AnyActerModel::RedactedActerModel(redaction) = executor.store().get(&model_id).await?
        else {
            panic!("Model was not redacten :(");
        };
        assert_eq!(redaction.origin_type(), "test_model");

        // redacting again

        let redaction: UnsignedRoomRedactionEvent = from_value(json!({
            "event_id" : format!("{model_id}:redacted2"),
            "sender": "@someone:example.org",
            "origin_server_ts": 123456,
            "content": { "redacts" : model_id, },
        }))?;

        executor
            .redact(
                "test_model".to_owned(),
                model.event_meta().clone(),
                redaction,
            )
            .await?;

        let AnyActerModel::RedactedActerModel(redaction) = executor.store().get(&model_id).await?
        else {
            panic!("Model was not redacted :(");
        };
        assert_eq!(redaction.origin_type(), "test_model"); // we stay with the existing redaction

        Ok(())
    }
}
