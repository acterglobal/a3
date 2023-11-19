use anyhow::Result;
use futures::stream::StreamExt;
use tracing::info;

use crate::utils::random_users_with_random_convo;

#[tokio::test]
async fn sisko_detects_kyra_read() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut sisko, mut kyra, _, room_id) = random_users_with_random_convo("detect_read").await?;
    let sisko_sync = sisko.start_sync();
    sisko_sync.await_has_synced_history().await?;

    info!("1");

    let kyra_sync = kyra.start_sync();
    kyra_sync.await_has_synced_history().await?;
    let mut kyra_stream = Box::pin(kyra.sync_stream(Default::default()).await);
    kyra_stream.next().await;
    for invited in kyra.invited_rooms().iter() {
        info!(" - accepting {:?}", invited.room_id());
        invited.join().await?;
    }

    info!("2");

    let sisko_convo = sisko
        .convo(room_id.to_string())
        .await
        .expect("sisko should belong to convo");
    let sisko_timeline = sisko_convo
        .timeline_stream()
        .await
        .expect("sisko should get timeline stream");
    sisko_timeline
        .send_plain_message("Hi, everyone".to_string())
        .await?;

    info!("3");

    let mut sisko_stream = Box::pin(sisko.sync_stream(Default::default()).await);
    let mut event_id = None;
    loop {
        sisko_stream.next().await;
        if let Some(msg) = sisko_convo.latest_message() {
            if let Some(event_item) = msg.event_item() {
                if let Some(text_desc) = event_item.text_desc() {
                    assert_eq!(text_desc.body(), "Hi, everyone");
                    event_id = Some(event_item.event_id());
                    break;
                }
            }
        }
    }

    info!("4");

    let kyra_convo: acter::Convo = kyra
        .convo(room_id.to_string())
        .await
        .expect("kyra should belong to convo");
    let kyra_timeline = kyra_convo
        .timeline_stream()
        .await
        .expect("kyra should get timeline stream");
    kyra_timeline
        .send_multiple_receipts(event_id.clone(), event_id.clone(), event_id)
        .await?;

    info!("5");

    let mut event_rx = sisko.receipt_event_rx().unwrap();
    loop {
        info!("receipt loop ----------------------------------");
        sisko_stream.next().await;
        match event_rx.try_next() {
            Ok(Some(event)) => {
                info!("received: {:?}", event.clone());
                let mut found = false;
                for record in event.receipt_records() {
                    if record.seen_by() == kyra.user_id()?.to_string() {
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
    }

    Ok(())
}
