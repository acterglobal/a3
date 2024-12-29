use crate::{Client, RUNTIME};
use acter_core::{events::RefDetails, share_link::api};
use anyhow::Result;

impl Client {
    pub async fn generate_external_link_for_ref(&self, req: RefDetails) -> Result<String> {
        let c = self.core.client().clone();
        RUNTIME
            .spawn(async move {
                let req = api::create::Request::new(req);
                let resp = c.send(req, None).await?;
                Ok(resp.url)
            })
            .await?
    }
}
