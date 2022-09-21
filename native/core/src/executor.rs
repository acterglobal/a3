use crate::{events::AnyEffektioEvent, store::Store};
use crate::{Error, Result};
use matrix_sdk::{deserialized_responses::TimelineEvent, Client as MatrixClient};

#[derive(Clone, Debug)]
pub struct Executor {
    client: MatrixClient,
    store: Store,
}

impl Executor {
    pub async fn new(client: MatrixClient, store: Store) -> Result<Self> {
        Ok(Executor { client, store })
    }
    pub async fn handle(&self, msg: TimelineEvent) -> Result<()> {
        let event: AnyEffektioEvent = msg
            .event
            .deserialize_as()
            .map_err(|_| Error::UnknownEvent)?;

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
