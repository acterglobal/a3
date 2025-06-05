use anyhow::{Context, Result};
use core::time::Duration;
use futures::{pin_mut, stream::StreamExt, FutureExt};
use tokio::time::sleep;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};
use tracing::info;

use crate::utils::{match_text_msg, random_users_with_random_convo};

#[tokio::test]
async fn sisko_reads_kyra_reply() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut sisko, mut kyra, _, room_id) = random_users_with_random_convo("reply").await?;

    let sisko_sync = sisko.start_sync();
    sisko_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), || async {
        sisko.convo(room_id.to_string()).await
    })
    .await?;

    let sisko_convo = sisko.convo(room_id.to_string()).await?;
    let sisko_timeline = sisko_convo.timeline_stream();
    let sisko_stream = sisko_timeline.messages_stream();
    pin_mut!(sisko_stream);

    let kyra_sync = kyra.start_sync();
    kyra_sync.await_has_synced_history().await?;

    for invited in kyra.invited_rooms().iter() {
        info!(" - accepting {:?}", invited.room_id());
        invited.join().await?;
    }

    // wait for sync to catch up
    Retry::spawn(retry_strategy.clone(), || async {
        kyra.convo(room_id.to_string()).await
    })
    .await?;

    let kyra_convo = kyra.convo(room_id.to_string()).await?;
    let kyra_timeline = kyra_convo.timeline_stream();

    let draft = sisko.text_plain_draft("Hi, everyone".to_owned());
    sisko_timeline.send_message(Box::new(draft)).await?;

    // text msg may reach via reset action or set action
    let mut i = 30;
    let mut received = None;
    while i > 0 {
        info!("stream loop - {i}");
        if let Some(diff) = sisko_stream.next().now_or_never().flatten() {
            info!("stream diff - {}", diff.action());
            match diff.action().as_str() {
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    info!("diff reset - {:?}", values);
                    for value in values.iter() {
                        if let Some(event_id) = match_text_msg(value, "Hi, everyone", false) {
                            received = Some(event_id);
                            break;
                        }
                    }
                }
                "Set" => {
                    let value = diff
                        .value()
                        .expect("diff set action should have valid value");
                    info!("diff set - {:?}", value);
                    if let Some(event_id) = match_text_msg(&value, "Hi, everyone", false) {
                        received = Some(event_id);
                    }
                }
                _ => {}
            }
            // yay
            if received.is_some() {
                break;
            }
        }
        info!("continue loop");
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    info!("loop finished - {:?}", received);
    let received = received.context("Even after 30 seconds, text msg not received")?;

    // wait for sync to catch up
    Retry::spawn(retry_strategy, || async {
        kyra_timeline.get_message(received.clone()).await
    })
    .await?;

    let draft = kyra.text_plain_draft("Sorry, it’s my bad".to_owned());
    kyra_timeline
        .reply_message(received, Box::new(draft))
        .await?;

    // msg reply may reach via pushback action
    i = 10;
    let mut found = false;
    while i > 0 {
        info!("stream loop - {i}");
        if let Some(diff) = sisko_stream.next().now_or_never().flatten() {
            info!("stream diff - {}", diff.action());
            if diff.action().as_str() == "PushBack" {
                let value = diff
                    .value()
                    .expect("diff pushback action should have valid value");
                info!("diff pushback - {:?}", value);
                if match_text_msg(&value, "Sorry, it’s my bad", false).is_some() {
                    found = true;
                }
            }
            // yay
            if found {
                break;
            }
        }
        info!("continue loop");
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    info!("loop finished");
    assert!(found, "Even after 10 seconds, msg reply not received");

    Ok(())
}
