use acter::api::TimelineItem;
use acter_core::util::do_vecs_match;
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
    let mut found_event_id = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" | "Set" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(event_id) =
                        match_msg(&value, "Set", true, "Set", &allow, "Set", &deny)
                    {
                        found_event_id = Some(event_id);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(event_id) =
                            match_msg(value, "Set", true, "Set", &allow, "Set", &deny)
                        {
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
        Some(acl_event_id.to_string()),
        "Even after 30 seconds, room server acl not received",
    );

    Ok(())
}

fn match_msg(
    msg: &TimelineItem,
    allow_ip_literals_change: &str,
    allow_ip_literals_new_val: bool,
    allow_change: &str,
    allow_new_val: &Vec<String>,
    deny_change: &str,
    deny_new_val: &Vec<String>,
) -> Option<String> {
    if msg.is_virtual() {
        return None;
    }
    let event_item = msg.event_item().expect("room msg should have event item");
    let Some(content) = event_item.room_server_acl_content() else {
        return None;
    };
    let Some(chg) = content.allow_ip_literals_change() else {
        return None;
    };
    if chg != allow_ip_literals_change {
        return None;
    }
    if content.allow_ip_literals_new_val() != allow_ip_literals_new_val {
        return None;
    }
    let Some(chg) = content.allow_change() else {
        return None;
    };
    if chg != allow_change {
        return None;
    }
    if !do_vecs_match(content.allow_new_val().as_slice(), allow_new_val.as_slice()) {
        return None;
    }
    let Some(chg) = content.deny_change() else {
        return None;
    };
    if chg != deny_change {
        return None;
    }
    if !do_vecs_match(content.deny_new_val().as_slice(), deny_new_val.as_slice()) {
        return None;
    }
    event_item.event_id()
}
