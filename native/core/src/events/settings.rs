mod space;
mod user;

pub static APP_SETTINGS_FIELD: ExecuteReference = ExecuteReference::ModelType(Cow::Borrowed(
    <ActerAppSettingsContent as StaticEventContent>::TYPE,
));
pub static APP_USER_SETTINGS: ExecuteReference = ExecuteReference::ModelType(Cow::Borrowed(
    <ActerUserAppSettingsContent as StaticEventContent>::TYPE,
));

use std::borrow::Cow;

use matrix_sdk::ruma::events::StaticEventContent;
pub use space::{
    ActerAppSettings, ActerAppSettingsContent, ActerAppSettingsContentBuilder,
    ActerAppSettingsContentBuilderError, EventsSettings, NewsSettings, PinsSettings,
    SimpleOnOffSetting, SimpleOnOffSettingBuilder, SimpleSettingWithTurnOff,
    SimpleSettingWithTurnOffBuilder, StoriesSettings, TasksSettings,
};
pub use user::{
    ActerUserAppSettingsContent, ActerUserAppSettingsContentBuilder, AppChatSettings, AutoDownload,
};

use crate::referencing::ExecuteReference;
