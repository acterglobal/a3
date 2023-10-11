use crate::{api::RUNTIME, NotificationItem, login_with_token};

#[uniffi::export]
pub async fn get_notification_item(restore_token: String, room_id: String, event_id: String) -> Result<NotificationItem> {
    let client = login_with_token(restore_token).await?;
    Ok(client.get_notification_item(room_id, event_id).await?)
}