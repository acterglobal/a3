use scc::hash_map::{Entry, HashMap};
use std::sync::Arc;
use tokio::sync::broadcast::{Receiver, Sender, channel};
use tracing::{error, info, trace, trace_span};

use crate::{
    meta::EventMeta,
    referencing::ExecuteReference,
    traits::{ModelT, StoreError, StoreT, TypeConfig},
};

#[derive(Clone, Debug)]
pub struct Executor<C: TypeConfig, S: StoreT<C>> {
    store: S,
    notifiers: Arc<HashMap<ExecuteReference<C>, Sender<()>>>,
}

impl<C: TypeConfig, S: StoreT<C> + 'static> Executor<C, S> {
    pub fn new(store: S) -> Self {
        Executor {
            store,
            notifiers: Default::default(),
        }
    }

    pub fn store(&self) -> &S {
        &self.store
    }

    pub fn subscribe<K: Into<ExecuteReference<C>>>(&self, key: K) -> Receiver<()> {
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

    pub async fn wait_for(&self, key: C::ObjectId) -> Result<S::Model, C::Error> {
        let mut subscribe = self.subscribe(ExecuteReference::Model(key.clone()));
        let Ok(model) = self.store.get(&key).await else {
            if let Err(e) = subscribe.recv().await {
                error!(event_id=?key, "Receiving pong failed: {e}");
            }
            return self.store.get(&key).await;
        };

        Ok(model)
    }

    pub fn notify(&self, mut keys: Vec<ExecuteReference<C>>) -> u32 {
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
                    counter = counter.saturating_add(1);
                }
            } else {
                trace!("No one to notify");
            }
        }
        counter
    }

    pub async fn handle(&self, model: S::Model) -> Result<(), C::Error> {
        let object_id = model.object_id();
        trace!(?object_id, ?model, "handle");
        match model.execute(&self.store).await {
            Err(error) => {
                error!(?object_id, ?error, "handling failed");
                Err(error)
            }
            Ok(keys) => {
                trace!(?object_id, "handling done");
                self.notify(keys);
                Ok(())
            }
        }
    }

    pub async fn clear_room(&self, room_id: &C::RoomId) -> Result<(), C::Error> {
        let keys = self.store.clear_room(room_id).await?;
        self.notify(keys);
        Ok(())
    }

    pub async fn redact(
        &self,
        model_type: C::ModelType,
        event_meta: EventMeta<C>,
        reason: Option<C::RedactionReason>,
    ) -> Result<(), C::Error> {
        let event_id = event_meta.event_id.clone();
        trace!(event_id=?event_id, ?model_type, "asked to redact");

        match self.store.get(&event_id).await {
            Ok(model) if model.is_redacted() => {
                info!(?event_id, "live redacted: Already redacted");
            }
            Ok(model) => {
                trace!("previous model found. overwriting");
                self.notify(model.redact(&self.store, reason).await?);
            }
            Err(error) if error.is_not_found() => {
                trace!("no model found, storing redaction model");
                self.notify(vec![ExecuteReference::Model(event_id)]);
            }
            Err(error) => return Err(error),
        }
        Ok(())
    }

    pub async fn live_redact(
        &self,
        meta: EventMeta<C>,
        reason: Option<C::RedactionReason>,
    ) -> Result<(), C::Error> {
        let event_id = meta.event_id.clone();

        match self.store.get(&event_id).await {
            Ok(model) if model.is_redacted() => {
                info!(?event_id, "live redacted: Already redacted");
            }
            Ok(model) => {
                trace!("live redacted: model found");
                let keys = model.redact(&self.store, reason).await?;
                info!(?event_id, "live redacted: {:?}", &keys);
                self.notify(keys);
            }
            Err(error) if error.is_not_found() => {
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

    use crate::mocks::{MockStore, MockTypeConfig};

    use super::*;

    async fn fresh_executor() -> Result<Executor<MockTypeConfig, MockStore>> {
        let store = MockStore::new();
        Ok(Executor::new(store))
    }
    use anyhow::Result;

    #[tokio::test]
    async fn smoke_test() -> Result<()> {
        let _ = env_logger::try_init();
        let _ = fresh_executor().await?;
        Ok(())
    }
}
