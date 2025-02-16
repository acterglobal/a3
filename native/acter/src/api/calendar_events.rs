use acter_core::{
    events::{
        calendar::{
            self as calendar_events, CalendarEventBuilder, EventLocation, EventLocationInfo,
        },
        rsvp::RsvpStatus,
        CalendarEventRefPreview, RefDetails as CoreRefDetails, UtcDateTime,
    },
    models::{self, can_redact, ActerModel, AnyActerModel},
    referencing::{IndexKey, SectionIndex},
};
use anyhow::{bail, Result};
use chrono::DateTime;
use futures::{stream::StreamExt, FutureExt};
use icalendar::Calendar as iCalendar;
use matrix_sdk::room::Room;
use matrix_sdk::ruma::EventId;
use matrix_sdk_base::{
    ruma::{
        events::{room::message::TextMessageEventContent, MessageLikeEventType},
        OwnedEventId, OwnedRoomId, OwnedUserId,
    },
    RoomState,
};
use std::{
    collections::{hash_map::Entry, HashMap},
    ops::Deref,
};
use tokio::sync::broadcast::Receiver;
use tokio_stream::{wrappers::BroadcastStream, Stream};
use tracing::warn;

use super::{
    client::Client, common::OptionRsvpStatus, deep_linking::RefDetails, spaces::Space, RUNTIME,
};

impl Client {
    pub async fn wait_for_calendar_event(
        &self,
        key: String,
        timeout: Option<u8>,
    ) -> Result<CalendarEvent> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let AnyActerModel::CalendarEvent(inner) = me.wait_for(key.clone(), timeout).await?
                else {
                    bail!("{key} is not a calendar_event");
                };
                let room = me.room_by_id_typed(inner.room_id())?;
                Ok(CalendarEvent::new(me.clone(), room, inner))
            })
            .await?
    }

    pub async fn calendar_event(&self, calendar_id: String) -> Result<CalendarEvent> {
        let me = self.clone();
        self.model_with_room(EventId::parse(calendar_id)?)
            .await
            .map(|(model, room)| CalendarEvent::new(me, room, model))
    }

    pub async fn calendar_events(&self) -> Result<Vec<CalendarEvent>> {
        let me = self.clone();
        Ok(self
            .models_of_list_with_room(IndexKey::Section(SectionIndex::Calendar))
            .await?
            .map(|(inner, room)| CalendarEvent::new(self.clone(), room, inner))
            .collect())
    }
}

impl Space {
    pub async fn calendar_events(&self) -> Result<Vec<CalendarEvent>> {
        let client = self.client.clone();
        let room = self.room.clone();
        Ok(client
            .models_of_list_with_room_under_check(
                IndexKey::RoomSection(room.room_id().to_owned(), SectionIndex::Calendar),
                move |_r| Ok(room.clone()),
            )
            .await?
            .map(|(inner, room)| CalendarEvent::new(client.clone(), room, inner))
            .collect())
    }
}

#[derive(Clone, Debug)]
pub struct CalendarEvent {
    client: Client,
    room: Room,
    inner: models::CalendarEvent,
}

impl PartialEq for CalendarEvent {
    fn eq(&self, other: &Self) -> bool {
        self.inner.event_id() == other.inner.event_id()
    }
}

impl Eq for CalendarEvent {}

impl PartialOrd for CalendarEvent {
    fn partial_cmp(&self, other: &Self) -> Option<std::cmp::Ordering> {
        Some(self.cmp(other))
    }
}

impl Ord for CalendarEvent {
    fn cmp(&self, other: &Self) -> std::cmp::Ordering {
        self.inner.utc_start.cmp(&other.inner.utc_start)
    }
}

impl Deref for CalendarEvent {
    type Target = models::CalendarEvent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

/// helpers for inner
impl CalendarEvent {
    pub fn event_id(&self) -> OwnedEventId {
        self.inner.event_id().to_owned()
    }

    pub fn room_id_str(&self) -> String {
        self.inner.room_id().to_string()
    }

    pub fn sender(&self) -> OwnedUserId {
        self.inner.sender().to_owned()
    }
}

/// Custom functions
impl CalendarEvent {
    pub(crate) fn new(client: Client, room: Room, inner: models::CalendarEvent) -> Self {
        CalendarEvent {
            client,
            room,
            inner,
        }
    }

    pub async fn refresh(&self) -> Result<CalendarEvent> {
        let key = self.inner.event_id().to_owned();
        let client = self.client.clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let AnyActerModel::CalendarEvent(inner) = client.store().get(&key).await? else {
                    bail!("Refreshing failed. {key} not a calendar_event")
                };
                Ok(CalendarEvent::new(client, room, inner))
            })
            .await?
    }

    pub async fn can_redact(&self) -> Result<bool> {
        let sender = self.inner.sender().to_owned();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move { Ok(can_redact(&room, &sender).await?) })
            .await?
    }

    fn is_joined(&self) -> bool {
        matches!(self.room.state(), RoomState::Joined)
    }

    pub fn update_builder(&self) -> Result<CalendarEventUpdateBuilder> {
        if !self.is_joined() {
            bail!("Can only update calendar_events in joined rooms");
        }
        Ok(CalendarEventUpdateBuilder {
            client: self.client.clone(),
            room: self.room.clone(),
            inner: self.inner.updater(),
        })
    }

    pub fn subscribe_stream(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.subscribe()).map(|f| true)
    }

    pub fn subscribe(&self) -> Receiver<()> {
        let key = self.inner.event_id().to_owned();
        self.client.subscribe(key)
    }

    pub async fn comments(&self) -> Result<crate::CommentsManager> {
        let client = self.client.clone();
        let room = self.room.clone();
        let event_id = self.inner.event_id().to_owned();
        crate::CommentsManager::new(client, room, event_id).await
    }

    pub async fn attachments(&self) -> Result<crate::AttachmentsManager> {
        let client = self.client.clone();
        let room = self.room.clone();
        let event_id = self.inner.event_id().to_owned();
        crate::AttachmentsManager::new(client, room, event_id).await
    }

    pub async fn rsvps(&self) -> Result<crate::RsvpManager> {
        let client = self.client.clone();
        let room = self.room.clone();
        let event_id = self.inner.event_id().to_owned();
        crate::RsvpManager::new(client, room, event_id).await
    }

    pub async fn reactions(&self) -> Result<crate::ReactionManager> {
        let client = self.client.clone();
        let room = self.room.clone();
        let event_id = self.inner.event_id().to_owned();
        crate::ReactionManager::new(client, room, event_id).await
    }

    pub async fn participants(&self) -> Result<Vec<String>> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let manager = me.rsvps().await?;
                let users = manager
                    .users_at_status_typed(RsvpStatus::Yes)
                    .await?
                    .into_iter()
                    .map(|u| u.to_string())
                    .collect();
                Ok(users)
            })
            .await?
    }

    pub fn physical_locations(&self) -> Vec<EventLocationInfo> {
        let calendar_event = self.clone();
        calendar_event
            .inner
            .locations()
            .iter()
            .filter(|e| matches!(e, EventLocation::Physical { .. }))
            .map(EventLocationInfo::new)
            .collect::<Vec<_>>()
    }

    pub fn virtual_locations(&self) -> Vec<EventLocationInfo> {
        let calendar_event = self.clone();
        calendar_event
            .inner
            .locations()
            .iter()
            .filter(|e| matches!(e, EventLocation::Virtual { .. }))
            .map(EventLocationInfo::new)
            .collect::<Vec<_>>()
    }

    pub fn locations(&self) -> Vec<EventLocationInfo> {
        let calendar_event = self.clone();
        let locations = calendar_event.inner.locations();
        locations.iter().map(EventLocationInfo::new).collect()
    }

    pub async fn responded_by_me(&self) -> Result<OptionRsvpStatus> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let manager = me.rsvps().await?;
                manager.responded_by_me().await
            })
            .await?
    }

    pub fn ical_for_sharing(&self, file_name: String) -> Result<bool> {
        let ical_data: String = (&iCalendar::from([self.inner.as_ical_event()])).try_into()?;
        std::fs::write(file_name, ical_data)?;
        Ok(true)
    }

    pub async fn ref_details(&self) -> Result<RefDetails> {
        let room = self.room.clone();
        let client = self.client.deref().clone();
        let target_id = self.inner.event_id().to_owned();
        let room_id = self.room.room_id().to_owned();
        let title = self.inner.title.clone();
        let start_at_utc = self.inner.utc_start;
        let participants = self.participants().await?.len() as u32;

        RUNTIME
            .spawn(async move {
                let via = room.route().await?;
                let room_display_name = room.cached_display_name();
                Ok(RefDetails::new(
                    client,
                    CoreRefDetails::CalendarEvent {
                        target_id,
                        room_id: Some(room_id),
                        via,
                        preview: CalendarEventRefPreview::new(
                            Some(title),
                            room_display_name,
                            Some(participants),
                            Some(start_at_utc),
                        ),
                        action: Default::default(),
                    },
                ))
            })
            .await?
    }
}

#[derive(Clone)]
pub struct CalendarEventDraft {
    client: Client,
    room: Room,
    inner: CalendarEventBuilder,
}

impl CalendarEventDraft {
    pub fn title(&mut self, title: String) -> &mut Self {
        self.inner.title(title);
        self
    }

    pub fn description_text(&mut self, body: String) -> &mut Self {
        let desc = TextMessageEventContent::plain(body);
        self.inner.description(Some(desc));
        self
    }

    pub fn description_html(&mut self, body: String, html_body: String) -> &mut Self {
        let desc = TextMessageEventContent::html(body, html_body);
        self.inner.description(Some(desc));
        self
    }

    pub fn unset_description(&mut self) -> &mut Self {
        self.inner.description(None);
        self
    }

    pub fn utc_start_from_rfc3339(&mut self, utc_start: String) -> Result<()> {
        let dt: UtcDateTime = DateTime::parse_from_rfc3339(&utc_start)?.into();
        self.inner.utc_start(dt);
        Ok(())
    }

    pub fn utc_start_from_rfc2822(&mut self, utc_start: String) -> Result<()> {
        let dt: UtcDateTime = DateTime::parse_from_rfc2822(&utc_start)?.into();
        self.inner.utc_start(dt);
        Ok(())
    }

    pub fn utc_start_from_format(&mut self, utc_start: String, format: String) -> Result<()> {
        let dt: UtcDateTime = DateTime::parse_from_str(&utc_start, &format)?.into();
        self.inner.utc_start(dt);
        Ok(())
    }

    pub fn utc_end_from_rfc3339(&mut self, utc_end: String) -> Result<()> {
        let dt: UtcDateTime = DateTime::parse_from_rfc3339(&utc_end)?.into();
        self.inner.utc_end(dt);
        Ok(())
    }

    pub fn utc_end_from_rfc2822(&mut self, utc_end: String) -> Result<()> {
        let dt: UtcDateTime = DateTime::parse_from_rfc2822(&utc_end)?.into();
        self.inner.utc_end(dt);
        Ok(())
    }

    pub fn utc_end_from_format(&mut self, utc_end: String, format: String) -> Result<()> {
        let dt: UtcDateTime = DateTime::parse_from_str(&utc_end, &format)?.into();
        self.inner.utc_end(dt);
        Ok(())
    }

    pub fn physical_location(
        &mut self,
        name: Option<String>,
        description: Option<String>,
        description_html: Option<String>,
        cooridnates: Option<String>,
        uri: Option<String>,
    ) -> Result<()> {
        let mut desc_plain = None;
        let mut desc_html = None;
        if let Some(ref desc) = description {
            if !desc.is_empty() {
                desc_plain = Some(TextMessageEventContent::plain(desc.clone()));
                desc_html =
                    description_html.map(|html| TextMessageEventContent::html(desc.clone(), html));
            }
        }
        let inner = EventLocation::Physical {
            name,
            description: desc_html.or(desc_plain),
            // TODO: add icon support
            icon: None,
            coordinates: cooridnates,
            uri: uri.clone(),
        };
        let loc_info = EventLocationInfo { inner };
        // convert object to enum and push it
        self.inner.into_event_loc(&loc_info);
        Ok(())
    }

    pub fn virtual_location(
        &mut self,
        name: Option<String>,
        description: Option<String>,
        description_html: Option<String>,
        uri: String,
    ) -> Result<()> {
        let calendar_event = self.inner.clone();
        let mut desc_plain = None;
        let mut desc_html = None;
        if let Some(ref desc) = description {
            if !desc.is_empty() {
                desc_plain = Some(TextMessageEventContent::plain(desc.clone()));
                desc_html =
                    description_html.map(|html| TextMessageEventContent::html(desc.clone(), html));
            }
        }

        let inner = EventLocation::Virtual {
            name,
            description: desc_html.or(desc_plain),
            // TODO: add icon support
            icon: None,
            uri,
        };
        let event_location = EventLocationInfo { inner };
        // convert object to enum and push it
        self.inner.into_event_loc(&event_location);
        Ok(())
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let my_id = self.client.user_id()?;
        let inner = self.inner.build()?;

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::RoomMessage)
                    .await?;
                if !permitted {
                    bail!("No permissions to send message in this room");
                }
                let response = room.send(inner).await?;
                Ok(response.event_id)
            })
            .await?
    }
}

#[derive(Clone)]
pub struct CalendarEventUpdateBuilder {
    client: Client,
    room: Room,
    inner: calendar_events::CalendarEventUpdateBuilder,
}

impl CalendarEventUpdateBuilder {
    pub fn title(&mut self, title: String) -> &mut Self {
        self.inner.title(Some(title));
        self
    }

    pub fn unset_title_update(&mut self) -> &mut Self {
        self.inner.title(None);
        self
    }

    pub fn description_text(&mut self, body: String) -> &mut Self {
        let desc = TextMessageEventContent::plain(body);
        self.inner.description(Some(Some(desc)));
        self
    }

    pub fn description_html(&mut self, body: String, html_body: String) -> &mut Self {
        let desc = TextMessageEventContent::html(body, html_body);
        self.inner.description(Some(Some(desc)));
        self
    }

    pub fn unset_description(&mut self) -> &mut Self {
        self.inner.description(Some(None));
        self
    }

    pub fn unset_description_update(&mut self) -> &mut Self {
        self.inner
            .description(None::<Option<TextMessageEventContent>>);
        self
    }

    pub fn utc_start_from_rfc3339(&mut self, utc_start: String) -> Result<()> {
        let dt = DateTime::parse_from_rfc3339(&utc_start)?.into();
        self.inner.utc_start(Some(dt));
        Ok(())
    }

    pub fn utc_start_from_rfc2822(&mut self, utc_start: String) -> Result<()> {
        let dt = DateTime::parse_from_rfc2822(&utc_start)?.into();
        self.inner.utc_start(Some(dt));
        Ok(())
    }

    pub fn utc_start_from_format(&mut self, utc_start: String, format: String) -> Result<()> {
        let dt = DateTime::parse_from_str(&utc_start, &format)?.into();
        self.inner.utc_start(Some(dt));
        Ok(())
    }

    pub fn unset_utc_start_update(&mut self) -> &mut Self {
        self.inner.utc_start(None);
        self
    }

    pub fn utc_end_from_rfc3339(&mut self, utc_end: String) -> Result<()> {
        let dt = DateTime::parse_from_rfc3339(&utc_end)?.into();
        self.inner.utc_end(Some(dt));
        Ok(())
    }

    pub fn utc_end_from_rfc2822(&mut self, utc_end: String) -> Result<()> {
        let dt = DateTime::parse_from_rfc2822(&utc_end)?.into();
        self.inner.utc_end(Some(dt));
        Ok(())
    }

    pub fn utc_end_from_format(&mut self, utc_end: String, format: String) -> Result<()> {
        let dt = DateTime::parse_from_str(&utc_end, &format)?.into();
        self.inner.utc_end(Some(dt));
        Ok(())
    }

    pub fn unset_utc_end_update(&mut self) -> &mut Self {
        self.inner.utc_end(None);
        self
    }

    pub fn unset_locations(&mut self) -> &mut Self {
        self.inner.locations(Some(vec![]));
        self
    }

    pub fn unset_locations_update(&mut self) -> &mut Self {
        self.inner.locations(None);
        self
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let my_id = self.client.user_id()?;
        let inner = self.inner.build()?;

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::RoomMessage)
                    .await?;
                if !permitted {
                    bail!("No permissions to send message in this room");
                }
                let response = room.send(inner).await?;
                Ok(response.event_id)
            })
            .await?
    }
}

impl Space {
    pub fn calendar_event_draft(&self) -> Result<CalendarEventDraft> {
        if !self.is_joined() {
            bail!("Unable to create calendar_events for spaces we are not part on");
        }
        Ok(CalendarEventDraft {
            client: self.client.clone(),
            room: self.inner.room.clone(),
            inner: Default::default(),
        })
    }

    pub fn calendar_event_draft_with_builder(
        &self,
        inner: CalendarEventBuilder,
    ) -> Result<CalendarEventDraft> {
        if !self.is_joined() {
            bail!("Unable to create calendar_events for spaces we are not part on");
        }
        Ok(CalendarEventDraft {
            client: self.client.clone(),
            room: self.inner.room.clone(),
            inner,
        })
    }
}
