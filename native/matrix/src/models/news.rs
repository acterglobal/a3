use matrix_sdk::ruma::OwnedEventId;
use matrix_sdk_base::ruma::{events::OriginalMessageLikeEvent, RoomId, UserId};
use serde::{Deserialize, Serialize};
use std::ops::Deref;

use super::{default_model_execute, ActerModel, AnyActerModel, Capability, EventMeta};
use crate::{
    events::news::{NewsEntryEventContent, NewsEntryUpdateBuilder, NewsEntryUpdateEventContent},
    referencing::{ExecuteReference, IndexKey, SectionIndex},
    store::Store,
    Result,
};

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

    pub fn sender(&self) -> &UserId {
        &self.meta.sender
    }

    pub fn updater(&self) -> NewsEntryUpdateBuilder {
        NewsEntryUpdateBuilder::default()
            .news_entry(self.meta.event_id.clone())
            .to_owned()
    }
}

impl ActerModel for NewsEntry {
    fn indizes(&self, _user_id: &UserId) -> Vec<IndexKey> {
        vec![
            IndexKey::Section(SectionIndex::Boosts),
            IndexKey::RoomSection(self.meta.room_id.clone(), SectionIndex::Boosts),
            IndexKey::ObjectHistory(self.meta.event_id.clone()),
            IndexKey::RoomHistory(self.meta.room_id.clone()),
            IndexKey::AllHistory,
        ]
    }

    fn event_meta(&self) -> &EventMeta {
        &self.meta
    }

    fn capabilities(&self) -> &[Capability] {
        &[
            Capability::Commentable,
            Capability::Reactable,
            Capability::ReadTracking,
        ]
    }

    async fn execute(self, store: &Store) -> Result<Vec<ExecuteReference>> {
        default_model_execute(store, self.into()).await
    }

    fn belongs_to(&self) -> Option<Vec<OwnedEventId>> {
        None
    }

    fn transition(&mut self, model: &AnyActerModel) -> Result<bool> {
        let AnyActerModel::NewsEntryUpdate(update) = model else {
            return Ok(false);
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
                timestamp: origin_server_ts,
                redacted: None,
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
    fn indizes(&self, _user_id: &UserId) -> Vec<IndexKey> {
        vec![
            IndexKey::ObjectHistory(self.inner.news_entry.event_id.clone()),
            IndexKey::RoomHistory(self.meta.room_id.clone()),
            IndexKey::AllHistory,
        ]
    }

    fn event_meta(&self) -> &EventMeta {
        &self.meta
    }

    async fn execute(self, store: &Store) -> Result<Vec<ExecuteReference>> {
        default_model_execute(store, self.into()).await
    }

    fn belongs_to(&self) -> Option<Vec<OwnedEventId>> {
        Some(vec![self.inner.news_entry.event_id.clone()])
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
                timestamp: origin_server_ts,
                redacted: None,
            },
        }
    }
}
