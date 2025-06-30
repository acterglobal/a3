use acter::{api::TimelineItem, matrix_sdk::ruma::events::policy::rule::Recommendation};
use acter_matrix::models::status::PolicyRuleRoomContent;
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
async fn test_policy_rule_room() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("policy_rule_room").await?;
    let state_sync = user.start_sync();
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

    let policy_event_id = convo
        .set_policy_rule_room(
            "#*:example.org".to_owned(),
            "undesirable content".to_owned(),
        )
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
        found_result.expect("Even after 30 seconds, policy rule room not received");
    assert_eq!(found_event_id, policy_event_id, "Incorrect event id");

    assert_eq!(
        content.entity_change().as_deref(),
        Some("Set"),
        "entity in policy rule room should be set"
    );
    assert_eq!(
        content.entity_new_val(),
        "#*:example.org",
        "new val of entity in policy rule room is invalid"
    );
    assert_eq!(
        content.entity_old_val(),
        None,
        "old val of entity in policy rule room is invalid"
    );

    assert_eq!(
        content.recommendation_change().as_deref(),
        Some("Set"),
        "recommendation in policy rule room should be set"
    );
    assert_eq!(
        content.recommendation_new_val(),
        Recommendation::Ban.as_str(),
        "new val of recommendation in policy rule room is invalid"
    );
    assert_eq!(
        content.recommendation_old_val(),
        None,
        "old val of recommendation in policy rule room is invalid"
    );

    assert_eq!(
        content.reason_change().as_deref(),
        Some("Set"),
        "reason in policy rule room should be set"
    );
    assert_eq!(
        content.reason_new_val(),
        "undesirable content",
        "new val of reason in policy rule room is invalid"
    );
    assert_eq!(
        content.reason_old_val(),
        None,
        "old val of reason in policy rule room is invalid"
    );

    Ok(())
}

fn match_msg(msg: &TimelineItem) -> Option<(String, PolicyRuleRoomContent)> {
    if msg.is_virtual() {
        return None;
    }
    let event_item = msg.event_item().expect("room msg should have event item");
    let content = event_item.policy_rule_room_content()?;
    let event_id = event_item
        .event_id()
        .expect("event item should have event id");
    Some((event_id, content))
}
