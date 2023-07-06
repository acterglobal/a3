use matrix_sdk::ruma::{events::OriginalMessageLikeEvent, EventId, RoomId};
use serde::{Deserialize, Serialize};
use std::ops::Deref;

use super::{default_model_execute, ActerModel, AnyActerModel, Capability, EventMeta, Store};
use crate::{
    events::news::{NewsEntryEventContent, NewsEntryUpdateBuilder, NewsEntryUpdateEventContent},
    statics::KEYS,
};

static NEWS_KEY: &str = KEYS::NEWS;

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct NewsEntry {
    inner: NewsEntryEventContent,
    pub meta: EventMeta,
}

impl Deref for NewsEntry {
    type Target = NewsEntryEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl NewsEntry {
    pub fn room_id(&self) -> &RoomId {
        &self.meta.room_id
    }

    pub fn key_from_event(event_id: &EventId) -> String {
        event_id.to_string()
    }

    pub fn updater(&self) -> NewsEntryUpdateBuilder {
        NewsEntryUpdateBuilder::default()
            .news_entry(self.meta.event_id.clone())
            .to_owned()
    }
}

impl ActerModel for NewsEntry {
    fn indizes(&self) -> Vec<String> {
        vec![
            NEWS_KEY.to_string(),
            format!("{}::{NEWS_KEY}", self.meta.room_id),
        ]
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }

    fn capabilities(&self) -> &[Capability] {
        &[Capability::Commentable]
    }

    async fn execute(self, store: &Store) -> crate::Result<Vec<String>> {
        default_model_execute(store, self.into()).await
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        None
    }

    fn transition(&mut self, model: &AnyActerModel) -> crate::Result<bool> {
        let AnyActerModel::NewsEntryUpdate(update) = model else {
            return Ok(false)
        };

        update.apply(&mut self.inner)
    }
}

impl From<OriginalMessageLikeEvent<NewsEntryEventContent>> for NewsEntry {
    fn from(outer: OriginalMessageLikeEvent<NewsEntryEventContent>) -> Self {
        let OriginalMessageLikeEvent {
            content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = outer;
        NewsEntry {
            inner: content,
            meta: EventMeta {
                room_id,
                event_id,
                sender,
                origin_server_ts,
            },
        }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct NewsEntryUpdate {
    inner: NewsEntryUpdateEventContent,
    meta: EventMeta,
}

impl ActerModel for NewsEntryUpdate {
    fn indizes(&self) -> Vec<String> {
        vec![format!("{:}::history", self.inner.news_entry.event_id)]
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }

    async fn execute(self, store: &Store) -> crate::Result<Vec<String>> {
        default_model_execute(store, self.into()).await
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        let event_ids = vec![NewsEntry::key_from_event(&self.inner.news_entry.event_id)];
        Some(event_ids)
    }
}

impl Deref for NewsEntryUpdate {
    type Target = NewsEntryUpdateEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl From<OriginalMessageLikeEvent<NewsEntryUpdateEventContent>> for NewsEntryUpdate {
    fn from(outer: OriginalMessageLikeEvent<NewsEntryUpdateEventContent>) -> Self {
        let OriginalMessageLikeEvent {
            content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = outer;
        NewsEntryUpdate {
            inner: content,
            meta: EventMeta {
                room_id,
                event_id,
                sender,
                origin_server_ts,
            },
        }
    }
}
