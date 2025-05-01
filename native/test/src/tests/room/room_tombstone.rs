use acter::api::TimelineItem;
use acter_core::models::status::RoomTombstoneContent;
use anyhow::Result;
use core::time::Duration;
use futures::{pin_mut, stream::StreamExt, FutureExt};
use nanoid::nanoid;
use tokio::time::sleep;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::random_user_with_random_convo;

#[tokio::test]
async fn test_room_tombstone() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("room_tombstone").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

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

    let body = "This room was upgraded to the other version";
    let id = gen_id(18);
    let replacement_room_id = format!("!{}:localhost", id);
    let tombstone_event_id = convo
        .set_tombstone(body.to_owned(), replacement_room_id.clone())
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
        found_result.expect("Even after 30 seconds, room tombstone not received");
    assert_eq!(found_event_id, tombstone_event_id, "event id should match");

    assert_eq!(
        content.body_change(),
        Some("Set".to_owned()),
        "body in room tombstone should be set"
    );
    assert_eq!(
        content.body_new_val(),
        body,
        "new val of body in room tombstone is invalid"
    );

    assert_eq!(
        content.replacement_room_change(),
        Some("Set".to_owned()),
        "replacement in room tombstone should be set"
    );
    assert_eq!(
        content.replacement_room_new_val(),
        replacement_room_id.as_str(),
        "new val of replacement in room tombstone is invalid"
    );

    Ok(())
}

fn gen_id(len: usize) -> String {
    let alphabet: [char; 16] = [
        '1', '2', '3', '4', '5', '6', '7', '8', '9', '0', 'a', 'b', 'c', 'd', 'e', 'f',
    ];
    nanoid!(len, &alphabet)
}

fn match_msg(msg: &TimelineItem) -> Option<(String, RoomTombstoneContent)> {
    if msg.is_virtual() {
        return None;
    }
    let event_item = msg.event_item().expect("room msg should have event item");
    let content = event_item.room_tombstone_content()?;
    let event_id = event_item
        .event_id()
        .expect("event item should have event id");
    Some((event_id, content))
}
