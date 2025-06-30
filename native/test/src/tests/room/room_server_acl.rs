use acter::api::TimelineItem;
use acter_matrix::{models::status::RoomServerAclContent, util::do_vecs_match};
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
async fn test_room_server_acl() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("room_server_acl").await?;
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

    let allow = vec!["*".to_owned()];
    let deny = vec!["1.1.1.1".to_owned()];
    let acl_event_id = convo
        .set_server_acl(
            true,
            serde_json::to_string(&allow)?,
            serde_json::to_string(&deny)?,
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
        found_result.expect("Even after 30 seconds, room server acl not received");
    assert_eq!(found_event_id, acl_event_id, "event id should match");

    assert_eq!(
        content.allow_ip_literals_change().as_deref(),
        Some("Set"),
        "allow ip literals in room server acl should be set"
    );
    assert!(
        content.allow_ip_literals_new_val(),
        "new val of allow ip literals in room server acl is invalid"
    );

    assert_eq!(
        content.allow_change().as_deref(),
        Some("Set"),
        "allow in room server acl should be set"
    );
    assert!(
        do_vecs_match(content.allow_new_val().as_slice(), allow.as_slice()),
        "new val of allow in room server acl is invalid"
    );

    assert_eq!(
        content.deny_change().as_deref(),
        Some("Set"),
        "deny in room server acl should be set"
    );
    assert!(
        do_vecs_match(content.deny_new_val().as_slice(), deny.as_slice()),
        "new val of deny in room server acl is invalid"
    );

    Ok(())
}

fn match_msg(msg: &TimelineItem) -> Option<(String, RoomServerAclContent)> {
    if msg.is_virtual() {
        return None;
    }
    let event_item = msg.event_item().expect("room msg should have event item");
    let content = event_item.room_server_acl_content()?;
    let event_id = event_item
        .event_id()
        .expect("event item should have event id");
    Some((event_id, content))
}
