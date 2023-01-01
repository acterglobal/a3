use crate::{
    models::{AnyEffektioModel, EffektioModel},
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
            Entry::Occupied(o) => o.get().new_receiver(),
            Entry::Vacant(v) => {
                let (mut sender, receiver) = broadcast(1);
                sender.set_overflow(true);
                v.insert(sender);
                receiver
            }
        }
    }

    pub fn notifv(&self, keys: Vec<String>) {
        for key in keys {
            if let Entry::Occupied(o) = self.notifiers.entry(key) {
                let v = o.get();
                if v.is_closed() || v.receiver_count() == 0 {
                    o.remove();
                    continue;
                }
                if v.try_broadcast(()).is_err() {
                    // we have overflow activated, this only fails because it has been closed
                    o.remove();
                }
            }
        }
    }

    pub async fn handle(&self, model: AnyEffektioModel) -> Result<()> {
        tracing::trace!(?model, "handling");
        let Some(belongs_to) = model.belongs_to() else {
            self.store.save(model).await?;
            return Ok(())
        };

        let mut models = self.transition_tree(belongs_to, &model).await?;
        models.push(model);
        // models.dedup();
        let keys = models.iter().map(|m| m.key()).collect();
        self.store.save_many(models).await?;
        self.notifv(keys);

        Ok(())
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
