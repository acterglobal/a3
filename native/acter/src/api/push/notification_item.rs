use acter_core::{
    events::{
        news::{FallbackNewsContent, NewsContent},
        AnyActerEvent, SyncAnyActerEvent,
    },
    models::{ActerModel, AnyActerModel},
    push::default_rules,
};
use anyhow::{bail, Context, Result};
use derive_builder::Builder;
use futures::stream::StreamExt;
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
use ruma::{
    api::client::push::PushRule,
    events::{policy::rule, room::message::TextMessageEventContent},
    push::{Action, NewConditionalPushRule, NewPushRule, PushCondition},
    OwnedDeviceId, OwnedEventId,
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
                .compute_display_name()
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
pub enum NotificationItemParent {
    News {
        parent_id: OwnedEventId,
    },
    Pin {
        parent_id: OwnedEventId,
        title: String,
    },
    CalendarEvent {
        parent_id: OwnedEventId,
        title: String,
    },
}

impl NotificationItemParent {
    pub fn object_type_str(&self) -> String {
        match self {
            NotificationItemParent::News { .. } => "news",
            NotificationItemParent::Pin { parent_id, title } => "pin",
            NotificationItemParent::CalendarEvent { parent_id, title } => "event",
        }
        .to_owned()
    }
    pub fn object_id_str(&self) -> String {
        match self {
            NotificationItemParent::News { parent_id }
            | NotificationItemParent::Pin { parent_id, .. }
            | NotificationItemParent::CalendarEvent { parent_id, .. } => parent_id.to_string(),
        }
    }
    pub fn title(&self) -> Option<String> {
        match self {
            NotificationItemParent::News { parent_id } => None,
            NotificationItemParent::Pin { title, .. }
            | NotificationItemParent::CalendarEvent { title, .. } => Some(title.clone()),
        }
    }

    pub fn target_url(&self) -> String {
        match self {
            NotificationItemParent::News { .. } => "/news".to_owned(),
            NotificationItemParent::Pin { parent_id, .. } => format!("/pins/{}", parent_id),
            NotificationItemParent::CalendarEvent { parent_id, .. } => {
                format!("/events/{}", parent_id)
            } //
        }
    }

    pub fn emoji(&self) -> String {
        match self {
            NotificationItemParent::News { .. } => "🚀", // boost rocket
            NotificationItemParent::Pin { .. } => "📌",  // pin
            NotificationItemParent::CalendarEvent { .. } => "🗓️", // calendar
        }
        .to_owned()
    }
}

impl TryFrom<&AnyActerModel> for NotificationItemParent {
    type Error = ();

    fn try_from(value: &AnyActerModel) -> std::result::Result<Self, Self::Error> {
        match value {
            AnyActerModel::NewsEntry(e) => Ok(NotificationItemParent::News {
                parent_id: e.event_id().to_owned(),
            }),
            AnyActerModel::CalendarEvent(e) => Ok(NotificationItemParent::CalendarEvent {
                parent_id: e.event_id().to_owned(),
                title: e.title().clone(),
            }),
            AnyActerModel::Pin(e) => Ok(NotificationItemParent::Pin {
                parent_id: e.event_id().to_owned(),
                title: e.title().clone(),
            }),
            AnyActerModel::RedactedActerModel(_)
            | AnyActerModel::CalendarEventUpdate(_)
            | AnyActerModel::TaskList(_)
            | AnyActerModel::TaskListUpdate(_)
            | AnyActerModel::Task(_)
            | AnyActerModel::TaskUpdate(_)
            | AnyActerModel::TaskSelfAssign(_)
            | AnyActerModel::TaskSelfUnassign(_)
            | AnyActerModel::PinUpdate(_)
            | AnyActerModel::NewsEntryUpdate(_)
            | AnyActerModel::Story(_)
            | AnyActerModel::StoryUpdate(_)
            | AnyActerModel::Comment(_)
            | AnyActerModel::CommentUpdate(_)
            | AnyActerModel::Attachment(_)
            | AnyActerModel::AttachmentUpdate(_)
            | AnyActerModel::Rsvp(_)
            | AnyActerModel::Reaction(_)
            | AnyActerModel::ReadReceipt(_) => {
                tracing::trace!("Received Notification on an unsupported parent");
                Err(())
            }
            #[cfg(test)]
            AnyActerModel::TestModel(test_model) => Err(()),
        }
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
    Boost {
        first_slide: Option<NewsContent>,
    },
    Comment {
        parent_obj: Option<NotificationItemParent>,
        parent_id: OwnedEventId,
        room_id: OwnedRoomId,
        event_id: OwnedEventId,
        content: TextMessageEventContent,
    },
}

impl NotificationItemInner {
    pub fn key(&self) -> String {
        match &self {
            NotificationItemInner::Fallback { .. } => "fallback",
            NotificationItemInner::Invite { .. } => "invite",
            NotificationItemInner::Comment { .. } => "comment",
            NotificationItemInner::ChatMessage { is_dm, .. } => {
                if *is_dm {
                    "dm"
                } else {
                    "chat"
                }
            }
            NotificationItemInner::Boost { .. } => "news",
        }
        .to_owned()
    }
    pub fn target_url(&self) -> String {
        match &self {
            NotificationItemInner::Fallback { device_id, room_id } => format!(
                "/forward?deviceId={}&roomId={}",
                encode(device_id.as_str()),
                encode(room_id.as_str())
            ),
            NotificationItemInner::Invite { room_id } => "/activities/invites".to_string(),
            NotificationItemInner::ChatMessage { room_id, .. } => todo!(),
            NotificationItemInner::Boost { first_slide } => todo!(),
            NotificationItemInner::Comment {
                parent_obj: Some(parent),
                event_id,
                ..
            } => format!(
                "{}?section=comments&commentId={}",
                parent.target_url(),
                encode(event_id.as_str()),
            ),
            // -- fallback when the parent isn't there.
            NotificationItemInner::Comment {
                event_id,
                room_id,
                parent_id,
                ..
            } => {
                format!(
                    "/forward?eventId={}&roomId={}&parentId={}",
                    encode(event_id.as_str()),
                    encode(room_id.as_str()),
                    encode(parent_id.as_str())
                )
            }
        }
    }

    pub fn room_invite(&self) -> Option<OwnedRoomId> {
        if let NotificationItemInner::Invite { room_id } = &self {
            Some(room_id.clone())
        } else {
            None
        }
    }

    pub fn parent(&self) -> Option<NotificationItemParent> {
        match self {
            NotificationItemInner::Comment { parent_obj, .. } => parent_obj.clone(),
            _ => None,
        }
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
            NotificationItemInner::Comment { content, .. } => Some(MsgContent::from(content)),
            NotificationItemInner::Boost {
                first_slide: Some(first_slide),
            } => match &first_slide {
                // everything else we have to fallback to the body-text thing ...
                NewsContent::Fallback(FallbackNewsContent::Text(msg_content))
                | NewsContent::Text(msg_content) => Some(MsgContent::from(msg_content)),
                NewsContent::Fallback(FallbackNewsContent::Video(msg_content))
                | NewsContent::Video(msg_content) => Some(MsgContent::from(msg_content)),
                NewsContent::Fallback(FallbackNewsContent::Audio(msg_content))
                | NewsContent::Audio(msg_content) => Some(MsgContent::from(msg_content)),
                NewsContent::Fallback(FallbackNewsContent::File(msg_content))
                | NewsContent::File(msg_content) => Some(MsgContent::from(msg_content)),
                NewsContent::Fallback(FallbackNewsContent::Location(msg_content))
                | NewsContent::Location(msg_content) => Some(MsgContent::from(msg_content)),
                _ => None,
            },

            _ => None,
        }
    }

    pub fn image_source(&self) -> Option<MediaSource> {
        match &self {
            NotificationItemInner::Boost {
                first_slide: Some(NewsContent::Fallback(FallbackNewsContent::Image(msg_content))),
            }
            | NotificationItemInner::Boost {
                first_slide: Some(NewsContent::Image(msg_content)),
            } => return Some(msg_content.source.clone()),
            NotificationItemInner::Boost {
                first_slide: Some(NewsContent::Fallback(FallbackNewsContent::Image(msg_content))),
            }
            | NotificationItemInner::Boost {
                first_slide: Some(NewsContent::Image(msg_content)),
            } => return Some(msg_content.source.clone()),
            _ => {}
        };
        None
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
}

impl NotificationItem {
    pub fn title(&self) -> String {
        self.title.clone()
    }
    pub fn push_style(&self) -> String {
        self.inner.key()
    }
    pub fn target_url(&self) -> String {
        self.inner.target_url()
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
        self.inner.body()
    }
    pub fn parent(&self) -> Option<NotificationItemParent> {
        self.inner.parent()
    }
    pub fn parent_id_str(&self) -> Option<String> {
        match &self.inner {
            NotificationItemInner::Comment { parent_id, .. } => Some(parent_id.to_string()),
            _ => None,
        }
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
    pub fn has_image(&self) -> bool {
        self.inner.image_source().is_some()
    }
    pub async fn image(&self) -> Result<FfiBuffer<u8>> {
        #[allow(clippy::diverging_sub_expression)]
        let Some(source) = self.inner.image_source() else {
            bail!("No media found in item")
        };
        let client = self.client.clone();

        RUNTIME
            .spawn(async move { client.source_binary(source, None).await })
            .await?
    }

    pub async fn image_path(&self, tmp_dir: String) -> Result<String> {
        #[allow(clippy::diverging_sub_expression)]
        let Some(source) = self.inner.image_source() else {
            bail!("No media found in item")
        };
        self.client
            .source_binary_tmp_path(source, None, tmp_dir, "png")
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
            if let Ok(event) = raw_tl.deserialize_as::<SyncAnyActerEvent>() {
                return NotificationItem::for_acter_object(
                    client,
                    builder,
                    event.into_full_any_acter_event(room_id),
                )
                .await;
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

    async fn for_acter_object(
        client: Client,
        mut builder: NotificationItemBuilder,
        event: AnyActerEvent,
    ) -> Result<Self> {
        match event {
            AnyActerEvent::NewsEntry(MessageLikeEvent::Original(e)) => {
                let first_slide = e.content.slides.first().map(|a| a.content().clone());
                Ok(builder
                    .inner(NotificationItemInner::Boost { first_slide })
                    .build()?)
            }

            AnyActerEvent::Comment(MessageLikeEvent::Original(e)) => {
                let parent_obj = client
                    .store()
                    .get(e.content.on.event_id.as_str())
                    .await
                    .map_err(|error| {
                        tracing::error!(?error, "Error loading parent of comment");
                    })
                    .ok()
                    .and_then(|o| NotificationItemParent::try_from(&o).ok());
                let content = e.content.content;
                Ok(builder
                    .inner(NotificationItemInner::Comment {
                        parent_obj,
                        parent_id: e.content.on.event_id,
                        room_id: e.room_id,
                        event_id: e.event_id,
                        content,
                    })
                    .build()?)
            }
            _ => {
                tracing::warn!(?event, "Notification not support");
                Ok(builder.build()?)
            }
        }
    }
}
