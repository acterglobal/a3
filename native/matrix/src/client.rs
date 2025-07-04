use derive_getters::Getters;
use matrix_sdk::Client;

use crate::{error::Error, executor::Executor, referencing::ExecuteReference, store::Store};
use tokio::sync::broadcast::Receiver;

/// Core Client wrapper
#[derive(Clone, Debug, Getters)]
pub struct CoreClient {
    pub(crate) client: Client,
    pub(crate) store: Store,
    pub(crate) executor: Executor,
}

impl CoreClient {
    pub async fn new(client: Client) -> Result<Self, Error> {
        let store = Store::new(client.clone()).await?;
        let executor = Executor::new(store.clone());
        client.add_event_handler_context(executor.clone());

        Ok(CoreClient {
            store,
            executor,
            client,
        })
    }

    pub fn subscribe<K: Into<ExecuteReference>>(&self, key: K) -> Receiver<()> {
        self.executor.subscribe(key)
    }
}
