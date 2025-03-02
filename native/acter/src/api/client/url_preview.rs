use crate::RUNTIME;
use ruma::{assign, events::room::message::UrlPreview};
use url_preview::{Preview, PreviewService};

use super::Client;

pub struct LocalUrlPreview(pub(crate) Preview);

impl LocalUrlPreview {
    fn new(prev: Preview) -> Self {
        Self(prev)
    }
    pub fn url(&self) -> String {
        self.0.url.clone()
    }
    pub fn title(&self) -> Option<String> {
        self.0.title.clone()
    }
    pub fn description(&self) -> Option<String> {
        self.0.description.clone()
    }
    pub fn favicon(&self) -> Option<String> {
        self.0.favicon.clone()
    }

    pub fn site_name(&self) -> Option<String> {
        self.0.site_name.clone()
    }

    pub fn has_image(&self) -> bool {
        self.0.image_url.is_some()
    }
    pub fn image_url(&self) -> Option<String> {
        self.0.image_url.clone()
    }
}

impl From<LocalUrlPreview> for UrlPreview {
    fn from(val: LocalUrlPreview) -> Self {
        assign!(UrlPreview::canonical_url(val.0.url), {
            title: val.0.title,
            description: val.0.description
        })
    }
}

impl Client {
    pub async fn url_preview(&self, url: String) -> anyhow::Result<LocalUrlPreview> {
        let cl = self.core.client().clone();

        RUNTIME
            .spawn(async move {
                let service = PreviewService::with_no_cache();
                let preview = service.generate_preview(&url).await?;
                Ok(LocalUrlPreview::new(preview))
            })
            .await?
    }
}
