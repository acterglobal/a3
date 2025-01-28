use matrix_sdk_base::ruma::events::macros::EventContent;
use serde::{Deserialize, Serialize};

pub static USER_SETTINGS_KEY: &str = "global.acter.user_settings";

struct BoolDefaults();

impl BoolDefaults {
    const fn default_true() -> bool {
        true
    }

    const fn default_false() -> bool {
        false
    }

    const fn is_true(value: &bool) -> bool {
        *value == true
    }

    const fn is_false(value: &bool) -> bool {
        *value == false
    }
}
#[derive(Debug, Serialize, Deserialize, Clone, EventContent)]
#[ruma_event(type = "global.acter.user_settings", kind = RoomAccountData)]
pub struct UserSettingsEventContent {
    #[serde(
        default = "BoolDefaults::default_false",
        skip_serializing_if = "BoolDefaults::is_false"
    )]
    pub has_seen_suggested: bool,

    #[serde(
        default = "BoolDefaults::default_true",
        skip_serializing_if = "BoolDefaults::is_true"
    )]
    pub include_cal_sync: bool,
}

impl Default for UserSettingsEventContent {
    fn default() -> Self {
        Self {
            has_seen_suggested: false,
            include_cal_sync: true,
        }
    }
}
