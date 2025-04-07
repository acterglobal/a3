use anyhow::{bail, Context, Result};
use futures::stream::{Stream, StreamExt};
use matrix_sdk::room::{edit::EditedContent, Receipts};
use matrix_sdk_base::{
    ruma::{
        api::client::receipt::create_receipt,
        assign,
        events::{
            receipt::ReceiptThread,
            room::{
                message::{AudioInfo, FileInfo, ForwardThread, VideoInfo},
                ImageInfo,
            },
            MessageLikeEventType,
        },
        EventId, OwnedEventId, OwnedTransactionId,
    },
    RoomState,
};
use matrix_sdk_ui::{
    eyeball_im::VectorDiff,
    timeline::{Timeline, TimelineEventItemId, TimelineItem as SdkTimelineItem},
};
use std::{ops::Deref, sync::Arc};
use tracing::{error, info};

use crate::{Client, Room, TimelineItem, RUNTIME};

use super::{
    super::utils::{remap_for_diff, ApiVectorDiff},
    msg_draft::{MsgContentDraft, MsgDraft},
};

pub type TimelineItemDiff = ApiVectorDiff<TimelineItem>;

#[derive(Clone)]
pub struct TimelineStream {
    room: Room,
    timeline: Arc<Timeline>,
}

impl TimelineStream {
    pub(crate) fn new(room: Room, timeline: Arc<Timeline>) -> Self {
        TimelineStream { room, timeline }
    }

    pub fn messages_stream(&self) -> impl Stream<Item = TimelineItemDiff> {
        let timeline = self.timeline.clone();
        let my_id = self
            .room
            .deref()
            .client()
            .user_id()
            .expect("User must be logged in")
            .to_owned();

        async_stream::stream! {
            let (timeline_items, mut timeline_stream) = timeline.subscribe().await;
            let values = timeline_items
                .into_iter()
                .map(|x| TimelineItem::from((x, my_id.clone())))
                .collect::<Vec<TimelineItem>>();
            yield TimelineItemDiff::current_items(values);

            while let Some(diffs) = timeline_stream.next().await {
                for diff in diffs {
                    let d = match diff {
                        VectorDiff::Append { values } => {
                            info!("items append");
                            for value in values.clone() {
                                fetch_details_for_event(value, timeline.clone()).await;
                            }
                            let items = values
                                .into_iter()
                                .map(|x| TimelineItem::from((x, my_id.clone())))
                                .collect::<Vec<TimelineItem>>();
                            ApiVectorDiff {
                                action: "Append".to_string(),
                                values: Some(items),
                                index: None,
                                value: None,
                            }
                        }
                        VectorDiff::Clear => {
                            info!("items clear");
                            ApiVectorDiff {
                                action: "Clear".to_string(),
                                values: None,
                                index: None,
                                value: None,
                            }
                        }
                        VectorDiff::Insert { index, value } => {
                            info!("items insert");
                            fetch_details_for_event(value.clone(), timeline.clone()).await;
                            ApiVectorDiff {
                                action: "Insert".to_string(),
                                values: None,
                                index: Some(index),
                                value: Some(TimelineItem::from((value, my_id.clone()))),
                            }
                        }
                        VectorDiff::PopBack => {
                            info!("items pop back");
                            ApiVectorDiff {
                                action: "PopBack".to_string(),
                                values: None,
                                index: None,
                                value: None,
                            }
                        }
                        VectorDiff::PopFront => {
                            info!("items pop front");
                            ApiVectorDiff {
                                action: "PopFront".to_string(),
                                values: None,
                                index: None,
                                value: None,
                            }
                        }
                        VectorDiff::PushBack { value } => {
                            info!("items push back");
                            fetch_details_for_event(value.clone(), timeline.clone()).await;
                            ApiVectorDiff {
                                action: "PushBack".to_string(),
                                values: None,
                                index: None,
                                value: Some(TimelineItem::from((value, my_id.clone()))),
                            }
                        }
                        VectorDiff::PushFront { value } => {
                            info!("items push front");
                            fetch_details_for_event(value.clone(), timeline.clone()).await;
                            ApiVectorDiff {
                                action: "PushFront".to_string(),
                                values: None,
                                index: None,
                                value: Some(TimelineItem::from((value, my_id.clone()))),
                            }
                        }
                        VectorDiff::Remove { index } => {
                            info!("items remove");
                            ApiVectorDiff {
                                action: "Remove".to_string(),
                                values: None,
                                index: Some(index),
                                value: None,
                            }
                        }
                        VectorDiff::Reset { values } => {
                            info!("items reset");
                            for value in values.clone() {
                                fetch_details_for_event(value, timeline.clone()).await;
                            }
                            let items = values
                                .into_iter()
                                .map(|x| TimelineItem::from((x, my_id.clone())))
                                .collect::<Vec<TimelineItem>>();
                            ApiVectorDiff {
                                action: "Reset".to_string(),
                                values: Some(items),
                                index: None,
                                value: None,
                            }
                        }
                        VectorDiff::Set { index, value } => {
                            info!("items set");
                            fetch_details_for_event(value.clone(), timeline.clone()).await;
                            ApiVectorDiff {
                                action: "Set".to_string(),
                                values: None,
                                index: Some(index),
                                value: Some(TimelineItem::from((value, my_id.clone()))),
                            }
                        }
                        VectorDiff::Truncate { length } => {
                            info!("items truncate");
                            ApiVectorDiff {
                                action: "Truncate".to_string(),
                                values: None,
                                index: Some(length),
                                value: None,
                            }
                        }
                    };
                    yield d;
                }
            }
        }
    }

    /// Get the next count messages backwards, and return whether it reached the end
    pub async fn paginate_backwards(&self, mut count: u16) -> Result<bool> {
        let timeline = self.timeline.clone();

        RUNTIME
            .spawn(async move {
                let result = timeline.paginate_backwards(count).await?;
                Ok(result)
            })
            .await?
    }

    pub async fn get_message(&self, event_id: String) -> Result<TimelineItem> {
        let event_id = OwnedEventId::try_from(event_id)?;
        let timeline = self.timeline.clone();
        let my_id = self.room.user_id()?;

        RUNTIME
            .spawn(async move {
                let tl = timeline
                    .item_by_event_id(&event_id)
                    .await
                    .context("Event not found")?;
                Ok(TimelineItem::new_event_item(&tl, my_id))
            })
            .await?
    }

    fn is_joined(&self) -> bool {
        matches!(self.room.state(), RoomState::Joined)
    }

    pub async fn send_message(&self, draft: Box<MsgDraft>) -> Result<bool> {
        if !self.is_joined() {
            bail!("Unable to send message in a room we are not in");
        }
        let room = self.room.clone();
        let timeline = self.timeline.clone();
        let my_id = self.room.user_id()?;

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::RoomMessage)
                    .await?;
                if !permitted {
                    bail!("No permissions to send message in this room");
                }
                let msg = draft.into_room_msg(&room).await?;
                timeline.send(msg.with_relation(None).into()).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn edit_message(&self, event_id: String, draft: Box<MsgDraft>) -> Result<bool> {
        if !self.is_joined() {
            bail!("Unable to edit message in a room we are not in");
        }
        let room = self.room.deref().clone();
        let my_id = self.room.user_id()?;
        let timeline = self.timeline.clone();
        let event_id = EventId::parse(event_id)?;

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::RoomMessage)
                    .await?;
                if !permitted {
                    bail!("No permissions to send message in this room");
                }

                let item = timeline
                    .item_by_event_id(&event_id)
                    .await
                    .context("Unable to find event")?;

                if !item.is_own() {
                    // !item.is_editable() { // FIXME: matrix-sdk is_editable doesn't allow us to post other things
                    bail!("You can't edit other peoples messages");
                }

                let item = timeline
                    .item_by_event_id(&event_id)
                    .await
                    .context("Not found which item would be edited")?;
                let event_content = draft.into_room_msg(&room).await?;
                let new_content = EditedContent::RoomMessage(event_content);
                timeline.edit(&item.identifier(), new_content).await?;
                Ok(true)
            })
            .await?
    }

    pub async fn reply_message(&self, event_id: String, draft: Box<MsgDraft>) -> Result<bool> {
        if !self.is_joined() {
            bail!("Unable to send reply in a room we are not in");
        }
        let room = self.room.deref().clone();
        let my_id = self.room.user_id()?;
        let timeline = self.timeline.clone();
        let event_id = EventId::parse(event_id)?;

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::RoomMessage)
                    .await?;
                if !permitted {
                    bail!("No permissions to send message in this room");
                }
                let reply_item = timeline
                    .replied_to_info_from_event_id(&event_id)
                    .await
                    .context("Not found which item would be replied to")?;
                let content = draft.into_room_msg(&room).await?;
                timeline
                    .send_reply(
                        content.with_relation(None).into(),
                        reply_item,
                        ForwardThread::Yes,
                    )
                    .await?;
                Ok(true)
            })
            .await?
    }

    pub async fn mark_as_read(&self, publicly: bool) -> Result<bool> {
        let timeline = self.timeline.clone();
        let receipt = if publicly {
            create_receipt::v3::ReceiptType::Read
        } else {
            create_receipt::v3::ReceiptType::ReadPrivate
        };

        RUNTIME
            .spawn(async move {
                let result = timeline.mark_as_read(receipt).await?;
                Ok(result)
            })
            .await?
    }

    pub async fn toggle_reaction(&self, unique_id: String, key: String) -> Result<bool> {
        if !self.is_joined() {
            bail!("Unable to send reaction in a room we are not in");
        }
        let room = self.room.clone();
        let my_id = self.room.user_id()?;
        let timeline = self.timeline.clone();
        let unique_id =
            match OwnedEventId::try_from(unique_id.clone()).map(TimelineEventItemId::EventId) {
                Ok(o) => o,
                Err(e) => TimelineEventItemId::TransactionId(OwnedTransactionId::from(unique_id)),
            };

        RUNTIME
            .spawn(async move {
                let permitted = room
                    .can_user_send_message(&my_id, MessageLikeEventType::Reaction)
                    .await?;
                if !permitted {
                    bail!("No permissions to send reaction in this room");
                }
                timeline.toggle_reaction(&unique_id, &key).await?;
                Ok(true)
            })
            .await?
    }
}

impl Client {
    pub fn text_plain_draft(&self, body: String) -> MsgDraft {
        MsgDraft::new(MsgContentDraft::TextPlain {
            body,
            url_previews: Default::default(),
        })
    }

    pub fn text_markdown_draft(&self, body: String) -> MsgDraft {
        MsgDraft::new(MsgContentDraft::TextMarkdown {
            body,
            url_previews: Default::default(),
        })
    }

    pub fn text_html_draft(&self, html: String, plain: String) -> MsgDraft {
        MsgDraft::new(MsgContentDraft::TextHtml {
            html,
            plain,
            url_previews: Default::default(),
        })
    }

    pub fn image_draft(&self, source: String, mimetype: String) -> MsgDraft {
        let info = assign!(ImageInfo::new(), {
            mimetype: Some(mimetype),
        });
        MsgDraft::new(MsgContentDraft::Image {
            source,
            info: Some(info),
            filename: None,
        })
    }

    pub fn audio_draft(&self, source: String, mimetype: String) -> MsgDraft {
        let info = assign!(AudioInfo::new(), {
            mimetype: Some(mimetype),
        });
        MsgDraft::new(MsgContentDraft::Audio {
            source,
            info: Some(info),
            filename: None,
        })
    }

    pub fn video_draft(&self, source: String, mimetype: String) -> MsgDraft {
        let info = assign!(VideoInfo::new(), {
            mimetype: Some(mimetype),
        });
        MsgDraft::new(MsgContentDraft::Video {
            source,
            info: Some(info),
            filename: None,
        })
    }

    pub fn file_draft(&self, source: String, mimetype: String) -> MsgDraft {
        let info = assign!(FileInfo::new(), {
            mimetype: Some(mimetype),
        });
        MsgDraft::new(MsgContentDraft::File {
            source,
            info: Some(info),
            filename: None,
        })
    }

    pub fn location_draft(&self, body: String, geo_uri: String) -> MsgDraft {
        MsgDraft::new(MsgContentDraft::Location {
            body,
            geo_uri,
            info: None,
        })
    }
}

async fn fetch_details_for_event(
    item: Arc<SdkTimelineItem>,
    timeline: Arc<Timeline>,
) -> Result<bool> {
    RUNTIME
        .spawn(async move {
            if let Some(event) = item.as_event() {
                if let Ok(info) = event.replied_to_info() {
                    let replied_to = info.event_id();
                    info!("fetching replied_to: {}", replied_to);
                    if let Err(err) = timeline.fetch_details_for_event(replied_to).await {
                        error!("error when fetching replied_to_info via timeline: {err}");
                        return Ok(false);
                    }
                }
            }
            Ok(true)
        })
        .await?
}
