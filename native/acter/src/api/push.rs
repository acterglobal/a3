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

use super::Client;

use crate::{api::api::FfiBuffer, MsgContent, RoomMessage, RUNTIME};

pub(crate) fn room_notification_mode_name(input: &RoomNotificationMode) -> String {
    match input {
        RoomNotificationMode::AllMessages => "all".to_owned(),
        RoomNotificationMode::MentionsAndKeywordsOnly => "mentions".to_owned(),
        RoomNotificationMode::Mute => "muted".to_owned(),
    }
}

pub(crate) fn notification_mode_from_input(input: &str) -> Option<RoomNotificationMode> {
    match input.trim().to_lowercase().as_str() {
        "all" => Some(RoomNotificationMode::AllMessages),
        "mentions" => Some(RoomNotificationMode::MentionsAndKeywordsOnly),
        "muted" => Some(RoomNotificationMode::Mute),
        _ => None,
    }
}

// pub struct NotificationItem {
//     pub(crate) inner: SdkNotificationItem,
//     pub(crate) acter_event: Option<AnyActerEvent>,
//     pub(crate) room_id: OwnedRoomId,
// }

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

    fn from(client: Client, inner: SdkNotificationItem, room_id: OwnedRoomId) -> Result<Self> {
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

pub struct Pusher {
    inner: RumaPusher,
    client: Client,
}

impl Pusher {
    fn new(inner: RumaPusher, client: Client) -> Self {
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

                let notif = notif_client
                    .get_notification(&room_id, &event_id)
                    .await?
                    .context("(hidden notification)")?;
                NotificationItem::from(me, notif, room_id)
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
                client.send(request, None).await?;
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
        let push_data = if with_ios_defaults {
            assign!(HttpPusherData::new(server_url), {
                // we only send over the event id & room id, preventing the service from
                // leaking any further information to apple
                // additionally this prevents sygnal (the push relayer) from adding
                // further information in the json that will then be displayed as fallback
                format: Some(PushFormat::EventIdOnly),
                default_payload: serde_json::json!({
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
                })
            })
        } else {
            assign!(HttpPusherData::new(server_url), {
                default_payload: serde_json::json!({
                    "device_id": device_id,
                })
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
                client.send(request, None).await?;
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
                    .send(get_pushers::v3::Request::new(), None)
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
                    let resp = client
                        .send(set_pushrule::v3::Request::new(rule), None)
                        .await?;
                }
                Ok(true)
            })
            .await?
    }

    pub async fn push_rules(&self) -> Result<Ruleset> {
        let client = self.core.client().clone();
        RUNTIME
            .spawn(async move {
                let resp = client
                    .send(get_pushrules_all::v3::Request::new(), None)
                    .await?;
                Ok(resp.global)
            })
            .await?
    }
}

fn make_notification_key(parent_id: &str, sub_type: Option<&String>) -> String {
    if let Some(sub) = sub_type {
        format!("acter::rel::{parent_id}::{sub}")
    } else {
        format!("acter::rel::{parent_id}")
    }
}

fn make_push_rule(parent_id: &str, sub_type: Option<&String>) -> NewConditionalPushRule {
    let push_key = make_notification_key(parent_id, sub_type);
    let mut conditions = vec![PushCondition::EventPropertyIs {
        key: "content.m\\.relates_to".to_owned(),
        value: parent_id.to_owned().into(),
    }];
    if let Some(event_type) = sub_type {
        conditions.push(PushCondition::EventPropertyIs {
            key: "type".to_owned(),
            value: event_type.to_owned().into(),
        })
    }
    NewConditionalPushRule::new(push_key, conditions, vec![Action::Notify])
}

#[derive(Debug, Clone)]
pub struct NotificationSettings {
    client: SdkClient,
    inner: Arc<SdkNotificationSettings>,
}
impl NotificationSettings {
    pub fn new(client: SdkClient, inner: SdkNotificationSettings) -> Self {
        NotificationSettings {
            client,
            inner: Arc::new(inner),
        }
    }

    pub fn changes_stream(&self) -> impl Stream<Item = bool> {
        BroadcastStream::new(self.inner.subscribe_to_changes()).map(|_| true)
    }

    pub async fn object_push_subscription_status_str(
        &self,
        object_id: String,
        sub_type: Option<String>,
    ) -> Result<String> {
        let inner = self.inner.clone();
        RUNTIME
            .spawn(async move {
                if sub_type.is_some() {
                    // check for the full key:
                    if inner
                        .is_push_rule_enabled(
                            RuleKind::Override,
                            make_notification_key(&object_id, sub_type.as_ref()),
                        )
                        .await?
                    {
                        return Ok("subscribed".to_owned());
                    }
                }
                // check for the parent key as fallback
                if inner
                    .is_push_rule_enabled(
                        RuleKind::Override,
                        make_notification_key(&object_id, None),
                    )
                    .await?
                {
                    if sub_type.is_some() {
                        return Ok("parent".to_owned());
                    } else {
                        return Ok("subscribed".to_owned());
                    }
                }
                Ok("none".to_owned())
            })
            .await?
    }

    pub async fn subscribe_object_push(
        &self,
        object_id: String,
        sub_type: Option<String>,
    ) -> Result<bool> {
        let inner = self.inner.clone();
        let client = self.client.clone();
        RUNTIME
            .spawn(async move {
                let rules = client.account().push_rules().await?.override_;
                let notif_key = make_notification_key(&object_id, sub_type.as_ref());
                let mut found = false;
                for rule in rules {
                    if rule.rule_id == notif_key {
                        if rule.enabled {
                            return Ok(true);
                        }
                        found = true;
                        break;
                    }
                }

                if found {
                    inner
                        .set_push_rule_enabled(RuleKind::Override, notif_key, true)
                        .await?;
                    return Ok(true);
                }
                // not found, we have to create it the first time:
                let new_push_rule = make_push_rule(&object_id, sub_type.as_ref());

                let resp = client
                    .send(
                        set_pushrule::v3::Request::new(NewPushRule::Override(new_push_rule)),
                        None,
                    )
                    .await?;

                Ok(true)
            })
            .await?
    }

    pub async fn unsubscribe_object_push(
        &self,
        object_id: String,
        sub_type: Option<String>,
    ) -> Result<bool> {
        let inner = self.inner.clone();
        RUNTIME
            .spawn(async move {
                // check for the full key:
                inner
                    .set_push_rule_enabled(
                        RuleKind::Override,
                        make_notification_key(&object_id, sub_type.as_ref()),
                        false,
                    )
                    .await?;
                Ok(true)
            })
            .await?
    }

    pub async fn default_notification_mode(
        &self,
        is_encrypted: bool,
        is_one_to_one: bool,
    ) -> Result<String> {
        let inner = self.inner.clone();
        RUNTIME
            .spawn(async move {
                let mode = inner
                    .get_default_room_notification_mode(
                        IsEncrypted::from(is_encrypted),
                        IsOneToOne::from(is_one_to_one),
                    )
                    .await;
                Ok(room_notification_mode_name(&mode))
            })
            .await?
    }

    pub async fn set_default_notification_mode(
        &self,
        is_encrypted: bool,
        is_one_to_one: bool,
        mode: String,
    ) -> Result<bool> {
        let new_level =
            notification_mode_from_input(&mode).context("Unknown Notification Level")?;
        let inner = self.inner.clone();
        RUNTIME
            .spawn(async move {
                inner
                    .set_default_room_notification_mode(
                        IsEncrypted::from(is_encrypted),
                        IsOneToOne::from(is_one_to_one),
                        new_level,
                    )
                    .await?;
                Ok(true)
            })
            .await?
    }

    pub async fn global_content_setting(&self, content_key: String) -> Result<bool> {
        let inner = self.inner.clone();
        RUNTIME
            .spawn(async move {
                let result = inner
                    .is_push_rule_enabled(RuleKind::Underride, content_key)
                    .await?;
                Ok(result)
            })
            .await?
    }

    pub async fn set_global_content_setting(
        &self,
        content_key: String,
        enabled: bool,
    ) -> Result<bool> {
        let inner = self.inner.clone();
        RUNTIME
            .spawn(async move {
                inner
                    .set_push_rule_enabled(RuleKind::Underride, content_key, enabled)
                    .await?;
                Ok(enabled)
            })
            .await?
    }
}
