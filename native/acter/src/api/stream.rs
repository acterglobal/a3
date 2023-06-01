use anyhow::{bail, Context, Result};
use eyeball_im::VectorDiff;
use futures::{Stream, StreamExt};
use log::info;
use matrix_sdk::{
    room::Room,
    ruma::{
        events::{
            relation::Replacement,
            room::message::{MessageType, Relation, RoomMessageEvent, RoomMessageEventContent},
        },
        EventId,
    },
    Client,
};
use matrix_sdk_ui::timeline::{
    PaginationOptions, Timeline, TimelineItem, VirtualTimelineItem,
};
use std::sync::Arc;

use super::{
    message::{timeline_item_to_message, RoomMessage},
    RUNTIME,
};

pub struct TimelineDiff {
    action: String,
    values: Option<Vec<RoomMessage>>,
    index: Option<usize>,
    value: Option<RoomMessage>,
}

impl TimelineDiff {
    pub fn action(&self) -> String {
        self.action.clone()
    }

    pub fn values(&self) -> Option<Vec<RoomMessage>> {
        match self.action.as_str() {
            "Append" | "Reset" => self.values.clone(),
            _ => None,
        }
    }

    pub fn index(&self) -> Option<usize> {
        match self.action.as_str() {
            "Insert" | "Set" | "Remove" => self.index,
            _ => None,
        }
    }

    pub fn value(&self) -> Option<RoomMessage> {
        match self.action.as_str() {
            "Insert" | "Set" | "PushBack" | "PushFront" => self.value.clone(),
            _ => None,
        }
    }
}

#[derive(Clone)]
pub struct TimelineStream {
    room: Room,
    timeline: Arc<Timeline>,
}

impl TimelineStream {
    pub fn new(room: Room, timeline: Arc<Timeline>) -> Self {
        TimelineStream { room, timeline }
    }

    pub fn diff_rx(&self) -> impl Stream<Item = TimelineDiff> {
        let timeline = self.timeline.clone();
        let room = self.room.clone();

        async_stream::stream! {
            let (timeline_items, mut timeline_stream) = timeline.subscribe().await;
            let mut remap = timeline_stream.map(move |diff| match diff {
                // Append the given elements at the end of the `Vector` and notify subscribers
                VectorDiff::Append { values } => TimelineDiff {
                    action: "Append".to_string(),
                    values: Some(
                        values
                            .iter()
                            .map(|x| timeline_item_to_message(x.clone(), room.clone()))
                            .collect(),
                    ),
                    index: None,
                    value: None,
                },
                // Insert an element at the given position and notify subscribers
                VectorDiff::Insert { index, value } => TimelineDiff {
                    action: "Insert".to_string(),
                    values: None,
                    index: Some(index),
                    value: Some(timeline_item_to_message(value, room.clone())),
                },
                // Replace the element at the given position, notify subscribers and return the previous element at that position
                VectorDiff::Set { index, value } => TimelineDiff {
                    action: "Set".to_string(),
                    values: None,
                    index: Some(index),
                    value: Some(timeline_item_to_message(value, room.clone())),
                },
                // Remove the element at the given position, notify subscribers and return the element
                VectorDiff::Remove { index } => TimelineDiff {
                    action: "Remove".to_string(),
                    values: None,
                    index: Some(index),
                    value: None,
                },
                // Add an element at the back of the list and notify subscribers
                VectorDiff::PushBack { value } => TimelineDiff {
                    action: "PushBack".to_string(),
                    values: None,
                    index: None,
                    value: Some(timeline_item_to_message(value, room.clone())),
                },
                // Add an element at the front of the list and notify subscribers
                VectorDiff::PushFront { value } => TimelineDiff {
                    action: "PushFront".to_string(),
                    values: None,
                    index: None,
                    value: Some(timeline_item_to_message(value, room.clone())),
                },
                // Remove the last element, notify subscribers and return the element
                VectorDiff::PopBack => TimelineDiff {
                    action: "PopBack".to_string(),
                    values: None,
                    index: None,
                    value: None,
                },
                // Remove the first element, notify subscribers and return the element
                VectorDiff::PopFront => TimelineDiff {
                    action: "PopFront".to_string(),
                    values: None,
                    index: None,
                    value: None,
                },
                // Clear out all of the elements in this `Vector` and notify subscribers
                VectorDiff::Clear => TimelineDiff {
                    action: "Clear".to_string(),
                    values: None,
                    index: None,
                    value: None,
                },
                VectorDiff::Reset { values } => TimelineDiff {
                    action: "Reset".to_string(),
                    values: Some(
                        values
                            .iter()
                            .map(|x| timeline_item_to_message(x.clone(), room.clone()))
                            .collect(),
                    ),
                    index: None,
                    value: None,
                },
            });

            while let Some(d) = remap.next().await {
                yield d
            }
        }
    }

    pub async fn paginate_backwards(&self, mut count: u16) -> Result<bool> {
        let timeline = self.timeline.clone();

        RUNTIME
            .spawn(async move {
                let (timeline_items, mut timeline_stream) = timeline.subscribe().await;
                timeline
                    .paginate_backwards(PaginationOptions::single_request(count))
                    .await
                    .context("Couldn't paginate backwards from timeline")?;

                let mut is_loading_indicator = false;
                if let Some(VectorDiff::Insert { index: 0, value }) = timeline_stream.next().await {
                    if let TimelineItem::Virtual(VirtualTimelineItem::LoadingIndicator) =
                        value.as_ref()
                    {
                        is_loading_indicator = true;
                    }
                }
                if !is_loading_indicator {
                    return Ok(true);
                }

                let mut is_timeline_start = false;
                if let Some(VectorDiff::Set { index: 0, value }) = timeline_stream.next().await {
                    if let TimelineItem::Virtual(VirtualTimelineItem::TimelineStart) =
                        value.as_ref()
                    {
                        is_timeline_start = true;
                    }
                }
                if !is_timeline_start {
                    return Ok(true);
                }

                Ok(false)
            })
            .await?
    }

    pub async fn next(&self) -> Result<RoomMessage> {
        let timeline = self.timeline.clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let (timeline_items, mut timeline_stream) = timeline.subscribe().await;
                loop {
                    if let Some(diff) = timeline_stream.next().await {
                        match diff {
                            VectorDiff::Append { values } => {
                                info!("stream forward timeline append");
                            }
                            VectorDiff::Insert { index, value } => {
                                info!("stream forward timeline insert");
                            }
                            VectorDiff::Set { index, value } => {
                                info!("stream forward timeline set");
                            }
                            VectorDiff::Reset { values } => {
                                info!("stream forward timeline reset");
                            }
                            VectorDiff::Remove { index } => {
                                info!("stream forward timeline remove");
                            }
                            VectorDiff::PushBack { value } => {
                                info!("stream forward timeline push_back");
                                let msg = timeline_item_to_message(value, room.clone());
                                return Ok(msg);
                            }
                            VectorDiff::PushFront { value } => {
                                info!("stream forward timeline push_front");
                                let msg = timeline_item_to_message(value, room.clone());
                                return Ok(msg);
                            }
                            VectorDiff::PopBack => {
                                info!("stream forward timeline pop_back");
                            }
                            VectorDiff::PopFront => {
                                info!("stream forward timeline pop_front");
                            }
                            VectorDiff::Clear => {
                                info!("stream forward timeline clear");
                            }
                            VectorDiff::Reset { values } => {
                                info!("stream forward timeline reset");
                            }
                        }
                    }
                }
            })
            .await?
    }

    pub async fn edit(
        &self,
        new_msg: String,
        original_event_id: String,
        txn_id: Option<String>,
    ) -> Result<bool> {
        let room = if let Room::Joined(r) = &self.room {
            r.clone()
        } else {
            bail!("Can't edit message from a room we are not in")
        };
        let timeline = self.timeline.clone();
        let event_id = EventId::parse(original_event_id)?;
        let client = self.room.client();

        RUNTIME
            .spawn(async move {
                let timeline_event = room
                    .event(&event_id)
                    .await
                    .context("Couldn't find event.")?;
                let event_content = timeline_event
                    .event
                    .deserialize_as::<RoomMessageEvent>()
                    .context("Couldn't deserialise event")?;

                let mut sent_by_me = false;
                if let Some(user_id) = client.user_id() {
                    if user_id == event_content.sender() {
                        sent_by_me = true;
                    }
                }
                if !sent_by_me {
                    info!("Can't edit an event not sent by own user");
                    return Ok(false);
                }

                let replacement = Replacement::new(
                    event_id.to_owned(),
                    MessageType::text_markdown(new_msg.to_string()),
                );
                let mut edited_content = RoomMessageEventContent::text_markdown(new_msg);
                edited_content.relates_to = Some(Relation::Replacement(replacement));

                timeline
                    .send(edited_content.into(), txn_id.as_deref().map(Into::into))
                    .await;
                Ok(true)
            })
            .await?
    }
}
