use acter_core::util::do_vecs_match;
use anyhow::Result;
use core::time::Duration;
use futures::{pin_mut, stream::StreamExt, FutureExt};
use tokio::time::sleep;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::random_user_with_random_convo;
use crate::utils::{match_pinned_msg, match_text_msg};

#[tokio::test]
async fn test_room_pinned_events() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("room_pinned_events").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    Retry::spawn(retry_strategy, || async {
        user.convo(room_id.to_string()).await
    })
    .await?;

    let convo = user.convo(room_id.to_string()).await?;
    let timeline = convo.timeline_stream();
    let stream = timeline.messages_stream();
    pin_mut!(stream);

    // user sends the text message
    let text_body = "Hello";
    let draft = user.text_plain_draft(text_body.to_owned());
    timeline.send_message(Box::new(draft)).await?;

    // text msg may reach via pushback action or reset action
    let mut i = 30;
    let mut text_result = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" | "Set" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(result) = match_text_msg(&value, text_body, false) {
                        text_result = Some(result);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(result) = match_text_msg(value, text_body, false) {
                            text_result = Some(result);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if text_result.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    let text_event_id = text_result.expect("Even after 30 seconds, text msg not received");

    let pinned_events = vec![text_event_id];
    let pinned_event_id = convo
        .set_pinned_events(serde_json::to_string(&pinned_events)?)
        .await?;

    // room state event may reach via pushback action or reset action
    let mut i = 30;
    let mut found_result = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" | "Set" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(result) = match_pinned_msg(&value) {
                        found_result = Some(result);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(result) = match_pinned_msg(value) {
                            found_result = Some(result);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if found_result.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    let (found_event_id, content) =
        found_result.expect("Even after 30 seconds, room pinned events not received");
    assert_eq!(found_event_id, pinned_event_id, "event id should match");

    assert_eq!(
        content.change().as_deref(),
        Some("Set"),
        "room pinned events should be set"
    );
    assert!(
        do_vecs_match(content.new_val().as_slice(), pinned_events.as_slice()),
        "new val of room pinned events is invalid"
    );
    assert_eq!(
        content.old_val(),
        None,
        "old val of room pinned events is invalid"
    );

    Ok(())
}
