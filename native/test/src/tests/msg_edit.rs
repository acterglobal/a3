use acter::{
    api::RoomMessage,
    ruma_events::{AnyMessageLikeEvent, AnyTimelineEvent, MessageLikeEvent},
};
use anyhow::{bail, Result};
use futures::stream::StreamExt;
use std::ops::Deref;

use crate::utils::random_user_with_random_space;

#[tokio::test]
async fn message_edit() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_space("message_edit").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    let space = user.space(room_id.to_string()).await?;
    let event_id = space.send_plain_message("Hi, everyone".to_string()).await?;
    println!("event id: {event_id:?}");

    let edited_id = space
        .edit_plain_message(event_id.to_string(), "This is message edition".to_string())
        .await?;

    let ev = space.event(&edited_id).await?;
    println!("msg edition: {ev:?}");

    let Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(MessageLikeEvent::Original(r)))) = ev.event.deserialize() else {
        bail!("not the proper room event")
    };

    let msg = RoomMessage::room_message_from_event(r, space.deref().deref().clone(), false);
    let Some(item) = msg.event_item() else {
        bail!("This item should be event item not virtual item")
    };

    assert!(item.is_edited());
    Ok(())
}
