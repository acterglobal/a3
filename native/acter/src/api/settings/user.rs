pub use acter_core::events::settings::{
    ActerUserAppSettingsContent, ActerUserAppSettingsContentBuilder, AppChatSettings, AutoDownload,
};
use anyhow::Result;
use core::ops::Deref;
use matrix_sdk::Account;

use crate::RUNTIME;

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

    pub fn typing_notice(&self) -> Option<bool> {
        self.inner.chat.typing_notice.as_ref().map(|a| *a)
    }

    pub fn update_builder(&self) -> ActerUserAppSettingsBuilder {
        ActerUserAppSettingsBuilder {
            account: self.account.clone(),
            inner: self.inner.updater(),
        }
    }
}

impl ActerUserAppSettingsBuilder {
    pub fn auto_download_chat(&mut self, new_value: String) -> Result<&mut Self> {
        self.inner.auto_download_chat(new_value)?;
        Ok(self)
    }

    pub fn typing_notice(&mut self, value: bool) -> Result<&mut Self> {
        self.inner.typing_notice(value)?;
        Ok(self)
    }

    pub async fn send(&self) -> Result<bool> {
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
