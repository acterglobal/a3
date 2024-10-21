use acter_core::models::{self, ActerModel, AnyActerModel};
use anyhow::{bail, Result};
use futures::stream::StreamExt;
use matrix_sdk::room::Room;
use matrix_sdk_base::ruma::{
    events::MessageLikeEventType, OwnedEventId, OwnedTransactionId, OwnedUserId, UserId,
};
use std::ops::Deref;
use tokio::sync::broadcast::Receiver;
use tokio_stream::{wrappers::BroadcastStream, Stream};

use super::{client::Client, RUNTIME};

// #[derive(Clone, Debug)]
// pub struct ReadReceipts {
// }

// impl Deref for ReadReceipts {
//     type Target = models::ReadReceipts;
//     fn deref(&self) -> &Self::Target {
//         &self.inner
//     }
// }

// impl ReadReceipts {
//     pub fn event_id_str(&self) -> String {
//         self.inner.event_id().to_string()
//     }

//     pub fn sender(&self) -> OwnedUserId {
//         self.inner.meta.sender.clone()
//     }

//     pub fn origin_server_ts(&self) -> u64 {
//         self.inner.meta.origin_server_ts.get().into()
//     }

//     pub fn relates_to(&self) -> String {
//         self.inner.relates_to.event_id.to_string()
//     }
// }

#[derive(Clone, Debug)]
pub struct ReadReceiptsManager {
    client: Client,
    room: Room,
    event_id: OwnedEventId,
    // inner: models::ReadReceiptsManager,
}

// impl Deref for ReadReceiptsManager {
//     type Target = models::ReadReceiptsManager;
//     fn deref(&self) -> &Self::Target {
//         &self.inner
//     }
// }

impl ReadReceiptsManager {
    pub(crate) async fn new(
        client: Client,
        room: Room,
        event_id: OwnedEventId,
    ) -> Result<ReadReceiptsManager> {
        Ok(ReadReceiptsManager {
            client,
            room,
            event_id,
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

    pub async fn mark_read(&self) -> Result<OwnedEventId> {
        unimplemented!();
        // let room = self.room.clone();
        // let my_id = self.client.user_id()?;
        // let event = self.inner.construct_like_event();

        // RUNTIME
        //     .spawn(async move {
        //         let permitted = room
        //             .can_user_send_message(&my_id, MessageLikeEventType::ReadReceipts)
        //             .await?;
        //         if !permitted {
        //             bail!("No permission to send reaction in this room");
        //         }
        //         let response = room.send(event).await?;
        //         Ok(response.event_id)
        //     })
        //     .await?
    }

    // pub fn stats(&self) -> models::ReadReceiptsStats {
    //     self.inner.stats().clone()
    // }

    pub fn seen_count(&self) -> u32 {
        0
        // self.inner.stats().total_like_reactions
    }

    pub fn seen_by_me(&self) -> bool {
        false
    }

    pub fn subscribe_stream(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.subscribe()).map(|f| true)
    }

    pub fn subscribe(&self) -> Receiver<()> {
        unimplemented!();
        // self.client.subscribe(self.inner.update_key())
    }
}
