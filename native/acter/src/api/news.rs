use acter_core::{
    events::{
        news::{self, NewsEntryBuilder},
        Icon, TextMessageEventContent,
    },
    models::{self, ActerModel, AnyActerModel, Color},
    ruma::{OwnedEventId, OwnedRoomId},
    statics::KEYS,
};
use anyhow::{bail, Context, Result};
use async_broadcast::Receiver;
use core::time::Duration;
use matrix_sdk::{room::Joined, room::Room};
use std::collections::{hash_map::Entry, HashMap};

use super::{client::Client, group::Group, RUNTIME};

impl Client {
    pub async fn wait_for_news(
        &self,
        key: String,
        timeout: Option<Box<Duration>>,
    ) -> Result<NewsEntry> {
        let AnyActerModel::NewsEntry(content) = self.wait_for(key.clone(), timeout).await? else {
            bail!("{key} is not a news");
        };
        let room = self
            .core
            .client()
            .get_room(content.room_id())
            .context("Room not found")?;
        Ok(NewsEntry {
            client: self.clone(),
            room,
            content,
        })
    }

    pub async fn latest_news(&self, mut count: u32) -> Result<Vec<NewsEntry>> {
        let mut news = Vec::new();
        let mut rooms_map: HashMap<OwnedRoomId, Room> = HashMap::new();
        let client = self.clone();
        let mut all_news: Vec<_> = self
            .store()
            .get_list(KEYS::NEWS)
            .await?
            .filter_map(|any| {
                if let AnyActerModel::NewsEntry(t) = any {
                    Some(t)
                } else {
                    None
                }
            })
            .collect();
        all_news.reverse();

        for t in all_news {
            if count == 0 {
                break; // we filled what we wanted
            }
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
            news.push(NewsEntry {
                client: client.clone(),
                room,
                content: t,
            });
            count -= 1;
        }
        Ok(news)
    }
}

impl Group {
    pub async fn latest_news(&self, mut count: u32) -> Result<Vec<NewsEntry>> {
        let mut news = Vec::new();
        let room_id = self.room_id();
        let mut all_news: Vec<_> = self
            .client
            .store()
            .get_list(&format!("{room_id}::{}", KEYS::NEWS))
            .await?
            .filter_map(|any| {
                if let AnyActerModel::NewsEntry(t) = any {
                    Some(t)
                } else {
                    None
                }
            })
            .collect();
        all_news.reverse();

        for t in all_news {
            if count == 0 {
                break; // we filled what we wanted
            }
            news.push(NewsEntry {
                client: self.client.clone(),
                room: self.room.clone(),
                content: t,
            });
            count -= 1;
        }
        Ok(news)
    }
}

#[derive(Clone, Debug)]
pub struct NewsEntry {
    client: Client,
    room: Room,
    content: models::NewsEntry,
}

impl std::ops::Deref for NewsEntry {
    type Target = models::NewsEntry;
    fn deref(&self) -> &Self::Target {
        &self.content
    }
}

/// helpers for content
impl NewsEntry {}

/// Custom functions
impl NewsEntry {
    pub async fn refresh(&self) -> Result<NewsEntry> {
        let key = self.content.event_id().to_string();
        let client = self.client.clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let AnyActerModel::NewsEntry(content) = client.store().get(&key).await? else {
                    bail!("Refreshing failed. {key} not a news")
                };
                Ok(NewsEntry {
                    client,
                    room,
                    content,
                })
            })
            .await?
    }

    pub fn update_builder(&self) -> Result<NewsEntryUpdateBuilder> {
        let Room::Joined(joined) = &self.room else {
            bail!("Can only update news in joined rooms");
        };
        Ok(NewsEntryUpdateBuilder {
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
}

#[derive(Clone)]
pub struct NewsEntryDraft {
    client: Client,
    room: Joined,
    content: NewsEntryBuilder,
}

impl NewsEntryDraft {
    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let inner = self.content.build()?;
        RUNTIME
            .spawn(async move {
                let resp = room.send(inner, None).await?;
                Ok(resp.event_id)
            })
            .await?
    }
}

#[derive(Clone)]
pub struct NewsEntryUpdateBuilder {
    client: Client,
    room: Joined,
    content: news::NewsEntryUpdateBuilder,
}

impl NewsEntryUpdateBuilder {
    pub async fn send(&self) -> Result<OwnedEventId> {
        let room = self.room.clone();
        let inner = self.content.build()?;
        RUNTIME
            .spawn(async move {
                let resp = room.send(inner, None).await?;
                Ok(resp.event_id)
            })
            .await?
    }
}

impl Group {
    pub fn news_draft(&self) -> Result<NewsEntryDraft> {
        let matrix_sdk::room::Room::Joined(joined) = &self.inner.room else {
            bail!("You can't create news for groups we are not part on")
        };
        Ok(NewsEntryDraft {
            client: self.client.clone(),
            room: joined.clone(),
            content: Default::default(),
        })
    }

    pub fn news_draft_with_builder(&self, content: NewsEntryBuilder) -> Result<NewsEntryDraft> {
        let matrix_sdk::room::Room::Joined(joined) = &self.inner.room else {
            bail!("You can't create news for groups we are not part on")
        };
        Ok(NewsEntryDraft {
            client: self.client.clone(),
            room: joined.clone(),
            content,
        })
    }
}
