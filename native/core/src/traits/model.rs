use crate::{
    referencing::ExecuteReference,
    traits::{StoreT, TypeConfig},
};

pub trait ModelT<C: TypeConfig>: core::fmt::Debug + Clone + Send {
    fn belongs_to(&self) -> Option<Vec<C::ObjectId>>;
    fn object_id(&self) -> C::ObjectId;

    fn execute<T: StoreT<C, Model = Self> + Sync + 'static>(
        self,
        store: &T,
    ) -> impl core::future::Future<Output = Result<Vec<ExecuteReference<C>>, C::Error>> + Send;

    fn transition(&mut self, model: &Self) -> Result<bool, C::Error>;

    fn is_redacted(&self) -> bool;

    fn redact<T: StoreT<C, Model = Self> + Sync + 'static>(
        &self,
        store: &T,
        reason: Option<C::RedactionReason>,
    ) -> impl core::future::Future<Output = Result<Vec<ExecuteReference<C>>, C::Error>> + Send;
}
