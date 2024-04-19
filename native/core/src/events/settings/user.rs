use derive_builder::Builder;
use ruma_macros::EventContent;
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

#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder, Default)]
#[ruma_event(type = "global.acter.user_app_settings", kind = GlobalAccountData)]
pub struct ActerUserAppSettingsContent {
    #[serde(default)]
    pub chat: AppChatSettings,
}

impl ActerUserAppSettingsContent {
    pub fn updater(&self) -> ActerUserAppSettingsContentBuilder {
        ActerUserAppSettingsContentBuilder::default()
            .chat(self.chat.clone())
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
