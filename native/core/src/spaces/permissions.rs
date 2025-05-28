use matrix_sdk::ruma::{
    events::{
        room::power_levels::RoomPowerLevelsEventContent, StaticEventContent, TimelineEventType,
    },
    Int,
};
use serde::Deserialize;

use crate::events::{
    attachments::AttachmentEventContent,
    calendar::CalendarEventEventContent,
    comments::CommentEventContent,
    news::NewsEntryEventContent,
    pins::PinEventContent,
    rsvp::RsvpEventContent,
    settings::{
        ActerAppSettingsContent, SimpleOnOffSettingBuilder, SimpleSettingWithTurnOffBuilder,
    },
    stories::StoryEventContent,
    tasks::{TaskEventContent, TaskListEventContent},
};

pub fn new_app_permissions_builder() -> AppPermissionsBuilder {
    AppPermissionsBuilder::new()
}

#[derive(Clone, Deserialize)]
pub struct AppPermissionsBuilder {
    #[serde(default = "ActerAppSettingsContent::creation_defaults")]
    pub(super) settings: ActerAppSettingsContent,
    #[serde(default)]
    pub(super) permissions: RoomPowerLevelsEventContent,
}

impl Default for AppPermissionsBuilder {
    fn default() -> Self {
        Self {
            settings: ActerAppSettingsContent::creation_defaults(),
            permissions: RoomPowerLevelsEventContent::default(),
        }
    }
}

impl AppPermissionsBuilder {
    pub fn new() -> Self {
        AppPermissionsBuilder::default()
    }

    pub(crate) fn unpack(self) -> (ActerAppSettingsContent, RoomPowerLevelsEventContent) {
        let AppPermissionsBuilder {
            settings,
            mut permissions,
        } = self;
        if settings.news().active() {
            permissions
                .events
                .entry(<NewsEntryEventContent as StaticEventContent>::TYPE.into())
                .or_insert_with(|| Int::from(100));
        }
        if settings.stories().active() {
            permissions
                .events
                .entry(<StoryEventContent as StaticEventContent>::TYPE.into())
                .or_insert_with(|| Int::from(0));
        }
        if settings.events().active() {
            permissions
                .events
                .entry(<CalendarEventEventContent as StaticEventContent>::TYPE.into())
                .or_insert_with(|| Int::from(0));
            permissions
                .events
                .entry(<RsvpEventContent as StaticEventContent>::TYPE.into())
                .or_insert_with(|| Int::from(0));
        }
        if settings.pins().active() {
            permissions
                .events
                .entry(<PinEventContent as StaticEventContent>::TYPE.into())
                .or_insert_with(|| Int::from(0));
        }
        if settings.tasks().active() {
            permissions
                .events
                .entry(<TaskListEventContent as StaticEventContent>::TYPE.into())
                .or_insert_with(|| Int::from(0));

            permissions
                .events
                .entry(<TaskEventContent as StaticEventContent>::TYPE.into())
                .or_insert_with(|| Int::from(0));
        }
        (settings, permissions)
    }

    // Settings functions
    pub fn news(&mut self, active: bool) -> &mut Self {
        self.settings.news = Some(
            SimpleSettingWithTurnOffBuilder::default()
                .active(active)
                .build()
                .unwrap(),
        );
        self
    }

    pub fn stories(&mut self, active: bool) -> &mut Self {
        self.settings.stories = Some(
            SimpleOnOffSettingBuilder::default()
                .active(active)
                .build()
                .unwrap(),
        );
        self
    }

    pub fn pins(&mut self, active: bool) -> &mut Self {
        self.settings.pins = Some(
            SimpleSettingWithTurnOffBuilder::default()
                .active(active)
                .build()
                .unwrap(),
        );
        self
    }

    pub fn calendar_events(&mut self, active: bool) -> &mut Self {
        self.settings.events = Some(
            SimpleSettingWithTurnOffBuilder::default()
                .active(active)
                .build()
                .unwrap(),
        );
        self
    }

    pub fn tasks(&mut self, active: bool) -> &mut Self {
        self.settings.tasks = Some(
            SimpleOnOffSettingBuilder::default()
                .active(active)
                .build()
                .unwrap(),
        );
        self
    }

    fn set_for_key(&mut self, key: TimelineEventType, value: u32) {
        self.permissions.events.insert(key, Int::from(value));
    }

    pub fn news_permissions(&mut self, value: u32) -> &mut Self {
        self.set_for_key(
            <NewsEntryEventContent as StaticEventContent>::TYPE.into(),
            value,
        );
        self
    }

    pub fn stories_permissions(&mut self, value: u32) -> &mut Self {
        self.set_for_key(
            <StoryEventContent as StaticEventContent>::TYPE.into(),
            value,
        );
        self
    }

    pub fn calendar_events_permissions(&mut self, value: u32) -> &mut Self {
        self.set_for_key(
            <CalendarEventEventContent as StaticEventContent>::TYPE.into(),
            value,
        );
        self
    }

    pub fn task_lists_permissions(&mut self, value: u32) -> &mut Self {
        self.set_for_key(
            <TaskListEventContent as StaticEventContent>::TYPE.into(),
            value,
        );
        self
    }

    pub fn tasks_permissions(&mut self, value: u32) -> &mut Self {
        self.set_for_key(<TaskEventContent as StaticEventContent>::TYPE.into(), value);
        self
    }

    pub fn pins_permissions(&mut self, value: u32) -> &mut Self {
        self.set_for_key(<PinEventContent as StaticEventContent>::TYPE.into(), value);
        self
    }

    pub fn comments_permissions(&mut self, value: u32) -> &mut Self {
        self.set_for_key(
            <CommentEventContent as StaticEventContent>::TYPE.into(),
            value,
        );
        self
    }

    pub fn attachments_permissions(&mut self, value: u32) -> &mut Self {
        self.set_for_key(
            <AttachmentEventContent as StaticEventContent>::TYPE.into(),
            value,
        );
        self
    }

    pub fn rsvp_permissions(&mut self, value: u32) -> &mut Self {
        self.set_for_key(<RsvpEventContent as StaticEventContent>::TYPE.into(), value);
        self
    }

    pub fn events_default(&mut self, value: u32) -> &mut Self {
        self.permissions.events_default = Int::from(value);
        self
    }

    pub fn users_default(&mut self, value: u32) -> &mut Self {
        self.permissions.users_default = Int::from(value);
        self
    }

    pub fn state_default(&mut self, value: u32) -> &mut Self {
        self.permissions.state_default = Int::from(value);
        self
    }

    pub fn kick(&mut self, value: u32) -> &mut Self {
        self.permissions.kick = Int::from(value);
        self
    }

    pub fn ban(&mut self, value: u32) -> &mut Self {
        self.permissions.ban = Int::from(value);
        self
    }

    pub fn invite(&mut self, value: u32) -> &mut Self {
        self.permissions.invite = Int::from(value);
        self
    }

    pub fn redact(&mut self, value: u32) -> &mut Self {
        self.permissions.redact = Int::from(value);
        self
    }
}
