use anyhow::{bail, Context, Result};
use matrix_sdk_base::{
    ruma::{OwnedEventId, OwnedRoomId},
    ComposerDraft, ComposerDraftType,
};
use std::{cmp::Ordering, ops::Deref, sync::Arc};

use crate::{
    Client, ComposeDraft, OptionComposeDraft, OptionTimelineItem, Room, TimelineItem, TimelineStream,
    RUNTIME,
};

#[derive(Debug, Clone)]
pub struct SimpleConvo {
    client: Client,
    inner: Room,
}

// internal API
impl SimpleConvo {
    pub(crate) fn new(client: Client, inner: Room) -> Self {
        SimpleConvo { client, inner }
    }
}

// External API

impl SimpleConvo {
    pub(crate) fn update_room(self, room: Room) -> Self {
        let SimpleConvo { client, .. } = self;
        SimpleConvo {
            client,
            inner: room,
        }
    }

    pub async fn timeline_stream(&self) -> Result<TimelineStream> {
        let client = self.client.clone();
        let inner = self.inner.clone();
        RUNTIME
            .spawn(async move {
                let timelines = client.sync_controller.timelines.lock().await;
                let room_id = inner.room.room_id();
                let timeline = timelines.get(room_id).context("timeline not started yet")?;
                Ok(TimelineStream::new(inner, timeline.inner.clone()))
            })
            .await?
    }

    pub async fn items(&self) -> Result<Vec<TimelineItem>> {
        let client = self.client.clone();
        let room_id = self.inner.room.room_id().to_owned();
        RUNTIME
            .spawn(async move {
                let timelines = client.sync_controller.timelines.lock().await;
                let timeline = timelines
                    .get(&room_id)
                    .context("timeline not started yet")?;
                let user_id = client.user_id()?;
                let tl_items = timeline
                    .inner
                    .items()
                    .await
                    .into_iter()
                    .map(|x| TimelineItem::from((x, user_id.clone())))
                    .collect();
                Ok(tl_items)
            })
            .await?
    }

    pub fn num_unread_notification_count(&self) -> u64 {
        self.inner
            .room
            .unread_notification_counts()
            .notification_count
    }

    pub fn num_unread_messages(&self) -> u64 {
        self.inner.room.num_unread_messages()
    }

    pub fn num_unread_mentions(&self) -> u64 {
        self.inner.room.unread_notification_counts().highlight_count
    }

    pub async fn latest_message_ts(&self) -> Result<u64> {
        let client = self.client.clone();
        let room_id = self.inner.room.room_id().to_owned();
        RUNTIME
            .spawn(async move {
                let room_infos = client.sync_controller.room_infos.lock().await;
                let info = room_infos
                    .get(&room_id)
                    .context("room info not inited yet")?;
                let ts = info.latest_msg().and_then(|x| x.origin_server_ts());
                Ok(ts.unwrap_or_default())
            })
            .await?
    }

    pub async fn latest_message(&self) -> Result<OptionTimelineItem> {
        let client = self.client.clone();
        let room_id = self.inner.room.room_id().to_owned();
        RUNTIME
            .spawn(async move {
                let room_infos = client.sync_controller.room_infos.lock().await;
                let info = room_infos
                    .get(&room_id)
                    .context("room info not inited yet")?;
                Ok(OptionTimelineItem::new(info.latest_msg()))
            })
            .await?
    }

    pub fn get_room_id(&self) -> OwnedRoomId {
        self.inner.room.room_id().to_owned()
    }

    pub fn get_room_id_str(&self) -> String {
        self.inner.room.room_id().to_string()
    }

    pub fn is_dm(&self) -> bool {
        self.inner.room.direct_targets_length() > 0
    }

    pub fn is_bookmarked(&self) -> bool {
        self.inner.room.is_favourite()
    }

    pub async fn set_bookmarked(&self, is_bookmarked: bool) -> Result<bool> {
        let inner = self.inner.clone();
        RUNTIME
            .spawn(async move {
                inner.room.set_is_favourite(is_bookmarked, None).await?;
                Ok(true)
            })
            .await?
    }

    pub fn is_low_priority(&self) -> bool {
        self.inner.room.is_low_priority()
    }

    pub async fn permalink(&self) -> Result<String> {
        let inner = self.inner.clone();
        RUNTIME
            .spawn(async move {
                let uri = inner.room.matrix_permalink(false).await?;
                Ok(uri.to_string())
            })
            .await?
    }

    pub fn dm_users(&self) -> Vec<String> {
        self.inner
            .room
            .direct_targets()
            .iter()
            .map(|f| f.to_string())
            .collect()
    }

    pub async fn msg_draft(&self) -> Result<OptionComposeDraft> {
        if !self.inner.is_joined() {
            bail!("Unable to fetch composer draft of a room we are not in");
        }
        let inner = self.inner.clone();
        RUNTIME
            .spawn(async move {
                let draft = inner.room.load_composer_draft().await?.map(|x| {
                    let (msg_type, event_id) = match x.draft_type {
                        ComposerDraftType::NewMessage => ("new".to_string(), None),
                        ComposerDraftType::Edit { event_id } => {
                            ("edit".to_string(), Some(event_id))
                        }
                        ComposerDraftType::Reply { event_id } => {
                            ("reply".to_string(), Some(event_id))
                        }
                    };
                    ComposeDraft::new(x.plain_text, x.html_text, msg_type, event_id)
                });
                Ok(OptionComposeDraft::new(draft))
            })
            .await?
    }

    pub async fn save_msg_draft(
        &self,
        text: String,
        html: Option<String>,
        draft_type: String,
        event_id: Option<String>,
    ) -> Result<bool> {
        if !self.is_joined() {
            bail!("Unable to save composer draft of a room we are not in");
        }
        let inner = self.inner.clone();

        let draft_type = match (draft_type.as_str(), event_id) {
            ("new", None) => ComposerDraftType::NewMessage,
            ("edit", Some(id)) => ComposerDraftType::Edit {
                event_id: OwnedEventId::try_from(id)?,
            },
            ("reply", Some(id)) => ComposerDraftType::Reply {
                event_id: OwnedEventId::try_from(id)?,
            },
            ("reply", None) | ("edit", None) => bail!("Invalid event id"),
            (draft_type, _) => bail!("Invalid draft type {draft_type}"),
        };

        let msg_draft = ComposerDraft {
            plain_text: text,
            html_text: html,
            draft_type,
        };

        RUNTIME
            .spawn(async move {
                inner.room.save_composer_draft(msg_draft).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn clear_msg_draft(&self) -> Result<bool> {
        if !self.inner.is_joined() {
            bail!("Unable to remove composer draft of a room we are not in");
        }
        let inner = self.inner.clone();
        RUNTIME
            .spawn(async move {
                inner.room.clear_composer_draft().await?;
                Ok(true)
            })
            .await?
    }
}

impl Deref for SimpleConvo {
    type Target = Room;
    fn deref(&self) -> &Room {
        &self.inner
    }
}
