use anyhow::{bail, Result};
use effektio::{matrix_sdk::config::StoreConfig, testing::ensure_user};
use effektio_core::models::EffektioModel;
use tokio::time::{sleep, Duration};

#[tokio::test]
async fn odos_tasks() -> Result<()> {
    let _ = env_logger::try_init();
    let list_name = "Daily Security Brief".to_owned();
    let mut odo = ensure_user(
        option_env!("HOMESERVER").unwrap_or("http://localhost:8118"),
        "odo".to_owned(),
        "effektio-integration-tests".to_owned(),
        StoreConfig::default(),
    )
    .await?;

    let state_sync = odo.start_sync();
    state_sync.await_has_synced_history().await?;

    let task_lists = odo.task_lists().await?;
    let Some(task_list) = task_lists.into_iter().find(|t| t.name() == &list_name) else {
        bail!("TaskList not found");
    };

    assert!(
        task_list.tasks().await?.len() >= 3,
        "Number of tasks too low",
    );

    let mut list_subscription = task_list.subscribe();

    let new_task_event_id = task_list
        .task_builder()
        .title("Integation Test Task".into())
        .description("Integration Test Task Description".into())
        .send()
        .await?;
    let task_key = effektio_core::models::Task::key_from_event(&new_task_event_id);

    let mut remaining = 3;

    let task = loop {
        if remaining == 0 {
            bail!("tried to find the new task 3 seconds");
        }
        remaining -= 1;

        if Ok(()) == list_subscription.try_recv() {
            if let Some(task) = task_list
                .tasks()
                .await?
                .into_iter()
                .find(|t| t.key() == task_key)
            {
                break task;
            }
        }

        sleep(Duration::from_secs(1)).await;
    };

    assert_eq!(*task.title(), "Integation Test Task".to_string());
    assert_eq!(task.is_done(), false, "Task is already done");

    let mut task_update = task.subscribe();
    let update = task
        .update_builder()
        .title("New Test title".to_owned())
        .mark_done()
        .send()
        .await?;

    let mut remaining = 3;
    loop {
        if remaining == 0 {
            bail!("even after 3 seconds, no task update has been reported");
        }
        remaining -= 1;

        if task_update.try_recv().is_ok() {
            break;
        }

        sleep(Duration::from_secs(1)).await;
    }

    // we can expect a signal on the list, too
    let mut remaining = 3;
    loop {
        if remaining == 0 {
            bail!("even after 3 seconds, no task list update has been reported");
        }
        remaining -= 1;

        if list_subscription.try_recv().is_ok() {
            break;
        }

        sleep(Duration::from_secs(1)).await;
    }

    let Some(task) = task_list
        .tasks()
        .await?
        .into_iter()
        .find(|t| t.key() == task_key) else {
            bail!("Task not found?!?")
        };

    assert_eq!(*task.title(), "New Test title".to_string());
    assert_eq!(task.is_done(), true, "Task is not be marked as done");

    Ok(())
}
