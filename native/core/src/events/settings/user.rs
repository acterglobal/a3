use derive_builder::Builder;
use matrix_sdk_base::ruma::events::macros::EventContent;
use serde::{Deserialize, Serialize};
use std::str::FromStr;
use strum::{Display, EnumString, ParseError};

#[derive(Clone, Debug, Deserialize, Serialize, Display, EnumString)]
#[strum(serialize_all = "camelCase")]
pub enum AutoDownload {
    Always,
    WifiOnly,
    Never,
}

#[derive(Clone, Debug, Deserialize, Serialize, Default)]
pub struct AppChatSettings {
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub auto_download: Option<AutoDownload>,
    #[serde(default, skip_serializing_if = "Option::is_none")]
    pub typing_notice: Option<bool>,
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct AppNotificationSettings {
    pub auto_subscribe_on_activity: bool,
}

impl AppNotificationSettings {
    fn is_empty(&self) -> bool {
        self.auto_subscribe_on_activity
    }
}
impl Default for AppNotificationSettings {
    fn default() -> Self {
        Self {
            auto_subscribe_on_activity: true,
        }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder, Default)]
#[ruma_event(type = "global.acter.user_app_settings", kind = GlobalAccountData)]
pub struct ActerUserAppSettingsContent {
    #[serde(default)]
    pub chat: AppChatSettings,
    #[serde(default, skip_serializing_if = "AppNotificationSettings::is_empty")]
    pub notifications: AppNotificationSettings,
}

impl ActerUserAppSettingsContent {
    pub fn updater(&self) -> ActerUserAppSettingsContentBuilder {
        ActerUserAppSettingsContentBuilder::default()
            .chat(self.chat.clone())
            .notifications(self.notifications.clone())
            .to_owned()
    }
}

impl ActerUserAppSettingsContentBuilder {
    pub fn auto_download_chat(&mut self, new_value: String) -> Result<&mut Self, ParseError> {
        let auto_d = AutoDownload::from_str(&new_value)?;
        if let Some(chat) = &mut self.chat {
            chat.auto_download = Some(auto_d);
        } else {
            self.chat = Some(AppChatSettings {
                auto_download: Some(auto_d),
                typing_notice: Default::default(),
            });
        }
        Ok(self)
    }

    pub fn auto_subscribe_on_activity(&mut self, value: bool) -> Result<&mut Self, ParseError> {
        if let Some(notifications) = &mut self.notifications {
            notifications.auto_subscribe_on_activity = value;
        } else {
            self.notifications = Some(AppNotificationSettings {
                auto_subscribe_on_activity: value,
            });
        }
        Ok(self)
    }

    pub fn typing_notice(&mut self, value: bool) -> Result<&mut Self, ParseError> {
        if let Some(chat) = &mut self.chat {
            chat.typing_notice = Some(value);
        } else {
            self.chat = Some(AppChatSettings {
                auto_download: Default::default(),
                typing_notice: Some(value),
            });
        }

        Ok(self)
    }
}
