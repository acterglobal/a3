use acter::api::{TimelineItem, TimelineItemDiff};
use anyhow::{bail, Result};
use core::time::Duration;
use futures::{pin_mut, stream::StreamExt, FutureExt, Stream};
use tokio::time::sleep;
use tracing::{info, warn};

use crate::utils::{
    accept_all_invites, match_msg_reaction, match_text_msg, random_users_with_random_convo,
    wait_for_convo_joined,
};

type MessageMatchesTest = dyn Fn(&TimelineItem) -> bool;

async fn wait_for_message(
    stream: impl Stream<Item = TimelineItemDiff>,
    match_test: &MessageMatchesTest,
    error: &'static str,
) -> Result<(String, String)> {
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
                        return Ok((
                            value
                                .event_item()
                                .expect("has item")
                                .event_id()
                                .expect("has id"),
                            value.unique_id(),
                        ));
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action must have valid values");
                    for value in values.iter() {
                        info!("diff reset msg: {:?}", value);
                        if match_test(value) {
                            return Ok((
                                value
                                    .event_item()
                                    .expect("has item")
                                    .event_id()
                                    .expect("has id"),
                                value.unique_id(),
                            ));
                        }
                    }
                }
                _ => {
                    warn!(
                        "Weirdly we’ve seen another event: {}",
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
    let (users, room_id) = random_users_with_random_convo("reaction", 2).await?;
    let mut sisko = users[0].clone();
    let mut kyra = users[1].clone();
    let mut worf = users[2].clone();

    let sisko_sync = sisko.start_sync().await?;
    sisko_sync.await_has_synced_history().await?;

    let sisko_convo = wait_for_convo_joined(sisko.clone(), room_id.clone()).await?;
    let sisko_timeline = sisko_convo.timeline_stream().await?;
    let sisko_stream = sisko_timeline.messages_stream();
    pin_mut!(sisko_stream);

    let kyra_sync = kyra.start_sync().await?;
    kyra_sync.await_has_synced_history().await?;
    accept_all_invites(&kyra).await?;

    let kyra_convo = wait_for_convo_joined(kyra.clone(), room_id.clone()).await?;
    let kyra_timeline = kyra_convo.timeline_stream().await?;
    let kyra_stream = kyra_timeline.messages_stream();

    let worf_sync = worf.start_sync().await?;
    worf_sync.await_has_synced_history().await?;
    accept_all_invites(&worf).await?;
    // wait for sync to catch up
    let worf_convo = wait_for_convo_joined(worf.clone(), room_id.clone()).await?;
    let worf_timeline = worf_convo.timeline_stream().await?;
    let worf_stream = worf_timeline.messages_stream();

    let body = "Hi, everyone";
    let draft = sisko.text_plain_draft(body.to_owned());
    sisko_timeline.send_message(Box::new(draft)).await?;

    let (kyra_received, kyra_unique_id) = wait_for_message(
        kyra_stream,
        &|m| match_text_msg(m, body, false).is_some(),
        "even after 30 seconds, kyra didn’t see sisko’s message",
    )
    .await?;

    // FIXME: for some unknown reason worf only receives an encrypted message
    //        they can’t decrypt. Doesn’t really matter for the tests itself,
    //        but it’s still bad. so this test takes kyras event_id and matches
    //        it against the stream to find the item to react to.

    let check_id = kyra_received.clone();

    let (_worf_received, worf_unique_id) = wait_for_message(
        worf_stream,
        &move |m| {
            m.event_item()
                .and_then(|e| e.event_id())
                .map(|s| s == check_id)
                .unwrap_or_default()
        },
        "even after 30 seconds, worf didn’t see sisko’s message",
    )
    .await?;

    info!("toggling kyra");
    kyra_timeline
        .toggle_reaction(kyra_unique_id, "👏".to_owned())
        .await?;
    info!("toggling worf");
    worf_timeline
        .toggle_reaction(worf_unique_id, "😎".to_owned())
        .await?;
    info!("after toggle");

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
                if match_msg_reaction(&value, body, "👏".to_owned())
                    && match_msg_reaction(&value, body, "😎".to_owned())
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
        "Even after 10 seconds, sisko didn’t receive msg reaction from kyra and worf"
    );

    Ok(())
}
