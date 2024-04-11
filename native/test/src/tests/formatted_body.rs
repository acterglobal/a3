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
async fn sisko_sends_rich_text_to_kyra() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut sisko, mut kyra, _, room_id) = random_users_with_random_convo("markdown").await?;
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
    let kyra_stream = kyra_timeline.messages_stream();
    pin_mut!(kyra_stream);

    // sisko sends the formatted text message to kyra
    let draft = sisko.text_markdown_draft("**Hello**".to_string());
    sisko_timeline.send_message(Box::new(draft)).await?;

    // text msg may reach via pushback action or reset action
    let mut i = 30;
    let mut received = None;
    while i > 0 {
        info!("stream loop - {i}");
        if let Some(diff) = kyra_stream.next().now_or_never().flatten() {
            info!("stream diff - {}", diff.action());
            match diff.action().as_str() {
                "PushBack" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    info!("diff pushback - {:?}", value);
                    if let Some(event_id) =
                        match_room_msg(&value, "<p><strong>Hello</strong></p>\n")
                    {
                        received = Some(event_id);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    info!("diff reset - {:?}", values);
                    for value in values.iter() {
                        if let Some(event_id) =
                            match_room_msg(value, "<p><strong>Hello</strong></p>\n")
                        {
                            received = Some(event_id);
                            break;
                        }
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

    Ok(())
}

fn match_room_msg(msg: &RoomMessage, body: &str) -> Option<OwnedEventId> {
    info!("match room msg - {:?}", msg.clone());
    if msg.item_type() == "event" {
        let event_item = msg.event_item().expect("room msg should have event item");
        if let Some(msg_content) = event_item.msg_content() {
            if let Some(formatted) = msg_content.formatted_body() {
                if formatted == body {
                    // exclude the pending msg
                    if let Some(event_id) = event_item.evt_id() {
                        return Some(event_id);
                    }
                }
            }
        }
    }
    None
}
