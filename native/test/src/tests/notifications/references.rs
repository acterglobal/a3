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
name = "References Notifications Setup Template"

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

[objects.tasklist]
type = "task-list"
name = "Onboarding list" 

[objects.task_1]
type = "task"
title = "Scroll news"
assignees = ["{{ main.user_id }}"]
"m.relates_to" = { event_id = "{{ tasklist.id }}" }
utc_due = "{{ now().as_rfc3339 }}"

"#;

#[tokio::test]
async fn ref_event_on_pin() -> Result<()> {
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

    let fetcher_client = second_user.clone();
    let ref_entry = Retry::spawn(retry_strategy.clone(), move || {
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
    let ref_details = ref_entry.ref_details().await?;

    // ensure we are expected to see these notifications
    let notif_settings = first.notification_settings().await?;
    let obj_id = obj_entry.event_id().to_string();

    notif_settings
        .subscribe_object_push(obj_id.clone(), None)
        .await
        .expect("setting notifications subscription works");
    // ensure this has been locally synced
    let fetcher_client = notif_settings.clone();
    Retry::spawn(retry_strategy, move || {
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
        .reference_draft(Box::new(ref_details))
        .await?
        .send()
        .await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_id.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "references");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in references"),
        *obj_entry.event_id()
    );

    assert_eq!(notification_item.title(), "🗓️ First meeting");
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!(
            "/pins/{}?section=references&referenceId={}",
            obj_entry.event_id(),
            encode(notification_id.as_str())
        )
    );
    assert_eq!(parent.type_str(), "pin");
    assert_eq!(parent.title().as_deref(), Some("Acter Website"));
    assert_eq!(parent.emoji(), "📌"); // pin
    assert_eq!(parent.object_id_str(), *obj_entry.event_id());

    Ok(())
}

#[tokio::test]
async fn reference_pin_on_event() -> Result<()> {
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

    let fetcher_client = second_user.clone();
    let ref_entry = Retry::spawn(retry_strategy.clone(), move || {
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
    let ref_details = ref_entry.ref_details().await?;

    // ensure we are expected to see these notifications
    let notif_settings = first.notification_settings().await?;
    let obj_id = obj_entry.event_id();

    notif_settings
        .subscribe_object_push(obj_id.to_string(), None)
        .await
        .expect("setting notifications subscription works");
    // ensure this has been locally synced
    let fetcher_client = notif_settings.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let obj_id = obj_id.to_string();
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
        .reference_draft(Box::new(ref_details))
        .await?
        .send()
        .await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_id.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "references");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in references"),
        obj_entry.event_id()
    );

    assert_eq!(notification_item.title(), "📌 Acter Website");
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!(
            "/events/{}?section=references&referenceId={}",
            obj_entry.event_id(),
            encode(notification_id.as_str())
        )
    );
    assert_eq!(parent.type_str(), "event");
    assert_eq!(parent.title().as_deref(), Some("First meeting"));
    assert_eq!(parent.emoji(), "🗓️");
    assert_eq!(parent.object_id_str(), *obj_entry.event_id());

    Ok(())
}

#[tokio::test]
async fn reference_pin_on_tasklist() -> Result<()> {
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

    let fetcher_client = second_user.clone();
    let ref_entry = Retry::spawn(retry_strategy.clone(), move || {
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
    let ref_details = ref_entry.ref_details().await?;

    // ensure we are expected to see these notifications
    let notif_settings = first.notification_settings().await?;
    let obj_id = obj_entry.event_id();

    notif_settings
        .subscribe_object_push(obj_id.to_string(), None)
        .await
        .expect("setting notifications subscription works");
    // ensure this has been locally synced
    let fetcher_client = notif_settings.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let obj_id = obj_id.to_string();
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
        .reference_draft(Box::new(ref_details))
        .await?
        .send()
        .await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_id.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "references");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in references"),
        *obj_entry.event_id()
    );

    assert_eq!(notification_item.title(), "📌 Acter Website");
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!(
            "/tasks/{}?section=references&referenceId={}",
            obj_entry.event_id(),
            encode(notification_id.as_str())
        )
    );
    assert_eq!(parent.type_str(), "task-list");
    assert_eq!(parent.title().as_deref(), Some("Onboarding list"));
    assert_eq!(parent.emoji(), "📋"); // task list
    assert_eq!(parent.object_id_str(), *obj_entry.event_id());

    Ok(())
}

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
            let task = tasks.first().expect("first task should be available");
            Ok(task.clone())
        }
    })
    .await?;

    let fetcher_client = second_user.clone();
    let ref_entry = Retry::spawn(retry_strategy.clone(), move || {
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
    let ref_details = ref_entry.ref_details().await?;

    // ensure we are expected to see these notifications
    let notif_settings = first.notification_settings().await?;
    let obj_id = obj_entry.event_id();

    notif_settings
        .subscribe_object_push(obj_id.to_string(), None)
        .await
        .expect("setting notifications subscription works");
    // ensure this has been locally synced
    let fetcher_client = notif_settings.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let obj_id = obj_id.to_string();
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
        .reference_draft(Box::new(ref_details))
        .await?
        .send()
        .await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_id.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "references");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in references"),
        *obj_entry.event_id()
    );

    assert_eq!(notification_item.title(), "📌 Acter Website");
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!(
            "/tasks/{}/{}?section=references&referenceId={}",
            obj_entry.task_list_id_str(),
            obj_entry.event_id(),
            encode(notification_id.as_str())
        )
    );
    assert_eq!(parent.type_str(), "task");
    assert_eq!(parent.title().as_deref(), Some("Scroll news"));
    assert_eq!(parent.emoji(), "☑️"); // task

    Ok(())
}
