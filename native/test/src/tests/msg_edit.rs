use acter::ruma_events::{AnyMessageLikeEvent, AnyTimelineEvent};
use anyhow::{bail, Result};
use futures::stream::StreamExt;

use crate::utils::random_user_with_random_space;

#[tokio::test]
async fn message_edit() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_space("message_edit").await?;
    let syncer = user.start_sync();
    let mut synced = syncer.first_synced_rx();
    while synced.next().await != Some(true) {} // let's wait for it to have synced

    let space = user
        .space(room_id.to_string())
        .await
        .expect("user belongs to its space");
    let event_id = space.send_plain_message("Hi, everyone".to_string()).await?;
    println!("event id: {event_id:?}");

    let edited_id = space
        .edit_plain_message(event_id.to_string(), "This is message edition".to_string())
        .await?;

    let ev = space.event(&edited_id).await?;
    println!("msg edition: {ev:?}");

    let Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomMessage(r))) = ev.event.deserialize() else {
        bail!("not the proper room event")
    };

    let Some(e) = r.as_original() else {
        bail!("This event should have original message")
    };

    let Some(ref relation) = e.content.relates_to else {
        bail!("The edition message should have relation")
    };
    assert_eq!(relation.event_id(), &event_id);
    Ok(())
}
