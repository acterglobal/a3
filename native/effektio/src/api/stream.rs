use anyhow::Result;
use futures::{Stream, StreamExt};
use futures_signals::signal_vec::{SignalVecExt, VecDiff};
use js_int::UInt;
use log::info;
use matrix_sdk::{
    room::{timeline::Timeline, Room},
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
}
