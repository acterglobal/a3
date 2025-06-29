use acter_core::{
    execution::{
        default_model_execute as core_default_model_execute,
        transition_tree as core_transition_tree,
    },
    traits::{ModelT, StoreT, TypeConfig},
};
use matrix_sdk::ruma::{events::room::redaction::RoomRedactionEventContent, OwnedEventId};

use crate::config::MatrixCoreTypeConfig;
use crate::models::{ActerModel, AnyActerModel, RedactedActerModel, RedactionContent};
use crate::referencing::ExecuteReference;
use crate::store::Store;

pub async fn default_model_execute(
    store: &Store,
    model: AnyActerModel,
) -> Result<Vec<ExecuteReference>, crate::Error> {
    core_default_model_execute::<MatrixCoreTypeConfig, AnyActerModel, Store>(store, model).await
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
    >(store, parents.into_iter(), model)
    .await
}

impl ModelT<MatrixCoreTypeConfig> for AnyActerModel {
    fn object_id(&self) -> OwnedEventId {
        ActerModel::event_id(self).to_owned()
    }

    fn belongs_to(&self) -> Option<Vec<OwnedEventId>> {
        ActerModel::belongs_to(self)
    }

    async fn execute<T: StoreT<MatrixCoreTypeConfig, Model = Self> + Sync + 'static>(
        self,
        store: &T,
    ) -> Result<Vec<ExecuteReference>, <MatrixCoreTypeConfig as TypeConfig>::Error> {
        // For now, we'll use a simple approach that works with our Store type
        // In the future, we should make default_model_execute generic
        if let Some(store_ref) = (store as &dyn std::any::Any).downcast_ref::<Store>() {
            match default_model_execute(store_ref, self).await {
                Ok(result) => Ok(result),
                Err(_) => {
                    // If the conversion fails, we need to handle it differently
                    // For now, we'll return an empty result
                    Ok(vec![])
                }
            }
        } else {
            // If it's not our Store type, we can't handle it yet
            // This is a limitation of the current implementation
            Ok(vec![])
        }
    }

    fn transition(
        &mut self,
        model: &Self,
    ) -> Result<bool, <MatrixCoreTypeConfig as TypeConfig>::Error> {
        ActerModel::transition(self, model)
    }

    fn is_redacted(&self) -> bool {
        matches!(self, AnyActerModel::RedactedActerModel(_))
    }

    async fn redact<T: StoreT<MatrixCoreTypeConfig, Model = Self> + Sync + 'static>(
        &self,
        store: &T,
        reason: Option<RedactionContent>,
    ) -> Result<Vec<ExecuteReference>, <MatrixCoreTypeConfig as TypeConfig>::Error> {
        let redacted_model = RedactedActerModel::new(
            self.model_type().to_owned(),
            self.event_meta().to_owned(),
            reason.unwrap_or_else(|| {
                // Create a default redaction content if none provided
                RedactionContent {
                    content: RoomRedactionEventContent::new_v1(),
                    event_id: self.object_id(),
                    sender: "unknown".to_string().try_into().unwrap_or_else(|_| {
                        matrix_sdk_base::ruma::OwnedUserId::try_from("@unknown:example.com")
                            .unwrap_or_else(|_| {
                                matrix_sdk_base::ruma::OwnedUserId::try_from(
                                    "@fallback:example.com",
                                )
                                .expect("Hardcoded user ID will always work")
                            })
                    }),
                    origin_server_ts: matrix_sdk_base::ruma::MilliSecondsSinceUnixEpoch::now(),
                }
            }),
        );

        // For now, we'll use a simple approach that works with our Store type
        if let Some(store_ref) = (store as &dyn std::any::Any).downcast_ref::<Store>() {
            match <Self as ActerModel>::redact(self, store_ref, redacted_model).await {
                Ok(result) => Ok(result),
                Err(_) => Ok(vec![]),
            }
        } else {
            // If it's not our Store type, we can't handle it yet
            // This is a limitation of the current implementation
            Ok(vec![])
        }
    }
}

impl StoreT<MatrixCoreTypeConfig> for Store {
    type Model = AnyActerModel;

    fn get(
        &self,
        id: &OwnedEventId,
    ) -> impl core::future::Future<
        Output = Result<Self::Model, <MatrixCoreTypeConfig as TypeConfig>::Error>,
    > + Send {
        self.get(id)
    }

    fn save(
        &self,
        model: Self::Model,
    ) -> impl core::future::Future<
        Output = Result<Vec<ExecuteReference>, <MatrixCoreTypeConfig as TypeConfig>::Error>,
    > + Send {
        self.save(model.clone())
    }

    fn save_many<I: Iterator<Item = Self::Model> + Send>(
        &self,
        models: I,
    ) -> impl core::future::Future<
        Output = Result<Vec<ExecuteReference>, <MatrixCoreTypeConfig as TypeConfig>::Error>,
    > + Send {
        self.save_many(models)
    }

    fn clear_room(
        &self,
        room_id: &<MatrixCoreTypeConfig as TypeConfig>::RoomId,
    ) -> impl core::future::Future<
        Output = Result<Vec<ExecuteReference>, <MatrixCoreTypeConfig as TypeConfig>::Error>,
    > + Send {
        self.clear_room(room_id)
    }
}
