use acter::RoomMessage;
use anyhow::Result;
use core::time::Duration;
use futures::{pin_mut, stream::StreamExt, FutureExt};
use tokio::time::sleep;
use tracing::info;

use crate::utils::random_user_with_random_convo;

#[tokio::test]
async fn message_edit() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("message_edit").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    let convo = user.convo(room_id.to_string()).await?;
    let timeline = convo.timeline_stream().await?;
    let stream = timeline.diff_stream();
    pin_mut!(stream);

    let event_id = convo.send_plain_message("Hi, everyone".to_string()).await?;
    info!("event id: {event_id:?}");

    // text msg may reach via pushback action or reset action
    let mut i = 3;
    let mut received = false;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if match_room_msg(&value, event_id.to_string(), "Hi, everyone", false) {
                        received = true;
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if match_room_msg(value, event_id.to_string(), "Hi, everyone", false) {
                            received = true;
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if received {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    assert!(received, "Even after 3 seconds, text msg not received");

    let edited_id = convo
        .edit_plain_message(event_id.to_string(), "This is message edition".to_string())
        .await?;
    info!("edited id: {edited_id:?}");

    // msg edition may reach via set action
    i = 3;
    received = false;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            if diff.action() == "Set" {
                let value = diff
                    .value()
                    .expect("diff set action should have valid value");
                if match_room_msg(
                    &value,
                    event_id.to_string(), // not edited_id, because stream will replace old msg with new msg in timeline
                    "This is message edition",
                    true,
                ) {
                    received = true;
                }
            }
            // yay
            if received {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    assert!(received, "Even after 3 seconds, text msg not received");

    Ok(())
}

fn match_room_msg(msg: &RoomMessage, event_id: String, body: &str, modified: bool) -> bool {
    if msg.item_type() == "event" {
        let event_item = msg.event_item().expect("room msg should have event item");
        if event_item.event_id() == event_id {
            assert_eq!(event_item.is_edited(), modified);
            let text_desc = event_item
                .text_desc()
                .expect("text msg should have text desc");
            assert_eq!(text_desc.body(), body);
            return true;
        }
    }
    false
}
