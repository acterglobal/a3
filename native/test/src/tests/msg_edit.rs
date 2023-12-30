use acter::{api::RoomMessage, ruma_common::OwnedEventId};
use anyhow::{Context, Result};
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

    let draft = user.text_plain_draft("Hi, everyone".to_string());
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

    let draft = user.text_plain_draft("This is message edition".to_string());
    timeline
        .edit_message(sent_event_id.to_string(), Box::new(draft))
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
                if let Some(event_id) = match_text_msg(&value, "This is message edition", true) {
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
    let edited_event_id =
        edited_event_id.context("Even after 3 seconds, msg edition not received")?;

    assert_eq!(
        edited_event_id,
        sent_event_id,
        "edited id should be same as sent id, because stream will replace old msg with new msg in timeline"
    );

    Ok(())
}

fn match_text_msg(msg: &RoomMessage, body: &str, modified: bool) -> Option<OwnedEventId> {
    info!("match room msg - {:?}", msg.clone());
    if msg.item_type() == "event" {
        let event_item = msg.event_item().expect("room msg should have event item");
        if let Some(msg_content) = event_item.msg_content() {
            if msg_content.body() == body && event_item.was_edited() == modified {
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
    let jpg_name = tmp_jpg // it is randomly generated by system and not kingfisher.jpg
        .path()
        .file_name()
        .expect("it is not file")
        .to_string_lossy()
        .to_string();

    let draft = user.image_draft(
        tmp_jpg.path().to_string_lossy().to_string(),
        "image/jpeg".to_string(),
    );
    timeline.send_message(Box::new(draft)).await?;

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
                    if let Some((event_id, body)) = match_image_msg(&value, "image/jpeg", false) {
                        assert_eq!(body, jpg_name, "msg body should be filename");
                        sent_event_id = Some(event_id);
                    }
                }
                "Reset" => {
                    let values = diff
                        .values()
                        .expect("diff reset action should have valid values");
                    for value in values.iter() {
                        if let Some((event_id, body)) = match_image_msg(value, "image/jpeg", false)
                        {
                            assert_eq!(body, jpg_name, "msg body should be filename");
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
    let sent_event_id = sent_event_id.context("Even after 3 seconds, text msg not received")?;

    let mut tmp_png = NamedTempFile::new()?;
    tmp_png.as_file_mut().write_all(include_bytes!(
        "./fixtures/PNG_transparency_demonstration_1.png"
    ))?;
    let png_name = tmp_png // it is randomly generated by system and not PNG_transparency_demonstration_1.png
        .path()
        .file_name()
        .expect("it is not file")
        .to_string_lossy()
        .to_string();

    let draft = user.image_draft(
        tmp_png.path().to_string_lossy().to_string(),
        "image/png".to_string(),
    );
    timeline
        .edit_message(sent_event_id.to_string(), Box::new(draft))
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
                if let Some((event_id, body)) = match_image_msg(&value, "image/png", true) {
                    assert_eq!(body, png_name, "msg body should be filename");
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
    let edited_event_id =
        edited_event_id.context("Even after 3 seconds, msg edition not received")?;

    assert_eq!(
        edited_event_id,
        sent_event_id,
        "edited id should be same as sent id, because stream will replace old msg with new msg in timeline"
    );

    Ok(())
}

fn match_image_msg(
    msg: &RoomMessage,
    content_type: &str,
    modified: bool,
) -> Option<(OwnedEventId, String)> {
    if msg.item_type() == "event" {
        let event_item = msg.event_item().expect("room msg should have event item");
        if let Some(msg_content) = event_item.msg_content() {
            if event_item.was_edited() == modified {
                if let Some(mimetype) = msg_content.mimetype() {
                    if mimetype == content_type {
                        // exclude the pending msg
                        if let Some(evt_id) = event_item.evt_id() {
                            return Some((evt_id, msg_content.body()));
                        }
                    }
                }
            }
        }
    }
    None
}
