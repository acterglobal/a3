use anyhow::{bail, Result};
use futures::{Stream, StreamExt};
use futures_signals::signal_vec::{SignalVecExt, VecDiff};
use js_int::UInt;
use log::info;
use matrix_sdk::{
    room::{timeline::Timeline, Room},
    ruma::{
        events::room::message::{Relation, Replacement, RoomMessageEvent, RoomMessageEventContent},
        EventId,
    },
    Client,
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
    new_index: Option<usize>,
    old_index: Option<usize>,
}

impl TimelineDiff {
    pub fn action(&self) -> String {
        self.action.clone()
    }

    pub fn values(&self) -> Option<Vec<RoomMessage>> {
        if self.action == "Replace" {
            self.values.clone()
        } else {
            None
        }
    }

    pub fn index(&self) -> Option<usize> {
        if self.action == "InsertAt" || self.action == "UpdateAt" || self.action == "RemoveAt" {
            self.index
        } else {
            None
        }
    }

    pub fn value(&self) -> Option<RoomMessage> {
        if self.action == "InsertAt" || self.action == "UpdateAt" || self.action == "Push" {
            self.value.clone()
        } else {
            None
        }
    }

    pub fn old_index(&self) -> Option<usize> {
        if self.action == "Move" {
            self.old_index
        } else {
            None
        }
    }

    pub fn new_index(&self) -> Option<usize> {
        if self.action == "Move" {
            self.new_index
        } else {
            None
        }
    }
}

#[derive(Clone)]
pub struct TimelineStream {
    client: Client,
    room: Room,
    timeline: Arc<Timeline>,
}

impl TimelineStream {
    pub fn new(client: Client, room: Room) -> Self {
        let timeline = Arc::new(room.timeline());
        TimelineStream {
            client,
            room,
            timeline,
        }
    }

    pub fn diff_rx(&self) -> impl Stream<Item = TimelineDiff> {
        let timeline = self.timeline.clone();
        let room = self.room.clone();

        let mut stream = timeline.signal().to_stream();
        stream.map(move |diff| match diff {
            VecDiff::Replace { values } => TimelineDiff {
                action: "Replace".to_string(),
                values: values
                    .iter()
                    .map(|x| timeline_item_to_message(x.clone(), room.clone()))
                    .collect(),
                index: None,
                value: None,
                new_index: None,
                old_index: None,
            },
            VecDiff::InsertAt { index, value } => TimelineDiff {
                action: "InsertAt".to_string(),
                values: None,
                index: Some(index),
                value: timeline_item_to_message(value, room.clone()),
                new_index: None,
                old_index: None,
            },
            VecDiff::UpdateAt { index, value } => TimelineDiff {
                action: "UpdateAt".to_string(),
                values: None,
                index: Some(index),
                value: timeline_item_to_message(value, room.clone()),
                new_index: None,
                old_index: None,
            },
            VecDiff::Push { value } => TimelineDiff {
                action: "Push".to_string(),
                values: None,
                index: None,
                value: timeline_item_to_message(value, room.clone()),
                new_index: None,
                old_index: None,
            },
            VecDiff::RemoveAt { index } => TimelineDiff {
                action: "RemoveAt".to_string(),
                values: None,
                index: Some(index),
                value: None,
                new_index: None,
                old_index: None,
            },
            VecDiff::Move {
                old_index,
                new_index,
            } => TimelineDiff {
                action: "Move".to_string(),
                values: None,
                index: None,
                value: None,
                old_index: Some(old_index),
                new_index: Some(new_index),
            },
            VecDiff::Pop {} => TimelineDiff {
                action: "Pop".to_string(),
                values: None,
                index: None,
                value: None,
                old_index: None,
                new_index: None,
            },
            VecDiff::Clear {} => TimelineDiff {
                action: "Clear".to_string(),
                values: None,
                index: None,
                value: None,
                old_index: None,
                new_index: None,
            },
        })
    }

    pub async fn paginate_backwards(&self, mut count: u16) -> Result<bool> {
        let timeline = self.timeline.clone();
        RUNTIME
            .spawn(async move {
                let outcome = timeline.paginate_backwards(UInt::from(count)).await?;
                Ok(outcome.more_messages)
            })
            .await?
    }

    pub async fn next(&self) -> Result<RoomMessage> {
        let timeline = self.timeline.clone();
        let room = self.room.clone();

        RUNTIME
            .spawn(async move {
                let mut stream = timeline.stream();
                loop {
                    if let Some(diff) = stream.next().await {
                        match (diff) {
                            VecDiff::Replace { values } => {
                                info!("stream forward timeline replace");
                            }
                            VecDiff::InsertAt { index, value } => {
                                info!("stream forward timeline insert_at");
                            }
                            VecDiff::UpdateAt { index, value } => {
                                info!("stream forward timeline update_at");
                            }
                            VecDiff::Push { value } => {
                                info!("stream forward timeline push");
                                if let Some(inner) = timeline_item_to_message(value, room.clone()) {
                                    return Ok(inner);
                                }
                            }
                            VecDiff::RemoveAt { index } => {
                                info!("stream forward timeline remove_at");
                            }
                            VecDiff::Move {
                                old_index,
                                new_index,
                            } => {
                                info!("stream forward timeline move");
                            }
                            VecDiff::Pop {} => {
                                info!("stream forward timeline pop");
                            }
                            VecDiff::Clear {} => {
                                info!("stream forward timeline clear");
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
        let client = self.client.clone();

        RUNTIME
            .spawn(async move {
                let timeline_event = room.event(&event_id).await.expect("Couldn't find event.");
                let event_content = timeline_event
                    .event
                    .deserialize_as::<RoomMessageEvent>()
                    .expect("Couldn't deserialise event");

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
                    Box::new(RoomMessageEventContent::text_markdown(new_msg.to_owned())),
                );
                let mut edited_content = RoomMessageEventContent::text_markdown(new_msg);
                edited_content.relates_to = Some(Relation::Replacement(replacement));

                timeline
                    .send(edited_content.into(), txn_id.as_deref().map(Into::into))
                    .await?;
                Ok(true)
            })
            .await?
    }
}
