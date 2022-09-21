use anyhow::Result;
use core::pin::Pin;
use futures::{lock::Mutex, pin_mut, StreamExt};
use matrix_sdk::{deserialized_responses::SyncTimelineEvent, room::Room, Client};
use std::sync::Arc;

use super::{
    message::{sync_event_to_message, RoomMessage},
    RUNTIME,
};

type BackwardMsgStream =
    Pin<Box<dyn futures::Stream<Item = Result<SyncTimelineEvent, matrix_sdk::Error>> + Send>>;
type ForwardMsgStream = Pin<Box<dyn futures::Stream<Item = SyncTimelineEvent> + Send>>;

#[derive(Clone)]
pub struct TimelineStream {
    client: Client,
    room: Room,
    backward: Arc<Mutex<BackwardMsgStream>>,
    forward: Arc<Mutex<ForwardMsgStream>>,
}

unsafe impl Send for TimelineStream {}
unsafe impl Sync for TimelineStream {}

impl TimelineStream {
    pub fn new(
        forward: ForwardMsgStream,
        backward: BackwardMsgStream,
        client: Client,
        room: Room,
    ) -> Self {
        TimelineStream {
            forward: Arc::new(Mutex::new(forward)),
            backward: Arc::new(Mutex::new(backward)),
            client,
            room,
        }
    }

    pub async fn paginate_backwards(&self, mut count: u64) -> Result<Vec<RoomMessage>> {
        let backward = self.backward.clone();
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                let mut messages: Vec<RoomMessage> = Vec::new();
                let stream = backward.lock().await;
                pin_mut!(stream);

                while count > 0 {
                    match stream.next().await {
                        Some(Ok(e)) => {
                            if let Some(inner) = sync_event_to_message(e, room.clone()) {
                                messages.push(inner);
                                count -= 1;
                            }
                        }
                        None => {
                            // end of stream
                            break;
                        }
                        _ => {
                            // error cases, skipping
                        }
                    }
                }

                Ok(messages)
            })
            .await?
    }

    pub async fn next(&self) -> Result<RoomMessage> {
        let forward = self.forward.clone();
        let room = self.room.clone();
        RUNTIME
            .spawn(async move {
                let stream = forward.lock().await;
                pin_mut!(stream);
                loop {
                    if let Some(e) = stream
                        .next()
                        .await
                        .and_then(|e| sync_event_to_message(e, room.clone()))
                    {
                        return Ok(e);
                    }
                }
            })
            .await?
    }
}
