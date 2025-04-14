use acter::api::TimelineItem;
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
async fn test_policy_rule_server() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("policy_rule_server").await?;
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
        .set_policy_rule_server(
            "*.example.org".to_owned(),
            "undesirable engagement".to_owned(),
        )
        .await?;

    // room state event may reach via pushback action or reset action
    let mut i = 30;
    let mut found_event_id = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" | "Set" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(event_id) = match_msg(&value, "Set", "*.example.org") {
                        found_event_id = Some(event_id);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(event_id) = match_msg(value, "Set", "*.example.org") {
                            found_event_id = Some(event_id);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if found_event_id.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    assert_eq!(
        found_event_id,
        Some(policy_event_id.to_string()),
        "Even after 30 seconds, policy rule server not received",
    );

    Ok(())
}

fn match_msg(msg: &TimelineItem, change: &str, new_val: &str) -> Option<String> {
    if msg.is_virtual() {
        return None;
    }
    let event_item = msg.event_item().expect("room msg should have event item");
    let Some(content) = event_item.policy_rule_server_content() else {
        return None;
    };
    if let Some(chg) = content.entity_change() {
        if chg != change {
            return None;
        }
    }
    if content.entity_new_val() != new_val {
        return None;
    }
    event_item.event_id()
}
