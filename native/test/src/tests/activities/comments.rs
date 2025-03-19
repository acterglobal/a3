use anyhow::{bail, Result};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::random_user_with_template;

const TMPL: &str = r#"
version = "0.1"
name = "Smoketest Template"

[inputs]
main = { type = "user", is-default = true, required = true, description = "The starting user" }

[objects]
main_space = { type = "space", is-default = true, name = "{{ main.display_name }}’s pins test space"}

[objects.list]
type = "task-list"
name = "Onboarding on Acter"

[objects.task-1]
type = "task"
title = "Check the weather"
"m.relates_to" = { event_id = "{{ list.id }}" }

"#;

#[tokio::test]
async fn task_comment_activity() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) = random_user_with_template("tasks_activities", TMPL).await?;
    sync_state.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
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

    let tasks = task_list.tasks().await?;
    assert_eq!(tasks.len(), 1);

    let task = tasks.first().unwrap();

    let comments_manager = task.comments().await?;
    let comment_1_id = comments_manager
        .comment_draft()?
        .content_text("Looking forward to it!".to_owned())
        .send()
        .await?;

    // ensure we have seen it
    let fetcher_client = comments_manager.clone();
    Retry::spawn(retry_strategy, move || {
        let manager = fetcher_client.clone();
        async move {
            let manager = manager.reload().await?;
            let comments = manager.comments().await?;
            if comments.len() != 1 {
                bail!("not all comments found");
            }
            Ok(comments)
        }
    })
    .await?;
    let activity = user.activity(comment_1_id.to_string()).await?;
    // on task add the "object" is our list this happened on
    let object = activity.object().expect("we have an object");
    assert_eq!(object.type_str(), "task");
    assert_eq!(object.title().unwrap(), "Check the weather");
    assert_eq!(object.task_list_id_str().unwrap(), task_list.event_id_str());
    Ok(())
}
