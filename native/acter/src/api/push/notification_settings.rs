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
    Client as SdkClient, NotificationSettingsError,
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
use strum::{Display, EnumString};
use tokio_stream::{wrappers::BroadcastStream, Stream};
use urlencoding::encode;

use crate::Client;

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

/// The status the subscription has
#[derive(Clone, Debug, Display)]
#[strum(serialize_all = "camelCase")]

pub enum SubscriptionStatus {
    /// The user shall receive notifications about the
    Subscribed,
    /// The user actively disabled the notifications about this
    Unsubscribed,
    /// The user subscribed on the parent, but has nothing specific on the item
    ParentSubscribed,
    /// The user unsubscribed on the parent, but has nothing specific on the item
    ParentUnsubscribed,
    /// The user hasn't been subscribed to the object or its parent
    None,
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
        self.object_push_subscription_status(object_id, sub_type)
            .await
            .map(|s| s.to_string())
    }
    pub async fn object_push_subscription_status(
        &self,
        object_id: String,
        sub_type: Option<String>,
    ) -> Result<SubscriptionStatus> {
        let inner = self.inner.clone();
        RUNTIME
            .spawn(async move {
                if sub_type.is_some() {
                    // check for the full key:
                    match inner
                        .is_push_rule_enabled(
                            RuleKind::Override,
                            make_notification_key(&object_id, sub_type.as_ref()),
                        )
                        .await
                    {
                        Ok(enabled) => {
                            if enabled {
                                return Ok(SubscriptionStatus::Subscribed);
                            } else {
                                return Ok(SubscriptionStatus::Unsubscribed);
                            }
                        }
                        Err(NotificationSettingsError::RuleNotFound(_)) => {
                            // ignore; we consider this a regular false
                        }
                        Err(e) => return Err(e.into()), // other error
                    }
                }
                // check for the parent key as fallback
                match inner
                    .is_push_rule_enabled(
                        RuleKind::Override,
                        make_notification_key(&object_id, None),
                    )
                    .await
                {
                    Ok(enabled) => {
                        if sub_type.is_some() {
                            if enabled {
                                return Ok(SubscriptionStatus::ParentSubscribed);
                            } else {
                                return Ok(SubscriptionStatus::ParentUnsubscribed);
                            }
                        } else {
                            if enabled {
                                return Ok(SubscriptionStatus::Subscribed);
                            } else {
                                return Ok(SubscriptionStatus::Unsubscribed);
                            }
                        }
                    }
                    Err(NotificationSettingsError::RuleNotFound(_)) => {
                        // ignore; we consider this a regular false
                    }
                    Err(e) => return Err(e.into()), // other error
                }
                Ok(SubscriptionStatus::None)
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
                let notif_key = make_notification_key(&object_id, sub_type.as_ref());

                match inner
                    .set_push_rule_enabled(RuleKind::Override, notif_key, true)
                    .await
                {
                    Err(NotificationSettingsError::RuleNotFound(_)) => {
                        // not found, we have to create it the first time:
                        let new_push_rule = make_push_rule(&object_id, sub_type.as_ref());

                        let resp = client
                            .send(
                                set_pushrule::v3::Request::new(NewPushRule::Override(
                                    new_push_rule,
                                )),
                                None,
                            )
                            .await?;

                        Ok(true)
                    }
                    Ok(_) => Ok(true),
                    Err(e) => Err(e.into()), // other error, bubble up
                }
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
