use anyhow::Result;
use futures::{pin_mut, StreamExt};
use futures_signals::signal_vec::{SignalVecExt, VecDiff};
use js_int::UInt;
use log::info;
use matrix_sdk::{room::Room, Client};
use std::sync::Arc;

use super::{
    message::{timeline_item_to_message, RoomMessage},
    RUNTIME,
};

#[derive(Clone)]
pub struct TimelineStream {
    client: Client,
    room: Room,
}

impl TimelineStream {
    pub fn new(client: Client, room: Room) -> Self {
        TimelineStream { client, room }
    }

    pub async fn paginate_backwards(&self, mut count: u32) -> Result<Vec<RoomMessage>> {
        let room = self.room.clone();
        let timeline = Arc::new(self.room.timeline());

        RUNTIME
            .spawn(async move {
                let mut stream = timeline.signal().to_stream();
                pin_mut!(stream);
                let mut messages: Vec<RoomMessage> = Vec::new();
                let outcome = timeline.paginate_backwards(UInt::from(count)).await?;

                while count > 0 {
                    info!("stream backward timeline loop");
                    if let Some(diff) = stream.next().await {
                        count -= 1;
                        match (diff) {
                            VecDiff::Replace { values } => {
                                info!("stream backward timeline replace");
                                messages.clear();
                                for value in values {
                                    if let Some(msg) = timeline_item_to_message(value, room.clone())
                                    {
                                        messages.push(msg);
                                    }
                                }
                            }
                            VecDiff::InsertAt { index, value } => {
                                info!("stream backward timeline insert_at");
                                if let Some(msg) = timeline_item_to_message(value, room.clone()) {
                                    messages.insert(index, msg);
                                }
                            }
                            VecDiff::UpdateAt { index, value } => {
                                info!("stream backward timeline update_at");
                                if let Some(msg) = timeline_item_to_message(value, room.clone()) {
                                    messages[index] = msg;
                                }
                            }
                            VecDiff::Push { value } => {
                                info!("stream backward timeline push");
                                if let Some(msg) = timeline_item_to_message(value, room.clone()) {
                                    messages.push(msg);
                                }
                            }
                            VecDiff::RemoveAt { index } => {
                                info!("stream backward timeline remove_at");
                                messages.remove(index);
                            }
                            VecDiff::Move {
                                old_index,
                                new_index,
                            } => {
                                info!("stream backward timeline move");
                                let msg = messages.remove(old_index);
                                messages.insert(new_index, msg);
                            }
                            VecDiff::Pop {} => {
                                info!("stream backward timeline pop");
                                messages.pop();
                            }
                            VecDiff::Clear {} => {
                                info!("stream backward timeline clear");
                                messages.clear();
                            }
                        }
                    } else {
                        // reach limit count
                        break;
                    }
                }
                Ok(messages)
            })
            .await?
    }

    pub async fn next(&self) -> Result<RoomMessage> {
        let room = self.room.clone();
        let timeline = self.room.timeline();
        let mut stream = timeline.signal().to_stream();

        RUNTIME
            .spawn(async move {
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
