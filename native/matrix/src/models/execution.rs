use acter_core::execution::{
    default_model_execute as core_default_model_execute, transition_tree as core_transition_tree,
    Model as CoreModel, Store as CoreStore,
};
use matrix_sdk::ruma::OwnedEventId;

use crate::config::MatrixCoreTypeConfig;
use crate::models::{ActerModel, AnyActerModel};
use crate::referencing::ExecuteReference;
use crate::store::Store;

pub async fn default_model_execute(
    store: &Store,
    model: AnyActerModel,
) -> Result<Vec<ExecuteReference>, crate::Error> {
    core_default_model_execute::<MatrixCoreTypeConfig, AnyActerModel, Store, crate::Error>(
            store, model,
        )
        .await
}

pub async fn transition_tree(
    store: &Store,
    parents: Vec<OwnedEventId>,
    model: &AnyActerModel,
) -> Result<Vec<AnyActerModel>, crate::Error> {
    core_transition_tree::<
        MatrixCoreTypeConfig,
        AnyActerModel,
        Store,
        std::vec::IntoIter<OwnedEventId>,
        crate::Error,
    >(store, parents.into_iter(), model)
    .await
}

impl CoreModel<MatrixCoreTypeConfig> for AnyActerModel {
    type Error = crate::Error;
    type Store = Store;

    fn object_id(&self) -> OwnedEventId {
        ActerModel::event_id(self).to_owned()
    }

    fn belongs_to(&self) -> Option<Vec<OwnedEventId>> {
        ActerModel::belongs_to(self)
    }

    async fn execute(self, store: &Self::Store) -> Result<Vec<ExecuteReference>, Self::Error> {
        default_model_execute(store, self).await
    }

    fn transition(&mut self, model: &Self) -> Result<bool, Self::Error> {
        ActerModel::transition(self, model)
    }
}

impl CoreStore<MatrixCoreTypeConfig> for Store {
    type Model = AnyActerModel;
    type Error = crate::Error;

    fn get(
        &self,
        id: &OwnedEventId,
    ) -> impl core::future::Future<Output = Result<Self::Model, Self::Error>> + Send {
        self.get(id)
    }

    fn save(
        &self,
        model: Self::Model,
    ) -> impl core::future::Future<Output = Result<Vec<ExecuteReference>, Self::Error>> + Send {
        self.save(model.clone())
    }

    fn save_many<I: Iterator<Item = Self::Model> + Send>(
        &self,
        models: I,
    ) -> impl core::future::Future<Output = Result<Vec<ExecuteReference>, Self::Error>> + Send {
        self.save_many(models)
    }
}
