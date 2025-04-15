use acter::api::{CreateConvoSettingsBuilder, TimelineItem};
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
async fn test_space_child() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("space_child").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    let settings = CreateConvoSettingsBuilder::default().build()?;
    let child_room_id = user.create_convo(Box::new(settings)).await?;

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

    let child_event_id = convo
        .add_child_room(child_room_id.to_string(), None, true)
        .await?;
    let via = vec!["localhost".to_owned()];

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
                    if let Some(event_id) = match_msg(
                        &value,
                        child_room_id.as_str(),
                        "Set",
                        via.clone(),
                        None,
                        None,
                        "Set",
                        true,
                    ) {
                        found_event_id = Some(event_id);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(event_id) = match_msg(
                            &value,
                            child_room_id.as_str(),
                            "Set",
                            via.clone(),
                            None,
                            None,
                            "Set",
                            true,
                        ) {
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
        Some(child_event_id.to_string()),
        "Even after 30 seconds, space child event not received",
    );

    Ok(())
}

fn match_msg(
    msg: &TimelineItem,
    room_id: &str,
    via_change: &str,
    via_new_val: Vec<String>,
    order_change: Option<String>,
    order_new_val: Option<String>,
    suggested_change: &str,
    suggested_new_val: bool,
) -> Option<String> {
    if msg.is_virtual() {
        return None;
    }
    let event_item = msg.event_item().expect("room msg should have event item");
    let Some(content) = event_item.space_child_content() else {
        return None;
    };
    let Ok(r_id) = content.room_id() else {
        return None;
    };
    if r_id.as_str() != room_id {
        return None;
    }
    let Some(chg) = content.via_change() else {
        return None;
    };
    if chg != via_change {
        return None;
    }
    if !do_vecs_match(content.via_new_val().as_slice(), via_new_val.as_slice()) {
        return None;
    }
    if content.order_change() != order_change {
        return None;
    }
    if content.order_new_val() != order_new_val {
        return None;
    }
    let Some(chg) = content.suggested_change() else {
        return None;
    };
    if chg != suggested_change {
        return None;
    }
    if content.suggested_new_val() != suggested_new_val {
        return None;
    }
    event_item.event_id()
}
