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

use crate::Client;

use crate::{api::api::FfiBuffer, MsgContent, RoomMessage, RUNTIME};

#[derive(Debug, Clone)]
pub struct NotificationSender {
    user_id: String,
    display_name: Option<String>,
    image: Option<MediaSource>,
    client: Client,
}
impl NotificationSender {
    fn from(client: Client, notif: &SdkNotificationItem) -> Self {
        NotificationSender {
            user_id: notif.event.sender().to_string(),
            display_name: notif.sender_display_name.clone(),
            image: notif
                .sender_avatar_url
                .clone()
                .map(|u| MediaSource::Plain(OwnedMxcUri::from(u))),
            client,
        }
    }
    pub fn user_id(&self) -> String {
        self.user_id.clone()
    }
    pub fn display_name(&self) -> Option<String> {
        self.display_name.clone()
    }
    pub fn has_image(&self) -> bool {
        self.image.is_some()
    }
    pub async fn image(&self) -> Result<FfiBuffer<u8>> {
        #[allow(clippy::diverging_sub_expression)]
        let Some(source) = self.image.clone() else {
            bail!("No media found in item")
        };
        let client = self.client.clone();

        RUNTIME
            .spawn(async move { client.source_binary(source, None).await })
            .await?
    }
}

#[derive(Debug, Clone)]
pub struct NotificationRoom {
    room_id: String,
    display_name: String,
    image: Option<MediaSource>,
    client: Client,
}
impl NotificationRoom {
    fn from(client: Client, notif: &SdkNotificationItem, room_id: &RoomId) -> Self {
        NotificationRoom {
            room_id: room_id.to_string(),
            display_name: notif.room_computed_display_name.clone(),
            image: notif
                .room_avatar_url
                .clone()
                .map(|u| MediaSource::Plain(OwnedMxcUri::from(u))),
            client,
        }
    }
    pub fn room_id(&self) -> String {
        self.room_id.clone()
    }
    pub fn display_name(&self) -> String {
        self.display_name.clone()
    }
    pub fn has_image(&self) -> bool {
        self.image.is_some()
    }
    pub async fn image(&self) -> Result<FfiBuffer<u8>> {
        #[allow(clippy::diverging_sub_expression)]
        let Some(source) = self.image.clone() else {
            bail!("No media found in item")
        };
        let client = self.client.clone();

        RUNTIME
            .spawn(async move { client.source_binary(source, None).await })
            .await?
    }
}

#[derive(Debug, Builder)]
pub struct NotificationItem {
    pub(crate) client: Client,
    pub(crate) title: String,
    pub(crate) push_style: String,
    pub(crate) target_url: String,
    pub(crate) sender: NotificationSender,
    pub(crate) room: NotificationRoom,
    #[builder(default)]
    pub(crate) icon_url: Option<String>,
    #[builder(setter(into, strip_option), default)]
    pub(crate) body: Option<MsgContent>,
    #[builder(default)]
    pub(crate) noisy: Option<bool>,
    #[builder(setter(into, strip_option), default)]
    pub(crate) thread_id: Option<String>,
    #[builder(setter(into, strip_option), default)]
    pub(crate) room_invite: Option<String>,
    #[builder(setter(into, strip_option), default)]
    pub(crate) image: Option<MediaSource>,
}

impl NotificationItem {
    pub fn title(&self) -> String {
        self.title.clone()
    }
    pub fn push_style(&self) -> String {
        self.push_style.clone()
    }
    pub fn target_url(&self) -> String {
        self.target_url.clone()
    }
    pub fn sender(&self) -> NotificationSender {
        self.sender.clone()
    }
    pub fn room(&self) -> NotificationRoom {
        self.room.clone()
    }
    pub fn icon_url(&self) -> Option<String> {
        self.icon_url.clone()
    }
    pub fn body(&self) -> Option<MsgContent> {
        self.body.clone()
    }
    pub fn noisy(&self) -> bool {
        self.noisy.unwrap_or_default()
    }
    pub fn thread_id(&self) -> Option<String> {
        self.thread_id.clone()
    }
    pub fn room_invite(&self) -> Option<String> {
        self.room_invite.clone()
    }
    pub fn has_image(&self) -> bool {
        self.image.is_some()
    }
    pub async fn image(&self) -> Result<FfiBuffer<u8>> {
        #[allow(clippy::diverging_sub_expression)]
        let Some(source) = self.image.clone() else {
            bail!("No media found in item")
        };
        let client = self.client.clone();

        RUNTIME
            .spawn(async move { client.source_binary(source, None).await })
            .await?
    }

    pub async fn image_path(&self, tmp_dir: String) -> Result<String> {
        #[allow(clippy::diverging_sub_expression)]
        let Some(source) = self.image.clone() else {
            bail!("No media found in item")
        };
        self.client
            .source_binary_tmp_path(source, None, tmp_dir, "png")
            .await
    }

    pub(super) fn from(
        client: Client,
        inner: SdkNotificationItem,
        room_id: OwnedRoomId,
    ) -> Result<Self> {
        let mut builder = NotificationItemBuilder::default();
        let device_id = client.device_id()?;
        // setting defaults;
        builder
            .sender(NotificationSender::from(client.clone(), &inner))
            .room(NotificationRoom::from(client.clone(), &inner, &room_id))
            .client(client)
            .thread_id(room_id.to_string())
            .title(inner.room_computed_display_name)
            .noisy(inner.is_noisy)
            .push_style("fallback".to_owned())
            .target_url(format!(
                "/forward?deviceId={}&roomId={}",
                encode(device_id.as_str()),
                encode(room_id.as_str())
            )) //default is forward
            .icon_url(inner.room_avatar_url);

        if let NotificationEvent::Invite(invite) = inner.event {
            return Ok(builder
                .target_url("/activities/invites".to_string())
                // FIXME: we still need support for specific activities linking
                // .target_url(format!("/activities/{:}", room_id))
                .room_invite(room_id.to_string())
                .push_style("invite".to_owned())
                .build()?);
        }

        if let RawNotificationEvent::Timeline(raw_tl) = &inner.raw_event {
            if let Ok(AnyActerEvent::NewsEntry(MessageLikeEvent::Original(e))) =
                raw_tl.deserialize_as::<AnyActerEvent>()
            {
                if let Some(first_slide) = e.content.slides.first() {
                    match &first_slide.content {
                        // we have improved support for showing images
                        NewsContent::Fallback(FallbackNewsContent::Image(msg_content))
                        | NewsContent::Image(msg_content) => {
                            builder.image(msg_content.source.clone());
                        }
                        // everything else we have to fallback to the body-text thing ...
                        NewsContent::Fallback(FallbackNewsContent::Text(msg_content))
                        | NewsContent::Text(msg_content) => {
                            builder.body(msg_content);
                        }
                        NewsContent::Fallback(FallbackNewsContent::Video(msg_content))
                        | NewsContent::Video(msg_content) => {
                            builder.body(MsgContent::from(msg_content));
                        }
                        NewsContent::Fallback(FallbackNewsContent::Audio(msg_content))
                        | NewsContent::Audio(msg_content) => {
                            builder.body(MsgContent::from(msg_content));
                        }
                        NewsContent::Fallback(FallbackNewsContent::File(msg_content))
                        | NewsContent::File(msg_content) => {
                            builder.body(MsgContent::from(msg_content));
                        }
                        NewsContent::Fallback(FallbackNewsContent::Location(msg_content))
                        | NewsContent::Location(msg_content) => {
                            builder.body(MsgContent::from(msg_content));
                        }
                    }
                    return Ok(builder
                        .target_url("/updates".to_owned())
                        // FIXME: link to each specific update directly.
                        // .target_url(format!("/updates/{:}", e.event_id))
                        .push_style("news".to_owned())
                        .build()?);
                }
            }
        };

        if let NotificationEvent::Timeline(AnySyncTimelineEvent::MessageLike(
            AnySyncMessageLikeEvent::RoomMessage(SyncMessageLikeEvent::Original(event)),
        )) = inner.event
        {
            if match event.content.msgtype {
                MessageType::Audio(content) => {
                    builder.body(MsgContent::from(&content));
                    true
                }
                MessageType::Emote(content) => {
                    builder.body(MsgContent::from(&content));
                    true
                }
                MessageType::File(content) => {
                    builder.body(MsgContent::from(&content));
                    true
                }
                MessageType::Image(content) => {
                    builder.image(content.source);
                    true
                }
                MessageType::Location(content) => {
                    // attach the actual content?!?
                    builder.body(MsgContent::from(&content));
                    true
                }
                MessageType::Text(content) => {
                    builder.body(MsgContent::from(content));
                    true
                }
                MessageType::Video(content) => {
                    // attach the actual content?!?
                    builder.body(MsgContent::from(&content));
                    true
                }
                _ => false,
            } {
                // a compatible message
                if inner.is_direct_message_room {
                    builder.push_style("dm".to_owned());
                } else {
                    builder.push_style("chat".to_owned());
                }
                builder.target_url(format!("/chat/{:}", room_id));
            }
        }

        Ok(builder.build()?)
    }
}
