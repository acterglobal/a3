use acter::api::{TimelineEventItem, TimelineItem};
use anyhow::{Context, Result};
use core::time::Duration;
use futures::{pin_mut, FutureExt, StreamExt};
use matrix_sdk_base::ruma::events::room::redaction::RoomRedactionEvent;
use tokio::time::sleep;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};
use tracing::info;

use crate::utils::{match_text_msg, random_user_with_random_convo};

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

    let draft = user.text_plain_draft("Hi, everyone".to_owned());
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
                        if let Some(event_id) = match_text_msg(value, "Hi, everyone", false) {
                            received = Some(event_id);
                            break;
                        }
                    }
                }
                "Set" => {
                    let value = diff
                        .value()
                        .expect("diff set action should have valid value");
                    if let Some(event_id) = match_text_msg(&value, "Hi, everyone", false) {
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
        async move { timeline.get_message(received).await }
    })
    .await?;

    let reason = "redact-test";
    let redact_id = convo
        .redact_message(
            received.clone(),
            user.user_id()?.to_string(),
            Some(reason.to_owned()),
            None,
        )
        .await?;

    // redaction event may reach via reset action or set action
    let mut i = 30;
    let mut found = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            info!("stream diff: {}", diff.action());
            match diff.action().as_str() {
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(event_item) = match_redaction_event(value) {
                            found = Some(event_item);
                            break;
                        }
                    }
                }
                "Set" => {
                    let value = diff
                        .value()
                        .expect("diff set action should have valid value");
                    if let Some(event_item) = match_redaction_event(&value) {
                        found = Some(event_item);
                    }
                }
                _ => {}
            }
            // yay
            if found.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    let event_item = found.context("Even after 30 seconds, redaction event not received")?;

    // timeline accumulates the events and doesn’t assign redaction as separate event
    // it is impossible to get redaction event by event id on timeline
    assert_eq!(
        event_item.event_id(),
        Some(received.clone()) // not redact_id
    );

    // but it is possible to get redaction event by event id on convo
    let ev = convo.event(&redact_id, None).await?;
    let event_content = ev.kind.raw().deserialize_as::<RoomRedactionEvent>()?;
    let original = event_content
        .as_original()
        .context("Redaction event should get original event")?;
    assert_eq!(
        original.redacts.as_deref().map(ToString::to_string),
        Some(received)
    );
    assert_eq!(original.content.reason.as_deref(), Some(reason));

    Ok(())
}

fn match_redaction_event(msg: &TimelineItem) -> Option<TimelineEventItem> {
    info!("match room msg - {:?}", msg.clone());
    if !msg.is_virtual() {
        let event_item = msg.event_item().expect("room msg should have event item");
        if event_item.event_type() == "m.room.redaction" {
            // exclude the pending msg
            if event_item.event_id().is_some() {
                return Some(event_item);
            }
        }
    }
    None
}
