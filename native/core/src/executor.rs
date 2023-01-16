use crate::{
    models::{AnyEffektioModel, EffektioModel},
    store::Store,
    Result,
};
use async_broadcast::{broadcast, Receiver, Sender};
use dashmap::{mapref::entry::Entry, DashMap};
use std::sync::Arc;

#[derive(Clone, Debug)]
pub struct Executor {
    store: Store,
    notifiers: Arc<DashMap<String, Sender<()>>>,
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
            Entry::Occupied(o) => {
                let sender = o.get();
                if sender.is_closed() {
                    // replace the existing channel to reopen
                    let (sender, recv) = broadcast(1);
                    o.replace_entry(sender);
                    recv
                } else {
                    sender.new_receiver()
                }
            }
            Entry::Vacant(v) => {
                let (mut sender, receiver) = broadcast(1);
                sender.set_overflow(true);
                v.insert(sender);
                receiver
            }
        }
    }

    pub async fn wait_for(&self, key: String) -> crate::Result<AnyEffektioModel> {
        let mut subscribe = self.subscribe(key.clone());
        let Ok(model) = self.store.get(&key).await else {
            if let Err(e) = subscribe.recv().await {
                tracing::error!(key, "Receiving pong faild: {e}");
            }
            return self.store.get(&key).await
        };

        Ok(model)
    }

    pub fn notify(&self, mut keys: Vec<String>) -> u32 {
        let mut counter = 0u32;
        keys.dedup();
        tracing::trace!(?keys, "notify");
        for key in keys {
            let span = tracing::trace_span!("Asked to notify", key = key);
            let _enter = span.enter();
            if let Entry::Occupied(o) = self.notifiers.entry(key) {
                let v = o.get();
                if v.is_closed() {
                    tracing::trace!("No listeners. removing");
                    o.remove();
                    continue;
                }
                tracing::trace!("Broadcasting");
                if let Err(error) = v.try_broadcast(()) {
                    tracing::trace!(?error, "Notifying failed");
                    // we have overflow activated, this only fails because it has been closed
                    o.remove();
                } else {
                    counter = counter.checked_add(1).unwrap_or(u32::MAX);
                }
            } else {
                tracing::trace!("No one to notify");
            }
        }
        counter
    }

    pub async fn handle(&self, model: AnyEffektioModel) -> Result<()> {
        self.notify(model.execute(&self.store).await?);
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::models::TestModelBuilder;
    use crate::ruma::{api::MatrixVersion, event_id};
    use env_logger;
    use matrix_sdk::Client;

    async fn fresh_executor() -> crate::Result<Executor> {
        let client = Client::builder()
            .homeserver_url("http://localhost")
            .server_versions([MatrixVersion::V1_5])
            .store_config(
                matrix_sdk_base::store::StoreConfig::default()
                    .state_store(matrix_sdk_base::store::MemoryStore::new()),
            )
            .build()
            .await
            .unwrap();

        let store = Store::new(client).await?;
        Executor::new(store).await
    }

    #[tokio::test]
    async fn smoke_test() -> crate::Result<()> {
        let _ = env_logger::try_init();
        let _ = fresh_executor().await?;
        Ok(())
    }

    #[tokio::test]
    async fn subscribe_simle_model() -> crate::Result<()> {
        let _ = env_logger::try_init();
        let executor = fresh_executor().await?;
        let model = TestModelBuilder::default().simple().build().unwrap();
        let model_id = model.event_id();
        let sub = executor.subscribe(model_id.to_string());
        assert!(sub.is_empty());

        executor.handle(model.into()).await?;
        assert!(!sub.is_empty());

        Ok(())
    }

    #[tokio::test]
    async fn subscribe_referenced_model() -> crate::Result<()> {
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
    async fn subscribe_models_index() -> crate::Result<()> {
        let _ = env_logger::try_init();
        let executor = fresh_executor().await?;
        let model = TestModelBuilder::default().simple().build().unwrap();
        let parent_id = model.event_id().to_owned();
        let parent_idx = format!("{parent_id}:comments");
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
    async fn wait_for_simple_model() -> crate::Result<()> {
        let _ = env_logger::try_init();
        let executor = fresh_executor().await?;
        let model = TestModelBuilder::default().simple().build().unwrap();
        let model_id = model.event_id().to_string();
        // nothing in the store
        assert!(executor.store().get(&model_id).await.is_err());

        let waiter = executor.wait_for(model_id);
        executor.handle(model.clone().into()).await?;

        let new_model = waiter.await?;

        let AnyEffektioModel::TestModel(inner_model) = new_model else {
            panic!("Not a test model")
        };

        assert_eq!(inner_model, model);
        Ok(())
    }
}
