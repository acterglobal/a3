use acter_core::{
    events::{
        pins::{self, PinBuilder},
        Icon,
    },
    models::{self, ActerModel, AnyActerModel, Color},
    statics::KEYS,
};
use anyhow::{bail, Context, Result};
use async_broadcast::Receiver;
use core::time::Duration;
use matrix_sdk::{
    room::{Joined, Room},
    ruma::{events::room::message::TextMessageEventContent, OwnedEventId, OwnedRoomId},
};
use std::{
    collections::{hash_map::Entry, HashMap},
    ops::Deref,
};
use tracing::warn;

use super::{client::Client, spaces::Space, RUNTIME};

impl Client {
    pub async fn wait_for_pin(&self, key: String, timeout: Option<Box<Duration>>) -> Result<Pin> {
        let client = self.clone();
        RUNTIME
            .spawn(async move {
                let AnyActerModel::Pin(content) = client.wait_for(key.clone(), timeout).await? else {
                    bail!("{key} is not a pin");
                };
                let room = client
                    .core
                    .client()
                    .get_room(content.room_id())
                    .context("Room not found")?;
                Ok(Pin {
                    client: client.clone(),
                    room,
                    content,
                })
            })
            .await?
    }

    pub async fn pins(&self) -> Result<Vec<Pin>> {
        let mut pins = Vec::new();
        let mut rooms_map: HashMap<OwnedRoomId, Room> = HashMap::new();
        let client = self.clone();
        RUNTIME
            .spawn(async move {
                for mdl in client.store().get_list(KEYS::PINS).await? {
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
                            client: client.clone(),
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
        let client = self.clone();
        RUNTIME
            .spawn(async move {
                let AnyActerModel::Pin(t) = client.store().get(&pin_id).await? else {
                    bail!("Ping not found");
                };
                let room = client
                    .get_room(t.room_id())
                    .context("Room of pin not found")?;
                Ok(Pin {
                    client,
                    room,
                    content: t,
                })
            })
            .await?
    }

    pub async fn pinned_links(&self) -> Result<Vec<Pin>> {
        let mut pins = Vec::new();
        let mut rooms_map: HashMap<OwnedRoomId, Room> = HashMap::new();
        let client = self.clone();
        RUNTIME
            .spawn(async move {
                for mdl in client.store().get_list(KEYS::PINS).await? {
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
                            client: client.clone(),
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

    pub fn content_text(&self) -> Option<String> {
        self.content.content.as_ref().map(|t| t.body.clone())
    }

    pub fn url(&self) -> Option<String> {
        self.content.url.clone()
    }

    pub fn color(&self) -> Option<Color> {
        self.content.display.as_ref().and_then(|t| t.color.clone())
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

    pub fn update_builder(&self) -> Result<PinUpdateBuilder> {
        let Room::Joined(joined) = &self.room else {
            bail!("Can only update pins in joined rooms");
        };
        Ok(PinUpdateBuilder {
            client: self.client.clone(),
            room: joined.clone(),
            content: self.content.updater(),
        })
    }

    pub fn subscribe(&self) -> Receiver<()> {
        let key = self.content.event_id().to_string();
        self.client.executor().subscribe(key)
    }

    pub async fn comments(&self) -> Result<crate::CommentsManager> {
        let client = self.client.clone();
        let room = self.room.clone();
        let event_id = self.content.event_id().to_owned();

        RUNTIME
            .spawn(async move {
                let inner =
                    models::CommentsManager::from_store_and_event_id(client.store(), &event_id)
                        .await;
                Ok(crate::CommentsManager::new(client, room, inner))
            })
            .await?
    }

    pub async fn attachments(&self) -> Result<crate::AttachmentsManager> {
        let client = self.client.clone();
        let room = self.room.clone();
        let event_id = self.content.event_id().to_owned();

        RUNTIME
            .spawn(async move {
                let inner =
                    models::AttachmentsManager::from_store_and_event_id(client.store(), &event_id)
                        .await;
                Ok(crate::AttachmentsManager::new(client, room, inner))
            })
            .await?
    }
}

#[derive(Clone)]
pub struct PinDraft {
    client: Client,
    room: Joined,
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
        let content = self.content.build()?;
        RUNTIME
            .spawn(async move {
                let resp = room.send(content, None).await?;
                Ok(resp.event_id)
            })
            .await?
    }
}

#[derive(Clone)]
pub struct PinUpdateBuilder {
    client: Client,
    room: Joined,
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
        let content = self.content.build()?;
        RUNTIME
            .spawn(async move {
                let resp = room.send(content, None).await?;
                Ok(resp.event_id)
            })
            .await?
    }
}

impl Space {
    pub fn pin_draft(&self) -> Result<PinDraft> {
        let Room::Joined(joined) = &self.inner.room else {
            bail!("You can't create pins for spaces we are not part on")
        };
        Ok(PinDraft {
            client: self.client.clone(),
            room: joined.clone(),
            content: Default::default(),
        })
    }

    pub fn pin_draft_with_builder(&self, content: PinBuilder) -> Result<PinDraft> {
        let Room::Joined(joined) = &self.inner.room else {
            bail!("You can't create pins for spaces we are not part on")
        };
        Ok(PinDraft {
            client: self.client.clone(),
            room: joined.clone(),
            content,
        })
    }
}
