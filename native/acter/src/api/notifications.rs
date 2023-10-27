use acter_core::spaces::is_acter_space;
use anyhow::{Context, Result};
use matrix_sdk::ruma::{api::client::push::get_notifications, assign};
use ruma_common::OwnedRoomId;

use crate::{Convo, RoomMessage, Space};

use super::{client::Client, message::sync_event_to_message, room::Room, RUNTIME};

pub struct Notification {
    notification: get_notifications::v3::Notification,
    client: Client,
    room: Option<Room>,
    room_message: Option<RoomMessage>,
    is_space: bool,
    is_acter_space: bool,
}

impl Notification {
    pub(crate) async fn new(
        notification: get_notifications::v3::Notification,
        client: Client,
    ) -> Self {
        let room = client.room_by_id_typed(&notification.room_id);
        let (is_space, is_acter_space) = if let Some(room) = &room {
            if room.is_space() {
                (true, is_acter_space(room).await)
            } else {
                (false, false)
            }
        } else {
            (false, false)
        };
        let room_message = if is_space {
            None
        } else {
            sync_event_to_message(&notification.event, notification.room_id.clone())
        };
        Notification {
            notification,
            client,
            room,
            is_space,
            is_acter_space,
            room_message,
        }
    }

    pub fn read(&self) -> bool {
        self.notification.read
    }

    pub fn room_id(&self) -> OwnedRoomId {
        self.notification.room_id.clone()
    }

    pub fn room_message(&self) -> Option<RoomMessage> {
        self.room_message.clone()
    }

    pub fn room_id_str(&self) -> String {
        self.notification.room_id.to_string()
    }

    pub fn has_room(&self) -> bool {
        self.room.is_some()
    }

    pub fn is_space(&self) -> bool {
        self.is_space
    }

    pub fn is_acter_space(&self) -> bool {
        self.is_acter_space
    }

    pub async fn space(&self) -> Result<Space> {
        self.client
            .space_typed(&self.notification.room_id)
            .await
            .context("Space not found")
    }

    pub async fn convo(&self) -> Result<Convo> {
        self.client
            .convo_typed(&self.notification.room_id)
            .await
            .context("Chat not found")
    }
}

pub struct NotificationListResult {
    resp: get_notifications::v3::Response,
    client: Client,
}

impl NotificationListResult {
    pub fn next_batch(&self) -> Option<String> {
        self.resp.next_token.clone()
    }

    pub async fn notifications(&self) -> Result<Vec<Notification>> {
        let client = self.client.clone();
        let ruma_notifications = self.resp.notifications.clone();
        RUNTIME
            .spawn(async move {
                let notifications = ruma_notifications
                    .into_iter()
                    .map(|notification| Notification::new(notification, client.clone()));
                Ok(futures::future::join_all(notifications).await)
            })
            .await?
    }
}

// internal API
impl Client {
    pub(crate) async fn list_notifications(
        &self,
        since: Option<String>,
        only: Option<String>,
    ) -> Result<NotificationListResult> {
        let c = self.clone();
        RUNTIME
            .spawn(async move {
                let request = assign!(get_notifications::v3::Request::new(), { from: since, only });
                let resp = c.send(request, None).await?;
                Ok(NotificationListResult { resp, client: c })
            })
            .await?
    }
}
