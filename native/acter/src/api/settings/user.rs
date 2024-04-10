use crate::RUNTIME;
pub use acter_core::events::settings::{
    ActerUserAppSettingsContent, ActerUserAppSettingsContentBuilder, AppChatSettings, AutoDownload,
};
use core::ops::Deref;
use matrix_sdk::Account;

#[derive(Clone)]
pub struct ActerUserAppSettings {
    account: Account,
    inner: ActerUserAppSettingsContent,
}

#[derive(Clone)]
pub struct ActerUserAppSettingsBuilder {
    account: Account,
    inner: ActerUserAppSettingsContentBuilder,
}

impl Deref for ActerUserAppSettings {
    type Target = ActerUserAppSettingsContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl ActerUserAppSettings {
    pub fn new(account: Account, inner: ActerUserAppSettingsContent) -> Self {
        ActerUserAppSettings { account, inner }
    }
    pub fn auto_download_chat(&self) -> Option<String> {
        self.inner
            .chat
            .auto_download
            .as_ref()
            .map(|a| a.to_string())
    }

    pub fn update_builder(&self) -> ActerUserAppSettingsBuilder {
        ActerUserAppSettingsBuilder {
            account: self.account.clone(),
            inner: self.inner.updater(),
        }
    }
}

impl ActerUserAppSettingsBuilder {
    pub fn auto_download_chat(&mut self, new_value: String) -> anyhow::Result<&mut Self> {
        self.inner.auto_download_chat(new_value)?;
        Ok(self)
    }

    pub async fn send(&self) -> anyhow::Result<bool> {
        let account = self.account.clone();
        let update = self.inner.build()?;

        RUNTIME
            .spawn(async move {
                account.set_account_data(update).await?;
                Ok(true)
            })
            .await?
    }
}
