use crate::{
    models::{AnyEffektioModel, EffektioModel},
    store::Store,
    Result,
};
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

    pub fn store(&self) -> &Store {
        &self.store
    }

    pub async fn handle(&self, model: AnyEffektioModel) -> Result<()> {
        tracing::trace!(?model, "handling");
        let Some(belongs_to) = model.belongs_to() else {
            self.store.save(model).await?;
            return Ok(())
        };

        let mut models = vec![];

        for parent in belongs_to {
            let mut parent = self.store.get(&parent).await?;
            if parent.transition(&model)? {
                models.push(parent);
            }
        }

        models.push(model);
        self.store.save_many(models).await?;

        Ok(())
    }
}
