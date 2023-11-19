use anyhow::Result;
use futures::stream::StreamExt;
use tracing::info;

use crate::utils::random_users_with_random_convo;

#[tokio::test]
async fn sisko_sends_rich_text_to_kyra() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut sisko, mut kyra, _, room_id) = random_users_with_random_convo("markdown").await?;
    let sisko_sync = sisko.start_sync();
    sisko_sync.await_has_synced_history().await?;

    let kyra_sync = kyra.start_sync();
    kyra_sync.await_has_synced_history().await?;
    let mut kyra_stream = Box::pin(kyra.sync_stream(Default::default()).await);
    kyra_stream.next().await;
    for invited in kyra.invited_rooms().iter() {
        info!(" - accepting {:?}", invited.room_id());
        invited.join().await?;
    }

    // sisko sends the formatted text message to kyra
    let sisko_convo = sisko
        .convo(room_id.to_string())
        .await
        .expect("sisko should belong to convo");
    let sisko_timeline = sisko_convo
        .timeline_stream()
        .await
        .expect("sisko should get timeline stream");
    sisko_timeline
        .send_formatted_message("**Hello**".to_string())
        .await?;

    // kyra receives the formatted text message from sisko
    let kyra_convo = kyra
        .convo(room_id.to_string())
        .await
        .expect("kyra should belong to convo");
    loop {
        kyra_stream.next().await;
        if let Some(msg) = kyra_convo.latest_message() {
            if let Some(event_item) = msg.event_item() {
                if let Some(text_desc) = event_item.text_desc() {
                    if let Some(formatted) = text_desc.formatted_body() {
                        let idx = formatted.find("<strong>Hello</strong>");
                        assert!(idx.is_some(), "formatted body not found");
                        break;
                    }
                }
            }
        }
    }

    Ok(())
}
