use derive_getters::Getters;
use matrix_sdk::Client;

use crate::{error::Error, executor::Executor, store::Store};

/// Comment Event
#[derive(Clone, Debug, Getters)]
pub struct CoreClient {
    client: Client,
    store: Store,
    executor: Executor,
}

impl CoreClient {
    pub async fn new(client: Client) -> Result<Self, Error> {
        let store = Store::new(client.clone()).await?;
        let executor = Executor::new(store.clone()).await?;
        client.add_event_handler_context(executor.clone());

        Ok(CoreClient {
            store,
            executor,
            client,
        })
    }
}
