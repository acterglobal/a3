use matrix_sdk::ruma::OwnedEventId;
use matrix_sdk_base::ruma::{events::OriginalMessageLikeEvent, RoomId, UserId};
use serde::{Deserialize, Serialize};
use std::ops::Deref;

use super::{default_model_execute, ActerModel, AnyActerModel, Capability, EventMeta};
use crate::{
    events::stories::{StoryEventContent, StoryUpdateBuilder, StoryUpdateEventContent},
    referencing::{ExecuteReference, IndexKey, SectionIndex},
    store::Store,
    Result,
};

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct Story {
    inner: StoryEventContent,
    pub meta: EventMeta,
}

impl Deref for Story {
    type Target = StoryEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl Story {
    pub fn room_id(&self) -> &RoomId {
        &self.meta.room_id
    }

    pub fn sender(&self) -> &UserId {
        &self.meta.sender
    }

    pub fn updater(&self) -> StoryUpdateBuilder {
        StoryUpdateBuilder::default()
            .story_entry(self.meta.event_id.clone())
            .to_owned()
    }
}

impl ActerModel for Story {
    fn indizes(&self, _user_id: &UserId) -> Vec<IndexKey> {
        vec![
            IndexKey::Section(SectionIndex::Stories),
            IndexKey::RoomSection(self.meta.room_id.clone(), SectionIndex::Stories),
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
        let AnyActerModel::StoryUpdate(update) = model else {
            return Ok(false);
        };

        update.apply(&mut self.inner)
    }
}

impl From<OriginalMessageLikeEvent<StoryEventContent>> for Story {
    fn from(outer: OriginalMessageLikeEvent<StoryEventContent>) -> Self {
        let OriginalMessageLikeEvent {
            content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = outer;
        Story {
            inner: content,
            meta: EventMeta {
                room_id,
                event_id,
                sender,
                origin_server_ts,
                redacted: None,
            },
        }
    }
}

#[derive(Clone, Debug, Deserialize, Serialize)]
pub struct StoryUpdate {
    inner: StoryUpdateEventContent,
    meta: EventMeta,
}

impl ActerModel for StoryUpdate {
    fn indizes(&self, _user_id: &UserId) -> Vec<IndexKey> {
        vec![
            IndexKey::ObjectHistory(self.inner.story_entry.event_id.clone()),
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
        Some(vec![self.inner.story_entry.event_id.clone()])
    }
}

impl Deref for StoryUpdate {
    type Target = StoryUpdateEventContent;
    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl From<OriginalMessageLikeEvent<StoryUpdateEventContent>> for StoryUpdate {
    fn from(outer: OriginalMessageLikeEvent<StoryUpdateEventContent>) -> Self {
        let OriginalMessageLikeEvent {
            content,
            room_id,
            event_id,
            sender,
            origin_server_ts,
            ..
        } = outer;
        StoryUpdate {
            inner: content,
            meta: EventMeta {
                room_id,
                event_id,
                sender,
                origin_server_ts,
                redacted: None,
            },
        }
    }
}
