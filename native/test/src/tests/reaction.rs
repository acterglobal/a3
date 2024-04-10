use acter::{api::RoomMessage, ruma_common::OwnedEventId};
use anyhow::{Context, Result};
use core::time::Duration;
use futures::{pin_mut, stream::StreamExt, FutureExt};
use tokio::time::sleep;
use tracing::info;

use crate::utils::random_users_with_random_convo;

#[tokio::test]
async fn sisko_reads_msg_reactions() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut sisko, mut kyra, mut worf, room_id) =
        random_users_with_random_convo("reaction").await?;

    let sisko_sync = sisko.start_sync();
    sisko_sync.await_has_synced_history().await?;

    let sisko_convo = sisko
        .convo(room_id.to_string())
        .await
        .expect("sisko should belong to convo");
    let sisko_timeline = sisko_convo.timeline_stream();
    let sisko_stream = sisko_timeline.messages_stream();
    pin_mut!(sisko_stream);

    let kyra_sync = kyra.start_sync();
    kyra_sync.await_has_synced_history().await?;

    let kyra_convo = kyra
        .convo(room_id.to_string())
        .await
        .expect("kyra should belong to convo");
    let kyra_timeline = kyra_convo.timeline_stream();
    let kyra_stream = kyra_timeline.messages_stream();
    pin_mut!(kyra_stream);

    kyra_stream.next().await;
    for invited in kyra.invited_rooms().iter() {
        info!(" - accepting {:?}", invited.room_id());
        invited.join().await?;
    }

    let worf_sync = worf.start_sync();
    worf_sync.await_has_synced_history().await?;

    let worf_convo = worf
        .convo(room_id.to_string())
        .await
        .expect("worf should belong to convo");
    let worf_timeline = worf_convo.timeline_stream();
    let worf_stream = worf_timeline.messages_stream();
    pin_mut!(worf_stream);

    worf_stream.next().await;
    for invited in worf.invited_rooms().iter() {
        info!(" - accepting {:?}", invited.room_id());
        invited.join().await?;
    }

    let draft = sisko.text_plain_draft("Hi, everyone".to_string());
    sisko_timeline.send_message(Box::new(draft)).await?;

    // text msg may reach via reset action or set action
    let mut i = 30;
    let mut received = None;
    while i > 0 {
        info!("stream loop - {i}");
        if let Some(diff) = kyra_stream.next().now_or_never().flatten() {
            info!("stream diff - {}", diff.action());
            match diff.action().as_str() {
                "PushBack" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    info!("diff pushback - {:?}", value);
                    if let Some(event_id) = match_text_msg(&value, "Hi, everyone") {
                        received = Some(event_id);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    info!("diff reset - {:?}", values);
                    for value in values.iter() {
                        if let Some(event_id) = match_text_msg(value, "Hi, everyone") {
                            received = Some(event_id);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if received.is_some() {
                break;
            }
        }
        info!("continue loop");
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    info!("loop finished");
    let kyra_received = received.context("Even after 30 seconds, text msg not received")?;

    // text msg may reach via reset action or set action
    i = 30;
    received = None;
    while i > 0 {
        info!("stream loop - {i}");
        if let Some(diff) = worf_stream.next().now_or_never().flatten() {
            info!("stream diff - {}", diff.action());
            match diff.action().as_str() {
                "PushBack" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    info!("diff pushback - {:?}", value);
                    if let Some(event_id) = match_text_msg(&value, "Hi, everyone") {
                        received = Some(event_id);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    info!("diff reset - {:?}", values);
                    for value in values.iter() {
                        if let Some(event_id) = match_text_msg(value, "Hi, everyone") {
                            received = Some(event_id);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if received.is_some() {
                break;
            }
        }
        info!("continue loop");
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    info!("loop finished");
    let worf_received = received.context("Even after 30 seconds, text msg not received")?;

    kyra_timeline
        .toggle_reaction(kyra_received.to_string(), "👏".to_string())
        .await?;
    worf_timeline
        .toggle_reaction(worf_received.to_string(), "😎".to_string())
        .await?;

    // msg reaction may reach via set action
    i = 10;
    let mut found = false;
    while i > 0 {
        info!("stream loop - {i}");
        if let Some(diff) = sisko_stream.next().now_or_never().flatten() {
            info!("stream diff - {}", diff.action());
            if diff.action().as_str() == "Set" {
                let value = diff
                    .value()
                    .expect("diff set action should have valid value");
                info!("diff set - {:?}", value);
                if match_msg_reaction(&value, "Hi, everyone", "👏".to_string())
                    && match_msg_reaction(&value, "Hi, everyone", "😎".to_string())
                {
                    found = true;
                }
            }
            // yay
            if found {
                break;
            }
        }
        info!("continue loop");
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    info!("loop finished");
    assert!(found, "Even after 10 seconds, msg reaction not received");

    Ok(())
}

fn match_text_msg(msg: &RoomMessage, body: &str) -> Option<OwnedEventId> {
    info!("match room msg - {:?}", msg.clone());
    if msg.item_type() == "event" {
        let event_item = msg.event_item().expect("room msg should have event item");
        if let Some(msg_content) = event_item.msg_content() {
            if msg_content.body() == body {
                // exclude the pending msg
                if let Some(event_id) = event_item.evt_id() {
                    return Some(event_id);
                }
            }
        }
    }
    None
}

fn match_msg_reaction(msg: &RoomMessage, body: &str, key: String) -> bool {
    info!("match room msg - {:?}", msg.clone());
    if msg.item_type() == "event" {
        let event_item = msg.event_item().expect("room msg should have event item");
        if let Some(msg_content) = event_item.msg_content() {
            if msg_content.body() == body && event_item.reaction_keys().contains(&key) {
                return true;
            }
        }
    }
    false
}
