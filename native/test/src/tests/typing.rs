use anyhow::{bail, Result};
use core::time::Duration;
use futures::{pin_mut, stream::StreamExt};
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

    let kyra_convo = kyra
        .convo(room_id.to_string())
        .await
        .expect("kyra should belong to convo");
    let kyra_timeline = kyra_convo
        .timeline_stream()
        .await
        .expect("kyra should get timeline stream");
    let kyra_stream = kyra_timeline.diff_stream();
    pin_mut!(kyra_stream);

    kyra_stream.next().await;
    for invited in kyra.invited_rooms().iter() {
        info!(" - accepting {:?}", invited.room_id());
        invited.join().await?;
    }

    let sent = sisko_convo.typing_notice(true).await?;
    println!("sent: {sent:?}");

    let Some(mut event_rx) = kyra.typing_event_rx() else {
        bail!("kyra needs typing event receiver")
    };

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
