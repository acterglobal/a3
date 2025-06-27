use async_recursion::async_recursion;
use tracing::trace;

use crate::{
    referencing::ExecuteReference,
    traits::{ModelT, StoreT, TypeConfig},
};

#[async_recursion]
pub async fn transition_tree<C, M, S, I, E>(store: &S, parents: I, model: &M) -> Result<Vec<M>, E>
where
    C: TypeConfig,
    M: ModelT<C> + Sync,
    S: StoreT<C, Model = M> + Sync,
    S::Model: ModelT<C>,
    I: Iterator<Item = C::ObjectId> + Send,
    E: core::error::Error + Send,
    E: From<<S as StoreT<C>>::Error>,
    E: From<<M as ModelT<C>>::Error>,
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
    M: ModelT<C> + Sync,
    S: StoreT<C, Model = M> + Sync,
    S::Model: ModelT<C>,
    E: core::error::Error + Send,
    E: From<<S as StoreT<C>>::Error>,
    E: From<<M as ModelT<C>>::Error>,
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

#[cfg(test)]
mod tests {
    use super::*;

    use crate::mocks::{MockError, MockModel, MockObjectId, MockStore, MockTypeConfig};

    #[tokio::test]
    async fn test_transition_tree_simple_no_transitions() {
        let store = MockStore::new();

        // Create a parent model
        let parent = MockModel::new("parent1", 10, None);
        store.insert(parent.clone()).await;

        // Create a child model that won't trigger transitions
        let child = MockModel::new("child1", 5, Some(vec!["parent1"]));

        let parents = vec![MockObjectId("parent1".to_string())];
        let result = transition_tree::<MockTypeConfig, MockModel, MockStore, _, MockError>(
            &store,
            parents.into_iter(),
            &child,
        )
        .await;

        assert!(result.is_ok());
        let models = result.unwrap();
        assert_eq!(models.len(), 0); // No transitions occurred
    }

    #[tokio::test]
    async fn test_transition_tree_single_transition() {
        let store = MockStore::new();

        // Create a parent model
        let parent = MockModel::new("parent1", 5, None);
        store.insert(parent.clone()).await;

        // Create a child model that will trigger transition
        let child = MockModel::new("child1", 10, Some(vec!["parent1"]));

        let parents = vec![MockObjectId("parent1".to_string())];
        let result = transition_tree::<MockTypeConfig, MockModel, MockStore, _, MockError>(
            &store,
            parents.into_iter(),
            &child,
        )
        .await;

        assert!(result.is_ok());
        let models = result.unwrap();
        assert_eq!(models.len(), 1);

        let transitioned_parent = &models[0];
        assert_eq!(transitioned_parent.value, 10); // Should have been updated
        assert_eq!(transitioned_parent.transition_count, 1);
    }

    #[tokio::test]
    async fn test_transition_tree_multiple_parents() {
        let store = MockStore::new();

        // Create parent models
        let parent1 = MockModel::new("parent1", 5, None);
        let parent2 = MockModel::new("parent2", 3, None);
        store.insert(parent1.clone()).await;
        store.insert(parent2.clone()).await;

        // Create a child model that will trigger transitions
        let child = MockModel::new("child1", 10, Some(vec!["parent1", "parent2"]));

        let parents = vec![
            MockObjectId("parent1".to_string()),
            MockObjectId("parent2".to_string()),
        ];
        let result = transition_tree::<MockTypeConfig, MockModel, MockStore, _, MockError>(
            &store,
            parents.into_iter(),
            &child,
        )
        .await;

        assert!(result.is_ok());
        let models = result.unwrap();
        assert_eq!(models.len(), 2);

        // Both parents should have been updated
        let parent1_updated = models.iter().find(|m| m.id.0 == "parent1").unwrap();
        let parent2_updated = models.iter().find(|m| m.id.0 == "parent2").unwrap();

        assert_eq!(parent1_updated.value, 10);
        assert_eq!(parent1_updated.transition_count, 1);
        assert_eq!(parent2_updated.value, 10);
        assert_eq!(parent2_updated.transition_count, 1);
    }

    #[tokio::test]
    async fn test_transition_tree_nested_hierarchy() {
        let store = MockStore::new();

        // Create a grandparent model
        let grandparent = MockModel::new("grandparent", 2, None);
        store.insert(grandparent.clone()).await;

        // Create a parent model that belongs to grandparent
        let parent = MockModel::new("parent", 5, Some(vec!["grandparent"]));
        store.insert(parent.clone()).await;

        // Create a child model that will trigger transitions up the chain
        let child = MockModel::new("child", 15, Some(vec!["parent"]));

        let parents = vec![MockObjectId("parent".to_string())];
        let result = transition_tree::<MockTypeConfig, MockModel, MockStore, _, MockError>(
            &store,
            parents.into_iter(),
            &child,
        )
        .await;

        assert!(result.is_ok());
        let models = result.unwrap();
        assert_eq!(models.len(), 2); // Both parent and grandparent should transition

        // Check that parent was updated
        let parent_updated = models.iter().find(|m| m.id.0 == "parent").unwrap();
        assert_eq!(parent_updated.value, 15);
        assert_eq!(parent_updated.transition_count, 1);

        // Check that grandparent was also updated (through recursive call)
        let grandparent_updated = models.iter().find(|m| m.id.0 == "grandparent").unwrap();
        assert_eq!(grandparent_updated.value, 15);
        assert_eq!(grandparent_updated.transition_count, 1);
    }

    #[tokio::test]
    async fn test_transition_tree_no_parents() {
        let store = MockStore::new();

        let child = MockModel::new("child1", 10, None);
        let parents: Vec<MockObjectId> = vec![];

        let result = transition_tree::<MockTypeConfig, MockModel, MockStore, _, MockError>(
            &store,
            parents.into_iter(),
            &child,
        )
        .await;

        assert!(result.is_ok());
        let models = result.unwrap();
        assert_eq!(models.len(), 0);
    }

    #[tokio::test]
    async fn test_transition_tree_parent_not_found() {
        let store = MockStore::new();

        let child = MockModel::new("child1", 10, Some(vec!["nonexistent"]));
        let parents = vec![MockObjectId("nonexistent".to_string())];

        let result = transition_tree::<MockTypeConfig, MockModel, MockStore, _, MockError>(
            &store,
            parents.into_iter(),
            &child,
        )
        .await;

        assert!(result.is_err());
        assert_eq!(
            result.unwrap_err(),
            MockError::NotFound("nonexistent".to_string())
        );
    }

    #[tokio::test]
    async fn test_default_model_execute_simple_model() {
        let store = MockStore::new();

        // Create a model with no parents
        let model = MockModel::new("simple", 10, None);

        let result =
            default_model_execute::<MockTypeConfig, MockModel, MockStore, MockError>(&store, model)
                .await;

        assert!(result.is_ok());
        let references = result.unwrap();
        assert_eq!(references.len(), 1);
        assert!(matches!(references[0], ExecuteReference::Model(_)));
    }

    #[tokio::test]
    async fn test_default_model_execute_with_parents() {
        let store = MockStore::new();

        // Create parent models
        let parent1 = MockModel::new("parent1", 5, None);
        let parent2 = MockModel::new("parent2", 3, None);
        store.insert(parent1.clone()).await;
        store.insert(parent2.clone()).await;

        // Create a model with parents that will trigger transitions
        let model = MockModel::new("child", 15, Some(vec!["parent1", "parent2"]));

        let result =
            default_model_execute::<MockTypeConfig, MockModel, MockStore, MockError>(&store, model)
                .await;

        assert!(result.is_ok());
        let references = result.unwrap();
        assert_eq!(references.len(), 3); // child + 2 updated parents

        // Verify that parents were updated in the store
        let updated_parent1 = store
            .get_model(&MockObjectId("parent1".to_string()))
            .await
            .unwrap();
        let updated_parent2 = store
            .get_model(&MockObjectId("parent2".to_string()))
            .await
            .unwrap();

        assert_eq!(updated_parent1.value, 15);
        assert_eq!(updated_parent1.transition_count, 1);
        assert_eq!(updated_parent2.value, 15);
        assert_eq!(updated_parent2.transition_count, 1);
    }

    #[tokio::test]
    async fn test_default_model_execute_nested_hierarchy() {
        let store = MockStore::new();

        // Create a grandparent
        let grandparent = MockModel::new("grandparent", 2, None);
        store.insert(grandparent.clone()).await;

        // Create a parent that belongs to grandparent
        let parent = MockModel::new("parent", 5, Some(vec!["grandparent"]));
        store.insert(parent.clone()).await;

        // Create a child that will trigger the full chain
        let child = MockModel::new("child", 20, Some(vec!["parent"]));

        let result =
            default_model_execute::<MockTypeConfig, MockModel, MockStore, MockError>(&store, child)
                .await;

        assert!(result.is_ok());
        let references = result.unwrap();
        assert_eq!(references.len(), 3); // child + parent + grandparent

        // Verify the entire chain was updated
        let updated_grandparent = store
            .get_model(&MockObjectId("grandparent".to_string()))
            .await
            .unwrap();
        let updated_parent = store
            .get_model(&MockObjectId("parent".to_string()))
            .await
            .unwrap();

        assert_eq!(updated_grandparent.value, 20);
        assert_eq!(updated_grandparent.transition_count, 1);
        assert_eq!(updated_parent.value, 20);
        assert_eq!(updated_parent.transition_count, 1);
    }

    #[tokio::test]
    async fn test_default_model_execute_partial_transitions() {
        let store = MockStore::new();

        // Create parent models with different values
        let parent1 = MockModel::new("parent1", 5, None); // Will transition
        let parent2 = MockModel::new("parent2", 25, None); // Won't transition (higher value)
        store.insert(parent1.clone()).await;
        store.insert(parent2.clone()).await;

        // Create a model with value between the parents
        let model = MockModel::new("child", 15, Some(vec!["parent1", "parent2"]));

        let result =
            default_model_execute::<MockTypeConfig, MockModel, MockStore, MockError>(&store, model)
                .await;

        assert!(result.is_ok());
        let references = result.unwrap();
        assert_eq!(references.len(), 2); // child + only parent1 (parent2 didn't transition)

        // Verify only parent1 was updated
        let updated_parent1 = store
            .get_model(&MockObjectId("parent1".to_string()))
            .await
            .unwrap();
        let updated_parent2 = store
            .get_model(&MockObjectId("parent2".to_string()))
            .await
            .unwrap();

        assert_eq!(updated_parent1.value, 15);
        assert_eq!(updated_parent1.transition_count, 1);
        assert_eq!(updated_parent2.value, 25); // Unchanged
        assert_eq!(updated_parent2.transition_count, 0);
    }

    #[tokio::test]
    async fn test_default_model_execute_parent_not_found() {
        let store = MockStore::new();

        // Create a model with a non-existent parent
        let model = MockModel::new("child", 15, Some(vec!["nonexistent"]));

        let result =
            default_model_execute::<MockTypeConfig, MockModel, MockStore, MockError>(&store, model)
                .await;

        assert!(result.is_err());
        assert_eq!(
            result.unwrap_err(),
            MockError::NotFound("nonexistent".to_string())
        );
    }

    #[tokio::test]
    async fn test_transition_tree_multiple_transitions_same_parent() {
        let store = MockStore::new();

        // Create a parent model
        let parent = MockModel::new("parent", 5, None);
        store.insert(parent.clone()).await;

        // Create multiple children that will trigger transitions
        let child1 = MockModel::new("child1", 10, Some(vec!["parent"]));
        let child2 = MockModel::new("child2", 25, Some(vec!["parent"]));

        // First transition
        let parents = vec![MockObjectId("parent".to_string())];
        let result1 = transition_tree::<MockTypeConfig, MockModel, MockStore, _, MockError>(
            &store,
            parents.clone().into_iter(),
            &child1,
        )
        .await;

        assert!(result1.is_ok());
        let models1 = result1.unwrap();
        assert_eq!(models1.len(), 1);
        let current_parent = models1.into_iter().next().unwrap();
        assert_eq!(current_parent.value, 10);
        assert_eq!(current_parent.transition_count, 1);

        // this updated the parent, save it to the store for further processing
        store.save(current_parent).await.unwrap();

        // Second transition should update the already-transitioned parent
        let result2 = transition_tree::<MockTypeConfig, MockModel, MockStore, _, MockError>(
            &store,
            parents.clone().into_iter(),
            &child2,
        )
        .await;

        assert!(result2.is_ok());
        let models2 = result2.unwrap();
        assert_eq!(models2.len(), 1);

        let final_parent = &models2[0];
        assert_eq!(final_parent.value, 25); // Should have been updated
        assert_eq!(final_parent.transition_count, 2); // Should have transitioned twice
    }

    #[tokio::test]
    async fn test_transition_tree_complex_hierarchy() {
        let store = MockStore::new();

        // Create a complex hierarchy: root -> level1 -> level2 -> level3
        let root = MockModel::new("root", 1, None);
        let level1 = MockModel::new("level1", 2, Some(vec!["root"]));
        let level2 = MockModel::new("level2", 3, Some(vec!["level1"]));

        store.insert(root.clone()).await;
        store.insert(level1.clone()).await;
        store.insert(level2.clone()).await;

        // Create a leaf node that will trigger the entire chain
        let leaf = MockModel::new("leaf", 100, Some(vec!["level2"]));

        let parents = vec![MockObjectId("level2".to_string())];
        let result = transition_tree::<MockTypeConfig, MockModel, MockStore, _, MockError>(
            &store,
            parents.into_iter(),
            &leaf,
        )
        .await;

        assert!(result.is_ok());
        let models = result.unwrap();
        assert_eq!(models.len(), 3); // level2, level1, root

        // Verify all levels were updated
        let level2_updated = models.iter().find(|m| m.id.0 == "level2").unwrap();
        let level1_updated = models.iter().find(|m| m.id.0 == "level1").unwrap();
        let root_updated = models.iter().find(|m| m.id.0 == "root").unwrap();

        assert_eq!(level2_updated.value, 100);
        assert_eq!(level2_updated.transition_count, 1);
        assert_eq!(level1_updated.value, 100);
        assert_eq!(level1_updated.transition_count, 1);
        assert_eq!(root_updated.value, 100);
        assert_eq!(root_updated.transition_count, 1);
    }
}
