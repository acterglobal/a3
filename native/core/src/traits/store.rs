use crate::{
    referencing::ExecuteReference,
    traits::{Error, ModelT, TypeConfig},
};

pub trait StoreError: Error {
    fn is_not_found(&self) -> bool;
}

pub trait StoreT<C: TypeConfig>: Send + Sync {
    type Model: ModelT<C>;

    fn get(
        &self,
        id: &C::ObjectId,
    ) -> impl core::future::Future<Output = Result<Self::Model, C::Error>> + Send;

    fn save(
        &self,
        model: Self::Model,
    ) -> impl core::future::Future<Output = Result<Vec<ExecuteReference<C>>, C::Error>> + Send;

    fn save_many<I: Iterator<Item = Self::Model> + Send>(
        &self,
        models: I,
    ) -> impl core::future::Future<Output = Result<Vec<ExecuteReference<C>>, C::Error>> + Send;

    fn clear_room(
        &self,
        room_id: &C::RoomId,
    ) -> impl core::future::Future<Output = Result<Vec<ExecuteReference<C>>, C::Error>> + Send;
}
