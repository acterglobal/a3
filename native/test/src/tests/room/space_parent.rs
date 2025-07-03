use acter::api::{CreateConvoSettingsBuilder, TimelineItem};
use acter_matrix::models::status::SpaceParentContent;
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
async fn test_space_parent() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("space_parent").await?;
    let state_sync = user.start_sync().await?;
    state_sync.await_has_synced_history().await?;

    let settings = CreateConvoSettingsBuilder::default().build()?;
    let parent_room_id = user.create_convo(Box::new(settings)).await?;

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

    let parent_event_id = convo
        .add_parent_room(parent_room_id.to_string(), false)
        .await?;
    let via = vec!["localhost".to_owned()];

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
        found_result.expect("Even after 30 seconds, space parent not received");
    assert_eq!(found_event_id, parent_event_id, "event id should match");

    let room_id = content.room_id().ok();
    assert_eq!(room_id, Some(parent_room_id), "room id should be present");

    assert_eq!(
        content.via_change().as_deref(),
        Some("Set"),
        "change of via should be set"
    );
    assert_eq!(
        content.via_new_val(),
        via.clone(),
        "new val of via is invalid"
    );

    assert_eq!(
        content.canonical_change().as_deref(),
        Some("Set"),
        "change of canonical should be set"
    );
    assert!(
        !content.canonical_new_val(),
        "new val of canonical is invalid"
    );

    Ok(())
}

fn match_msg(msg: &TimelineItem) -> Option<(String, SpaceParentContent)> {
    if msg.is_virtual() {
        return None;
    }
    let event_item = msg.event_item().expect("room msg should have event item");
    let content = event_item.space_parent_content()?;
    let event_id = event_item
        .event_id()
        .expect("event item should have event id");
    Some((event_id, content))
}
