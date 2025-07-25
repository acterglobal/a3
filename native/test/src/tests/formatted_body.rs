use acter::api::TimelineItem;
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

    let (users, room_id) = random_users_with_random_convo("markdown", 1).await?;
    let mut sisko = users[0].clone();
    let mut kyra = users[1].clone();

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

    // sisko sends the formatted text message to kyra
    let draft = sisko.text_markdown_draft("**Hello**".to_owned());
    sisko_timeline.send_message(Box::new(draft)).await?;

    // wait for sync to catch up
    let event_id = Retry::spawn(retry_strategy, || async {
        for v in kyra_convo.items().await {
            if let Some(event_id) = match_html_msg(&v, "<strong>Hello</strong>") {
                return Ok(event_id);
            };
        }
        bail!("Event not found");
    })
    .await?;

    info!("kyra received rich text msg: {}", event_id);

    Ok(())
}

fn match_html_msg(msg: &TimelineItem, body: &str) -> Option<String> {
    info!("match room msg - {:?}", msg.clone());
    if msg.is_virtual() {
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
