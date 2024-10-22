use acter_core::models::{self, ActerModel, AnyActerModel};
use anyhow::{bail, Result};
use futures::stream::StreamExt;
use matrix_sdk::room::Room;
use matrix_sdk::ruma::api::client::receipt::create_receipt::v3::ReceiptType;
use matrix_sdk_base::ruma::{
    events::{
        receipt::{Receipt, ReceiptThread, SyncReceiptEvent},
        MessageLikeEventType,
    },
    OwnedEventId, OwnedTransactionId, OwnedUserId, UserId,
};
use std::{collections::BTreeMap, ops::Deref};
use tokio::sync::broadcast::Receiver;
use tokio_stream::{wrappers::BroadcastStream, Stream};

use super::{client::Client, RUNTIME};

#[derive(Clone, Debug)]
pub struct ReadReceiptsManager {
    client: Client,
    room: Room,
    event_id: OwnedEventId,
    events: BTreeMap<OwnedUserId, Receipt>, // inner: models::ReadReceiptsManager,
}

impl ReadReceiptsManager {
    pub(crate) async fn new(
        client: Client,
        room: Room,
        event_id: OwnedEventId,
    ) -> Result<ReadReceiptsManager> {
        let events = client
            .core
            .client()
            .store()
            .get_event_room_receipt_events(
                room.room_id(),
                matrix_sdk::ruma::events::receipt::ReceiptType::Read,
                ReceiptThread::Unthreaded,
                &event_id,
            )
            .await?;
        Ok(ReadReceiptsManager {
            client,
            room,
            event_id,
            events: events.into_iter().collect(),
        })
    }

    pub async fn reload(&self) -> Result<ReadReceiptsManager> {
        ReadReceiptsManager::new(
            self.client.clone(),
            self.room.clone(),
            self.event_id.clone(),
        )
        .await
    }

    pub fn update_key(&self) -> String {
        format!("{:}:{:}:rr", self.room.room_id(), self.event_id)
    }

    pub async fn announce_read(&self) -> Result<bool> {
        let room = self.room.clone();
        let event_id = self.event_id.clone();

        RUNTIME
            .spawn(async move {
                room.send_single_receipt(ReceiptType::Read, ReceiptThread::Unthreaded, event_id)
                    .await?;
                Ok(true)
            })
            .await?
    }

    pub fn read_count(&self) -> u32 {
        self.events.len() as u32
    }

    pub fn read_by_me(&self) -> bool {
        let Ok(user_id) = self.client.user_id() else {
            return false;
        };
        self.events.contains_key(&user_id)
    }

    pub fn subscribe_stream(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.subscribe()).map(|f| true)
    }

    pub fn subscribe(&self) -> Receiver<()> {
        self.client.subscribe(self.update_key())
    }
}
