use crate::Result;
use crate::{events::AnyEffektioEvent, store::Store};
use matrix_sdk::Client as MatrixClient;

#[derive(Clone, Debug)]
pub struct Executor {
    client: MatrixClient,
    store: Store,
}

impl Executor {
    pub async fn new(client: MatrixClient, store: Store) -> Result<Self> {
        Ok(Executor { client, store })
    }
    pub async fn handle(&self, event: AnyEffektioEvent) -> Result<()> {
        let model = if let Some(belongs_event) = event.belongs_to() {
            let model_id = belongs_event.belongs_to();
            let model = self.store.get(model_id).await?;
            model.transition(belongs_event);
            model
        } else {
            // this creates a new model
            event.create().unwrap()
        };

        self.store.save(model).await?;

        Ok(())
    }
}
