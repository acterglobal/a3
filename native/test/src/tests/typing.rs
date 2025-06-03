use anyhow::Result;
use core::time::Duration;
use tokio::time::sleep;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};
use tracing::info;

use crate::utils::random_users_with_random_convo;

#[tokio::test]
async fn kyra_detects_sisko_typing() -> Result<()> {
    let _ = env_logger::try_init();
    let (users, room_id) = random_users_with_random_convo("detect_read", 1).await?;

    let mut sisko = users[0].clone();
    let mut kyra = users[1].clone();

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

    let mut event_rx = kyra.subscribe_to_typing_event(room_id.to_string());
    let _sent = sisko_convo.typing_notice(true).await?;

    let mut i = 10;
    let mut found = false;
    while i > 0 {
        match event_rx.try_recv() {
            Ok(event) => {
                info!("received: {event:?}");
                found = true;
                break;
            }
            Err(e) => {
                info!("received error: {:?}", e);
            }
        }
        info!("continue loop");
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    assert!(found, "Even after 10 seconds, typing event not reached");

    Ok(())
}
