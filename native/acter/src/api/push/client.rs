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
use matrix_sdk::ruma::{
    api::client::push::PushRule,
    events::policy::rule,
    push::{Action, NewConditionalPushRule, NewPushRule, PushCondition},
    serde::JsonObject,
};
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
use std::{ops::Deref, sync::Arc};
use tokio_stream::{wrappers::BroadcastStream, Stream};
use urlencoding::encode;

use super::{NotificationItem, NotificationSettings, Pusher};

use crate::{api::api::FfiBuffer, Client, MsgContent, RoomMessage, RUNTIME};

impl Client {
    pub async fn get_notification_item(
        &self,
        room_id: String,
        event_id: String,
    ) -> Result<NotificationItem> {
        let me = self.clone();
        let room_id = RoomId::parse(room_id)?;
        let event_id = EventId::parse(event_id)?;
        RUNTIME
            .spawn(async move {
                let notif_client = NotificationClient::new(
                    me.core.client().clone(),
                    NotificationProcessSetup::MultipleProcesses,
                )
                .await?;

                let Some(notif) = notif_client.get_notification(&room_id, &event_id).await? else {
                    tracing::warn!("Notification couldn't be loaded. Showing fallback");
                    return NotificationItem::fallback(me, room_id).await
                };

                NotificationItem::from(me, notif, room_id).await
            })
            .await?
    }

    pub async fn notification_settings(&self) -> Result<NotificationSettings> {
        let client = self.core.client().clone();
        RUNTIME
            .spawn(async move {
                let inner = client.notification_settings().await;
                Ok(NotificationSettings::new(client, inner))
            })
            .await?
    }

    pub async fn add_email_pusher(
        &self,
        device_name: String,
        app_name: String,
        email: String,
        lang: Option<String>,
    ) -> Result<bool> {
        let pusher_data = PusherInit {
            ids: PusherIds::new(email, "m.email".to_owned()),
            kind: PusherKind::Email(EmailPusherData::new()),
            app_display_name: app_name,
            device_display_name: device_name,
            profile_tag: None,
            lang: lang.unwrap_or("en".to_owned()),
        };
        let client = self.core.client().clone();
        RUNTIME
            .spawn(async move {
                // FIXME: how to set `append = true` for single-device-multi-user-support...?!?
                let request = set_pusher::v3::Request::post(pusher_data.into());
                client.send(request).await?;
                Ok(false)
            })
            .await?
    }

    #[allow(clippy::too_many_arguments)]
    pub async fn add_pusher(
        &self,
        app_id: String,
        token: String,
        device_name: String,
        app_name: String,
        server_url: String,
        with_ios_defaults: bool,
        lang: Option<String>,
    ) -> Result<bool> {
        let client = self.core.client().clone();
        let device_id = self.device_id()?;
        let mut data = JsonObject::default();
        data.insert(
            "default_payload".to_owned(),
            serde_json::json!({
                "aps": {
                    // specific tags to ensure the iOS notifications work as expected
                    //
                    // allows us to change the content in the extension:
                    "mutable-content": 1,
                    // make sure this goes to the foreground process, too:
                    "content-available": 1,
                    // the fallback message if the extension fails to load:
                    "alert": {
                        "title": "Acter",
                        "body": "New messages available",
                    },

                    // Further information: by sending only the event-id and including the `alert`
                    // text in the aps payload, apple will regard this as _important_ messages
                    // that have to be delivered and processed by the background services
                },
                // include the device-id allowing us to identify _which_ client we
                // need to process that with
                "device_id": device_id,
            }),
        );
        let push_data = if with_ios_defaults {
            assign!(HttpPusherData::new(server_url), {
                // we only send over the event id & room id, preventing the service from
                // leaking any further information to apple
                // additionally this prevents sygnal (the push relayer) from adding
                // further information in the json that will then be displayed as fallback
                format: Some(PushFormat::EventIdOnly),
                data: data
            })
        } else {
            let mut data = JsonObject::default();
            data.insert(
                "default_payload".to_owned(),
                serde_json::json!({
                    "device_id": device_id,
                }),
            );
            assign!(HttpPusherData::new(server_url), {
                data: data
            })
        };
        let pusher_data = PusherInit {
            ids: PusherIds::new(token, app_id),
            kind: PusherKind::Http(push_data),
            app_display_name: app_name,
            device_display_name: device_name,
            profile_tag: None,
            lang: lang.unwrap_or("en".to_owned()),
        };
        RUNTIME
            .spawn(async move {
                // FIXME: how to set `append = true` for single-device-multi-user-support...?!?
                let request = set_pusher::v3::Request::post(pusher_data.into());
                client.send(request).await?;
                Ok(false)
            })
            .await?
    }

    pub async fn pushers(&self) -> Result<Vec<Pusher>> {
        let me = self.clone();
        RUNTIME
            .spawn(async move {
                let resp = me
                    .core
                    .client()
                    .send(get_pushers::v3::Request::new())
                    .await?;
                let items = resp
                    .pushers
                    .into_iter()
                    .map(|inner| Pusher::new(inner, me.clone()))
                    .collect();
                Ok(items)
            })
            .await?
    }

    pub async fn install_default_acter_push_rules(&self) -> Result<bool> {
        let client = self.core.client().clone();
        RUNTIME
            .spawn(async move {
                for rule in default_rules() {
                    let resp = client.send(set_pushrule::v3::Request::new(rule)).await?;
                }
                Ok(true)
            })
            .await?
    }

    pub async fn push_rules(&self) -> Result<Ruleset> {
        let client = self.core.client().clone();
        RUNTIME
            .spawn(async move {
                let resp = client.send(get_pushrules_all::v3::Request::new()).await?;
                Ok(resp.global)
            })
            .await?
    }
}
