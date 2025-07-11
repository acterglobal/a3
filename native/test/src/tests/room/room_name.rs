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
    let state_sync = user.start_sync().await?;
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    Retry::spawn(retry_strategy, || async {
        user.convo(room_id.to_string()).await
    })
    .await?;

    let convo = user.convo(room_id.to_string()).await?;
    let timeline = convo.timeline_stream().await?;
    let stream = timeline.messages_stream();
    pin_mut!(stream);

    let new_name = "Babbling Room";
    let old_name = convo.name();
    let name_event_id = convo.set_name(new_name.to_owned()).await?;

    // room state event may reach via pushback action or reset action
    let mut i = 30;
    let mut found = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(content) = match_msg(&value, name_event_id.as_str()) {
                        found = Some(content);
                    }
                }
                "Set" => {
                    let value = diff
                        .value()
                        .expect("diff set action should have valid value");
                    if let Some(content) = match_msg(&value, name_event_id.as_str()) {
                        found = Some(content);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(content) = match_msg(value, name_event_id.as_str()) {
                            found = Some(content);
                            break;
                        }
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
    let content = found.expect("Even after 30 seconds, room name not received");

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

fn match_msg(msg: &TimelineItem, event_id: &str) -> Option<RoomNameContent> {
    if msg.is_virtual() {
        return None;
    }
    let event_item = msg.event_item().expect("room msg should have event item");
    if event_item.event_id().as_deref() != Some(event_id) {
        return None;
    }
    event_item.room_name_content()
}
