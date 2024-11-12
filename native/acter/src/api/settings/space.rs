pub use acter_core::events::settings::{
    ActerAppSettingsContent, EventsSettings, NewsSettings, PinsSettings, SimpleOnOffSetting,
    SimpleOnOffSettingBuilder, SimpleSettingWithTurnOff, SimpleSettingWithTurnOffBuilder,
    TasksSettings,
};
use acter_core::events::{
    attachments::AttachmentEventContent,
    calendar::CalendarEventEventContent,
    comments::CommentEventContent,
    news::NewsEntryEventContent,
    pins::PinEventContent,
    rsvp::RsvpEventContent,
    settings::ActerAppSettingsContentBuilder,
    tasks::{TaskEventContent, TaskListEventContent},
};
use anyhow::{bail, Context, Result};
use matrix_sdk::deserialized_responses::SyncOrStrippedState;
use matrix_sdk_base::ruma::{
    events::{
        room::power_levels::{RoomPowerLevels as RumaRoomPowerLevels, RoomPowerLevelsEventContent},
        StateEventType, StaticEventContent, SyncStateEvent, TimelineEventType,
    },
    Int,
};
use std::{collections::btree_map, ops::Deref};

use crate::{Room, RUNTIME};

#[derive(Clone)]
pub struct ActerAppSettingsBuilder {
    inner: ActerAppSettingsContentBuilder,
}

impl From<ActerAppSettingsContentBuilder> for ActerAppSettingsBuilder {
    fn from(inner: ActerAppSettingsContentBuilder) -> Self {
        ActerAppSettingsBuilder { inner }
    }
}
impl ActerAppSettingsBuilder {
    pub fn news(&mut self, value: Option<Box<SimpleSettingWithTurnOff>>) {
        self.inner.news(value.map(|i| *i));
    }
    pub fn pins(&mut self, value: Option<Box<SimpleSettingWithTurnOff>>) {
        self.inner.pins(value.map(|i| *i));
    }
    pub fn events(&mut self, value: Option<Box<SimpleSettingWithTurnOff>>) {
        self.inner.events(value.map(|i| *i));
    }
    pub fn tasks(&mut self, value: Option<Box<TasksSettings>>) {
        self.inner.tasks(value.map(|i| *i));
    }
}

pub struct RoomPowerLevels {
    inner: RumaRoomPowerLevels,
}

impl RoomPowerLevels {
    fn get_for_key(&self, key: TimelineEventType) -> Option<i64> {
        self.inner.events.get(&key).map(|i| (*i).into())
    }
    pub fn news(&self) -> Option<i64> {
        self.get_for_key(<NewsEntryEventContent as StaticEventContent>::TYPE.into())
    }
    pub fn news_key(&self) -> String {
        <NewsEntryEventContent as StaticEventContent>::TYPE.into()
    }
    pub fn events(&self) -> Option<i64> {
        self.get_for_key(<CalendarEventEventContent as StaticEventContent>::TYPE.into())
    }
    pub fn events_key(&self) -> String {
        <CalendarEventEventContent as StaticEventContent>::TYPE.into()
    }
    pub fn task_lists(&self) -> Option<i64> {
        self.get_for_key(<TaskListEventContent as StaticEventContent>::TYPE.into())
    }
    pub fn task_lists_key(&self) -> String {
        <TaskListEventContent as StaticEventContent>::TYPE.into()
    }
    pub fn tasks(&self) -> Option<i64> {
        self.get_for_key(<TaskEventContent as StaticEventContent>::TYPE.into())
    }
    pub fn tasks_key(&self) -> String {
        <TaskEventContent as StaticEventContent>::TYPE.into()
    }
    pub fn pins(&self) -> Option<i64> {
        self.get_for_key(<PinEventContent as StaticEventContent>::TYPE.into())
    }
    pub fn pins_key(&self) -> String {
        <PinEventContent as StaticEventContent>::TYPE.into()
    }
    pub fn comments(&self) -> Option<i64> {
        self.get_for_key(<CommentEventContent as StaticEventContent>::TYPE.into())
    }
    pub fn comments_key(&self) -> String {
        <CommentEventContent as StaticEventContent>::TYPE.into()
    }
    pub fn attachments(&self) -> Option<i64> {
        self.get_for_key(<AttachmentEventContent as StaticEventContent>::TYPE.into())
    }
    pub fn attachments_key(&self) -> String {
        <AttachmentEventContent as StaticEventContent>::TYPE.into()
    }
    pub fn rsvp(&self) -> Option<i64> {
        self.get_for_key(<RsvpEventContent as StaticEventContent>::TYPE.into())
    }
    pub fn rsvp_key(&self) -> String {
        <RsvpEventContent as StaticEventContent>::TYPE.into()
    }
    pub fn events_default(&self) -> i64 {
        self.inner.events_default.into()
    }
    pub fn users_default(&self) -> i64 {
        self.inner.users_default.into()
    }
    pub fn max_power_level(&self) -> i64 {
        self.inner.max().into()
    }
    pub fn kick(&self) -> i64 {
        self.inner.kick.into()
    }
    pub fn ban(&self) -> i64 {
        self.inner.ban.into()
    }
    pub fn invite(&self) -> i64 {
        self.inner.invite.into()
    }
    pub fn redact(&self) -> i64 {
        self.inner.redact.into()
    }
}

#[derive(Clone)]
pub struct ActerAppSettings {
    inner: ActerAppSettingsContent,
}

impl Deref for ActerAppSettings {
    type Target = ActerAppSettingsContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl ActerAppSettings {
    pub fn update_builder(&self) -> ActerAppSettingsBuilder {
        ActerAppSettingsBuilder {
            inner: self.inner.updater(),
        }
    }
}

impl Room {
    pub async fn app_settings(&self) -> Result<ActerAppSettings> {
        Ok(ActerAppSettings {
            inner: self.app_settings_content().await?,
        })
    }

    pub async fn power_levels(&self) -> Result<RoomPowerLevels> {
        Ok(RoomPowerLevels {
            inner: self.power_levels_content().await?,
        })
    }

    pub(crate) async fn power_levels_content(&self) -> Result<RumaRoomPowerLevels> {
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                let content = room
                    .get_state_event_static::<RoomPowerLevelsEventContent>()
                    .await?
                    .context("Power levels not set up")?
                    .deserialize()?;
                Ok(content.power_levels())
            })
            .await?
    }

    pub async fn update_regular_power_levels(
        &self,
        name: String,
        power_level: i32,
    ) -> Result<bool> {
        if !self.is_joined() {
            bail!("Unable to update a space you aren’t part of");
        }
        let mut current_power_levels = self.power_levels_content().await?;

        match name.to_lowercase().as_str() {
            "events_default" => {
                current_power_levels.events_default = Int::from(power_level);
            }
            "ban" => {
                current_power_levels.ban = Int::from(power_level);
            }
            "kick" => {
                current_power_levels.kick = Int::from(power_level);
            }
            "redact" => {
                current_power_levels.redact = Int::from(power_level);
            }
            "invite" => {
                current_power_levels.invite = Int::from(power_level);
            }
            "state_default" => {
                current_power_levels.state_default = Int::from(power_level);
            }
            _ => {
                bail!("Power level {name} unknown");
            }
        }
        self.update_power_levels(current_power_levels).await
    }

    pub async fn update_feature_power_levels(
        &self,
        name: String,
        power_level: Option<i32>,
    ) -> Result<bool> {
        if !self.is_joined() {
            bail!("Unable to update a space you aren’t part of");
        }
        let mut current_power_levels = self.power_levels_content().await?;
        let mut updated = false;
        match current_power_levels.events.entry(name.into()) {
            btree_map::Entry::Vacant(e) => {
                if let Some(p) = power_level {
                    e.insert(Int::from(p));
                    updated = true;
                }
            }
            btree_map::Entry::Occupied(mut e) => {
                if let Some(p) = power_level {
                    e.insert(Int::from(p));
                    updated = true;
                } else {
                    e.remove_entry();
                    updated = true;
                }
            }
        }

        if !updated {
            return Ok(false);
        }
        self.update_power_levels(current_power_levels).await
    }

    async fn update_power_levels(&self, current_power_levels: RumaRoomPowerLevels) -> Result<bool> {
        if !self
            .get_my_membership()
            .await?
            .can(crate::MemberPermission::CanUpdatePowerLevels)
        {
            bail!("No permissions to change the power levels");
        }

        let room = self.room.clone();
        let my_id = self.user_id()?;

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_state(&my_id, StateEventType::RoomPowerLevels)
                    .await?;
                if !permitted {
                    bail!("No permissions to change power levels in this room");
                }
                let response = room
                    .send_state_event(RoomPowerLevelsEventContent::from(current_power_levels))
                    .await?;
                Ok(true)
            })
            .await?
    }

    pub(crate) async fn app_settings_content(&self) -> Result<ActerAppSettingsContent> {
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                if let Some(a) = room
                    .get_state_event_static::<ActerAppSettingsContent>()
                    .await?
                {
                    if let Ok(SyncOrStrippedState::Sync(SyncStateEvent::Original(inner))) =
                        a.deserialize()
                    {
                        return Ok(inner.content);
                    }
                }
                Ok(ActerAppSettingsContent::default()) // all other cases we fall back to default
            })
            .await?
    }

    pub async fn update_app_settings(
        &self,
        new_settings: Box<ActerAppSettingsBuilder>,
    ) -> Result<String> {
        let actual_settings = new_settings.inner.build()?;

        if !self
            .get_my_membership()
            .await?
            .can(crate::MemberPermission::CanChangeAppSettings)
        {
            bail!("No permissions to change the app settings");
        }

        if !self.is_joined() {
            bail!("Unable to update a space you aren’t part of");
        }
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let response = room.send_state_event(actual_settings).await?;
                Ok(response.event_id.to_string())
            })
            .await?
    }
}
