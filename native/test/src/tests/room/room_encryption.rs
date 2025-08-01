use acter::api::TimelineItem;
use acter_matrix::models::status::RoomEncryptionContent;
use anyhow::Result;
use core::time::Duration;
use futures::{pin_mut, stream::StreamExt, FutureExt};
use matrix_sdk_base::ruma::EventEncryptionAlgorithm;
use tokio::time::sleep;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::random_user_with_random_convo;

#[tokio::test]
async fn test_room_encryption() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("room_encryption").await?;
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

    let new_algorithm = EventEncryptionAlgorithm::OlmV1Curve25519AesSha2;
    let default_algorithm = EventEncryptionAlgorithm::MegolmV1AesSha2;
    let encryption_event_id = convo.set_encryption(new_algorithm.to_string()).await?;

    // room state event may reach via pushback action or reset action
    let mut i = 30;
    let mut found_result = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(result) = match_msg(&value) {
                        found_result = Some(result);
                    }
                }
                "Set" => {
                    let value = diff
                        .value()
                        .expect("diff set action should have valid value");
                    if let Some(result) = match_msg(&value) {
                        found_result = Some(result);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(result) = match_msg(value) {
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
        found_result.expect("Even after 30 seconds, room encryption not received");
    assert_eq!(found_event_id, encryption_event_id, "event id should match");

    assert_eq!(
        content.algorithm_change().as_deref(),
        Some("Changed"),
        "algorithm in room encryption should be changed"
    );
    assert_eq!(
        content.algorithm_new_val(),
        new_algorithm.to_string(),
        "new val of algorithm in room encryption is invalid"
    );
    assert_eq!(
        content.algorithm_old_val(),
        Some(default_algorithm.to_string()),
        "old val of algorithm in room encryption is invalid"
    );

    Ok(())
}

fn match_msg(msg: &TimelineItem) -> Option<(String, RoomEncryptionContent)> {
    if msg.is_virtual() {
        return None;
    }
    let event_item = msg.event_item().expect("room msg should have event item");
    let content = event_item.room_encryption_content()?;
    let event_id = event_item
        .event_id()
        .expect("event item should have event id");
    Some((event_id, content))
}
