use crate::RUNTIME;

use super::Client;
use anyhow::Result;
use ruma::{
    api::client::push::{set_pusher, PusherIds, PusherInit, PusherKind},
    assign,
    push::HttpPusherData,
};

impl Client {
    pub async fn add_pusher(
        &self,
        app_id: String,
        token: String,
        device_name: String,
        app_name: String,
        server_url: String,
        lang: Option<String>,
    ) -> Result<bool> {
        let client = self.core.client().clone();
        let pusher_data = PusherInit {
            ids: PusherIds::new(token, app_id),
            kind: PusherKind::Http(HttpPusherData::new(server_url)),
            app_display_name: app_name,
            device_display_name: device_name,
            profile_tag: None,
            lang: lang.unwrap_or("en".to_owned()), //
        };
        RUNTIME
            .spawn(async move {
                // FIXME: how to set `append = true` for single-device-multi-user-support...?!?
                let request = set_pusher::v3::Request::post(pusher_data.into());
                client.send(request, None).await?;
                Ok(false)
            })
            .await?
    }
}
