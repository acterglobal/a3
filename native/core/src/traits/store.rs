use crate::{
    referencing::ExecuteReference,
    traits::{Error, ModelT, TypeConfig},
};

pub trait StoreT<C: TypeConfig>: Send {
    type Model: ModelT<C>;
    type Error: Error;

    fn get(
        &self,
        id: &C::ObjectId,
    ) -> impl core::future::Future<Output = Result<Self::Model, Self::Error>> + Send;

    fn save(
        &self,
        model: Self::Model,
    ) -> impl core::future::Future<Output = Result<Vec<ExecuteReference<C>>, Self::Error>> + Send;

    fn save_many<I: Iterator<Item = Self::Model> + Send>(
        &self,
        models: I,
    ) -> impl core::future::Future<Output = Result<Vec<ExecuteReference<C>>, Self::Error>> + Send;
}
