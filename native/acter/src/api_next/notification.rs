use matrix_sdk_ui::notification_client::{
    NotificationEvent, NotificationItem as SdkNotificationItem,
};

use crate::{api::NotificationItem as ApiNotificationItem, login_with_token};
use std::sync::Arc;
use crate::api::Client;
use super::error::Result;


#[derive(Debug, uniffi::Record)]
pub struct UniffiNotificationItem {
    pub title: String,
    pub push_style: String,
    pub target_url: String,
    pub body: Option<String>,
    pub thread_id: Option<String>,
    pub image_path: Option<String>,

    /// Is it a noisy notification? (i.e. does any push action contain a sound
    /// action)
    ///
    /// It is set if and only if the push actions could be determined.
    pub is_noisy: Option<bool>,
}

impl UniffiNotificationItem {
    async fn from(value: ApiNotificationItem, temp_dir: String) -> UniffiNotificationItem {
        let image_path = if value.has_image() {
            value.image_path(temp_dir).await.ok()
        } else {
            None
        };

        let ApiNotificationItem {
            title,
            thread_id,
            noisy,
            sender,
            inner,
            ..
        } = value;

        let target_url = inner.target_url();
        let room_invite = inner.room_invite();
        let push_style = inner.key();
        let body = inner.body();

        let mut msg_title = title;
        let mut short_msg = None;

        let parent_title = if let Some(p) = inner.parent() {
            let parent_title = p.title().unwrap_or("boost".to_owned());
            let parent_emoji = p.emoji();
            Some(format!("{parent_emoji} {parent_title}"))
        } else {
            None
        };

        let sender_name = sender
            .display_name()
            .clone()
            .unwrap_or_else(|| sender.user_id());

        if let Some(content) = body {
            let msg = Some(content.body());
            short_msg = Some(format!("${sender_name}: $msg"))
        }

        match push_style.as_str() {
            "invite" => {
                if let Some(invite_id) = room_invite {
                    short_msg = Some(invite_id.to_string());
                }
            }
            "comment" => {
                if let Some(pt) = parent_title {
                    msg_title = format!("💬 Comment on {pt}");
                } else {
                    msg_title = "💬 Comment".to_owned();
                }
            }
            "reaction" => {
                short_msg = Some(sender_name);
                let reaction = inner.reaction_key().unwrap_or("❤️".to_owned());

                if let Some(pt) = parent_title {
                    msg_title = format!("{reaction} to {pt}");
                } else {
                    msg_title = reaction;
                }
            }
            _ => {
                // e.g. "chat" -> default is fine.
            }
        }

        UniffiNotificationItem {
            title: msg_title,
            body: short_msg,
            push_style,
            target_url,
            is_noisy: noisy,
            image_path,
            thread_id,
        }
    }
}

#[uniffi::export]
pub async fn get_notification_item(
    base_path: String,
    media_cache_path: String,
    temp_dir: String,
    restore_token: String,
    room_id: String,
    event_id: String,
) -> Result<UniffiNotificationItem> {
    let client = login_with_token(base_path, media_cache_path, restore_token).await?;
    Ok(UniffiNotificationItem::from(
        client.get_notification_item(room_id, event_id).await?,
        temp_dir,
    )
    .await)
}

