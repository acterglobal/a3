use anyhow::Result;
use futures::stream::StreamExt;
use tracing::info;

use crate::utils::random_users_with_random_convo;

#[tokio::test]
async fn sisko_reads_kyra_reply() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut sisko, mut kyra, worf, room_id) = random_users_with_random_convo("reply").await?;
    let sisko_sync = sisko.start_sync();
    sisko_sync.await_has_synced_history().await?;
    let mut sisko_stream = Box::pin(sisko.sync_stream(Default::default()).await);

    let kyra_sync = kyra.start_sync();
    kyra_sync.await_has_synced_history().await?;
    let mut kyra_stream = Box::pin(kyra.sync_stream(Default::default()).await);
    kyra_stream.next().await;
    for invited in kyra.invited_rooms().iter() {
        info!(" - accepting {:?}", invited.room_id());
        invited.join().await?;
    }

    let mut worf_stream = Box::pin(worf.sync_stream(Default::default()).await);
    worf_stream.next().await;
    for invited in worf.invited_rooms().iter() {
        info!(" - accepting {:?}", invited.room_id());
        invited.join().await?;
    }

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

    let mut event_id = None;
    loop {
        sisko_stream.next().await;
        if let Some(msg) = sisko_convo.latest_message() {
            if let Some(event_item) = msg.event_item() {
                if let Some(text_desc) = event_item.text_desc() {
                    if text_desc.body() == "Hi, everyone" {
                        event_id = Some(event_item.event_id());
                        break;
                    }
                }
            }
        }
    }

    let kyra_convo = kyra
        .convo(room_id.to_string())
        .await
        .expect("kyra should belong to convo");
    let kyra_timeline = kyra_convo
        .timeline_stream()
        .await
        .expect("kyra should get timeline stream");
    kyra_timeline
        .send_plain_reply("Sorry, it's my bad".to_string(), event_id.unwrap(), None)
        .await?;

    loop {
        sisko_stream.next().await;
        if let Some(msg) = sisko_convo.latest_message() {
            if let Some(event_item) = msg.event_item() {
                if let Some(text_desc) = event_item.text_desc() {
                    assert_eq!(
                        text_desc.body(),
                        format!("> <{}> Hi, everyone\n\nSorry, it's my bad", kyra.user_id()?),
                    );
                    break;
                }
            }
        }
    }

    Ok(())
}
