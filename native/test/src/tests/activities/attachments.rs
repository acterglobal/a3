use std::io::Write;

use anyhow::{bail, Result};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use acter::ActerModel;
use urlencoding::encode;

use crate::{
    tests::activities::{all_activities_observer, assert_triggered_with_latest_activity},
    utils::random_users_with_random_space_under_template,
};

const TMPL: &str = r#"
version = "0.1"
name = "Attachment Notifications Setup Template"

[inputs]
main = { type = "user", is-default = true, required = true, description = "The starting user" }
space = { type = "space", is-default = true, required = true, description = "The main user" }

[objects.acter-event-1]
type = "calendar-event"
title = "First meeting"
utc_start = "{{ future(add_mins=1).as_rfc3339 }}"
utc_end = "{{ future(add_mins=60).as_rfc3339 }}"

[objects.acter-website-pin]
type = "pin"
title = "Acter Website"
url = "https://acter.global"

"#;

#[tokio::test]
async fn image_attachment_activity_on_pin() -> Result<()> {
    let (users, _sync_states, _space_id, _engine) =
        random_users_with_random_space_under_template("aOnpin", 1, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];
    let mut act_obs = all_activities_observer(first).await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let obj_entry = Retry::spawn(retry_strategy.clone(), || async {
        let entries = second_user.pins().await?;
        if entries.is_empty() {
            bail!("entries not found");
        }
        Ok(entries[0].clone())
    })
    .await?;

    // ensure we are expected to see these activities
    let obj_id = obj_entry.event_id().to_string();

    let manager = obj_entry.attachments().await?;

    let bytes = include_bytes!("../fixtures/PNG_transparency_demonstration_1.png");
    let mut png_file = tempfile::Builder::new()
        .prefix("Fishy")
        .suffix(".png")
        .tempfile()?;
    png_file.as_file_mut().write_all(bytes)?;

    let base_draft = first
        .image_draft(
            png_file.path().to_string_lossy().to_string(),
            "image/png".to_owned(),
        )
        .filename("Fishy.png".to_owned())
        .clone(); // switch variable from temporary to normal so that content_draft can use it
    let activity_id = manager
        .content_draft(Box::new(base_draft))
        .await?
        .send()
        .await?;

    let activity = Retry::spawn(retry_strategy, || async {
        first.activity(activity_id.to_string()).await
    })
    .await?;
    assert_eq!(activity.type_str(), "attachment");
    assert_eq!(activity.sub_type_str().as_deref(), Some("image"));
    assert_eq!(activity.name().as_deref(), Some("Fishy.png"));
    let parent = activity.object().expect("parent was found");
    assert_eq!(
        activity.target_url(),
        format!(
            "/pins/{}?section=attachments&attachmentId={}",
            obj_id,
            encode(activity_id.as_str())
        )
    );
    assert_eq!(parent.type_str(), "pin");
    assert_eq!(parent.title().as_deref(), Some("Acter Website"));
    assert_eq!(parent.emoji(), "📌"); // pin
    assert_eq!(parent.object_id_str(), obj_id);

    assert_triggered_with_latest_activity(&mut act_obs, activity.event_id_str()).await?;

    Ok(())
}

#[tokio::test]
async fn file_attachment_activity_on_calendar() -> Result<()> {
    let (users, _sync_states, _space_id, _engine) =
        random_users_with_random_space_under_template("aOncal", 1, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let obj_entry = Retry::spawn(retry_strategy.clone(), || async {
        let entries = second_user.calendar_events().await?;
        if entries.is_empty() {
            bail!("entries not found");
        }
        Ok(entries[0].clone())
    })
    .await?;

    let mut act_obs = all_activities_observer(first).await?;
    // ensure we are expected to see these activities
    let obj_id = obj_entry.event_id().to_string();

    let manager = obj_entry.attachments().await?;

    let bytes = include_bytes!("../fixtures/PNG_transparency_demonstration_1.png");
    let mut png_file = tempfile::Builder::new()
        .prefix("Fishy")
        .suffix(".png")
        .tempfile()?;
    png_file.as_file_mut().write_all(bytes)?;

    let base_draft = first
        .file_draft(
            png_file.path().to_string_lossy().to_string(),
            "image/png".to_owned(),
        )
        .filename("Fishy.png".to_owned())
        .clone(); // switch variable from temporary to normal so that content_draft can use it
    let activity_id = manager
        .content_draft(Box::new(base_draft))
        .await?
        .send()
        .await?;

    let activity = Retry::spawn(retry_strategy, || async {
        first.activity(activity_id.to_string()).await
    })
    .await?;
    assert_eq!(activity.type_str(), "attachment");
    assert_eq!(activity.sub_type_str().as_deref(), Some("file"));
    assert_eq!(activity.name().as_deref(), Some("Fishy.png"));
    let parent = activity.object().expect("parent was found");
    assert_eq!(
        activity.target_url(),
        format!(
            "/events/{}?section=attachments&attachmentId={}",
            obj_id,
            encode(activity_id.as_str())
        )
    );
    assert_eq!(parent.type_str(), "event");
    assert_eq!(parent.title().as_deref(), Some("First meeting"));
    assert_eq!(parent.emoji(), "🗓️"); // calendar
    assert_eq!(parent.object_id_str(), obj_id);

    assert_triggered_with_latest_activity(&mut act_obs, activity_id.to_string()).await?;

    Ok(())
}

#[tokio::test]
async fn reference_attachment_activity_on_calendar() -> Result<()> {
    let (users, _sync_states, _space_id, _engine) =
        random_users_with_random_space_under_template("aOncal", 1, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let pin = Retry::spawn(retry_strategy.clone(), || async {
        let entries = second_user.pins().await?;
        if entries.is_empty() {
            bail!("entries not found");
        }
        Ok(entries[0].clone())
    })
    .await?;

    let mut act_obs = all_activities_observer(first).await?;
    let ref_details = pin.ref_details().await?;

    let obj_entry = Retry::spawn(retry_strategy.clone(), || async {
        let entries = second_user.calendar_events().await?;
        if entries.is_empty() {
            bail!("entries not found");
        }
        Ok(entries[0].clone())
    })
    .await?;

    // ensure we are expected to see these activities
    let obj_id = obj_entry.event_id().to_string();

    let manager = obj_entry.attachments().await?;
    let activity_id = manager
        .reference_draft(Box::new(ref_details))
        .await?
        .send()
        .await?;

    let activity = Retry::spawn(retry_strategy, || async {
        first.activity(activity_id.to_string()).await
    })
    .await?;
    assert_eq!(activity.type_str(), "references");
    // check the ref details
    let ref_details = activity.ref_details().expect("ref details were found");
    assert_eq!(ref_details.title().as_deref(), Some("Acter Website"));
    assert_eq!(
        ref_details.target_id_str(),
        Some(pin.event_id().to_string())
    );

    // check the parent
    let parent = activity.object().expect("parent was found");
    assert_eq!(
        activity.target_url(),
        format!(
            "/events/{}?section=references&referenceId={}",
            obj_id,
            encode(activity_id.as_str())
        )
    );

    assert_eq!(parent.type_str(), "event");
    assert_eq!(parent.title().as_deref(), Some("First meeting"));
    assert_eq!(parent.emoji(), "🗓️"); // calendar
    assert_eq!(parent.object_id_str(), obj_id);

    assert_triggered_with_latest_activity(&mut act_obs, activity_id.to_string()).await?;

    Ok(())
}
