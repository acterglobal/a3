mod space;
mod user;

pub static APP_SETTINGS_FIELD: &str = "global.acter.app_settings";
pub static APP_USER_SETTINGS: &str = "global.acter.user_app_settings";

pub use space::{
    ActerAppSettings, ActerAppSettingsContent, ActerAppSettingsContentBuilder,
    ActerAppSettingsContentBuilderError, EventsSettings, NewsSettings, PinsSettings,
    SimpleOnOffSetting, SimpleOnOffSettingBuilder, SimpleSettingWithTurnOff,
    SimpleSettingWithTurnOffBuilder, StoriesSettings, TasksSettings,
};
pub use user::{
    ActerUserAppSettingsContent, ActerUserAppSettingsContentBuilder, AppChatSettings, AutoDownload,
};
