use acter::{
    api::RoomMessage,
    ruma_common::OwnedEventId,
    ruma_events::{AnyMessageLikeEvent, AnyTimelineEvent},
};
use anyhow::{bail, Result};
use core::time::Duration;
use futures::{pin_mut, stream::StreamExt, FutureExt};
use tokio::time::sleep;
use tracing::info;

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
    let stream = timeline.diff_stream();
    pin_mut!(stream);

    timeline
        .send_plain_message("Hi, everyone".to_string())
        .await?;

    // text msg may reach via reset action or set action
    let mut i = 30;
    let mut received = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            info!("diff action: {}", diff.action());
            match diff.action().as_str() {
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(event_id) = match_room_msg(value, "Hi, everyone") {
                            received = Some(event_id);
                            break;
                        }
                    }
                }
                "Set" => {
                    let value = diff
                        .value()
                        .expect("diff set action should have valid value");
                    if let Some(event_id) = match_room_msg(&value, "Hi, everyone") {
                        received = Some(event_id);
                    }
                }
                _ => {}
            }
            // yay
            if received.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    assert!(
        received.is_some(),
        "Even after 30 seconds, text msg not received"
    );

    let redact_id = convo
        .redact_message(
            received.clone().unwrap().to_string(),
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
    assert_eq!(original.redacts, received);
    assert_eq!(original.content.reason, Some("redact-test".to_string()));

    Ok(())
}

fn match_room_msg(msg: &RoomMessage, body: &str) -> Option<OwnedEventId> {
    if msg.item_type() == "event" {
        let event_item = msg.event_item().expect("room msg should have event item");
        if let Some(text_desc) = event_item.text_desc() {
            if text_desc.body() == body {
                // exclude the pending msg
                if let Some(event_id) = event_item.evt_id() {
                    return Some(event_id);
                }
            }
        }
    }
    None
}
