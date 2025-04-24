use acter::{api::TimelineItem, matrix_sdk::ruma::events::policy::rule::Recommendation};
use acter_core::models::status::PolicyRuleUserContent;
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
async fn test_policy_rule_user() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("policy_rule_user").await?;
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

    let policy_event_id = convo
        .set_policy_rule_user(
            "@alice*:example.org".to_owned(),
            "undesirable behaviour".to_owned(),
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
        found_result.expect("Even after 30 seconds, policy rule user not received");
    assert_eq!(
        found_event_id,
        policy_event_id.to_string(),
        "Incorrect event id",
    );

    assert_eq!(
        content.entity_change(),
        Some("Set".to_owned()),
        "entity in policy rule user should be set"
    );
    assert_eq!(
        content.entity_new_val(),
        "@alice*:example.org",
        "new val of entity in policy rule user is invalid"
    );
    assert_eq!(
        content.entity_old_val(),
        None,
        "old val of entity in policy rule user is invalid"
    );

    assert_eq!(
        content.recommendation_change(),
        Some("Set".to_owned()),
        "recommendation in policy rule user should be set"
    );
    assert_eq!(
        content.recommendation_new_val(),
        Recommendation::Ban.as_str(),
        "new val of recommendation in policy rule user is invalid"
    );
    assert_eq!(
        content.recommendation_old_val(),
        None,
        "old val of recommendation in policy rule user is invalid"
    );

    assert_eq!(
        content.reason_change(),
        Some("Set".to_owned()),
        "reason in policy rule user should be set"
    );
    assert_eq!(
        content.reason_new_val(),
        "undesirable behaviour",
        "new val of reason in policy rule user is invalid"
    );
    assert_eq!(
        content.reason_old_val(),
        None,
        "old val of reason in policy rule user is invalid"
    );

    Ok(())
}

fn match_msg(msg: &TimelineItem) -> Option<(String, PolicyRuleUserContent)> {
    if msg.is_virtual() {
        return None;
    }
    let event_item = msg.event_item().expect("room msg should have event item");
    let Some(content) = event_item.policy_rule_user_content() else {
        return None;
    };
    let event_id = event_item
        .event_id()
        .expect("event item should have event id");
    Some((event_id, content))
}
