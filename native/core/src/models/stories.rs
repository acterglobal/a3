use matrix_sdk_base::ruma::{events::OriginalMessageLikeEvent, EventId, RoomId, UserId};
use serde::{Deserialize, Serialize};
use std::ops::Deref;

use super::{default_model_execute, ActerModel, AnyActerModel, Capability, EventMeta};
use crate::{
    events::stories::{StoryEventContent, StoryUpdateBuilder, StoryUpdateEventContent},
    statics::KEYS,
    store::Store,
    Result,
};

static STORIES_KEY: &str = KEYS::STORIES;

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
    fn indizes(&self, _user_id: &UserId) -> Vec<String> {
        vec![
            STORIES_KEY.to_string(),
            format!("{}::{STORIES_KEY}", self.meta.room_id),
        ]
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }
    fn room_id(&self) -> &RoomId {
        &self.meta.room_id
    }

    fn capabilities(&self) -> &[Capability] {
        &[
            Capability::Commentable,
            Capability::Reactable,
            Capability::ReadTracking,
        ]
    }

    async fn execute(self, store: &Store) -> Result<Vec<String>> {
        default_model_execute(store, self.into()).await
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
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
    fn indizes(&self, _user_id: &UserId) -> Vec<String> {
        vec![format!("{:}::history", self.inner.story_entry.event_id)]
    }

    fn event_id(&self) -> &EventId {
        &self.meta.event_id
    }
    fn room_id(&self) -> &RoomId {
        &self.meta.room_id
    }

    async fn execute(self, store: &Store) -> Result<Vec<String>> {
        default_model_execute(store, self.into()).await
    }

    fn belongs_to(&self) -> Option<Vec<String>> {
        Some(vec![self.inner.story_entry.event_id.to_string()])
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
