use acter::ruma_common::EventId;
use anyhow::{bail, Result};
use futures::stream::StreamExt;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};
use tracing::info;

use crate::utils::random_users_with_random_convo;

#[tokio::test]
async fn sisko_reads_msg_reactions() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut sisko, mut kyra, mut worf, room_id) =
        random_users_with_random_convo("reaction").await?;
    let sisko_sync = sisko.start_sync();
    sisko_sync.await_has_synced_history().await?;

    info!("1");

    let Ok(kyra_id) = kyra.user_id() else {
        bail!("kyra should have user id")
    };
    let kyra_sync = kyra.start_sync();
    kyra_sync.await_has_synced_history().await?;
    let mut kyra_stream = Box::pin(kyra.sync_stream(Default::default()).await);
    kyra_stream.next().await;
    for invited in kyra.invited_rooms().iter() {
        info!(" - accepting {:?}", invited.room_id());
        invited.join().await?;
    }

    info!("2");

    let Ok(worf_id) = worf.user_id() else {
        bail!("worf should have user id")
    };
    let worf_sync = worf.start_sync();
    worf_sync.await_has_synced_history().await?;
    let mut worf_stream = Box::pin(worf.sync_stream(Default::default()).await);
    worf_stream.next().await;
    for invited in worf.invited_rooms().iter() {
        info!(" - accepting {:?}", invited.room_id());
        invited.join().await?;
    }

    info!("3");

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

    info!("4");

    let mut sisko_stream = Box::pin(sisko.sync_stream(Default::default()).await);
    let mut event_id = None;
    loop {
        sisko_stream.next().await;
        if let Some(msg) = sisko_convo.latest_message() {
            if let Some(event_item) = msg.event_item() {
                let Some(text_desc) = event_item.text_desc() else {
                    bail!("this event should be text message")
                };
                assert_eq!(text_desc.body(), "Hi, everyone");
                event_id = Some(event_item.event_id());
                break;
            }
        }
    }

    info!("5");

    let kyra_convo = kyra
        .convo(room_id.to_string())
        .await
        .expect("kyra should belong to convo");
    let kyra_timeline = kyra_convo
        .timeline_stream()
        .await
        .expect("kyra should get timeline stream");

    info!("6");

    let worf_convo = worf
        .convo(room_id.to_string())
        .await
        .expect("worf should belong to convo");
    let worf_timeline = worf_convo
        .timeline_stream()
        .await
        .expect("worf should get timeline stream");

    info!("7");

    kyra_timeline
        .send_reaction(event_id.clone().unwrap(), "👏".to_string())
        .await?;
    worf_timeline
        .send_reaction(event_id.clone().unwrap(), "😎".to_string())
        .await?;

    info!("8");

    sisko_stream.next().await;
    let evt_id = EventId::parse(event_id.clone().unwrap())?;
    let ev = sisko_timeline.event(evt_id.clone()).await?;
    let Some(user_reactions) = ev.reactions().get("👏") else {
        bail!("kyra already reacted as 👏")
    };
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), move || {
        let sisko_timeline = sisko_timeline.clone();
        let evt_id = evt_id.clone();
        async move {
            let ev = sisko_timeline.event(evt_id).await?;
            info!("sisko's 2nd event: {:?}", ev);
            let Some(user_reactions) = ev.reactions().get("😎") else {
                bail!("worf already reacted as 😎")
            };
            Ok(())
        }
    })
    .await?;

    Ok(())
}
