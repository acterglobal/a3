use acter_core::{
    events::{
        pins::{self, PinBuilder},
        Icon,
    },
    models::{self, ActerModel, AnyActerModel},
    statics::KEYS,
};
use anyhow::{bail, Context, Result};
use futures::stream::StreamExt;
use matrix_sdk::{room::Room, RoomState};
use ruma_common::{OwnedEventId, OwnedRoomId, OwnedUserId};
use ruma_events::{room::message::TextMessageEventContent, MessageLikeEventType};
use std::{
    collections::{hash_map::Entry, HashMap},
    ops::Deref,
};
use tokio::sync::broadcast::Receiver;
use tokio_stream::{wrappers::BroadcastStream, Stream};
use tracing::warn;

use crate::MsgContent;

use super::{client::Client, spaces::Space, RUNTIME};

impl Client {
    pub async fn wait_for_pin(&self, key: String, timeout: Option<u8>) -> Result<Pin> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let AnyActerModel::Pin(content) = me.wait_for(key.clone(), timeout).await? else {
                    bail!("{key} is not a pin");
                };
                let room = me.room_by_id_typed(content.room_id())?;
                Ok(Pin {
                    client: me.clone(),
                    room,
                    content,
                })
            })
            .await?
    }

    pub async fn pins(&self) -> Result<Vec<Pin>> {
        let mut pins = Vec::new();
        let mut rooms_map: HashMap<OwnedRoomId, Room> = HashMap::new();
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let client = me.core.client();
                for mdl in me.store().get_list(KEYS::PINS).await? {
                    if let AnyActerModel::Pin(t) = mdl {
                        let room_id = t.room_id().to_owned();
                        let room = match rooms_map.entry(room_id) {
                            Entry::Occupied(t) => t.get().clone(),
                            Entry::Vacant(e) => {
                                if let Some(room) = client.get_room(e.key()) {
                                    e.insert(room.clone());
                                    room
                                } else {
                                    /// User not part of the room anymore, ignore
                                    continue;
                                }
                            }
                        };
                        pins.push(Pin {
                            client: me.clone(),
                            room,
                            content: t,
                        })
                    } else {
                        warn!("Non pin model found in `pins` index: {:?}", mdl);
                    }
                }
                Ok(pins)
            })
            .await?
    }

    pub async fn pin(&self, pin_id: String) -> Result<Pin> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let AnyActerModel::Pin(t) = me.store().get(&pin_id).await? else {
                    bail!("Ping not found");
                };
                let room = me.room_by_id_typed(t.room_id())?;
                Ok(Pin {
                    client: me,
                    room,
                    content: t,
                })
            })
            .await?
    }

    pub async fn pinned_links(&self) -> Result<Vec<Pin>> {
        let mut pins = Vec::new();
        let mut rooms_map: HashMap<OwnedRoomId, Room> = HashMap::new();
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let client = me.core.client();
                for mdl in me.store().get_list(KEYS::PINS).await? {
                    if let AnyActerModel::Pin(pin) = mdl {
                        if !pin.is_link() {
                            continue;
                        }
                        let room_id = pin.room_id().to_owned();
                        let room = match rooms_map.entry(room_id) {
                            Entry::Occupied(t) => t.get().clone(),
                            Entry::Vacant(e) => {
                                if let Some(room) = client.get_room(e.key()) {
                                    e.insert(room.clone());
                                    room
                                } else {
                                    /// User not part of the room anymore, ignore
                                    continue;
                                }
                            }
                        };
                        pins.push(Pin {
                            client: me.clone(),
                            room,
                            content: pin,
                        })
                    } else {
                        warn!("Non pin model found in `pins` index: {:?}", mdl);
                    }
                }
                Ok(pins)
            })
            .await?
    }
}

impl Space {
    pub async fn pins(&self) -> Result<Vec<Pin>> {
        let mut pins = Vec::new();
        let room_id = self.room_id().to_owned();
        let client = self.client.clone();
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                let k = format!("{room_id}::{}", KEYS::PINS);
                for mdl in client.store().get_list(&k).await? {
                    if let AnyActerModel::Pin(t) = mdl {
                        pins.push(Pin {
                            client: client.clone(),
                            room: room.clone(),
                            content: t,
                        })
                    } else {
                        warn!("Non pin model found in `pins` index: {:?}", mdl);
                    }
                }
                Ok(pins)
            })
            .await?
    }

    pub async fn pinned_links(&self) -> Result<Vec<Pin>> {
        let mut pins = Vec::new();
        let room_id = self.room_id().to_owned();
        let client = self.client.clone();
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                let k = format!("{room_id}::{}", KEYS::PINS);
                for mdl in client.store().get_list(&k).await? {
                    if let AnyActerModel::Pin(pin) = mdl {
                        if pin.is_link() {
                            pins.push(Pin {
                                client: client.clone(),
                                room: room.clone(),
                                content: pin,
                            })
                        }
                    } else {
                        warn!("Non pin model found in `pins` index: {:?}", mdl);
                    }
                }
                Ok(pins)
            })
            .await?
    }
}

#[derive(Clone, Debug)]
pub struct Pin {
    client: Client,
    room: Room,
    content: models::Pin,
}

impl Deref for Pin {
    type Target = models::Pin;
    fn deref(&self) -> &Self::Target {
        &self.content
    }
}

/// helpers for content
impl Pin {
    pub fn title(&self) -> String {
        self.content.title.clone()
    }

    pub fn has_formatted_text(&self) -> bool {
        matches!(
            self.content.content(),
            Some(TextMessageEventContent {
                formatted: Some(_),
                ..
            })
        )
    }

    pub fn content_formatted(&self) -> Option<String> {
        self.content
            .content
            .as_ref()
            .and_then(|t| t.formatted.clone().map(|f| f.body))
    }

    pub fn content(&self) -> Option<MsgContent> {
        self.content.content.as_ref().map(MsgContent::from)
    }

    pub fn url(&self) -> Option<String> {
        self.content.url.clone()
    }

    pub fn color(&self) -> Option<u32> {
        self.content.display.as_ref().and_then(|t| t.color)
    }

    pub fn icon(&self) -> Option<Icon> {
        self.content.display.as_ref().and_then(|t| t.icon.clone())
    }

    pub fn section(&self) -> Option<String> {
        self.content
            .display
            .as_ref()
            .and_then(|t| t.section.clone())
    }

    pub fn event_id_str(&self) -> String {
        self.content.event_id().to_string()
    }

    pub fn room_id_str(&self) -> String {
        self.content.room_id().to_string()
    }

    pub fn sender(&self) -> OwnedUserId {
        self.content.sender().to_owned()
    }
}

/// Custom functions
impl Pin {
    pub async fn refresh(&self) -> Result<Pin> {
        let key = self.content.event_id().to_string();
        let client = self.client.clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let AnyActerModel::Pin(content) = client.store().get(&key).await? else {
                    bail!("Refreshing failed. {key} not a pin")
                };
                Ok(Pin {
                    client,
                    room,
                    content,
                })
            })
            .await?
    }

    fn is_joined(&self) -> bool {
        matches!(self.room.state(), RoomState::Joined)
    }

    pub fn update_builder(&self) -> Result<PinUpdateBuilder> {
        if !self.is_joined() {
            bail!("Can only update pins in joined rooms");
        }
        Ok(PinUpdateBuilder {
            client: self.client.clone(),
            room: self.room.clone(),
            content: self.content.updater(),
        })
    }

    pub fn subscribe_stream(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.subscribe()).map(|_| true)
    }

    pub fn subscribe(&self) -> Receiver<()> {
        let key = self.content.event_id().to_string();
        self.client.subscribe(key)
    }

    pub async fn comments(&self) -> Result<crate::CommentsManager> {
        let client = self.client.clone();
        let room = self.room.clone();
        let event_id = self.content.event_id().to_owned();
        crate::CommentsManager::new(client, room, event_id).await
    }

    pub async fn attachments(&self) -> Result<crate::AttachmentsManager> {
        let client = self.client.clone();
        let room = self.room.clone();
        let event_id = self.content.event_id().to_owned();
        crate::AttachmentsManager::new(client, room, event_id).await
    }
}

#[derive(Clone)]
pub struct PinDraft {
    client: Client,
    room: Room,
    content: PinBuilder,
}

impl PinDraft {
    pub fn title(&mut self, title: String) -> &mut Self {
        self.content.title(title);
        self
    }

    pub fn content_text(&mut self, body: String) -> &mut Self {
        self.content
            .content(Some(TextMessageEventContent::plain(body)));
        self
    }

    pub fn content_markdown(&mut self, body: String) -> &mut Self {
        self.content
            .content(Some(TextMessageEventContent::markdown(body)));
        self
    }

    pub fn content_html(&mut self, body: String, html_body: String) -> &mut Self {
        self.content
            .content(Some(TextMessageEventContent::html(body, html_body)));
        self
    }

    pub fn unset_content(&mut self) -> &mut Self {
        self.content.content(None);
        self
    }

    pub fn url(&mut self, url: String) -> &mut Self {
        self.content.url(Some(url));
        self
    }

    pub fn unset_url(&mut self) -> &mut Self {
        self.content.url(None);
        self
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let my_id = self.client.user_id()?;
        let content = self.content.build()?;

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::RoomMessage)
                    .await?;
                if !permitted {
                    bail!("No permissions to send message in this room");
                }
                let response = room.send(content).await?;
                Ok(response.event_id)
            })
            .await?
    }
}

#[derive(Clone)]
pub struct PinUpdateBuilder {
    client: Client,
    room: Room,
    content: pins::PinUpdateBuilder,
}

impl PinUpdateBuilder {
    pub fn title(&mut self, title: String) -> &mut Self {
        self.content.title(Some(title));
        self
    }

    pub fn unset_title_update(&mut self) -> &mut Self {
        self.content.title(None);
        self
    }

    pub fn content_text(&mut self, body: String) -> &mut Self {
        self.content
            .content(Some(Some(TextMessageEventContent::plain(body))));
        self
    }

    pub fn content_markdown(&mut self, body: String) -> &mut Self {
        self.content
            .content(Some(Some(TextMessageEventContent::markdown(body))));
        self
    }

    pub fn content_html(&mut self, body: String, html_body: String) -> &mut Self {
        self.content
            .content(Some(Some(TextMessageEventContent::html(body, html_body))));
        self
    }

    pub fn unset_content(&mut self) -> &mut Self {
        self.content.content(Some(None));
        self
    }

    pub fn unset_content_update(&mut self) -> &mut Self {
        self.content
            .content(None::<Option<TextMessageEventContent>>);
        self
    }

    pub fn url(&mut self, url: String) -> &mut Self {
        self.content.url(Some(Some(url)));
        self
    }

    pub fn unset_url(&mut self) -> &mut Self {
        self.content.url(Some(None));
        self
    }

    pub fn unset_url_update(&mut self) -> &mut Self {
        self.content.url(None::<Option<String>>);
        self
    }

    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let my_id = self.client.user_id()?;
        let content = self.content.build()?;

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::RoomMessage)
                    .await?;
                if !permitted {
                    bail!("No permissions to send message in this room");
                }
                let response = room.send(content).await?;
                Ok(response.event_id)
            })
            .await?
    }
}

impl Space {
    pub fn pin_draft(&self) -> Result<PinDraft> {
        if !self.is_joined() {
            bail!("Unable to create pins for spaces we are not part on");
        }
        Ok(PinDraft {
            client: self.client.clone(),
            room: self.inner.room.clone(),
            content: Default::default(),
        })
    }

    pub fn pin_draft_with_builder(&self, content: PinBuilder) -> Result<PinDraft> {
        if !self.is_joined() {
            bail!("Unable to create pins for spaces we are not part on");
        }
        Ok(PinDraft {
            client: self.client.clone(),
            room: self.inner.room.clone(),
            content,
        })
    }
}
