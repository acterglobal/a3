use acter_core::{
    activities::{object::ActivityObject, Activity, ActivityContent},
    events::{
        attachments::{AttachmentContent, FallbackAttachmentContent},
        news::{FallbackNewsContent, NewsContent},
        rsvp::RsvpStatus,
        AnyActerEvent, AnySyncActerEvent, RefDetails, RefPreview, UtcDateTime,
    },
    models::{ActerModel, AnyActerModel, Attachment},
    push::default_rules,
};
use anyhow::{bail, Context, Result};
use chrono::{NaiveDate, NaiveTime, Utc};
use derive_builder::Builder;
use futures::stream::StreamExt;
use matrix_sdk::ruma::{
    api::client::push::PushRule,
    events::{policy::rule, room::message::TextMessageEventContent},
    push::{Action, NewConditionalPushRule, NewPushRule, PushCondition},
    OwnedDeviceId, OwnedEventId,
};
use matrix_sdk::{
    notification_settings::{
        IsEncrypted, IsOneToOne, NotificationSettings as SdkNotificationSettings,
    },
    Client as SdkClient, Room,
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
use tracing::warn;
use urlencoding::encode;

use crate::{Client, Rsvp};

use crate::{api::api::FfiBuffer, MsgContent, RUNTIME};

#[derive(Debug, Clone)]
pub struct NotificationSender {
    user_id: String,
    display_name: Option<String>,
    image: Option<MediaSource>,
    client: Client,
}
impl NotificationSender {
    fn fallback(client: Client) -> Self {
        NotificationSender {
            user_id: "".to_owned(),
            client,
            image: None,
            display_name: None,
        }
    }
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
    async fn for_room(client: Client, room: &Room) -> Self {
        NotificationRoom {
            room_id: room.room_id().to_string(),
            display_name: room
                .display_name()
                .await
                .map(|e| e.to_string())
                .unwrap_or("".to_owned()),
            image: room.avatar_url().clone().map(MediaSource::Plain),
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
#[derive(Clone, Debug)]
pub enum NotificationItemInner {
    Fallback {
        device_id: OwnedDeviceId,
        room_id: OwnedRoomId,
    },
    Invite {
        room_id: OwnedRoomId,
    },
    ChatMessage {
        is_dm: bool,
        content: MessageType,
        room_id: OwnedRoomId,
    },
    Activity(Activity),
}

impl NotificationItemInner {
    pub fn key(&self) -> String {
        match &self {
            NotificationItemInner::Fallback { .. } => "fallback".to_owned(),
            NotificationItemInner::Invite { .. } => "invite".to_owned(),
            NotificationItemInner::Activity(a) => a.type_str(),
            NotificationItemInner::ChatMessage { is_dm, .. } => {
                if *is_dm {
                    "dm"
                } else {
                    "chat"
                }
            }
            .to_owned(),
        }
    }
    pub fn target_url(&self) -> String {
        match &self {
            NotificationItemInner::Fallback { device_id, room_id } => format!(
                "/forward?deviceId={}&roomId={}",
                encode(device_id.as_str()),
                encode(room_id.as_str())
            ),
            NotificationItemInner::Invite { room_id } => "/activities/invites".to_string(),
            NotificationItemInner::ChatMessage { room_id, .. } => format!("/chat/{room_id}"),
            NotificationItemInner::Activity(a) => a.target_url(),
        }
    }

    pub fn room_invite(&self) -> Option<OwnedRoomId> {
        if let NotificationItemInner::Invite { room_id } = &self {
            Some(room_id.clone())
        } else {
            None
        }
    }

    pub fn parent(&self) -> Option<ActivityObject> {
        let NotificationItemInner::Activity(a) = &self else {
            return None;
        };

        a.object()
    }
    pub fn parent_id_str(&self) -> Option<String> {
        let NotificationItemInner::Activity(a) = &self else {
            return None;
        };
        a.object().map(|a| a.object_id_str())
    }

    pub fn reaction_key(&self) -> Option<String> {
        let NotificationItemInner::Activity(a) = &self else {
            return None;
        };
        a.reaction_key()
    }

    pub fn new_date(&self) -> Option<UtcDateTime> {
        let NotificationItemInner::Activity(a) = &self else {
            return None;
        };
        a.new_date()
    }

    pub fn body(&self) -> Option<MsgContent> {
        match &self {
            NotificationItemInner::ChatMessage { content, .. } => match content {
                MessageType::Audio(content) => Some(MsgContent::from(content)),
                MessageType::Emote(content) => Some(MsgContent::from(content)),
                MessageType::File(content) => Some(MsgContent::from(content)),
                MessageType::Location(content) => {
                    // attach the actual content?!?
                    Some(MsgContent::from(content))
                }
                MessageType::Text(content) => Some(MsgContent::from(content)),
                MessageType::Video(content) => {
                    // attach the actual content?!?
                    Some(MsgContent::from(content))
                }
                _ => None,
            },
            NotificationItemInner::Activity(activity) => match activity.content() {
                ActivityContent::DescriptionChange { content, .. } => {
                    content.as_ref().map(|e| MsgContent::from(e.clone()))
                }
                ActivityContent::Comment { content, .. } => Some(MsgContent::from(content)),
                ActivityContent::Boost {
                    first_slide: Some(first_slide),
                    ..
                } => MsgContent::try_from(first_slide).ok(),
                _ => None,
            },

            _ => None,
        }
    }
}

#[derive(Debug, Builder)]
pub struct NotificationItem {
    pub(crate) client: Client,
    pub(crate) title: String,
    pub(crate) sender: NotificationSender,
    pub(crate) room: NotificationRoom,
    #[builder(default)]
    pub(crate) icon_url: Option<String>,
    #[builder(default)]
    pub(crate) noisy: Option<bool>,
    #[builder(setter(into, strip_option), default)]
    pub(crate) thread_id: Option<String>,
    pub(crate) inner: NotificationItemInner,
    #[builder(setter(into, strip_option), default)]
    pub(crate) msg_content: Option<MsgContent>,
    #[builder(default)]
    pub(crate) mentions_you: bool,
}

impl Deref for NotificationItem {
    type Target = NotificationItemInner;

    fn deref(&self) -> &Self::Target {
        &self.inner
    }
}

impl NotificationItem {
    pub fn title(&self) -> String {
        self.title.clone()
    }
    pub fn push_style(&self) -> String {
        self.inner.key()
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
    pub fn noisy(&self) -> bool {
        self.noisy.unwrap_or_default()
    }
    pub fn thread_id(&self) -> Option<String> {
        self.thread_id.clone()
    }
    pub fn room_invite_str(&self) -> Option<String> {
        self.inner.room_invite().map(|r| r.to_string())
    }
    pub fn mentions_you(&self) -> bool {
        self.mentions_you
    }
    pub fn has_image(&self) -> bool {
        self.msg_content.as_ref().and_then(|a| a.source()).is_some()
    }

    pub fn whom(&self) -> Vec<String> {
        let NotificationItemInner::Activity(a) = &self.inner else {
            return vec![];
        };
        a.whom()
    }

    pub async fn image(&self) -> Result<FfiBuffer<u8>> {
        #[allow(clippy::diverging_sub_expression)]
        let Some(Some(source)) = self.msg_content.clone().map(|a| a.source()) else {
            bail!("No media found in item")
        };
        let client = self.client.clone();

        RUNTIME
            .spawn(async move { client.source_binary(source.inner, None).await })
            .await?
    }

    pub async fn image_path(&self, tmp_dir: String) -> Result<String> {
        #[allow(clippy::diverging_sub_expression)]
        let Some(Some(source)) = self.msg_content.clone().map(|a| a.source()) else {
            bail!("No media found in item")
        };
        self.client
            .source_binary_tmp_path(source.inner, None, tmp_dir, "png")
            .await
    }

    pub(super) async fn fallback(client: Client, room_id: OwnedRoomId) -> Result<Self> {
        let mut builder = NotificationItemBuilder::default();
        let device_id = client.device_id()?;
        // setting defaults;
        let mut builder = builder
            .sender(NotificationSender::fallback(client.clone()))
            .title("New messages".to_owned())
            .client(client.clone())
            .thread_id(room_id.to_string())
            .inner(NotificationItemInner::Fallback {
                device_id,
                room_id: room_id.clone(),
            });

        match client.room(room_id.to_string()).await {
            Ok(room) => {
                builder = builder.room(NotificationRoom::for_room(client, &room.room).await)
            }
            Err(error) => tracing::error!(?error, "Error fetching room for notification"),
        };
        Ok(builder.build()?)
    }

    pub(super) async fn from(
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
            .client(client.clone())
            .thread_id(room_id.to_string())
            .title(inner.room_computed_display_name)
            .noisy(inner.is_noisy)
            .inner(NotificationItemInner::Fallback {
                device_id,
                room_id: room_id.clone(),
            }) //default is forward
            .icon_url(inner.room_avatar_url);

        if let NotificationEvent::Invite(invite) = inner.event {
            return Ok(builder
                .inner(NotificationItemInner::Invite {
                    room_id: room_id.clone(),
                })
                .build()?);
        }

        // acter specific items:
        if let RawNotificationEvent::Timeline(raw_tl) = &inner.raw_event {
            if let Ok(event) = raw_tl.deserialize_as::<AnySyncActerEvent>() {
                if !matches!(
                    event,
                    AnySyncActerEvent::RegularTimelineEvent(AnySyncTimelineEvent::MessageLike(_))
                ) {
                    return builder
                        .build_for_acter_object(client, event.into_full_any_acter_event(room_id))
                        .await;
                }
            }
        }

        // fallback chat message:
        if let NotificationEvent::Timeline(AnySyncTimelineEvent::MessageLike(
            AnySyncMessageLikeEvent::RoomMessage(SyncMessageLikeEvent::Original(event)),
        )) = inner.event
        {
            let content = event.content.msgtype.clone();
            return Ok(builder
                .inner(NotificationItemInner::ChatMessage {
                    is_dm: inner.is_direct_message_room,
                    content,
                    room_id,
                })
                .build()?);
        }

        Ok(builder.build()?)
    }
}

async fn convert_acter_model(client: Client, event: AnyActerEvent) -> Result<Activity> {
    Ok(Activity::for_acter_model(client.store(), AnyActerModel::try_from(event)?).await?)
}

impl NotificationItemBuilder {
    async fn build_for_acter_object(
        mut self: NotificationItemBuilder,
        client: Client,
        event: AnyActerEvent,
    ) -> Result<NotificationItem> {
        let user_id = client.user_id()?;
        let activity = match convert_acter_model(client, event).await {
            Err(error) => {
                warn!(?error, "Could not convert acter activity");
                return Ok(self.build()?);
            }
            Ok(a) => a,
        };

        let mut builder = self;

        // a few special cases we want to deal with
        let builder = match activity.content() {
            ActivityContent::Attachment { content, .. } => match content {
                AttachmentContent::Image(i)
                | AttachmentContent::Fallback(FallbackAttachmentContent::Image(i)) => builder
                    .title(
                        i.filename
                            .as_ref()
                            .map(|f| format!("🖼️ \"{f}\""))
                            .unwrap_or("🖼️ Image".to_owned()),
                    ),

                AttachmentContent::Audio(i)
                | AttachmentContent::Fallback(FallbackAttachmentContent::Audio(i)) => builder
                    .title(
                        i.filename
                            .as_ref()
                            .map(|f| format!("🎵 \"{f}\""))
                            .unwrap_or("Audio".to_owned()),
                    ),

                AttachmentContent::Video(i)
                | AttachmentContent::Fallback(FallbackAttachmentContent::Video(i)) => builder
                    .title(
                        i.filename
                            .as_ref()
                            .map(|f| format!("🎥 \"{f}\""))
                            .unwrap_or("Video".to_owned()),
                    ),
                AttachmentContent::Location(i)
                | AttachmentContent::Fallback(FallbackAttachmentContent::Location(i)) => builder
                    .title(
                        i.location
                            .as_ref()
                            .and_then(|l| l.description.as_ref().map(|f| format!("📍 \"{f}\"")))
                            .unwrap_or("📍 Location".to_owned()),
                    ),

                AttachmentContent::File(i)
                | AttachmentContent::Fallback(FallbackAttachmentContent::File(i)) => builder.title(
                    i.filename
                        .as_ref()
                        .map(|f| format!("📄 \"{f}\""))
                        .unwrap_or("📄 File".to_owned()),
                ),
                AttachmentContent::Link(i) => builder.title(
                    i.name
                        .as_ref()
                        .map(|f| format!("🔗 \"{f}\""))
                        .unwrap_or("Link".to_owned()),
                ),
                _ => &mut builder,
            },
            ActivityContent::Reference { object, details } => {
                if let RefDetails::Room {
                    preview:
                        RefPreview {
                            room_display_name: Some(room_name),
                            ..
                        },
                    ..
                } = details
                {
                    builder.title(room_name.clone())
                } else if let Some(title) = details.title() {
                    builder.title(match details {
                        RefDetails::CalendarEvent { .. } => format!("🗓️ {title}"),
                        RefDetails::Pin { .. } => format!("📌 {title}"),
                        RefDetails::News { .. } => "🚀 boost".to_string(),
                        RefDetails::Task { .. } => format!("☑️ {title}"),
                        RefDetails::TaskList { .. } => format!("📋 {title}"),
                        RefDetails::Link { .. } => format!("🔗 {title}"),
                        RefDetails::Room { .. } => title,
                        RefDetails::SuperInviteToken { .. } => title,
                    })
                } else {
                    builder.title("Reference".to_owned())
                }
            }
            ActivityContent::TitleChange { new_title, .. } => builder.title(new_title.clone()),
            ActivityContent::EventDateChange { new_date, .. } => {
                builder.title(new_date.to_rfc3339())
            }
            ActivityContent::TaskDueDateChange {
                new_due_date: Some(new_due_date),
                ..
            } => builder.title(new_due_date.format("%Y-%m-%d").to_string()),
            ActivityContent::TaskDueDateChange { new_due_date, .. } => {
                builder.title("removed due date".to_owned())
            }
            ActivityContent::TaskAdd { task, .. } => builder.title(task.title().clone()),
            ActivityContent::DescriptionChange {
                object,
                content: Some(content),
            } => builder.msg_content(MsgContent::from(content)),
            ActivityContent::ObjectInvitation { object, invitees } => builder
                .title(object.title().unwrap_or("Object".to_owned()))
                .mentions_you(invitees.contains(&user_id)),
            _ => &mut builder,
        };

        Ok(builder
            .inner(NotificationItemInner::Activity(activity))
            .build()?)
    }
}
