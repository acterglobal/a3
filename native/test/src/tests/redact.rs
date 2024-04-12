use acter::{
    api::RoomMessage, ruma_common::OwnedEventId, ruma_events::room::redaction::RoomRedactionEvent,
};
use anyhow::{Context, Result};
use core::time::Duration;
use futures::{pin_mut, stream::StreamExt, FutureExt};
use tokio::time::sleep;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};
use tracing::info;

use crate::utils::random_user_with_random_convo;

#[tokio::test]
async fn message_redaction() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("redact").await?;
    let syncer = user.start_sync();
    syncer.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.convo(room_id.to_string()).await }
    })
    .await?;

    let convo = user.convo(room_id.to_string()).await?;
    let timeline = convo.timeline_stream();
    let stream = timeline.messages_stream();
    pin_mut!(stream);

    let draft = user.text_plain_draft("Hi, everyone".to_string());
    timeline.send_message(Box::new(draft)).await?;

    // text msg may reach via reset action or set action
    let mut i = 30;
    let mut received = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            info!("stream diff: {}", diff.action());
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
    let received = received.context("Even after 30 seconds, text msg not received")?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_timeline = timeline.clone();
    let target_id = received.clone();
    Retry::spawn(retry_strategy, move || {
        let timeline = fetcher_timeline.clone();
        let received = target_id.clone();
        async move { timeline.get_message(received.to_string()).await }
    })
    .await?;

    let redact_id = convo
        .redact_message(
            received.clone().to_string(),
            user.user_id()?.to_string(),
            Some("redact-test".to_string()),
            None,
        )
        .await?;

    // timeline reorders events and doesn't assign redaction as separate event
    // it is impossible to get redaction event by event id on timeline
    // so we don't use retry-loop about redact_id

    // but it is possible to get redaction event by event id on convo
    let ev = convo.event(&redact_id).await?;
    let event_content = ev.event.deserialize_as::<RoomRedactionEvent>()?;
    let original = event_content
        .as_original()
        .context("Redaction event should get original event")?;
    assert_eq!(original.redacts, Some(received));
    assert_eq!(original.content.reason, Some("redact-test".to_string()));

    Ok(())
}

fn match_room_msg(msg: &RoomMessage, body: &str) -> Option<OwnedEventId> {
    if msg.item_type() == "event" {
        let event_item = msg.event_item().expect("room msg should have event item");
        if let Some(msg_content) = event_item.msg_content() {
            if msg_content.body() == body {
                // exclude the pending msg
                if let Some(event_id) = event_item.evt_id() {
                    return Some(event_id);
                }
            }
        }
    }
    None
}
