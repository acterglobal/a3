use anyhow::{Context, Result};
use core::time::Duration;
use futures::stream::StreamExt;
use tokio::time::sleep;
use tracing::info;

use crate::utils::random_users_with_random_convo;

#[tokio::test]
async fn kyra_detects_sisko_typing() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut sisko, mut kyra, _, room_id) = random_users_with_random_convo("detect_read").await?;

    let sisko_sync = sisko.start_sync();
    sisko_sync.await_has_synced_history().await?;

    let sisko_convo = sisko
        .convo(room_id.to_string())
        .await
        .expect("sisko should belong to convo");

    let kyra_sync = kyra.start_sync();
    kyra_sync.await_has_synced_history().await?;
    let mut kyra_stream = Box::pin(kyra.sync_stream(Default::default()).await);
    kyra_stream.next().await;
    for invited in kyra.invited_rooms().iter() {
        info!(" - accepting {:?}", invited.room_id());
        invited.join().await?;
    }

    let sent = sisko_convo.typing_notice(true).await?;
    println!("sent: {sent:?}");

    let mut event_rx = kyra
        .typing_event_rx()
        .context("kyra needs typing event receiver")?;

    let mut i = 3;
    let mut found = false;
    while i > 0 {
        match event_rx.try_next() {
            Ok(Some(event)) => {
                info!("received: {event:?}");
                found = true;
                break;
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
    assert!(found, "typing event not reached");

    Ok(())
}
