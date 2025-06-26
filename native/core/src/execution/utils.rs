use async_recursion::async_recursion;
use tracing::trace;

use super::traits::{Model, Store};
use crate::{config::TypeConfig, referencing::ExecuteReference};

#[async_recursion]
pub async fn transition_tree<C: TypeConfig, M, S, I, E>(
    store: &S,
    parents: I,
    model: &M,
) -> Result<Vec<M>, E>
where
    M: Model<C> + Sync,
    S: Store<C, Model = M> + Sync,
    S::Model: Model<C>,
    I: Iterator<Item = C::ObjectId> + Send,
    E: core::error::Error + Send,
    E: From<<S as Store<C>>::Error>,
    E: From<<M as Model<C>>::Error>,
{
    let mut models = vec![];
    for p in parents {
        let mut parent = store.get(&p).await?;
        if parent.transition(model)? {
            if let Some(grandparents) = parent.belongs_to() {
                let mut parent_models =
                    transition_tree::<C, M, S, std::vec::IntoIter<<C as TypeConfig>::ObjectId>, E>(
                        store,
                        grandparents.into_iter(),
                        &parent,
                    )
                    .await?;
                if !parent_models.is_empty() {
                    models.append(&mut parent_models);
                }
            }
            models.push(parent);
        }
    }
    Ok(models)
}

pub async fn default_model_execute<C: TypeConfig, M, S, E>(
    store: &S,
    model: M,
) -> Result<Vec<ExecuteReference<C>>, E>
where
    M: Model<C> + Sync,
    S: Store<C, Model = M> + Sync,
    S::Model: Model<C>,
    E: core::error::Error + Send,
    E: From<<S as Store<C>>::Error>,
    E: From<<M as Model<C>>::Error>,
{
    trace!(object_id=?model.object_id(), ?model, "handling");
    let Some(belongs_to) = model.belongs_to() else {
        trace!(object_id=?model.object_id(), "saving simple model");
        return Ok(store.save(model).await?);
    };

    trace!(object_id=?model.object_id(), ?belongs_to, "transitioning tree");
    let mut models =
        transition_tree::<C, M, S, std::vec::IntoIter<<C as TypeConfig>::ObjectId>, E>(
            store,
            belongs_to.into_iter(),
            &model,
        )
        .await?;
    models.push(model);
    Ok(store.save_many(models.into_iter()).await?)
}
