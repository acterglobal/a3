use acter::{api::RoomMessage, ruma_common::OwnedEventId, RoomMessageDiff};
use anyhow::{bail, Result};
use core::time::Duration;
use futures::{pin_mut, stream::StreamExt, FutureExt, Stream};
use tokio::time::sleep;
use tracing::{info, warn};

use crate::utils::{accept_all_invites, random_users_with_random_convo, wait_for_convo_joined};

type MessageMatchesTest = dyn Fn(&RoomMessage) -> bool;

async fn wait_for_message(
    stream: impl Stream<Item = RoomMessageDiff>,
    match_test: &MessageMatchesTest,
    error: &'static str,
) -> Result<OwnedEventId> {
    // text msg may reach via reset action or set action
    let mut i = 30;
    pin_mut!(stream);
    while i > 0 {
        info!("stream loop - {i}");
        if let Some(diff) = stream.next().now_or_never().flatten() {
            info!("stream diff - {}", diff.action());
            match diff.action().as_str() {
                "PushBack" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action must have valid value");
                    info!("diff pushback - {:?}", value);
                    if match_test(&value) {
                        return Ok(value
                            .event_item()
                            .expect("has item")
                            .evt_id()
                            .expect("has id"));
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action must have valid values");
                    for value in values.iter() {
                        info!("diff reset msg: {:?}", value);
                        if match_test(value) {
                            return Ok(value
                                .event_item()
                                .expect("has item")
                                .evt_id()
                                .expect("has id"));
                        }
                    }
                }
                _ => {
                    warn!(
                        "Weirdly we've seen another event: {}",
                        diff.action().as_str()
                    );
                }
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    bail!(error)
}

#[tokio::test]
async fn sisko_reads_msg_reactions() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut sisko, mut kyra, mut worf, room_id) =
        random_users_with_random_convo("reaction").await?;

    let sisko_sync = sisko.start_sync();
    sisko_sync.await_has_synced_history().await?;

    let sisko_convo = wait_for_convo_joined(sisko.clone(), room_id.clone()).await?;
    let sisko_timeline = sisko_convo.timeline_stream();
    let sisko_stream = sisko_timeline.messages_stream();
    pin_mut!(sisko_stream);

    let kyra_sync = kyra.start_sync();
    kyra_sync.await_has_synced_history().await?;
    accept_all_invites(kyra.clone()).await?;

    let kyra_convo = wait_for_convo_joined(kyra.clone(), room_id.clone()).await?;
    let kyra_timeline = kyra_convo.timeline_stream();
    let kyra_stream = kyra_timeline.messages_stream();

    let worf_sync = worf.start_sync();
    worf_sync.await_has_synced_history().await?;
    accept_all_invites(worf.clone()).await?;
    // wait for sync to catch up
    let worf_convo = wait_for_convo_joined(worf.clone(), room_id.clone()).await?;
    let worf_timeline = worf_convo.timeline_stream();
    let worf_stream = worf_timeline.messages_stream();

    let draft = sisko.text_plain_draft("Hi, everyone".to_string());
    sisko_timeline.send_message(Box::new(draft)).await?;

    let kyra_received = wait_for_message(
        kyra_stream,
        &|m| match_text_msg(m, "Hi, everyone").is_some(),
        "even after 30 seconds, kyra didn't see sisko's message",
    )
    .await?;

    // FIXME: for some unknown reason worf only receives an encrypted message
    //        they can't decrypt. Doesn't really matter for the tests itself,
    //        but it's still bad. so this test takes kyras event_id and matches
    //        it against the stream to find the item to react to.

    let check_id = kyra_received.clone();

    let worf_received = wait_for_message(
        worf_stream,
        &move |m| {
            m.event_item()
                .and_then(|e| e.evt_id())
                .map(|s| s == check_id)
                .unwrap_or_default()
        },
        "even after 30 seconds, worf didn't see sisko's message",
    )
    .await?;

    kyra_timeline
        .toggle_reaction(kyra_received.to_string(), "👏".to_string())
        .await?;
    worf_timeline
        .toggle_reaction(worf_received.to_string(), "😎".to_string())
        .await?;

    // msg reaction may reach via set action
    let mut i = 10;
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
    assert!(
        found,
        "Even after 10 seconds, sisko didn't receive msg reaction from kyra and worf"
    );

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
