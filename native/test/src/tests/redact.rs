use acter::ruma_events::{AnyMessageLikeEvent, AnyTimelineEvent};
use anyhow::{bail, Result};

use crate::utils::random_user_with_random_space;

#[tokio::test]
async fn message_redaction() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_space("message_redaction").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    let space = user.space(room_id.to_string()).await?;
    let event_id = space.send_plain_message("Hi, everyone".to_string()).await?;
    println!("event id: {event_id:?}");

    let redact_id = space
        .redact_message(event_id.to_string(), Some("redact-test".to_string()), None)
        .await?;

    let ev = space.event(&redact_id).await?;
    println!("redact: {ev:?}");

    let Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomRedaction(r))) = ev.event.deserialize() else {
        bail!("not the proper room event");
    };

    let e = r
        .as_original()
        .expect("This should be m.room.redaction event");
    assert_eq!(e.redacts, Some(event_id));
    Ok(())
}
