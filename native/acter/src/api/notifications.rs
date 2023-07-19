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
use ruma::{
    assign, directory::PublicRoomJoinRule, room::RoomType, OwnedMxcUri, OwnedRoomOrAliasId,
    OwnedServerName,
};
use serde::{Deserialize, Serialize};
use std::ops::Deref;
use tokio::sync::broadcast::Receiver;
use tracing::{error, trace};

use super::{
    client::{devide_spaces_from_convos, Client, SpaceFilter, SpaceFilterBuilder},
    room::{Member, Room},
    RUNTIME,
};

pub struct Notification {
    notification: ruma::api::client::push::get_notifications::v3::Notification,
    client: Client,
}

impl Notification {
    pub fn read(&self) -> bool {
        self.notification.read
    }
    pub fn room_id(&self) -> OwnedRoomId {
        self.notification.room_id.clone()
    }
    pub fn room_id_str(&self) -> String {
        self.notification.room_id.to_string()
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
    pub fn notifications(&self) -> Vec<Notification> {
        self.resp
            .notifications
            .iter()
            .map(|notification| Notification {
                notification: notification.clone(),
                client: self.client.clone(),
            })
            .collect()
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
