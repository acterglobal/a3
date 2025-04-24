use acter::{
    api::TimelineItem, matrix_sdk::ruma::events::room::history_visibility::HistoryVisibility,
};
use acter_core::models::status::RoomHistoryVisibilityContent;
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
async fn test_room_history_visibility() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("room_history_visibility").await?;
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

    let new_visibility = HistoryVisibility::Invited;
    let default_visibility = HistoryVisibility::Shared;
    let visibility_event_id = convo
        .set_history_visibility(new_visibility.to_string())
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
        found_result.expect("Even after 30 seconds, room history visibility not received");
    assert_eq!(found_event_id, visibility_event_id, "event id should match");

    assert_eq!(
        content.change(),
        Some("Changed".to_owned()),
        "room history visibility should be changed"
    );
    assert_eq!(
        content.new_val(),
        new_visibility.to_string(),
        "new val of room history visibility is invalid"
    );
    assert_eq!(
        content.old_val(),
        Some(default_visibility.to_string()),
        "old val of room history visibility is invalid"
    );

    Ok(())
}

fn match_msg(msg: &TimelineItem) -> Option<(String, RoomHistoryVisibilityContent)> {
    if msg.is_virtual() {
        return None;
    }
    let event_item = msg.event_item().expect("room msg should have event item");
    let Some(content) = event_item.room_history_visibility_content() else {
        return None;
    };
    let event_id = event_item
        .event_id()
        .expect("event item should have event id");
    Some((event_id, content.clone()))
}
