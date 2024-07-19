use ruma_macros::EventContent;
use serde::{Deserialize, Serialize};

pub static USER_SETTINGS_KEY: &str = "global.acter.user_settings";

#[derive(Debug, Serialize, Default, Deserialize, Clone, EventContent)]
#[ruma_event(type = "global.acter.user_settings", kind = RoomAccountData)]
pub struct UserSettingsEventContent {
    #[serde(default)]
    pub has_seen_suggested: bool,
}
