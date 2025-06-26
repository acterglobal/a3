use async_recursion::async_recursion;
use matrix_sdk_base::ruma::OwnedEventId;
use tracing::trace;

use crate::referencing::ExecuteReference;
pub use crate::store::Store;

use super::{ActerModel, AnyActerModel};

#[async_recursion]
pub async fn transition_tree(
    store: &Store,
    parents: Vec<OwnedEventId>,
    model: &AnyActerModel,
) -> crate::Result<Vec<AnyActerModel>> {
    let mut models = vec![];
    for p in parents {
        let mut parent = store.get(&p).await?;
        if parent.transition(model)? {
            if let Some(grandparents) = parent.belongs_to() {
                let mut parent_models = transition_tree(store, grandparents, &parent).await?;
                if !parent_models.is_empty() {
                    models.append(&mut parent_models);
                }
            }
            models.push(parent);
        }
    }
    Ok(models)
}

pub async fn default_model_execute(
    store: &Store,
    model: AnyActerModel,
) -> crate::Result<Vec<ExecuteReference>> {
    trace!(event_id=?model.event_id(), ?model, "handling");
    let Some(belongs_to) = model.belongs_to() else {
        trace!(event_id=?model.event_id(), "saving simple model");
        return store.save(model).await;
    };

    trace!(event_id=?model.event_id(), ?belongs_to, "transitioning tree");
    let mut models = transition_tree(store, belongs_to, &model).await?;
    models.push(model);
    store.save_many(models).await
}
