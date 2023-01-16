use anyhow::{bail, Result};
use effektio::{matrix_sdk::config::StoreConfig, testing::ensure_user, CreateGroupSettingsBuilder};
use effektio_core::{models::EffektioModel, ruma::OwnedRoomId};
use futures::Future;
use tokio::time::{sleep, Duration};

async fn wait_for<F, T, O>(fun: F) -> Result<Option<T>>
where
    F: Fn() -> O,
    O: Future<Output = Result<Option<T>>>,
{
    let duration = Duration::from_secs(1);
    let mut remaining: u32 = 3;
    loop {
        if let Some(t) = fun().await? {
            return Ok(Some(t));
        }
        let Some(new) = remaining.checked_sub(1)  else {
            return Ok(None);
        };
        remaining = new;
        sleep(duration).await;
    }
}
pub async fn random_user_with_random_space(
    prefix: &str,
) -> Result<(effektio::Client, OwnedRoomId)> {
    let uuid = uuid::Uuid::new_v4().to_string();
    let user = ensure_user(
        option_env!("HOMESERVER").unwrap_or("http://localhost:8118"),
        format!("it-{prefix}-{uuid}"),
        "effektio-integration-tests".to_owned(),
        StoreConfig::default(),
    )
    .await?;

    let room_id = user
        .create_effektio_group(
            CreateGroupSettingsBuilder::default()
                .name(format!("it-room-{prefix}-{uuid}"))
                .build()?,
        )
        .await?;
    Ok((user, room_id))
}

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
    let Some(mut task_list) = task_lists.into_iter().find(|t| t.name() == &list_name) else {
        bail!("TaskList not found");
    };

    assert!(
        task_list.tasks().await?.len() >= 3,
        "Number of tasks too low",
    );

    let mut list_subscription = task_list.subscribe();

    let new_task_event_id = task_list
        .task_builder()?
        .title("Integation Test Task".into())
        .description_text("Integration Test Task Description".into())
        .send()
        .await?;

    let mut remaining = 3;

    let task = loop {
        if remaining == 0 {
            bail!("tried to find the new task 3 seconds");
        }
        remaining -= 1;

        if Ok(()) == list_subscription.try_recv() {
            task_list = odo
                .task_lists()
                .await?
                .into_iter()
                .find(|t| t.name() == &list_name)
                .expect("TaskList not found again");
            if let Some(task) = task_list
                .tasks()
                .await?
                .into_iter()
                .find(|t| t.event_id() == new_task_event_id)
            {
                break task;
            }
        }

        sleep(Duration::from_secs(1)).await;
    };

    assert_eq!(*task.title(), "Integation Test Task".to_string());
    assert!(!task.is_done(), "Task is already done");

    let mut task_update = task.subscribe();
    let _update_id = task
        .update_builder()?
        .title("New Test title".to_owned())
        .mark_done()
        .send()
        .await?;

    let mut remaining = 4;
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

    // we do not expect a signal on the list, as the order hasn't changed
    let Some(task) = task_list
        .tasks()
        .await?
        .into_iter()
        .find(|t| t.event_id() == new_task_event_id) else {
            bail!("Task not found?!?")
        };

    assert_eq!(*task.title(), "New Test title".to_string());
    assert!(task.is_done(), "Task is not be marked as done");

    Ok(())
}

#[tokio::test]
async fn task_smoketests() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, room_id) = random_user_with_random_space("tasks_smoketest").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;
    let group = user.get_group(room_id.to_string()).await?;

    assert_eq!(
        group.task_lists().await?.len(),
        0,
        "Why are there tasks in our fresh space!?!"
    );

    let task_list_id = {
        let mut draft = group.task_list_draft()?;
        draft.name("Starting up".to_owned());
        draft.send().await?
    };

    let task_list_key = effektio_core::models::TaskList::key_from_event(&task_list_id);

    let wait_for_group = group.clone();
    let Some(task_list) = wait_for(move || {
        let group = wait_for_group.clone();
        let task_list_key = task_list_key.clone();
        async move {
            Ok(group.task_list(&task_list_key).await.ok())
    }}).await? else {
        bail!("freshly created Task List couldn't be found");
    };

    assert_eq!(task_list.name(), &"Starting up".to_owned());
    assert_eq!(task_list.tasks().await?.len(), 0);

    let task_list_listener = task_list.subscribe();

    let task_1_id = task_list
        .task_builder()?
        .title("Testing 1".into())
        .send()
        .await?;

    assert!(
        wait_for(move || {
            let mut task_list_listener = task_list_listener.clone();
            async move {
                if let Ok(t) = task_list_listener.try_recv() {
                    Ok(Some(t))
                } else {
                    Ok(None)
                }
            }
        })
        .await?
        .is_some(),
        "Didn't receive any update on the list for the first event"
    );

    let task_list = task_list.refresh().await?;
    let tasks = task_list.tasks().await?;
    assert_eq!(tasks.len(), 1);
    assert_eq!(tasks[0].event_id(), task_1_id);

    let task_1 = tasks[0].clone();
    assert_eq!(task_1.title(), &"Testing 1".to_owned());
    assert!(!task_1.is_done());

    let task_list_listener = task_list.subscribe();

    let task_2_id = task_list
        .task_builder()?
        .title("Testing 2".into())
        .send()
        .await?;

    assert!(
        wait_for(move || {
            let mut task_list_listener = task_list_listener.clone();
            async move {
                if let Ok(t) = task_list_listener.try_recv() {
                    Ok(Some(t))
                } else {
                    Ok(None)
                }
            }
        })
        .await?
        .is_some(),
        "Didn't receive any update on the list for the second event"
    );

    let task_list = task_list.refresh().await?;
    let tasks = task_list.tasks().await?;
    assert_eq!(tasks.len(), 2);
    assert_eq!(tasks[1].event_id(), task_2_id);

    let task_2 = tasks[1].clone();
    assert_eq!(task_2.title(), &"Testing 2".to_owned());
    assert!(!task_2.is_done());

    let task_1_updater = task_1.subscribe();

    task_1
        .update_builder()?
        .title("Replacement Name".into())
        .mark_done()
        .send()
        .await?;

    assert!(
        wait_for(move || {
            let mut task_1_updater = task_1_updater.clone();
            async move {
                if let Ok(t) = task_1_updater.try_recv() {
                    Ok(Some(t))
                } else {
                    Ok(None)
                }
            }
        })
        .await?
        .is_some(),
        "Didn't receive any update on the task"
    );

    let task_1 = task_1.refresh().await?;
    // Update has been applied properly
    assert_eq!(task_1.title(), &"Replacement Name".to_owned());
    assert!(task_1.is_done());

    let task_list_listener = task_list.subscribe();

    task_list
        .update_builder()?
        .name("Setup".into())
        .description_text("All done now".into())
        .send()
        .await?;

    assert!(
        wait_for(move || {
            let mut task_list_listener = task_list_listener.clone();
            async move {
                if let Ok(t) = task_list_listener.try_recv() {
                    Ok(Some(t))
                } else {
                    Ok(None)
                }
            }
        })
        .await?
        .is_some(),
        "Didn't receive the update on the task list"
    );

    let task_list = task_list.refresh().await?;

    assert_eq!(task_list.name(), &"Setup".to_owned());
    assert_eq!(
        task_list.description().as_ref().unwrap().body,
        "All done now".to_owned()
    );

    Ok(())
}

#[tokio::test]
async fn task_lists_comments_smoketests() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, room_id) = random_user_with_random_space("tasklist_comments_smoketest").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;
    let group = user.get_group(room_id.to_string()).await?;

    assert_eq!(
        group.task_lists().await?.len(),
        0,
        "Why are there tasks in our fresh space!?!"
    );

    let task_list_id = {
        let mut draft = group.task_list_draft()?;
        draft.name("Comments test".to_owned());
        draft.send().await?
    };

    let task_list_key = effektio_core::models::TaskList::key_from_event(&task_list_id);

    let wait_for_group = group.clone();
    let Some(task_list) = wait_for(move || {
        let group = wait_for_group.clone();
        let task_list_key = task_list_key.clone();
        async move {
            Ok(group.task_list(&task_list_key).await.ok())
    }}).await? else {
        bail!("freshly created Task List couldn't be found");
    };

    let comments_manager = task_list.comments().await?;

    assert_eq!(task_list.name(), &"Comments test".to_owned());
    assert_eq!(task_list.tasks().await?.len(), 0);
    assert!(!comments_manager.stats().has_comments());

    // ---- let's make a comment

    let comments_listener = comments_manager.subscribe();
    let comment_1_id = comments_manager
        .comment_draft()?
        .content_text("I think this is very important".to_owned())
        .send()
        .await?;

    assert!(
        wait_for(move || {
            let mut comments_listener = comments_listener.clone();
            async move {
                if let Ok(t) = comments_listener.try_recv() {
                    Ok(Some(t))
                } else {
                    Ok(None)
                }
            }
        })
        .await?
        .is_some(),
        "Didn't receive any update on the list for the first event"
    );

    let comments = comments_manager.comments().await?;
    assert_eq!(comments.len(), 1);
    assert_eq!(comments[0].event_id(), comment_1_id);
    assert_eq!(
        comments[0].content().body,
        "I think this is very important".to_owned()
    );

    Ok(())
}

#[tokio::test]
async fn task_comment_smoketests() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, room_id) = random_user_with_random_space("tasks_smoketest").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;
    let group = user.get_group(room_id.to_string()).await?;

    assert_eq!(
        group.task_lists().await?.len(),
        0,
        "Why are there tasks in our fresh space!?!"
    );

    let task_list_id = {
        let mut draft = group.task_list_draft()?;
        draft.name("Starting up".to_owned());
        draft.send().await?
    };

    let task_list_key = effektio_core::models::TaskList::key_from_event(&task_list_id);

    let wait_for_group = group.clone();
    let Some(task_list) = wait_for(move || {
        let group = wait_for_group.clone();
        let task_list_key = task_list_key.clone();
        async move {
            Ok(group.task_list(&task_list_key).await.ok())
    }}).await? else {
        bail!("freshly created Task List couldn't be found");
    };

    assert_eq!(task_list.name(), &"Starting up".to_owned());
    assert_eq!(task_list.tasks().await?.len(), 0);

    let task_list_listener = task_list.subscribe();

    let task_1_id = task_list
        .task_builder()?
        .title("Testing 1".into())
        .send()
        .await?;

    assert!(
        wait_for(move || {
            let mut task_list_listener = task_list_listener.clone();
            async move {
                if let Ok(t) = task_list_listener.try_recv() {
                    Ok(Some(t))
                } else {
                    Ok(None)
                }
            }
        })
        .await?
        .is_some(),
        "Didn't receive any update on the list for the first event"
    );

    let task_list = task_list.refresh().await?;
    let mut tasks = task_list.tasks().await?;
    assert_eq!(tasks.len(), 1);
    assert_eq!(tasks[0].event_id(), task_1_id);

    let task = tasks.pop().unwrap();

    // START actual comment on task

    let comments_manager = task.comments().await?;
    assert!(!comments_manager.stats().has_comments());

    // ---- let's make a comment

    let comments_listener = comments_manager.subscribe();
    let comment_1_id = comments_manager
        .comment_draft()?
        .content_text("I updated the task".to_owned())
        .send()
        .await?;

    assert!(
        wait_for(move || {
            let mut comments_listener = comments_listener.clone();
            async move {
                if let Ok(t) = comments_listener.try_recv() {
                    Ok(Some(t))
                } else {
                    Ok(None)
                }
            }
        })
        .await?
        .is_some(),
        "Didn't receive any update on the list for the first event"
    );

    let comments = comments_manager.comments().await?;
    assert_eq!(comments.len(), 1);
    assert_eq!(comments[0].event_id(), comment_1_id);
    assert_eq!(comments[0].content().body, "I updated the task".to_owned());

    Ok(())
}
