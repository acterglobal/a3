use acter::ActerModel;
use anyhow::{bail, Result};
use chrono::{DateTime, NaiveDate, Utc};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::{random_users_with_random_space, random_users_with_random_space_under_template};

const TMPL: &str = r#"
version = "0.1"
name = "Task Notifications Setup Template"

[inputs]
main = { type = "user", is-default = true, required = true, description = "The starting user" }
space = { type = "space", is-default = true, required = true, description = "The main user" }

[objects.start_list]
type = "task-list"
name = "Onboarding list"

[objects.task_1]
type = "task"
title = "Scroll through the updates"
"m.relates_to" = { event_id = "{{ start_list.id }}" }
utc_due = "{{ now().as_rfc3339 }}"
"#;

#[tokio::test]
async fn tasklist_creation_notification() -> Result<()> {
    let _ = env_logger::try_init();
    let (users, room_id) = random_users_with_random_space("tl_creation_notifications", 1).await?;

    let mut user = users[0].clone();
    let mut second = users[1].clone();

    second.install_default_acter_push_rules().await?;

    let sync_state1 = user.start_sync();
    sync_state1.await_has_synced_history().await?;

    let sync_state2 = second.start_sync();
    sync_state2.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let main_space = Retry::spawn(retry_strategy, || async {
        let spaces = user.spaces().await?;
        if spaces.len() != 1 {
            bail!("space not found");
        }
        Ok(spaces.first().cloned().expect("space found"))
    })
    .await?;

    let space_on_second = second.room(main_space.room_id_str()).await?;
    space_on_second
        .set_notification_mode(Some("all".to_owned()))
        .await?; // we want to see push for everything;

    let title = "Babies first task list";
    let event_id = main_space
        .task_list_draft()?
        .name(title.to_owned())
        .send()
        .await?;
    tracing::trace!("draft sent event id: {}", event_id);

    let notifications = second
        .get_notification_item(room_id.to_string(), event_id.to_string())
        .await?;

    assert_eq!(notifications.push_style(), "creation");
    assert_eq!(notifications.target_url(), format!("/tasks/{event_id}"));
    let parent = notifications.parent().expect("parent should be available");
    assert_eq!(parent.type_str(), "task-list");
    assert_eq!(parent.title().as_deref(), Some(title));
    assert_eq!(parent.emoji(), "📋"); // task list icon
    assert_eq!(parent.object_id_str(), event_id);

    Ok(())
}

#[tokio::test]
async fn tasklist_title_update() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("eventTitleUpdate", 1, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let obj_entry = Retry::spawn(retry_strategy, || async {
        let entries = second_user.task_lists().await?;
        if entries.is_empty() {
            bail!("entries not found");
        }
        Ok(entries[0].clone())
    })
    .await?;

    // we want to see push for everything;
    first
        .room(obj_entry.room_id().to_string())
        .await?
        .set_notification_mode(Some("all".to_owned()))
        .await?;

    let title = "Renamed Tasklist";
    let notification_ev = obj_entry
        .update_builder()?
        .name(title.to_owned())
        .send()
        .await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "titleChange");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in change"),
        obj_entry.event_id_str(),
    );

    let obj_id = obj_entry.event_id_str();

    assert_eq!(notification_item.title(), title); // old title
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!("/tasks/{}", obj_id,)
    );
    assert_eq!(parent.type_str(), "task-list");
    // assert_eq!(parent.title().as_deref(), Some("Renamed Tasklist"));
    assert_eq!(parent.emoji(), "📋"); // task list icon
    assert_eq!(parent.object_id_str(), obj_id);

    Ok(())
}

#[tokio::test]
async fn tasklist_desc_update() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("tasklistDescUpdate", 1, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let obj_entry = Retry::spawn(retry_strategy, || async {
        let entries = second_user.task_lists().await?;
        if entries.is_empty() {
            bail!("entries not found");
        }
        Ok(entries[0].clone())
    })
    .await?;

    // we want to see push for everything;
    first
        .room(obj_entry.room_id().to_string())
        .await?
        .set_notification_mode(Some("all".to_owned()))
        .await?;

    let body = "Added description";
    let notification_ev = obj_entry
        .update_builder()?
        .description_text(body.to_owned())
        .send()
        .await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "descriptionChange");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in event"),
        obj_entry.event_id_str(),
    );

    let obj_id = obj_entry.event_id_str();

    let content = notification_item.body().expect("found content");
    assert_eq!(content.body(), body); // new description
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!("/tasks/{}", obj_id,)
    );
    assert_eq!(parent.type_str(), "task-list");
    assert_eq!(parent.title().as_deref(), Some("Onboarding list"));
    assert_eq!(parent.emoji(), "📋"); // task list icon
    assert_eq!(parent.object_id_str(), obj_id);

    Ok(())
}

#[ignore]
#[tokio::test]
async fn tasklist_redaction() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("tasklistRedaction", 1, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let event = Retry::spawn(retry_strategy, || async {
        let entries = first.task_lists().await?;
        if entries.is_empty() {
            bail!("entries not found");
        }
        Ok(entries[0].clone())
    })
    .await?;

    // we want to see push for everything;
    second_user
        .room(event.room_id().to_string())
        .await?
        .set_notification_mode(Some("all".to_owned()))
        .await?;

    let obj_id = event.event_id_str();
    let space = first.space(event.room_id().to_string()).await?;
    let notification_ev = space.redact(event.event_id(), None, None).await?.event_id;

    let notification_item = second_user
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "redaction");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in redaction"),
        obj_id,
    );

    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(notification_item.target_url(), format!("/tasks/"));
    assert_eq!(parent.type_str(), "task-list");
    assert_eq!(parent.title().as_deref(), Some("Onboarding list"));
    assert_eq!(parent.emoji(), "📋"); // task list icon
    assert_eq!(parent.object_id_str(), obj_id);

    Ok(())
}

#[tokio::test]
async fn task_created() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("taskCreated", 1, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let obj_entry = Retry::spawn(retry_strategy, || async {
        let entries = second_user.task_lists().await?;
        if entries.is_empty() {
            bail!("entries not found");
        }
        Ok(entries[0].clone())
    })
    .await?;

    // we want to see push for everything;
    first
        .room(obj_entry.room_id().to_string())
        .await?
        .set_notification_mode(Some("all".to_owned()))
        .await?;

    let title = "Baby's first task";
    let notification_ev = obj_entry
        .task_builder()?
        .due_date(2025, 11, 13)
        .title(title.to_owned())
        .send()
        .await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "taskAdd");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in change"),
        obj_entry.event_id_str(),
    );

    let obj_id = obj_entry.event_id_str();

    assert_eq!(notification_item.title(), title); // old title
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!("/tasks/{}/{}", obj_id, notification_ev)
    );
    assert_eq!(parent.type_str(), "task-list");
    assert_eq!(parent.title().as_deref(), Some("Onboarding list"));
    assert_eq!(parent.emoji(), "📋"); // task list icon
    assert_eq!(parent.object_id_str(), obj_id);

    Ok(())
}

#[tokio::test]
async fn task_title_update() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("taskTitleUpdate", 1, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let (tl_id, obj_entry) = Retry::spawn(retry_strategy, || async {
        let entries = second_user.task_lists().await?;
        if entries.is_empty() {
            bail!("entries not found");
        }
        let tasks = entries[0].tasks().await?;
        let Some(task) = tasks.first() else {
            bail!("task not found");
        };
        Ok((entries[0].event_id_str(), task.clone()))
    })
    .await?;

    // we want to see push for everything;
    first
        .room(obj_entry.room_id().to_string())
        .await?
        .set_notification_mode(Some("all".to_owned()))
        .await?;

    let title = "Renamed Task";
    let notification_ev = obj_entry
        .update_builder()?
        .title(title.to_owned())
        .send()
        .await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "titleChange");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in change"),
        obj_entry.event_id_str(),
    );

    let obj_id = obj_entry.event_id_str();

    assert_eq!(notification_item.title(), title); // old title
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!("/tasks/{tl_id}/{obj_id}")
    );
    assert_eq!(parent.type_str(), "task");
    // assert_eq!(parent.title().as_deref(), Some("Onboarding List"));
    assert_eq!(parent.emoji(), "☑️"); // task icon
    assert_eq!(parent.object_id_str(), obj_id);

    Ok(())
}

#[tokio::test]
async fn task_desc_update() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("taskDescUpdate", 1, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let (tl_id, obj_entry) = Retry::spawn(retry_strategy, || async {
        let entries = second_user.task_lists().await?;
        if entries.is_empty() {
            bail!("entries not found");
        }
        let tasks = entries[0].tasks().await?;
        let Some(task) = tasks.first() else {
            bail!("task not found");
        };
        Ok((entries[0].event_id_str(), task.clone()))
    })
    .await?;

    // we want to see push for everything;
    first
        .room(obj_entry.room_id().to_string())
        .await?
        .set_notification_mode(Some("all".to_owned()))
        .await?;

    let body = "Task is complicated";
    let notification_ev = obj_entry
        .update_builder()?
        .description_text(body.to_owned())
        .send()
        .await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "descriptionChange");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in change"),
        obj_entry.event_id_str()
    );

    let obj_id = obj_entry.event_id_str();

    let content = notification_item.body().expect("found content");
    assert_eq!(content.body(), body); // new description
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!("/tasks/{tl_id}/{obj_id}")
    );
    assert_eq!(parent.type_str(), "task");
    assert_eq!(
        parent.title().as_deref(),
        Some("Scroll through the updates")
    );
    assert_eq!(parent.emoji(), "☑️"); // task icon
    assert_eq!(parent.object_id_str(), obj_id);

    Ok(())
}

#[tokio::test]
async fn task_due_update() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("tasDueUpdate", 1, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let (tl_id, obj_entry) = Retry::spawn(retry_strategy, || async {
        let entries = second_user.task_lists().await?;
        if entries.is_empty() {
            bail!("entries not found");
        }
        let tasks = entries[0].tasks().await?;
        let Some(task) = tasks.first() else {
            bail!("task not found");
        };
        Ok((entries[0].event_id_str(), task.clone()))
    })
    .await?;

    // we want to see push for everything;
    first
        .room(obj_entry.room_id().to_string())
        .await?
        .set_notification_mode(Some("all".to_owned()))
        .await?;

    let notification_ev = obj_entry
        .update_builder()?
        .due_date(2026, 1, 1)
        .send()
        .await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "taskDueDateChange");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in change"),
        obj_entry.event_id_str(),
    );

    let obj_id = obj_entry.event_id_str();

    let naive_date = NaiveDate::from_ymd_opt(2026, 1, 1)
        .and_then(|d| d.and_hms_opt(0, 0, 0))
        .expect("naive date should be available");
    let utc_date = DateTime::<Utc>::from_naive_utc_and_offset(naive_date, Utc);
    assert_eq!(notification_item.new_date(), Some(utc_date));
    assert_eq!(notification_item.title(), "2026-01-01");
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!("/tasks/{tl_id}/{obj_id}")
    );
    assert_eq!(parent.type_str(), "task");
    assert_eq!(
        parent.title().as_deref(),
        Some("Scroll through the updates")
    );
    assert_eq!(parent.emoji(), "☑️"); // task icon
    assert_eq!(parent.object_id_str(), obj_id);

    Ok(())
}

#[tokio::test]
async fn task_done_and_undone() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("taskDoneUpdate", 1, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let (tl_id, obj_entry) = Retry::spawn(retry_strategy, || async {
        let entries = second_user.task_lists().await?;
        if entries.is_empty() {
            bail!("entries not found");
        }
        let tasks = entries[0].tasks().await?;
        let Some(task) = tasks.first() else {
            bail!("task not found");
        };
        Ok((entries[0].event_id_str(), task.clone()))
    })
    .await?;

    // we want to see push for everything;
    first
        .room(obj_entry.room_id().to_string())
        .await?
        .set_notification_mode(Some("all".to_owned()))
        .await?;

    let notification_ev = obj_entry.update_builder()?.mark_done().send().await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "taskComplete");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in change"),
        obj_entry.event_id_str(),
    );

    let obj_id = obj_entry.event_id_str();

    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!("/tasks/{tl_id}/{obj_id}")
    );
    assert_eq!(parent.type_str(), "task");
    assert_eq!(
        parent.title().as_deref(),
        Some("Scroll through the updates")
    );
    assert_eq!(parent.emoji(), "☑️"); // task icon
    assert_eq!(parent.object_id_str(), obj_id);

    // and undone

    let notification_ev = obj_entry.update_builder()?.mark_undone().send().await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "taskReOpen");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in change"),
        obj_entry.event_id_str(),
    );

    let obj_id = obj_entry.event_id_str();

    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!("/tasks/{tl_id}/{obj_id}")
    );
    assert_eq!(parent.type_str(), "task");
    assert_eq!(
        parent.title().as_deref(),
        Some("Scroll through the updates")
    );
    assert_eq!(parent.emoji(), "☑️"); // task icon
    assert_eq!(parent.object_id_str(), obj_id);

    Ok(())
}

#[tokio::test]
async fn task_self_assign_and_unassign() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("taskDoneUpdate", 1, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let (tl_id, obj_entry) = Retry::spawn(retry_strategy, || async {
        let entries = second_user.task_lists().await?;
        if entries.is_empty() {
            bail!("entries not found");
        }
        let tasks = entries[0].tasks().await?;
        let Some(task) = tasks.first() else {
            bail!("task not found");
        };
        Ok((entries[0].event_id_str(), task.clone()))
    })
    .await?;

    // we want to see push for everything;
    first
        .room(obj_entry.room_id().to_string())
        .await?
        .set_notification_mode(Some("all".to_owned()))
        .await?;

    let notification_ev = obj_entry.assign_self().await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "taskAccept");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in change"),
        obj_entry.event_id_str(),
    );

    let obj_id = obj_entry.event_id_str();

    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!("/tasks/{tl_id}/{obj_id}")
    );
    assert_eq!(parent.type_str(), "task");
    assert_eq!(
        parent.title().as_deref(),
        Some("Scroll through the updates")
    );
    assert_eq!(parent.emoji(), "☑️"); // task icon
    assert_eq!(parent.object_id_str(), obj_id);

    // and unassign
    let notification_ev = obj_entry.unassign_self().await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "taskDecline");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in change"),
        obj_entry.event_id_str(),
    );

    let obj_id = obj_entry.event_id_str();

    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!("/tasks/{tl_id}/{obj_id}")
    );
    assert_eq!(parent.type_str(), "task");
    assert_eq!(
        parent.title().as_deref(),
        Some("Scroll through the updates")
    );
    assert_eq!(parent.emoji(), "☑️"); // task icon
    assert_eq!(parent.object_id_str(), obj_id);

    Ok(())
}
