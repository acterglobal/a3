use derive_builder::Builder;
use ruma_events::EmptyStateKey;
use ruma_macros::EventContent;
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Deserialize, Serialize, Builder)]
pub struct SimpleSettingWithTurnOn {
    active: bool,
}

impl Default for SimpleSettingWithTurnOn {
    fn default() -> Self {
        SimpleSettingWithTurnOn { active: false }
    }
}

impl SimpleSettingWithTurnOn {
    pub fn active(&self) -> bool {
        self.active
    }
    pub fn updater(&self) -> SimpleSettingWithTurnOnBuilder {
        SimpleSettingWithTurnOnBuilder::default()
            .active(self.active)
            .to_owned()
    }
}

pub type NewsSettings = SimpleSettingWithTurnOn;
pub type PinsSettings = SimpleSettingWithTurnOn;
pub type EventsSettings = SimpleSettingWithTurnOn;
pub type TasksSettings = SimpleSettingWithTurnOn;

#[derive(Clone, Debug, Deserialize, Serialize, EventContent, Builder, Default)]
#[ruma_event(type = "global.acter.app_settings", kind = State, state_key_type = EmptyStateKey)]
pub struct ActerAppSettingsContent {
    news: Option<NewsSettings>,
    pins: Option<PinsSettings>,
    events: Option<EventsSettings>,
    tasks: Option<TasksSettings>,
}

impl ActerAppSettingsContent {
    pub fn news(&self) -> NewsSettings {
        self.news.clone().unwrap_or_default()
    }
    pub fn pins(&self) -> PinsSettings {
        self.pins.clone().unwrap_or_default()
    }
    pub fn events(&self) -> EventsSettings {
        self.events.clone().unwrap_or_default()
    }
    pub fn tasks(&self) -> TasksSettings {
        self.tasks.clone().unwrap_or_default()
    }

    pub fn updater(&self) -> ActerAppSettingsContentBuilder {
        ActerAppSettingsContentBuilder::default()
            .news(self.news.clone())
            .pins(self.pins.clone())
            .events(self.events.clone())
            .tasks(self.tasks.clone())
            .to_owned()
    }
}
