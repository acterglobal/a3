use anyhow::{bail, Result};
use futures::{pin_mut, stream::StreamExt};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};
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

    let event_id = convo.send_plain_message("Hi, everyone".to_string()).await?;
    info!("event id: {event_id:?}");

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetch_event_id = event_id.clone();
    Retry::spawn(retry_strategy, move || {
        pin_mut!(stream);
        let event_id = fetch_event_id.clone();
        async move {
            pin_mut!(stream);
            let Some(diff) = stream.next().await else {
                bail!("timeline stream should get diff")
            };
            info!("diff index: {:?}", diff.index());
            info!("diff value: {:?}", diff.value());
            info!("diff values: {:?}", diff.values());
            let values = diff
                .values()
                .expect("diff reset action should have valid values");
            for msg in values.iter() {
                if msg.item_type() == "event" {
                    let event_item =
                        msg.event_item().expect("user already sent message edition");
                    if event_item.event_id() == event_id.to_string() {
                        let text_desc = event_item
                            .text_desc()
                            .expect("text message should have text desc");
                        assert_eq!(text_desc.body(), "Hi, everyone");
                        bail!("");
                    }
                }
            }
            Ok(())
        }
    })
    .await?;

    let edited_id = convo
        .edit_plain_message(event_id.to_string(), "This is message edition".to_string())
        .await?;
    info!("edited id: {edited_id:?}");

    // while let Some(diff) = stream.next().await {
    //     match diff.action().as_str() {
    //         "Append" => {}
    //         "Insert" => {}
    //         "Set" => {
    //             info!("diff index: {:?}", diff.index());
    //             info!("diff value: {:?}", diff.value());
    //             info!("diff values: {:?}", diff.values());
    //             let value = diff
    //                 .value()
    //                 .expect("diff set action should have valid value");
    //             assert_eq!(value.item_type(), "event");
    //             let event_item = value
    //                 .event_item()
    //                 .expect("user already sent message edition");
    //             assert!(
    //                 event_item.is_edited(),
    //                 "this event should be edition message"
    //             );
    //             assert_eq!(
    //                 event_item.event_id(),
    //                 event_id.to_string(),
    //                 "should be original id, because original msg is replaced with msg edition"
    //             );
    //             let text_desc = event_item
    //                 .text_desc()
    //                 .expect("message edition should have text desc");
    //             assert_eq!(text_desc.body(), "This is message edition");
    //             break;
    //         }
    //         "Remove" => {}
    //         "PushBack" => {}
    //         "PushFront" => {}
    //         "PopBack" => {}
    //         "PopFront" => {}
    //         "Clear" => {}
    //         "Reset" => {
    //             info!("diff index: {:?}", diff.index());
    //             info!("diff value: {:?}", diff.value());
    //             info!("diff values: {:?}", diff.values());
    //             let values = diff
    //                 .values()
    //                 .expect("diff reset action should have valid values");
    //             for msg in values.iter() {
    //                 if msg.item_type() == "event" {
    //                     let event_item =
    //                         msg.event_item().expect("user already sent message edition");
    //                     if event_item.event_id() == event_id.to_string() {
    //                         let text_desc = event_item
    //                             .text_desc()
    //                             .expect("text message should have text desc");
    //                         assert_eq!(text_desc.body(), "Hi, everyone");
    //                         break;
    //                     }
    //                 }
    //             }
    //         }
    //         "Truncate" => {}
    //         _ => {}
    //     }
    // }

    Ok(())
}
