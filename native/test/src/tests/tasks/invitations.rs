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
    let (users, _sync_states, space_id, _engine) =
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
    let event_id = manager.invite(second_user.user_id()?.to_string()).await?;
    let _ = stream.next().await; // await the invite being sent

    // check activity
    let activity = first.activity(event_id.to_string()).await?;

    assert_eq!(activity.type_str(), "objectInvitation");
    let object = activity.object().unwrap();
    assert_eq!(object.object_id_str(), obj_entry.event_id().to_string());
    assert_eq!(activity.whom().len(), 1);
    assert_eq!(activity.whom()[0], second_user.user_id()?.to_string());
    assert!(!activity.mentions_you());

    // see what the recipient sees

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

    // check the invite as a notification
    // as it is a mention, we get it without having to actually
    // been subscribing to anything special
    let notification = second_user
        .get_notification_item(space_id.to_string(), event_id.to_string())
        .await?;
    assert_eq!(notification.push_style(), "objectInvitation");
    let parent = notification.parent().unwrap();
    assert_eq!(parent.title().unwrap(), "Scroll news");
    assert_eq!(parent.type_str(), "task");
    assert_eq!(notification.sender().user_id(), first.user_id()?);
    assert_eq!(
        notification.whom(),
        vec![second_user.user_id()?.to_string()]
    );
    assert!(notification.mentions_you());

    Ok(())
}

#[tokio::test]
async fn accept_and_decline_task_invitation() -> Result<()> {
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

    let s_invites_manager = second_user.invitations();
    let s_invites_stream = s_invites_manager.subscribe_stream();
    let mut s_invites_stream = s_invites_stream.fuse();

    let _obj_id = obj_entry.event_id().to_string();
    // this is a mention, so we need to subscribe to the room

    let manager = obj_entry.invitations().await?;
    let stream = manager.subscribe_stream();
    let mut stream = stream.fuse();
    let second_user_str = second_user.user_id()?.to_string();
    assert!(manager.can_invite(second_user_str.clone())?);

    let _event_id = manager.invite(second_user_str).await?;
    let _ = stream.next().await; // await the invite being sent

    // see what the recipient sees

    let fetcher_client = second_user.clone();
    let task = Retry::spawn(retry_strategy.clone(), move || {
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

    {
        let fetcher_task = task.clone();
        let invites = Retry::spawn(retry_strategy.clone(), move || {
            let task = fetcher_task.clone();
            async move {
                let invites = task.invitations().await?;
                if invites.invited().is_empty() {
                    bail!("no invites found");
                }
                Ok(invites)
            }
        })
        .await?;

        assert!(invites.is_invited());
        assert!(!invites.has_accepted());
        assert!(!invites.has_declined());
        let invite = invites.invited();

        assert_eq!(invite.len(), 1);
        assert_eq!(invite[0], second_user.user_id()?);
    } // dropping the invites

    assert_eq!(s_invites_stream.next().await, Some(true)); //invite was seen by the manager
    let object_invitations = s_invites_manager.object_invitations().await?;
    assert_eq!(object_invitations.len(), 1);
    assert_eq!(object_invitations[0], task.event_id().to_string());

    task.assign_self().await?; // this is the way we accept the task

    {
        let fetcher_task = task.clone();
        let invites = Retry::spawn(retry_strategy.clone(), move || {
            let task = fetcher_task.clone();
            async move {
                let invites = task.invitations().await?;
                if invites.is_invited() {
                    bail!("still being invited");
                }
                Ok(invites)
            }
        })
        .await?;

        assert!(!invites.is_invited()); // we are not invited anymore
        assert!(invites.has_accepted());
        assert!(!invites.has_declined());

        assert_eq!(invites.invited().len(), 0);
        assert_eq!(invites.declined().len(), 0);

        let accepted = invites.accepted();

        assert_eq!(accepted.len(), 1);
        assert_eq!(accepted[0], second_user.user_id()?);
    } // dropping the invites

    assert_eq!(s_invites_stream.next().await, Some(true)); //invite was seen by the manager
    let object_invitations = s_invites_manager.object_invitations().await?;
    assert_eq!(object_invitations.len(), 0); // invite is gone

    // -- and now we decline

    task.unassign_self().await?; // this is the way we decline a task

    {
        let fetcher_task = task.clone();
        let invites = Retry::spawn(retry_strategy.clone(), move || {
            let task = fetcher_task.clone();
            async move {
                let invites = task.invitations().await?;
                if invites.has_accepted() {
                    bail!("still being accepted");
                }
                Ok(invites)
            }
        })
        .await?;

        assert!(!invites.is_invited()); // we are not invited anymore
        assert!(!invites.has_accepted());
        assert!(invites.has_declined());

        assert_eq!(invites.invited().len(), 0);
        assert_eq!(invites.accepted().len(), 0);

        let declined = invites.declined();

        assert_eq!(declined.len(), 1);
        assert_eq!(declined[0], second_user.user_id()?);
    }

    // no interactions with the third user.

    Ok(())
}

#[tokio::test]
async fn can_invite_after_unassign_task() -> Result<()> {
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
    let second_user_str = second_user.user_id()?.to_string();

    // see what the recipient sees

    let fetcher_client = second_user.clone();
    let task = Retry::spawn(retry_strategy.clone(), move || {
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

    task.assign_self().await?; // this is the way we accept the task
    task.unassign_self().await?; // this is the way we decline a task

    // ensure despite the interaction, we can still invite the user
    let manager = obj_entry.invitations().await?;
    let stream = manager.subscribe_stream();
    let mut stream = stream.fuse();
    assert!(manager.can_invite(second_user_str.clone())?);
    manager.invite(second_user_str.clone()).await?;
    let _ = stream.next().await; // await the invite being sent

    {
        let fetcher_task = task.clone();
        let _invites = Retry::spawn(retry_strategy.clone(), move || {
            let task = fetcher_task.clone();
            async move {
                let invites = task.invitations().await?;
                if !invites.is_invited() {
                    bail!("still not invited");
                }
                Ok(invites)
            }
        })
        .await?;
    }

    // the declined after the invitations
    task.unassign_self().await?; // this is the way we decline a task

    // make sure we reload the manager properly

    {
        let fetcher_manager = manager.clone();
        let invites = Retry::spawn(retry_strategy.clone(), move || {
            let manager = fetcher_manager.clone();
            async move {
                let invites = manager.reload().await?;
                if invites.declined().is_empty() {
                    bail!("waiting for declined")
                }
                Ok(invites)
            }
        })
        .await?;

        assert!(!invites.can_invite(second_user_str.clone()).unwrap());
    }

    Ok(())
}
