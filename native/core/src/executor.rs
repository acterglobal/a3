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
            tracing::trace!(event_id=?model.event_id(), "saving simple model");
            self.store.save(model).await?;
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
