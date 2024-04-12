use acter::{api::RoomMessage, ruma_common::OwnedEventId};
use anyhow::{Context, Result};
use core::time::Duration;
use futures::{pin_mut, stream::StreamExt, FutureExt};
use tokio::time::sleep;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};
use tracing::info;

use crate::utils::random_users_with_random_convo;

#[tokio::test]
async fn sisko_detects_kyra_read() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut sisko, mut kyra, _, room_id) = random_users_with_random_convo("detect_read").await?;

    let sisko_sync = sisko.start_sync();
    sisko_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = sisko.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.convo(room_id.to_string()).await }
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
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = kyra.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.convo(room_id.to_string()).await }
    })
    .await?;

    let kyra_convo = kyra.convo(room_id.to_string()).await?;
    let kyra_timeline = kyra_convo.timeline_stream();

    let draft = sisko.text_plain_draft("Hi, everyone".to_string());
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
                        if let Some(event_id) = match_room_msg(value, "Hi, everyone") {
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
                    if let Some(event_id) = match_room_msg(&value, "Hi, everyone") {
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
    info!("loop finished");
    let received = received.context("Even after 30 seconds, text msg not received")?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_timeline = kyra_timeline.clone();
    let target_id = received.clone();
    Retry::spawn(retry_strategy, move || {
        let timeline = fetcher_timeline.clone();
        let received = target_id.clone();
        async move { timeline.get_message(received.to_string()).await }
    })
    .await?;

    kyra_timeline
        .send_single_receipt(
            "Read".to_string(), // will test only Read, because ReadPrivate not reached
            "Main".to_string(), // when not main, below event receiver will not receive this event
            received.to_string(),
        )
        .await?;

    let mut event_rx = sisko
        .receipt_event_rx()
        .context("sisko needs receipt event receiver")?;

    i = 30; // sometimes read receipt not reached
    let mut found = false;
    while i > 0 {
        info!("receipt loop ---------------------------------- {i}");
        match event_rx.try_next() {
            Ok(Some(event)) => {
                info!("received: {:?}", event.clone());
                for record in event.receipt_records() {
                    if record.seen_by() == kyra.user_id()? {
                        assert_eq!(record.receipt_type(), "m.read", "Incorrect receipt type");
                        let receipt_thread = record.receipt_thread();
                        assert!(receipt_thread.is_main(), "Incorrect receipt thread");
                        found = true;
                        break;
                    }
                }
                if found {
                    println!("received: {event:?}");
                    break;
                }
            }
            Ok(None) => {
                println!("received: none");
            }
            Err(e) => {
                info!("received error: {:?}", e);
            }
        }
        info!("continue loop");
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    info!("loop finished");
    assert!(found, "Even after 30 seconds, read receipt not received");

    Ok(())
}

fn match_room_msg(msg: &RoomMessage, body: &str) -> Option<OwnedEventId> {
    info!("match room msg - {:?}", msg.clone());
    if msg.item_type() == "event" {
        let event_item = msg.event_item().expect("room msg should have event item");
        if let Some(msg_content) = event_item.msg_content() {
            if msg_content.body() == body {
                // exclude the pending msg
                if let Some(event_id) = event_item.evt_id() {
                    return Some(event_id);
                }
            }
        }
    }
    None
}
