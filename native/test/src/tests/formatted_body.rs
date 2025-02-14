use acter::api::RoomMessage;
use anyhow::{bail, Result};
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
    let sisko_sync = sisko.start_sync().await?;
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

    let kyra_sync = kyra.start_sync().await?;
    kyra_sync.await_has_synced_history().await?;

    for invited in kyra.invited_rooms().iter() {
        info!(" - accepting {:?}", invited.room_id());
        invited.join().await?;
    }

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = kyra.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.convo(room_id.to_string()).await }
    })
    .await?;

    let kyra_convo = kyra.convo(room_id.to_string()).await?;

    // sisko sends the formatted text message to kyra
    let draft = sisko.text_markdown_draft("**Hello**".to_string());
    sisko_timeline.send_message(Box::new(draft)).await?;

    // wait for sync to catch up
    let room_tl = kyra_convo.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let timeline = room_tl.clone();
        async move {
            for v in timeline.items().await {
                let Some(event_id) = match_room_msg(&v, "<strong>Hello</strong>") else {
                    continue;
                };
                return Ok(event_id);
            }
            bail!("Event not found");
        }
    })
    .await?;

    Ok(())
}

fn match_room_msg(msg: &RoomMessage, body: &str) -> Option<String> {
    info!("match room msg - {:?}", msg.clone());
    if msg.item_type() != "event" {
        return None;
    }
    let event_item = msg.event_item()?;
    let msg_content = event_item.msg_content()?;
    let _fresh_body = msg_content.body();
    let formatted = msg_content.formatted_body()?;

    if formatted == body {
        // exclude the pending msg
        if let Some(event_id) = event_item.event_id() {
            return Some(event_id);
        }
    }
    None
}
