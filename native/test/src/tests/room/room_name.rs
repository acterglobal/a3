use acter::api::TimelineItem;
use acter_matrix::models::status::RoomNameContent;
use anyhow::Result;
use core::time::Duration;
use futures::{pin_mut, stream::StreamExt, FutureExt};
use tokio::time::sleep;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::random_user_with_random_convo;

#[tokio::test]
async fn test_room_name() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("room_name").await?;
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

    let new_name = "Babbling Room";
    let old_name = convo.name();
    let name_event_id = convo.set_name(new_name.to_owned()).await?;

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
        found_result.expect("Even after 30 seconds, room name not received");
    assert_eq!(found_event_id, name_event_id, "event id should match");

    assert_eq!(
        content.change().as_deref(),
        Some("Changed"),
        "room name should be changed"
    );
    assert_eq!(
        content.new_val(),
        new_name,
        "new val of room name is invalid"
    );
    assert_eq!(
        content.old_val(),
        old_name,
        "old val of room name is invalid"
    );

    Ok(())
}

fn match_msg(msg: &TimelineItem) -> Option<(String, RoomNameContent)> {
    if msg.is_virtual() {
        return None;
    }
    let event_item = msg.event_item().expect("room msg should have event item");
    let content = event_item.room_name_content()?;
    let event_id = event_item
        .event_id()
        .expect("event item should have event id");
    Some((event_id, content))
}
