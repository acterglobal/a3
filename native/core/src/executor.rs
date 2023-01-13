use crate::{
    models::{AnyEffektioModel, Comment, CommentsManager, EffektioModel},
    store::Store,
    Result,
};
use async_broadcast::{broadcast, Receiver, Sender};
use async_recursion::async_recursion;
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

    pub fn notify(&self, keys: Vec<String>) {
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
                }
            } else {
                tracing::trace!("No one to notify");
            }
        }
    }

    pub async fn handle(&self, model: AnyEffektioModel) -> Result<()> {
        tracing::trace!(event_id=?model.event_id(), ?model, "handling");
        let Some(belongs_to) = model.belongs_to() else {
            let event_id = model.event_id().to_string();
            tracing::trace!(?event_id, "saving simple model");
            self.store.save(model).await?;
            self.notify(vec![event_id]);
            return Ok(())
        };

        if model.is_comment() {
            tracing::trace!(event_id=?model.event_id(), ?belongs_to, "applying comment");
            let AnyEffektioModel::Comment(ref comment) = model else {
                unreachable!("match just checked before");
            };
            let managers = self.apply_comment(comment, belongs_to).await?;
            self.store.save(model).await?;
            let mut updates = vec![];
            for manager in managers {
                updates.push(manager.save().await?);
            }
            self.notify(updates);
            return Ok(());
        }

        tracing::trace!(event_id=?model.event_id(), ?belongs_to, "transitioning tree");
        let mut models = self.transition_tree(belongs_to, &model).await?;
        models.push(model);
        // models.dedup();
        let keys = models.iter().map(|m| m.event_id().to_string()).collect();
        self.store.save_many(models).await?;
        self.notify(keys);

        Ok(())
    }

    async fn apply_comment(
        &self,
        comment: &Comment,
        belongs_to: Vec<String>,
    ) -> Result<Vec<CommentsManager>> {
        let mut updates = vec![];
        for p in belongs_to {
            let parent = self.store.get(&p).await?;
            if !parent.supports_comments() {
                tracing::error!(?parent, ?comment, "doesn't support comments. can't apply");
                return Ok(vec![]);
            }

            // FIXME: what if we have this twice in the same loop?
            let mut manager =
                CommentsManager::from_store_and_event_id(&self.store, parent.event_id()).await;
            if manager.add_comment(comment).await? {
                updates.push(manager);
            }
        }
        Ok(updates)
    }

    #[async_recursion]
    async fn transition_tree(
        &self,
        parents: Vec<String>,
        model: &AnyEffektioModel,
    ) -> Result<Vec<AnyEffektioModel>> {
        let mut models = vec![];
        for p in parents {
            let mut parent = self.store.get(&p).await?;
            if parent.transition(model)? {
                if let Some(grandparents) = parent.belongs_to() {
                    let mut parent_models = self.transition_tree(grandparents, &parent).await?;
                    if !parent_models.is_empty() {
                        models.append(&mut parent_models);
                    }
                }
                models.push(parent);
            }
        }
        Ok(models)
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
