use derive_builder::Builder;
use matrix_sdk_base::ruma::events::{macros::EventContent, EmptyStateKey};
use serde::{Deserialize, Serialize};

#[derive(Clone, Debug, Deserialize, Serialize, Builder)]
pub struct SimpleSettingWithTurnOff {
    active: bool,
}

impl Default for SimpleSettingWithTurnOff {
    fn default() -> Self {
        SimpleSettingWithTurnOff { active: true }
    }
}

impl SimpleSettingWithTurnOff {
    pub fn off() -> Option<Self> {
        Some(SimpleSettingWithTurnOff { active: false })
    }
    pub fn active(&self) -> bool {
        self.active
    }
    pub fn updater(&self) -> SimpleSettingWithTurnOffBuilder {
        SimpleSettingWithTurnOffBuilder::default()
            .active(self.active)
            .to_owned()
    }
}

#[derive(Clone, Debug, Deserialize, Serialize, Builder, Default)]
pub struct SimpleOnOffSetting {
    // default: off
    active: bool,
}
impl SimpleOnOffSetting {
    pub fn off() -> Option<Self> {
        // no need, we are off by default
        None
    }

    pub fn active(&self) -> bool {
        self.active
    }
    pub fn updater(&self) -> SimpleOnOffSettingBuilder {
        SimpleOnOffSettingBuilder::default()
            .active(self.active)
            .to_owned()
    }
}

pub type TasksSettings = SimpleOnOffSetting;
pub type NewsSettings = SimpleSettingWithTurnOff;
pub type PinsSettings = SimpleSettingWithTurnOff;
pub type EventsSettings = SimpleSettingWithTurnOff;

/// Backwards compatibility note:
///
/// In an earlier version, we agreed that if pins, news and events hadn't changed,
/// we'd assume they are activated. Even switching the default today means, we'd
/// change that behavior for all where at least _some_ had been changed. Thus, we
/// are keeping that behavior but _recommend_ using `off` to explicitly set
/// the right behavior up for all future cases.
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

    pub fn off() -> ActerAppSettingsContent {
        ActerAppSettingsContent {
            news: NewsSettings::off(),
            pins: PinsSettings::off(),
            events: EventsSettings::off(),
            tasks: TasksSettings::off(),
        }
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
