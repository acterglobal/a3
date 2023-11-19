use acter::ruma_events::{AnyMessageLikeEvent, AnyTimelineEvent};
use anyhow::{bail, Result};

use crate::utils::random_user_with_random_convo;

#[tokio::test]
async fn message_redaction() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("redaction").await?;
    let syncer = user.start_sync();
    syncer.await_has_synced_history().await?;

    let convo = user
        .convo(room_id.to_string())
        .await
        .expect("user should belong to convo");
    let timeline = convo
        .timeline_stream()
        .await
        .expect("user should get timeline stream");
    timeline
        .send_plain_message("Hi, everyone".to_string())
        .await?;

    let mut stream = Box::pin(user.sync_stream(Default::default()).await);
    let mut event_id = None;
    loop {
        stream.next().await;
        if let Some(msg) = convo.latest_message() {
            if let Some(event_item) = msg.event_item() {
                if let Some(text_desc) = event_item.text_desc() {
                    if text_desc.body() == "Hi, everyone" {
                        event_id = Some(event_item.event_id());
                        break;
                    }
                }
            }
        }
    }

    let redact_id = convo
        .redact_message(
            event_id.clone().unwrap(),
            Some("redact-test".to_string()),
            None,
        )
        .await?;

    let ev = convo.event(&redact_id).await?;
    let Ok(AnyTimelineEvent::MessageLike(AnyMessageLikeEvent::RoomRedaction(redaction_event))) = ev.event.deserialize() else {
        bail!("This should be m.room.redaction event")
    };
    let Some(original) = redaction_event.as_original() else {
        bail!("Redaction event should get original event")
    };
    assert_eq!(original.redacts.clone().map(|x| x.to_string()), event_id);
    assert_eq!(original.content.reason, Some("redact-test".to_string()));

    Ok(())
}
