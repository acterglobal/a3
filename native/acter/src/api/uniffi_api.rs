use crate::{api::NotificationItem as ApiNotificationItem, login_with_token};
use matrix_sdk::ruma::events::AnySyncMessageLikeEvent;
use matrix_sdk::ruma::events::AnySyncTimelineEvent;
use matrix_sdk::ruma::events::SyncMessageLikeEvent;
use matrix_sdk::ruma::events::room::message::MessageType;

use matrix_sdk_ui::notification_client::{
    NotificationClient, NotificationEvent, NotificationItem as SdkNotificationItem,
};

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

#[derive(Debug)]
#[derive(uniffi::Record)]
pub struct NotificationItem {
    pub room_id: String,
    /// Underlying Ruma event.
    // pub event: NotificationEvent,
    pub short_msg: String,
    pub is_invite: bool,
    pub unsupported: bool,

    /// Display name of the sender.
    pub sender_display_name: Option<String>,
    /// Avatar URL of the sender.
    pub sender_avatar_url: Option<String>,

    /// Room display name.
    pub room_display_name: String,
    /// Room avatar URL.
    pub room_avatar_url: Option<String>,
    /// Room canonical alias.
    pub room_canonical_alias: Option<String>,
    /// Is this room encrypted?
    pub is_room_encrypted: Option<bool>,
    /// Is this room considered a direct message?
    pub is_direct_message_room: bool,
    /// Numbers of members who joined the room.
    pub joined_members_count: u64,

    /// Is it a noisy notification? (i.e. does any push action contain a sound
    /// action)
    ///
    /// It is set if and only if the push actions could be determined.
    pub is_noisy: Option<bool>,

}

impl From<ApiNotificationItem> for NotificationItem {
    fn from(value: ApiNotificationItem) -> NotificationItem {
        let ApiNotificationItem {
            room_id,
            inner: SdkNotificationItem {
                event,
                sender_display_name,
                room_display_name, 
                sender_avatar_url,
                room_avatar_url, room_canonical_alias,
                is_room_encrypted,  is_direct_message_room, 
                joined_members_count, is_noisy,
                ..
            }
        } = value;

        let mut is_invite = false;
        let mut short_msg = "".to_owned();
        let mut unsupported = false;

        match event {
            NotificationEvent::Invite(_) => {
                is_invite = true;
            }
            NotificationEvent::Timeline(AnySyncTimelineEvent::MessageLike(s)) => {
                short_msg = match s {
                    AnySyncMessageLikeEvent::RoomMessage(SyncMessageLikeEvent::Original(m)) => {
                        match m.content.msgtype {
                            MessageType::Audio(m) => m.body,
                            MessageType::Emote(m) => m.body,
                            MessageType::File(m) => m.body,
                            MessageType::Image(m) => m.body,
                            MessageType::Location(m) => m.body,
                            MessageType::Notice(m) => m.body,
                            MessageType::ServerNotice(m) => m.body,
                            MessageType::Text(m) => m.body,
                            MessageType::Video(m) => m.body,
                            _ => {
                                unsupported = true;
                                "".to_owned()
                            }
                        }
                    }
                    _ => {
                        unsupported = true;
                        "".to_owned()
                    }
                }
            }
            _ => {
                unsupported = true;
            }
            
        }



        NotificationItem {
            // event,
            short_msg,
            is_invite,
            unsupported,
            sender_display_name,
            room_display_name, 
            sender_avatar_url,
            room_avatar_url, room_canonical_alias,
            is_room_encrypted,  is_direct_message_room, 
            joined_members_count, is_noisy,
            room_id: room_id.to_string(),

        }

    }
}

#[uniffi::export]
pub async fn get_notification_item(restore_token: String, room_id: String, event_id: String) -> uniffi::Result<NotificationItem, ActerError> {
    let client = login_with_token(restore_token).await?;
    Ok(client.get_notification_item(room_id, event_id).await?.into())
}