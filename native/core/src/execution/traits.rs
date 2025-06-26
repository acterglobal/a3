use crate::{config::TypeConfig, referencing::ExecuteReference};

pub trait Error = core::error::Error + Send;

pub trait Store<C: TypeConfig>: Send {
    type Model: Model<C>;
    type Error: core::error::Error;

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

pub trait Model<C: TypeConfig>: core::fmt::Debug + Clone + Send {
    type Error: Error;
    type Store: Store<C, Model = Self>;

    fn belongs_to(&self) -> Option<Vec<C::ObjectId>>;
    fn object_id(&self) -> C::ObjectId;

    fn execute(
        self,
        store: &Self::Store,
    ) -> impl core::future::Future<
        Output = Result<Vec<ExecuteReference<C>>, <Self::Store as Store<C>>::Error>,
    > + Send;

    fn transition(&mut self, model: &Self) -> Result<bool, Self::Error>;
}
