use std::ops::Deref;

pub use acter_core::events::settings::{
    ActerAppSettingsContent, EventsSettings, NewsSettings, PinsSettings, SimpleSettingWithTurnOff,
    SimpleSettingWithTurnOffBuilder,
};

use acter_core::events::settings::ActerAppSettingsContentBuilder;
use anyhow::{bail, Result};
use matrix_sdk::{
    deserialized_responses::SyncOrStrippedState,
    room::{Messages, MessagesOptions, Room as SdkRoom},
};
use ruma::events::SyncStateEvent;

use crate::Room;
use crate::RUNTIME;

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

impl From<ActerAppSettingsContent> for ActerAppSettings {
    fn from(inner: ActerAppSettingsContent) -> Self {
        ActerAppSettings { inner }
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
        Ok(self.app_settings_content().await?.into())
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
            bail!("You don't have permissions to change the app settings");
        }

        let client = self.room.client().clone();
        let SdkRoom::Joined(joined) = &self.room else {
            bail!("You can't update a space you aren't part of");
        };
        let room = joined.clone();

        RUNTIME
            .spawn(async move {
                let response = room.send_state_event(actual_settings).await?;
                Ok(response.event_id.to_string())
            })
            .await?
    }
}
