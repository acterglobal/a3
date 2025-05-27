use anyhow::{bail, Result};
use chrono::{Datelike, Duration, Utc};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::{
    tests::activities::{
        all_activities_observer, assert_triggered_with_latest_activity, get_latest_activity,
    },
    utils::random_user_with_template,
};

const TMPL: &str = r#"
version = "0.1"
name = "Smoketest Template"

[inputs]
main = { type = "user", is-default = true, required = true, description = "The starting user" }

[objects]
main_space = { type = "space", is-default = true, name = "{{ main.display_name }}’s tasks test space" }

[objects.list]
type = "task-list"
name = "Onboarding on Acter"

[objects.task-1]
type = "task"
title = "Check the weather"
"m.relates_to" = { event_id = "{{ list.id }}" }

"#;

#[tokio::test]
async fn task_creation_activity() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) = random_user_with_template("tasks_creation", TMPL).await?;
    sync_state.await_has_synced_history().await?;

    let mut act_obs = all_activities_observer(&user).await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = user.clone();
    let task_lists = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            let task_lists = client.task_lists().await?;
            if task_lists.len() != 1 {
                bail!("not all task_lists found");
            }
            Ok(task_lists)
        }
    })
    .await?;

    assert_eq!(task_lists.len(), 1);

    let task_list = task_lists
        .first()
        .expect("first tasklist should be available");

    let target_list = task_list.clone();
    let tasks = Retry::spawn(retry_strategy, move || {
        let task_list = target_list.clone();
        async move {
            let tasks = task_list.tasks().await?;
            if tasks.len() != 1 {
                bail!("not all tasks found");
            }
            Ok(tasks)
        }
    })
    .await?;
    assert_eq!(tasks.len(), 1);

    let task = tasks.first().expect("first task should be available");

    let activity = user.activity(task_list.event_id_str()).await?;
    assert_eq!(activity.type_str(), "creation");
    let object = activity.object().expect("we have an object");
    assert_eq!(object.type_str(), "task-list");
    assert_eq!(object.title().as_deref(), Some("Onboarding on Acter"));

    let activity = user.activity(task.event_id_str()).await?;
    assert_eq!(activity.type_str(), "taskAdd");
    assert_eq!(activity.title().as_deref(), Some("Check the weather"));
    // on task add the "object" is our list this happened on
    let object = activity.object().expect("we have an object");
    assert_eq!(object.type_str(), "task-list");
    assert_eq!(object.title().as_deref(), Some("Onboarding on Acter"));

    assert_triggered_with_latest_activity(&mut act_obs, activity.event_id_str()).await?;

    Ok(())
}

#[tokio::test]
async fn task_update_description() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) =
        random_user_with_template("tasks_update_description", TMPL).await?;
    sync_state.await_has_synced_history().await?;

    let mut act_obs = all_activities_observer(&user).await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = user.clone();
    let spaces = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            // client would have the default space
            let spaces = client.spaces().await?;
            if spaces.len() != 1 {
                bail!("not all spaces found");
            }
            Ok(spaces)
        }
    })
    .await?;
    let main_space = spaces.first().expect("main space should be available");

    // wait for sync to catch up
    let fetcher_client = user.clone();
    let task_lists = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            let task_lists = client.task_lists().await?;
            if task_lists.len() != 1 {
                bail!("not all task_lists found");
            }
            Ok(task_lists)
        }
    })
    .await?;

    assert_eq!(task_lists.len(), 1);

    let task_list = task_lists.first().unwrap();

    let target_list = task_list.clone();
    let tasks = Retry::spawn(retry_strategy, move || {
        let task_list = target_list.clone();
        async move {
            let tasks = task_list.tasks().await?;
            if tasks.len() != 1 {
                bail!("not all tasks found");
            }
            Ok(tasks)
        }
    })
    .await?;
    assert_eq!(tasks.len(), 1);

    let task = tasks.first().unwrap();

    let task_updater = task.subscribe();

    // set up the description
    let desc_text = "This is test content of task";
    task.update_builder()?
        .description_text(desc_text.to_owned())
        .send()
        .await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), || async {
        if task_updater.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let activity =
        get_latest_activity(&user, main_space.room_id().to_string(), "descriptionChange").await?;
    assert_eq!(activity.type_str(), "descriptionChange");
    assert_eq!(
        activity.msg_content().map(|c| c.body()).as_deref(),
        Some(desc_text)
    );
    assert_eq!(
        activity
            .description_content()
            .map(|c| c.change())
            .as_deref(),
        Some("Changed")
    );
    assert_eq!(
        activity
            .description_content()
            .and_then(|c| c.new_val())
            .as_deref(),
        Some(desc_text)
    );

    // again, acquire task updater so that we can check for description deletion
    let task_lists = user.task_lists().await?;
    let task_list = task_lists.first().unwrap();
    let tasks = task_list.tasks().await?;
    let task = tasks.first().unwrap();
    let task_updater = task.subscribe();

    // delete the description
    let event_id = task.update_builder()?.unset_description().send().await?;

    Retry::spawn(retry_strategy, || async {
        if task_updater.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let activity = user.activity(event_id.to_string()).await?;
    assert_eq!(activity.type_str(), "descriptionChange");
    assert_eq!(
        activity
            .description_content()
            .map(|c| c.change())
            .as_deref(),
        Some("Unset")
    );
    assert_eq!(
        activity.description_content().and_then(|c| c.new_val()),
        None
    );

    assert_triggered_with_latest_activity(&mut act_obs, activity.event_id_str()).await?;

    Ok(())
}

#[tokio::test]
async fn task_update_title() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) = random_user_with_template("tasks_update_title", TMPL).await?;
    sync_state.await_has_synced_history().await?;

    let mut act_obs = all_activities_observer(&user).await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = user.clone();
    let task_lists = Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        async move {
            let task_lists = client.task_lists().await?;
            if task_lists.len() != 1 {
                bail!("not all task_lists found");
            }
            Ok(task_lists)
        }
    })
    .await?;

    assert_eq!(task_lists.len(), 1);

    let task_list = task_lists.first().unwrap();

    let tasks = task_list.tasks().await?;
    assert_eq!(tasks.len(), 1);

    let task = tasks.first().unwrap();

    let task_updater = task.subscribe();

    let title = "Check the reality";
    let event_id = task
        .update_builder()?
        .title(title.to_owned())
        .send()
        .await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy, || async {
        if task_updater.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let activity = user.activity(event_id.to_string()).await?;
    assert_eq!(activity.type_str(), "titleChange");
    assert_eq!(activity.title().as_deref(), Some(title));
    assert_eq!(
        activity.title_content().map(|c| c.change()).as_deref(),
        Some("Changed")
    );
    assert_eq!(
        activity.title_content().map(|c| c.new_val()).as_deref(),
        Some(title)
    );

    assert_triggered_with_latest_activity(&mut act_obs, activity.event_id_str()).await?;

    Ok(())
}

#[tokio::test]
async fn task_update_due_date() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) =
        random_user_with_template("tasks_update_due_date", TMPL).await?;
    sync_state.await_has_synced_history().await?;

    let mut act_obs = all_activities_observer(&user).await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = user.clone();
    let spaces = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            // client would have the default space
            let spaces = client.spaces().await?;
            if spaces.len() != 1 {
                bail!("not all spaces found");
            }
            Ok(spaces)
        }
    })
    .await?;
    let main_space = spaces.first().expect("main space should be available");

    // wait for sync to catch up
    let fetcher_client = user.clone();
    let task_lists = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            let task_lists = client.task_lists().await?;
            if task_lists.len() != 1 {
                bail!("not all task_lists found");
            }
            Ok(task_lists)
        }
    })
    .await?;

    assert_eq!(task_lists.len(), 1);

    let task_list = task_lists.first().unwrap();

    let target_list = task_list.clone();
    let tasks = Retry::spawn(retry_strategy, move || {
        let task_list = target_list.clone();
        async move {
            let tasks = task_list.tasks().await?;
            if tasks.len() != 1 {
                bail!("not all tasks found");
            }
            Ok(tasks)
        }
    })
    .await?;
    assert_eq!(tasks.len(), 1);

    let task = tasks.first().unwrap();

    let task_updater = task.subscribe();

    // set up the due date
    let today = Utc::now().date_naive();
    let tomorrow = today + Duration::days(1);
    task.update_builder()?
        .due_date(tomorrow.year(), tomorrow.month0() + 1, tomorrow.day0() + 1)
        .send()
        .await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), || async {
        if task_updater.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let activity =
        get_latest_activity(&user, main_space.room_id().to_string(), "taskDueDateChange").await?;
    assert_eq!(activity.type_str(), "taskDueDateChange");
    assert_eq!(
        activity.date_content().map(|c| c.change()).as_deref(),
        Some("Changed")
    );
    assert_eq!(
        activity.date_content().and_then(|c| c.new_val()),
        Some(tomorrow.format("%Y-%m-%d").to_string()),
    );

    let object = activity.object().expect("we have an object");
    assert_eq!(object.type_str(), "task");
    assert!(object.description().is_none());
    assert!(object.utc_start().is_none());
    assert!(object.utc_end().is_none());
    assert_eq!(object.due_date(), Some(tomorrow));

    // again, acquire task updater so that we can check for description deletion
    let task_lists = user.task_lists().await?;
    let task_list = task_lists.first().unwrap();
    let tasks = task_list.tasks().await?;
    let task = tasks.first().unwrap();
    let task_updater = task.subscribe();

    // delete the due date
    let event_id = task.update_builder()?.unset_due_date().send().await?;

    Retry::spawn(retry_strategy, || async {
        if task_updater.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let activity = user.activity(event_id.to_string()).await?;
    assert_eq!(activity.type_str(), "taskDueDateChange");
    assert_eq!(
        activity.date_content().map(|c| c.change()).as_deref(),
        Some("Unset")
    );
    assert_eq!(activity.date_content().and_then(|c| c.new_val()), None);

    assert_triggered_with_latest_activity(&mut act_obs, activity.event_id_str()).await?;

    Ok(())
}
