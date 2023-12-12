use acter::{api::RoomMessage, ruma_common::OwnedEventId};
use anyhow::{bail, Result};
use core::time::Duration;
use futures::{pin_mut, stream::StreamExt, FutureExt};
use std::io::Write;
use tempfile::NamedTempFile;
use tokio::time::sleep;
use tracing::info;

use crate::utils::random_user_with_random_convo;

#[tokio::test]
async fn edit_text_msg() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("edit_text_msg").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    let convo = user.convo(room_id.to_string()).await?;
    let timeline = convo.timeline_stream().await?;
    let stream = timeline.diff_stream();
    pin_mut!(stream);

    timeline
        .send_plain_message("Hi, everyone".to_string())
        .await?;

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
                        if let Some(event_id) = match_room_msg(value, "Hi, everyone", false) {
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
                    if let Some(event_id) = match_room_msg(&value, "Hi, everyone", false) {
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
    let Some(sent_event_id) = sent_event_id else {
        bail!("Even after 30 seconds, text msg not received")
    };

    timeline
        .edit_plain_message(
            sent_event_id.to_string(),
            "This is message edition".to_string(),
        )
        .await?;

    // msg edition may reach via set action
    i = 3;
    let mut edited_event_id = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            if diff.action() == "Set" {
                let value = diff
                    .value()
                    .expect("diff set action should have valid value");
                if let Some(event_id) = match_room_msg(&value, "This is message edition", true) {
                    edited_event_id = Some(event_id);
                }
            }
            // yay
            if edited_event_id.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    let Some(edited_event_id) = edited_event_id else {
        bail!("Even after 3 seconds, msg edition not received")
    };

    assert_eq!(
        edited_event_id,
        sent_event_id,
        "edited id should be same as sent id, because stream will replace old msg with new msg in timeline"
    );

    Ok(())
}

fn match_room_msg(msg: &RoomMessage, body: &str, modified: bool) -> Option<OwnedEventId> {
    info!("match room msg - {:?}", msg.clone());
    if msg.item_type() == "event" {
        let event_item = msg.event_item().expect("room msg should have event item");
        if let Some(text_desc) = event_item.text_desc() {
            if text_desc.body() == body {
                assert_eq!(event_item.was_edited(), modified);
                // exclude the pending msg
                if let Some(event_id) = event_item.evt_id() {
                    return Some(event_id);
                }
            }
        }
    }
    None
}

#[tokio::test]
async fn edit_image_msg() -> Result<()> {
    let _ = env_logger::try_init();

    let (mut user, room_id) = random_user_with_random_convo("edit_image_msg").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    let convo = user.convo(room_id.to_string()).await?;
    let timeline = convo.timeline_stream().await?;
    let stream = timeline.diff_stream();
    pin_mut!(stream);

    let mut tmp_jpg = NamedTempFile::new()?;
    tmp_jpg
        .as_file_mut()
        .write_all(include_bytes!("./fixtures/kingfisher.jpg"))?;

    timeline
        .send_image_message(
            tmp_jpg.path().to_string_lossy().to_string(),
            "jpg_file".to_string(),
            "image/jpeg".to_string(),
            None,
            None,
            None,
            None,
        )
        .await?;

    // text msg may reach via pushback action or reset action
    let mut i = 3;
    let mut sent_event_id = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            match diff.action().as_str() {
                "PushBack" => {
                    let value = diff
                        .value()
                        .expect("diff pushback action should have valid value");
                    if let Some(event_id) = match_image_msg(&value, "image/jpeg", false) {
                        sent_event_id = Some(event_id);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some(event_id) = match_image_msg(value, "image/jpeg", false) {
                            sent_event_id = Some(event_id);
                            break;
                        }
                    }
                }
                _ => {}
            }
            // yay
            if sent_event_id.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    let Some(sent_event_id) = sent_event_id else {
        bail!("Even after 3 seconds, text msg not received")
    };

    let mut tmp_png = NamedTempFile::new()?;
    tmp_png.as_file_mut().write_all(include_bytes!(
        "./fixtures/PNG_transparency_demonstration_1.png"
    ))?;

    timeline
        .edit_image_message(
            sent_event_id.to_string(),
            tmp_png.path().to_string_lossy().to_string(),
            "png_file".to_string(),
            "image/png".to_string(),
            None,
            None,
            None,
        )
        .await?;

    // msg edition may reach via set action
    i = 3;
    let mut edited_event_id = None;
    while i > 0 {
        if let Some(diff) = stream.next().now_or_never().flatten() {
            if diff.action() == "Set" {
                let value = diff
                    .value()
                    .expect("diff set action should have valid value");
                if let Some(event_id) = match_image_msg(&value, "image/png", true) {
                    edited_event_id = Some(event_id);
                }
            }
            // yay
            if edited_event_id.is_some() {
                break;
            }
        }
        i -= 1;
        sleep(Duration::from_secs(1)).await;
    }
    let Some(edited_event_id) = edited_event_id else {
        bail!("Even after 3 seconds, msg edition not received")
    };

    assert_eq!(
        edited_event_id,
        sent_event_id,
        "edited id should be same as sent id, because stream will replace old msg with new msg in timeline"
    );

    Ok(())
}

fn match_image_msg(msg: &RoomMessage, content_type: &str, modified: bool) -> Option<OwnedEventId> {
    if msg.item_type() == "event" {
        let event_item = msg.event_item().expect("room msg should have event item");
        if let Some(image_desc) = event_item.image_desc() {
            assert_eq!(event_item.was_edited(), modified);
            if let Some(mimetype) = image_desc.mimetype() {
                assert_eq!(mimetype, content_type);
            }
            // exclude the pending msg
            if let Some(evt_id) = event_item.evt_id() {
                return Some(evt_id);
            }
        }
    }
    None
}
