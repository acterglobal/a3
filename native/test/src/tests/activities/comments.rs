use anyhow::{bail, Result};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::{
    tests::activities::{all_activities_observer, assert_triggered_with_latest_activity},
    utils::random_user_with_template,
};

const TMPL: &str = r#"
version = "0.1"
name = "Smoketest Template"

[inputs]
main = { type = "user", is-default = true, required = true, description = "The starting user" }

[objects]
main_space = { type = "space", is-default = true, name = "{{ main.display_name }}’s comments test space" }

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
    let mut act_obs = all_activities_observer(&user).await?;

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
            if task_lists
                .first()
                .expect("first tasklist should be available")
                .tasks()
                .await?
                .len()
                != 1
            {
                bail!("not all tasks found");
            }
            Ok(task_lists)
        }
    })
    .await?;

    assert_eq!(task_lists.len(), 1);

    let task_list = task_lists
        .first()
        .expect("first tasklist should be available");

    let tasks = task_list.tasks().await?;
    assert_eq!(tasks.len(), 1);

    let task = tasks.first().expect("first task should be available");

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
    assert_eq!(
        activity.msg_content().map(|c| c.body()).as_deref(),
        Some("Looking forward to it!")
    );
    // on task add the "object" is our list this happened on
    let object = activity.object().expect("we have an object");
    assert_eq!(object.type_str(), "task");
    assert_eq!(object.title().as_deref(), Some("Check the weather"));
    assert_eq!(object.task_list_id_str(), Some(task_list.event_id_str()));

    assert_triggered_with_latest_activity(&mut act_obs, comment_1_id.to_string()).await?;

    Ok(())
}
