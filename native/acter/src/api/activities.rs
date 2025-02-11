use acter_core::activities::Activity as CoreActivity;
use ruma::EventId;

use super::{Client, RUNTIME};

#[derive(Clone, Debug)]
pub struct Activity {
    inner: CoreActivity,
    client: Client,
}

impl Activity {
    #[cfg(any(test, feature = "testing"))]
    pub fn inner(&self) -> CoreActivity {
        self.inner.clone()
    }
}

impl Client {
    pub async fn activity(&self, key: String) -> anyhow::Result<Activity> {
        let ev_id = EventId::parse(key)?;
        let client = self.clone();

        Ok(RUNTIME
            .spawn(async move {
                client
                    .core
                    .activity(&ev_id)
                    .await
                    .map(|inner| Activity { inner, client })
            })
            .await??)
    }
}
