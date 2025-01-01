use std::ops::Deref;

use crate::{Client, RUNTIME};
use acter_core::events::{ObjRef as CoreObjRef, RefDetails as CoreRefDetails};
use acter_core::share_link::api;
use anyhow::Result;

#[derive(Clone)]
pub struct ObjRef {
    client: Client,
    inner: CoreObjRef,
}

impl Deref for ObjRef {
    type Target = CoreObjRef;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl ObjRef {
    pub(crate) fn new(client: Client, inner: CoreObjRef) -> Self {
        Self { client, inner }
    }

    pub fn ref_details(&self) -> RefDetails {
        RefDetails {
            inner: self.inner.ref_details(),
            client: self.client.clone(),
        }
    }
}
pub struct RefDetails {
    inner: CoreRefDetails,
    client: Client,
}

impl Deref for RefDetails {
    type Target = CoreRefDetails;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl RefDetails {
    pub(crate) fn new(client: Client, inner: CoreRefDetails) -> Self {
        Self { client, inner }
    }

    pub async fn generate_external_link(&self) -> Result<String> {
        let c = self.client.core.client().clone();
        let inner = self.inner.clone();
        RUNTIME
            .spawn(async move {
                let req = api::create::Request::new(inner);
                let resp = c.send(req, None).await?;
                Ok(resp.url)
            })
            .await?
    }
}
