use anyhow::{bail, Result};
use futures::StreamExt;
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::random_users_with_random_space_under_template;
use acter::ActerModel;

const TMPL: &str = r#"
version = "0.1"
name = "Task Invitiation Template"

[inputs]
main = { type = "user", is-default = true, required = true, description = "The starting user" }
space = { type = "space", is-default = true, required = true, description = "The main user" }

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
async fn task_invitation() -> Result<()> {
    let _ = env_logger::try_init();
    let (users, _sync_states, _space_id, _engine) =
        random_users_with_random_space_under_template("i0t", 2, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = first.clone();
    let obj_entry = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            let entries = client.task_lists().await?;
            if entries.is_empty() {
                bail!("no task lists not found");
            }
            let tasks = entries[0].tasks().await?;
            let Some(task) = tasks.first() else {
                bail!("no tasks found")
            };
            Ok(task.clone())
        }
    })
    .await?;

    let _obj_id = obj_entry.event_id().to_string();
    // this is a mention, so we need to subscribe to the room

    let manager = obj_entry.invitations().await?;
    let stream = manager.subscribe_stream();
    let mut stream = stream.fuse();
    manager.invite(second_user.user_id()?).await?;
    let _ = stream.next().await; // await the invite being sent

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = second_user.clone();
    let invites = Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            let entries = client.task_lists().await?;
            if entries.is_empty() {
                bail!("no task lists not found");
            }
            let tasks = entries[0].tasks().await?;
            let Some(task) = tasks.first() else {
                bail!("no tasks found")
            };
            let invites = task.invitations().await?;
            if invites.invited().is_empty() {
                bail!("no invites found");
            }
            Ok(invites)
        }
    })
    .await?;

    let invite = invites.invited();
    assert_eq!(invite.len(), 1);
    assert_eq!(invite[0], second_user.user_id()?);
    Ok(())
}
