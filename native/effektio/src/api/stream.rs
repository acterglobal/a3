use super::messages::{sync_event_to_message, RoomMessage};
use super::RUNTIME;

use anyhow::{Context, Result};
use core::pin::Pin;
use futures::lock::Mutex;
use futures::{pin_mut, StreamExt};
use matrix_sdk::{deserialized_responses::SyncRoomEvent, Client as MatrixClient};
use std::sync::Arc;

type BackwardMsgStream =
    Pin<Box<dyn futures::Stream<Item = Result<SyncRoomEvent, matrix_sdk::Error>> + Send>>;
type FwdMsgStream = Pin<Box<dyn futures::Stream<Item = SyncRoomEvent> + Send>>;

#[derive(Clone)]
pub struct TimelineStream {
    client: MatrixClient,
    backward: Arc<Mutex<BackwardMsgStream>>,
    forward: Arc<Mutex<FwdMsgStream>>,
}

unsafe impl Send for TimelineStream {}
unsafe impl Sync for TimelineStream {}

impl TimelineStream {
    pub fn new(forward: FwdMsgStream, backward: BackwardMsgStream, client: MatrixClient) -> Self {
        TimelineStream {
            forward: Arc::new(Mutex::new(forward)),
            backward: Arc::new(Mutex::new(backward)),
            client,
        }
    }
    pub async fn paginate_backwards(&self, mut count: u64) -> Result<Vec<RoomMessage>> {
        let backward = self.backward.clone();
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let mut messages: Vec<RoomMessage> = Vec::new();
                let stream = backward.lock().await;
                pin_mut!(stream);

                while count > 0 {
                    match stream.next().await {
                        Some(Ok(e)) => {
                            if let Some(inner) = sync_event_to_message(e, client.clone()) {
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
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let stream = forward.lock().await;
                pin_mut!(stream);
                loop {
                    if let Some(e) = stream.next().await.and_then(|e| sync_event_to_message(e, client.clone())) {
                        return Ok(e);
                    }
                }
            })
            .await?
    }
}
