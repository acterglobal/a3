use matrix_sdk_ui::notification_client::{
    NotificationEvent, NotificationItem as SdkNotificationItem,
};
use ruma_events::{
    room::message::MessageType, AnySyncMessageLikeEvent, AnySyncTimelineEvent, SyncMessageLikeEvent,
};

use crate::{api::NotificationItem as ApiNotificationItem, login_with_token};

#[derive(Debug, uniffi::Error, thiserror::Error)]
#[uniffi(flat_error)]
pub enum ActerError {
    #[error("data store disconnected")]
    Disconnect(#[from] std::io::Error),
    #[error("unknown data store error")]
    Unknown,
    #[error("{0}")]
    Anyhow(#[from] anyhow::Error),
}

#[derive(Debug, uniffi::Record)]
pub struct NotificationItem {
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

impl NotificationItem {
    async fn from(value: ApiNotificationItem, temp_dir: String) -> NotificationItem {
        let image_path = if value.has_image() {
            value.image_path(temp_dir).await.ok()
        } else {
            None
        };

        let ApiNotificationItem {
            title,
            push_style,
            target_url,
            room_invite,
            thread_id,
            body,
            noisy,
            sender,
            image,
            ..
        } = value;

        let mut short_msg = None;

        if let Some(invite) = room_invite {
            short_msg = Some(invite);
        } else if let Some(content) = body {
            short_msg = Some(content.body());
        }

        if push_style == "chat" {
            if let Some(sender_name) = sender.display_name() {
                // wrap the user display name before the message
                short_msg = Some(format!("${sender_name}: $short_msg"));
            }
        }

        NotificationItem {
            title,
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
) -> uniffi::Result<NotificationItem, ActerError> {
    let client = login_with_token(base_path, media_cache_path, restore_token).await?;
    Ok(NotificationItem::from(
        client.get_notification_item(room_id, event_id).await?,
        temp_dir,
    )
    .await)
}
