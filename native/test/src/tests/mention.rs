use acter::api::TimelineItem;
use anyhow::{bail, Result};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};
use tracing::info;

use crate::utils::random_users_with_random_convo;

#[tokio::test]
async fn sisko_mentions_room() -> Result<()> {
    let _ = env_logger::try_init();

    let (users, room_id) = random_users_with_random_convo("mention_room", 2).await?;
    let mut sisko = users[0].clone();
    let mut kyra = users[1].clone();
    let mut worf = users[2].clone();

    // wait for sisko sync to catch up
    let sisko_sync = sisko.start_sync();
    sisko_sync.await_has_synced_history().await?;

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), || async {
        sisko.convo(room_id.to_string()).await
    })
    .await?;

    let sisko_convo = sisko.convo(room_id.to_string()).await?;
    let sisko_timeline = sisko_convo.timeline_stream().await?;

    // wait for kyra sync to catch up
    let kyra_sync = kyra.start_sync();
    kyra_sync.await_has_synced_history().await?;

    for invited in kyra.invited_rooms().iter() {
        info!(" - accepting {:?}", invited.room_id());
        invited.join().await?;
    }

    Retry::spawn(retry_strategy.clone(), || async {
        kyra.convo(room_id.to_string()).await
    })
    .await?;

    let kyra_convo = kyra.convo(room_id.to_string()).await?;

    // wait for worf sync to catch up
    let worf_sync = worf.start_sync();
    worf_sync.await_has_synced_history().await?;

    for invited in worf.invited_rooms().iter() {
        info!(" - accepting {:?}", invited.room_id());
        invited.join().await?;
    }

    Retry::spawn(retry_strategy.clone(), || async {
        worf.convo(room_id.to_string()).await
    })
    .await?;

    let worf_convo = worf.convo(room_id.to_string()).await?;

    // sisko sends the text message that mentions kyra and worf
    let draft = sisko
        .text_plain_draft("Hello, there".to_owned())
        .add_room_mention(true)?
        .clone(); // switch variable from temporary to normal so that send_message can use it
    sisko_timeline.send_message(Box::new(draft)).await?;

    // wait for kyra sync to catch up
    let (event_id, room_mentioned, _) = Retry::spawn(retry_strategy.clone(), || async {
        for v in kyra_convo.items().await? {
            if let Some(result) = match_mentioned_msg(&v, "Hello, there") {
                return Ok(result);
            };
        }
        bail!("Event not found");
    })
    .await?;

    info!("kyra found sisko mentioned room: {}", event_id);
    assert!(room_mentioned);

    // wait for worf sync to catch up
    let (event_id, room_mentioned, _) = Retry::spawn(retry_strategy, || async {
        for v in worf_convo.items().await? {
            if let Some(result) = match_mentioned_msg(&v, "Hello, there") {
                return Ok(result);
            };
        }
        bail!("Event not found");
    })
    .await?;

    info!("worf found sisko mentioned room: {}", event_id);
    assert!(room_mentioned);

    Ok(())
}

#[tokio::test]
async fn sisko_mentions_kyra_worf() -> Result<()> {
    let _ = env_logger::try_init();

    let (users, room_id) = random_users_with_random_convo("mention_users", 2).await?;
    let mut sisko = users[0].clone();
    let mut kyra = users[1].clone();
    let mut worf = users[2].clone();

    // wait for sisko sync to catch up
    let sisko_sync = sisko.start_sync();
    sisko_sync.await_has_synced_history().await?;

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), || async {
        sisko.convo(room_id.to_string()).await
    })
    .await?;

    let sisko_convo = sisko.convo(room_id.to_string()).await?;
    let sisko_timeline = sisko_convo.timeline_stream().await?;

    // wait for kyra sync to catch up
    let kyra_sync = kyra.start_sync();
    kyra_sync.await_has_synced_history().await?;

    for invited in kyra.invited_rooms().iter() {
        info!(" - accepting {:?}", invited.room_id());
        invited.join().await?;
    }

    Retry::spawn(retry_strategy.clone(), || async {
        kyra.convo(room_id.to_string()).await
    })
    .await?;

    let kyra_convo = kyra.convo(room_id.to_string()).await?;

    // wait for worf sync to catch up
    let worf_sync = worf.start_sync();
    worf_sync.await_has_synced_history().await?;

    for invited in worf.invited_rooms().iter() {
        info!(" - accepting {:?}", invited.room_id());
        invited.join().await?;
    }

    Retry::spawn(retry_strategy.clone(), || async {
        worf.convo(room_id.to_string()).await
    })
    .await?;

    let worf_convo = worf.convo(room_id.to_string()).await?;

    // sisko sends the text message that mentions kyra and worf
    let kyra_id = kyra.user_id()?.to_string();
    let worf_id = worf.user_id()?.to_string();
    let draft = sisko
        .text_plain_draft("Hello, there".to_owned())
        .add_mention(kyra_id.clone())?
        .add_mention(worf_id.clone())?
        .clone(); // switch variable from temporary to normal so that send_message can use it
    sisko_timeline.send_message(Box::new(draft)).await?;

    // wait for kyra sync to catch up
    let (event_id, room_mentioned, mentioned_users) =
        Retry::spawn(retry_strategy.clone(), || async {
            for v in kyra_convo.items().await? {
                if let Some(result) = match_mentioned_msg(&v, "Hello, there") {
                    return Ok(result);
                };
            }
            bail!("Event not found");
        })
        .await?;

    info!("kyra found sisko mentioned her: {}", event_id);
    assert!(!room_mentioned);
    assert!(mentioned_users.contains(&kyra_id));

    // wait for worf sync to catch up
    let (event_id, room_mentioned, mentioned_users) = Retry::spawn(retry_strategy, || async {
        for v in worf_convo.items().await? {
            if let Some(result) = match_mentioned_msg(&v, "Hello, there") {
                return Ok(result);
            };
        }
        bail!("Event not found");
    })
    .await?;

    info!("worf found sisko mentioned him: {}", event_id);
    assert!(!room_mentioned);
    assert!(mentioned_users.contains(&worf_id));

    Ok(())
}

fn match_mentioned_msg(msg: &TimelineItem, body: &str) -> Option<(String, bool, Vec<String>)> {
    info!("match room msg - {:?}", msg.clone());
    if !msg.is_virtual() {
        let event_item = msg.event_item().expect("room msg should have event item");
        if let Some(msg_content) = event_item.msg_content() {
            if msg_content.body() == body {
                // exclude the pending msg
                if let Some(event_id) = event_item.event_id() {
                    return Some((
                        event_id,
                        event_item.room_mentioned(),
                        event_item.mentioned_users(),
                    ));
                }
            }
        }
    }
    None
}
