use acter_core::{
    events::{
        news::{FallbackNewsContent, NewsContent},
        AnyActerEvent,
    },
    push::default_rules,
};
use anyhow::{bail, Context, Result};
use derive_builder::Builder;
use futures::stream::StreamExt;
use matrix_sdk::{
    notification_settings::{
        IsEncrypted, IsOneToOne, NotificationSettings as SdkNotificationSettings,
    },
    Client as SdkClient,
};
use matrix_sdk_base::{
    notification_settings::RoomNotificationMode,
    ruma::{
        api::client::{
            device,
            push::{
                get_pushers, get_pushrules_all, set_pusher, set_pushrule, EmailPusherData,
                Pusher as RumaPusher, PusherIds, PusherInit, PusherKind,
            },
        },
        assign,
        events::{
            room::{message::MessageType, MediaSource},
            AnySyncMessageLikeEvent, AnySyncTimelineEvent, MessageLikeEvent, SyncMessageLikeEvent,
        },
        push::{HttpPusherData, PushFormat, RuleKind, Ruleset},
        EventId, OwnedMxcUri, OwnedRoomId, RoomId,
    },
};
use matrix_sdk_ui::notification_client::{
    NotificationClient, NotificationEvent, NotificationItem as SdkNotificationItem,
    NotificationProcessSetup, RawNotificationEvent,
};
use ruma::{
    api::client::push::PushRule,
    events::policy::rule,
    push::{Action, NewConditionalPushRule, NewPushRule, PushCondition},
};
use std::{ops::Deref, os::unix::process::parent_id, sync::Arc};
use tokio_stream::{wrappers::BroadcastStream, Stream};
use urlencoding::encode;

use crate::{api::api::FfiBuffer, Client, MsgContent, RoomMessage, RUNTIME};

pub struct Pusher {
    inner: RumaPusher,
    client: Client,
}

impl Pusher {
    pub(super) fn new(inner: RumaPusher, client: Client) -> Self {
        Pusher { inner, client }
    }

    pub fn is_email_pusher(&self) -> bool {
        matches!(self.inner.kind, PusherKind::Email(_))
    }

    pub fn pushkey(&self) -> String {
        self.inner.ids.pushkey.clone()
    }

    pub fn app_id(&self) -> String {
        self.inner.ids.app_id.clone()
    }

    pub fn app_display_name(&self) -> String {
        self.inner.app_display_name.clone()
    }

    pub fn device_display_name(&self) -> String {
        self.inner.device_display_name.clone()
    }

    pub fn lang(&self) -> String {
        self.inner.lang.clone()
    }

    pub fn profile_tag(&self) -> Option<String> {
        self.inner.profile_tag.clone()
    }

    pub async fn delete(&self) -> Result<bool> {
        let client = self.client.deref().clone();
        let app_id = self.app_id();
        let pushkey = self.pushkey();
        RUNTIME
            .spawn(async move {
                // FIXME: how to set `append = true` for single-device-multi-user-support...?!?
                let request = set_pusher::v3::Request::delete(PusherIds::new(pushkey, app_id));
                client.send(request, None).await?;
                Ok(false)
            })
            .await?
    }
}
