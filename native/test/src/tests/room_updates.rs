use crate::utils::{
    invite_user, match_text_msg, random_user, random_user_with_random_convo,
    random_user_with_random_space,
};
use anyhow::{Context, Result};
use core::time::Duration;
use futures::{pin_mut, stream::StreamExt, FutureExt};
use matrix_sdk::RoomState;
use tokio::time::sleep;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};
use tracing::info;

#[tokio::test]
async fn simple_message_doesnt_trigger_room_update() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("room_update_test").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    let convo = Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.convo(room_id.to_string()).await }
    })
    .await?;

    let mut room_stream = user.subscribe_room_stream(room_id.to_string())?;
    // clear the streem
    while room_stream.next().now_or_never().flatten().is_some() {}

    let timeline = convo.timeline_stream();
    let stream = timeline.messages_stream();
    pin_mut!(stream);

    let draft = user.text_plain_draft("Hi, everyone".to_owned());
    timeline.send_message(Box::new(draft)).await?;

    // text msg may reach via reset action or set action
    let mut i = 30;
    let mut sent_event_id = None;
    while i > 0 {
        info!("stream loop - {i}");
        if let Some(diff) = stream.next().now_or_never().flatten() {
            info!("stream diff - {}", diff.action());
            match diff.action().as_str() {
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    info!("diff reset - {:?}", values);
                    for value in values.iter() {
                        if let Some(event_id) = match_text_msg(value, "Hi, everyone", false) {
                            sent_event_id = Some(event_id);
                            break;
                        }
                    }
                }
                "Set" => {
                    let value = diff
                        .value()
                        .expect("diff set action should have valid value");
                    info!("diff set - {:?}", value);
                    if let Some(event_id) = match_text_msg(&value, "Hi, everyone", false) {
                        sent_event_id = Some(event_id);
                    }
                }
                _ => {}
            }
            // yay
            if sent_event_id.is_some() {
                info!("found sent");
                break;
            }
        }
        info!("continue loop");
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    info!("loop finished");
    let sent_event_id = sent_event_id.context("Even after 30 seconds, text msg not received")?;

    // get the message
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_timeline = timeline.clone();
    let target_id = sent_event_id.clone();
    let _message = Retry::spawn(retry_strategy, move || {
        let timeline = fetcher_timeline.clone();
        let event_id = target_id.clone();
        async move { timeline.get_message(event_id.to_string()).await }
    })
    .await?;

    // ensure we didin't see any update to the room itself
    assert_eq!(room_stream.next().now_or_never().flatten(), None);

    // let's make sure that a reaction does trigger an update either
    timeline
        .toggle_reaction(sent_event_id.to_string(), "+1".to_owned())
        .await?;
    sleep(Duration::from_secs(2)).await; // make sure it came through the sync
    assert_eq!(room_stream.next().now_or_never().flatten(), None);

    Ok(())
}

#[tokio::test]
async fn state_update_triggers_room_update() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("room_update_test").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    let convo = Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.convo(room_id.to_string()).await }
    })
    .await?;

    let mut room_stream = user.subscribe_room_stream(room_id.to_string())?;
    // clear the streem
    while room_stream.next().now_or_never().flatten().is_some() {}

    convo.set_name("a fresh new name".to_owned()).await?;
    sleep(Duration::from_secs(2)).await; // make sure it came through the sync
    assert_eq!(room_stream.next().now_or_never().flatten(), Some(true));

    Ok(())
}

#[tokio::test]
async fn joining_room_triggers_room_update() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut sisko, room_id) = random_user_with_random_space("spI").await?;
    let _sisko_syncer = sisko.start_sync();

    let mut kyra = random_user("spI").await?;
    let _kyra_syncer = kyra.start_sync();

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);

    let invites = kyra.invitations();
    let stream = invites.subscribe_stream();
    let mut stream = stream.fuse();

    invite_user(&sisko, &room_id, &kyra.user_id()?).await?;

    let invited = Retry::spawn(retry_strategy.clone(), || async {
        let invited = kyra.invitations().room_invitations().await?;
        if invited.is_empty() {
            Err(anyhow::anyhow!("No pending invitations found"))
        } else {
            Ok(invited)
        }
    })
    .await?;

    // stream triggered
    assert_eq!(stream.next().await, Some(true));

    assert_eq!(invited.len(), 1);
    let room = invited.first().expect("first invitation should be available");
    assert_eq!(room.room_id(), room_id);
    assert_eq!(room.state(), RoomState::Invited);
    assert!(room.is_space());
    assert_eq!(room.sender_id(), sisko.user_id()?);

    let mut room_stream = kyra.subscribe_room_stream(room_id.to_string())?;
    // clear the streem
    while room_stream.next().now_or_never().flatten().is_some() {}

    room.join().await?;
    sleep(Duration::from_secs(2)).await; // make sure it came through the sync
    assert_eq!(room_stream.next().now_or_never().flatten(), Some(true));

    Ok(())
}
