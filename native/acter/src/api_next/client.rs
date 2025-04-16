use std::sync::Arc;

use crate::api::Client;
use super::error::Result;

#[derive(Debug, Clone, uniffi::Object)]
pub struct UniffiClient {
    pub(crate) client: Arc<Client>,
}

impl UniffiClient {
   pub(crate) fn wrap(client: Client) -> Self {
        Self { client: Arc::new(client) }
    }
}


#[uniffi::export]
impl UniffiClient {
    fn user_id(&self) -> Result<String> {
        Ok(self.client.user_id()?.to_string())
    }
    fn cloned(&self) -> Self {
        self.clone()
    }
}
