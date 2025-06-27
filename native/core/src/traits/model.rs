use crate::{
    referencing::ExecuteReference,
    traits::{Error, StoreT, TypeConfig},
};

pub trait ModelT<C: TypeConfig>: core::fmt::Debug + Clone + Send {
    type Error: Error;
    type Store: StoreT<C, Model = Self>;

    fn belongs_to(&self) -> Option<Vec<C::ObjectId>>;
    fn object_id(&self) -> C::ObjectId;

    fn execute(
        self,
        store: &Self::Store,
    ) -> impl core::future::Future<
        Output = Result<Vec<ExecuteReference<C>>, <Self::Store as StoreT<C>>::Error>,
    > + Send;

    fn transition(&mut self, model: &Self) -> Result<bool, Self::Error>;
}
