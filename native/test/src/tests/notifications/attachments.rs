use std::io::Write;

use anyhow::{bail, Result};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use acter::{api::SubscriptionStatus, ActerModel};
use urlencoding::encode;

use crate::utils::random_users_with_random_space_under_template;

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

[objects.acter-website-tasklist]
type = "task-list"
name = "Onboarding list" 

[objects.task_1]
type = "task"
title = "Scroll news"
assignees = ["{{ main.user_id }}"]
"m.relates_to" = { event_id = "{{ acter-website-tasklist.id }}" } 
utc_due = "{{ now().as_rfc3339 }}"

"#;

#[ignore]
#[tokio::test]
async fn image_attachment_on_pin() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("aOnpin", 2, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = second_user.clone();
    let obj_entry = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            let entries = client.pins().await?;
            if entries.is_empty() {
                bail!("entries not found");
            }
            Ok(entries[0].clone())
        }
    })
    .await?;

    // ensure we are expected to see these notifications
    let notif_settings = first.notification_settings().await?;
    let obj_id = obj_entry.event_id().to_string();

    notif_settings
        .subscribe_object_push(obj_id.clone(), None)
        .await
        .expect("setting notifications subscription works");
    // ensure this has been locally synced
    let fetcher_client = notif_settings.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        let obj_id = obj_id.clone();
        async move {
            if client.object_push_subscription_status(obj_id, None).await?
                != SubscriptionStatus::Subscribed
            {
                bail!("not yet subscribed");
            }
            Ok(())
        }
    })
    .await?;

    let manager = obj_entry.attachments().await?;

    let bytes = include_bytes!("../fixtures/PNG_transparency_demonstration_1.png");
    let mut png_file = tempfile::Builder::new()
        .prefix("Fishy")
        .suffix(".png")
        .tempfile()?;
    png_file.as_file_mut().write_all(bytes)?;

    let base_draft = first.file_draft(
        png_file.path().to_string_lossy().to_string(),
        "image/png".to_string(),
    );
    let notification_id = manager
        .content_draft(Box::new(base_draft))
        .await?
        .send()
        .await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_id.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "attachment");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in attachment"),
        obj_entry.event_id().to_string()
    );

    let obj_id = obj_entry.event_id().to_string();

    notification_item.body().expect("found content");
    assert_eq!(notification_item.title(), "🖼️ \"Fishy.png\"");
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!(
            "/pins/{}?section=attachments&attachmentId={}",
            obj_id,
            encode(notification_id.as_str())
        )
    );
    assert_eq!(parent.object_type_str(), "pin".to_owned());
    assert_eq!(parent.title().unwrap(), "Acter Website".to_owned());
    assert_eq!(parent.emoji(), "📌"); // pin
    assert_eq!(parent.object_id_str(), obj_id);

    Ok(())
}

#[ignore]
#[tokio::test]
async fn file_attachment_on_event() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("aOevent", 2, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = second_user.clone();
    let obj_entry = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            let entries = client.calendar_events().await?;
            if entries.is_empty() {
                bail!("entries not found");
            }
            Ok(entries[0].clone())
        }
    })
    .await?;

    // ensure we are expected to see these notifications
    let notif_settings = first.notification_settings().await?;
    let obj_id = obj_entry.event_id().to_string();

    notif_settings
        .subscribe_object_push(obj_id.clone(), None)
        .await
        .expect("setting notifications subscription works");
    // ensure this has been locally synced
    let fetcher_client = notif_settings.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        let obj_id = obj_id.clone();
        async move {
            if client.object_push_subscription_status(obj_id, None).await?
                != SubscriptionStatus::Subscribed
            {
                bail!("not yet subscribed");
            }
            Ok(())
        }
    })
    .await?;

    let manager = obj_entry.attachments().await?;

    let bytes = include_bytes!("../fixtures/PNG_transparency_demonstration_1.png");
    let mut png_file = tempfile::Builder::new()
        .prefix("Fishy")
        .suffix(".doc")
        .tempfile()?;
    png_file.as_file_mut().write_all(bytes)?;

    let base_draft = first.file_draft(
        png_file.path().to_string_lossy().to_string(),
        "document/x-src".to_string(),
    );
    let notification_id = manager
        .content_draft(Box::new(base_draft))
        .await?
        .send()
        .await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_id.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "attachment");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in attachment"),
        obj_entry.event_id().to_string()
    );

    let obj_id = obj_entry.event_id().to_string();

    notification_item.body().expect("found content");
    assert_eq!(notification_item.title(), "📄 \"Fishy.doc\"");
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!(
            "/events/{}?section=attachments&attachmentId={}",
            obj_id,
            encode(notification_id.as_str())
        )
    );
    assert_eq!(parent.object_type_str().as_str(), "event");
    assert_eq!(parent.title().unwrap().as_str(), "First meeting");
    assert_eq!(parent.emoji(), "🗓️"); // pin
    assert_eq!(parent.object_id_str(), obj_id);

    Ok(())
}

#[ignore]
#[tokio::test]
async fn video_attachment_on_tasklist() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("aOevent", 2, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = second_user.clone();
    let obj_entry = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            let entries = client.task_lists().await?;
            if entries.is_empty() {
                bail!("entries not found");
            }
            Ok(entries[0].clone())
        }
    })
    .await?;

    // ensure we are expected to see these notifications
    let notif_settings = first.notification_settings().await?;
    let obj_id = obj_entry.event_id().to_string();

    notif_settings
        .subscribe_object_push(obj_id.clone(), None)
        .await
        .expect("setting notifications subscription works");
    // ensure this has been locally synced
    let fetcher_client = notif_settings.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        let obj_id = obj_id.clone();
        async move {
            if client.object_push_subscription_status(obj_id, None).await?
                != SubscriptionStatus::Subscribed
            {
                bail!("not yet subscribed");
            }
            Ok(())
        }
    })
    .await?;

    let manager = obj_entry.attachments().await?;

    let bytes = include_bytes!("../fixtures/PNG_transparency_demonstration_1.png");
    let mut png_file = tempfile::Builder::new()
        .prefix("Fishy")
        .suffix(".mp4")
        .tempfile()?;
    png_file.as_file_mut().write_all(bytes)?;

    let base_draft = first.file_draft(
        png_file.path().to_string_lossy().to_string(),
        "video/mpeg4".to_string(),
    );
    let notification_id = manager
        .content_draft(Box::new(base_draft))
        .await?
        .send()
        .await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_id.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "attachment");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in attachment"),
        obj_entry.event_id().to_string()
    );

    let obj_id = obj_entry.event_id().to_string();

    notification_item.body().expect("found content");
    assert_eq!(notification_item.title(), "🎥 \"Fishy.mpv\"");
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!(
            "/tasks/{}?section=attachments&attachmentId={}",
            obj_id,
            encode(notification_id.as_str())
        )
    );
    assert_eq!(parent.object_type_str().as_str(), "task-list");
    assert_eq!(parent.title().unwrap().as_str(), "Onboarding list");
    assert_eq!(parent.emoji(), "📋"); // task list
    assert_eq!(parent.object_id_str(), obj_id);

    Ok(())
}

#[ignore]
#[tokio::test]
async fn link_attachment_on_task() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("aOevent", 2, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = second_user.clone();
    let obj_entry = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            let entries = client.task_lists().await?;
            if entries.is_empty() {
                bail!("entries not found");
            }
            let tl = entries[0].clone();
            let tasks = tl.tasks().await?;
            if tasks.is_empty() {
                bail!("task not found");
            }
            Ok(tasks.first().unwrap().clone())
        }
    })
    .await?;

    // ensure we are expected to see these notifications
    let notif_settings = first.notification_settings().await?;
    let obj_id = obj_entry.event_id().to_string();

    notif_settings
        .subscribe_object_push(obj_id.clone(), None)
        .await
        .expect("setting notifications subscription works");
    // ensure this has been locally synced
    let fetcher_client = notif_settings.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        let obj_id = obj_id.clone();
        async move {
            if client.object_push_subscription_status(obj_id, None).await?
                != SubscriptionStatus::Subscribed
            {
                bail!("not yet subscribed");
            }
            Ok(())
        }
    })
    .await?;

    let manager = obj_entry.attachments().await?;
    let notification_id = manager
        .link_draft(
            "https://acter.global".to_owned(),
            Some("Acter Website".to_owned()),
        )
        .await?
        .send()
        .await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_id.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "attachment");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in attachment"),
        obj_entry.event_id().to_string()
    );

    let obj_id = obj_entry.event_id().to_string();

    notification_item.body().expect("found content");
    assert_eq!(notification_item.title().as_str(), "🔗 \"Acter Website\"");
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!(
            "/tasks/{}/{}?section=attachments&attachmentId={}",
            obj_entry.task_list_id_str(),
            obj_id,
            encode(notification_id.as_str())
        )
    );
    assert_eq!(parent.object_type_str().as_str(), "task");
    assert_eq!(parent.title().unwrap().as_str(), "Scroll news");
    assert_eq!(parent.emoji(), "✔️"); // task

    Ok(())
}
