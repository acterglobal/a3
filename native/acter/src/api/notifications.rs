pub use acter_core::spaces::{
    CreateSpaceSettings, CreateSpaceSettingsBuilder, RelationTargetType, SpaceRelation,
    SpaceRelations,
};
use acter_core::{
    executor::Executor, models::AnyActerModel, spaces::is_acter_space,
    statics::default_acter_space_states, templates::Engine,
};
use anyhow::{bail, Context, Result};
use futures::stream::StreamExt;
use matrix_sdk::{
    deserialized_responses::EncryptionInfo,
    event_handler::{Ctx, EventHandlerHandle},
    room::{Messages, MessagesOptions, Room as SdkRoom},
    ruma::{
        api::client::state::send_state_event::v3::Request as SendStateEventRequest,
        events::{
            space::child::SpaceChildEventContent, AnyStateEventContent, MessageLikeEvent,
            StateEventType,
        },
        serde::Raw,
        OwnedRoomAliasId, OwnedRoomId, OwnedUserId,
    },
    Client as SdkClient,
};
use ruma::api::client::push::get_notifications::v3::Notification as RumaNotification;
use ruma::{
    assign, directory::PublicRoomJoinRule, room::RoomType, OwnedMxcUri, OwnedRoomOrAliasId,
    OwnedServerName,
};
use serde::{Deserialize, Serialize};
use std::ops::Deref;
use tokio::sync::broadcast::Receiver;
use tracing::{error, trace};

use crate::{Convo, Space};

use super::{
    client::{devide_spaces_from_convos, Client, SpaceFilter, SpaceFilterBuilder},
    room::{Member, Room},
    RUNTIME,
};

pub struct Notification {
    notification: RumaNotification,
    client: Client,
    room: Option<Room>,
    is_space: bool,
    is_acter_space: bool,
}

impl Notification {
    pub(crate) async fn new(notification: RumaNotification, client: Client) -> Self {
        let room = client.room_typed(&notification.room_id);
        let (is_space, is_acter_space) = if let Some(room) = &room {
            if room.is_space() {
                (true, room.is_acter_space().await)
            } else {
                (true, false)
            }
        } else {
            (false, false)
        };
        let mut me = Notification {
            notification,
            client,
            room,
            is_space,
            is_acter_space,
        };

        me
    }
    pub fn read(&self) -> bool {
        self.notification.read
    }
    pub fn room_id(&self) -> OwnedRoomId {
        self.notification.room_id.clone()
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
    pub fn space(&self) -> Option<Space> {
        self.room.as_ref().map(|r| Space {
            inner: r.clone(),
            client: self.client.clone(),
        })
    }
    pub fn convo(&self) -> Option<Convo> {
        self.room.as_ref().map(|r| Convo::new(r.clone()))
    }
}

pub struct NotificationListResult {
    resp: ruma::api::client::push::get_notifications::v3::Response,
    client: Client,
}

impl NotificationListResult {
    pub fn next_batch(&self) -> Option<String> {
        self.resp.next_token.clone()
    }
    pub async fn notifications(&self) -> Result<Vec<Notification>> {
        let client = self.client.clone();
        let notifs = self.resp.notifications.clone();
        Ok(RUNTIME
            .spawn(async move {
                futures::future::join_all(
                    notifs.into_iter().map(|notification| {
                        Notification::new(notification.clone(), client.clone())
                    }),
                )
                .await
            })
            .await?)
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
                let request = assign!(ruma::api::client::push::get_notifications::v3::Request::new(), { from: since, only});
                let resp = c.send(request, None).await?;
                Ok(NotificationListResult{ resp, client: c })
            })
            .await?
    }
}
