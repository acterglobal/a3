mod invitations;

use acter::testing::wait_for;
use acter_matrix::models::ActerModel;
use anyhow::{bail, Context, Result};
use chrono::{Datelike, Duration, Utc};
use matrix_sdk_base::ruma::{
    events::room::redaction::RoomRedactionEvent, MilliSecondsSinceUnixEpoch,
};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::random_user_with_random_space;

#[tokio::test]
async fn task_smoketests() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, room_id) = random_user_with_random_space("tasks_smoketest").await?;

    let user_id = user.user_id()?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    Retry::spawn(retry_strategy, || async {
        user.space(room_id.to_string()).await
    })
    .await?;

    let space = user.space(room_id.to_string()).await?;

    assert_eq!(
        space.task_lists().await?.len(),
        0,
        "Why are there tasks in our fresh space!?!"
    );

    let name = "Starting up";
    let task_list_id = space
        .task_list_draft()?
        .name(name.to_owned())
        .send()
        .await?;

    let task_list_key = task_list_id.clone();

    let wait_for_space = space.clone();
    let task_list = wait_for(move || {
        let space = wait_for_space.clone();
        let task_list_key = task_list_key.clone();
        async move {
            let result = space.task_list(task_list_key).await.ok();
            Ok(result)
        }
    })
    .await?
    .expect("freshly created Task List couldn’t be found");

    assert_eq!(task_list.name(), name);
    assert_eq!(task_list.tasks().await?.len(), 0);

    let task_list_listener = task_list.subscribe();

    let title = "Testing 1";
    let body = "This is testing task";
    let today = Utc::now().date_naive();
    let tomorrow = today + Duration::days(1);
    let task_1_id = task_list
        .task_builder()?
        .title(title.to_owned())
        .description_text(body.to_owned())
        .due_date(today.year(), today.month0() + 1, today.day0() + 1)
        .unset_due_date()
        .due_date(tomorrow.year(), tomorrow.month0() + 1, tomorrow.day0() + 1)
        .utc_due_time_of_day(9 * 3600) // 9 AM UTC
        .unset_utc_due_time_of_day()
        .utc_due_time_of_day(11 * 3600) // 11 AM UTC
        .send()
        .await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), || async {
        if task_list_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let task_list = task_list.refresh().await?;
    let tasks = task_list.tasks().await?;
    assert_eq!(tasks.len(), 1);
    assert_eq!(tasks[0].event_id(), task_1_id);

    let task_1 = tasks[0].clone();
    assert_eq!(task_1.title(), title);
    assert_eq!(
        task_1.description().map(|msg| msg.body()).as_deref(),
        Some(body)
    );
    assert_ne!(
        task_1.due_date(),
        Some(today.format("%Y-%m-%d").to_string())
    );
    assert_eq!(
        task_1.due_date(),
        Some(tomorrow.format("%Y-%m-%d").to_string())
    );
    assert_eq!(task_1.utc_due_time_of_day(), Some(11 * 3600)); // not 9 AM UTC
    assert!(!task_1.is_done());

    let task_list_listener = task_list.subscribe();

    let title = "Testing 2";
    let today = Utc::now();
    let tomorrow = today + Duration::days(1);
    let fmt = "%Y-%m-%dT%H:%M:%S%:z"; // ISO 8601 format with timezone
    let task_2_id = task_list
        .task_builder()?
        .title(title.to_owned())
        .sort_order(1)
        .utc_start_from_rfc2822(today.to_rfc2822())?
        .unset_utc_start()
        .utc_start_from_rfc3339(today.to_rfc3339())?
        .unset_utc_start()
        .utc_start_from_format(tomorrow.format(fmt).to_string(), fmt.to_owned())?
        .send()
        .await?;

    Retry::spawn(retry_strategy.clone(), || async {
        if task_list_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let task_list = task_list.refresh().await?;
    let tasks = task_list.tasks().await?;
    assert_eq!(tasks.len(), 2);
    assert_eq!(tasks[1].event_id(), task_2_id);
    assert_eq!(tasks[0].sort_order(), 0);
    assert_eq!(tasks[1].sort_order(), 1);

    let task_2 = tasks[1].clone();
    assert_eq!(task_2.title(), title);
    assert!(!task_2.is_done());
    assert_ne!(
        task_2.utc_start().map(|d| d.to_rfc2822()),
        Some(today.to_rfc2822())
    );
    assert_ne!(
        task_2.utc_start().map(|d| d.to_rfc3339()),
        Some(today.to_rfc3339())
    );
    assert_eq!(
        task_2.utc_start().map(|d| d.format(fmt).to_string()),
        Some(tomorrow.format(fmt).to_string())
    );

    let task_1_updater = task_1.subscribe();

    let title = "Replacement Name";
    let someday = today + Duration::days(10);
    let otherday = today + Duration::days(15);
    task_1
        .update_builder()?
        .title(title.to_owned())
        .utc_start_from_rfc2822(someday.to_rfc2822())?
        .unset_utc_start()
        .utc_start_from_rfc3339(someday.to_rfc3339())?
        .unset_utc_start()
        .utc_start_from_format(otherday.format(fmt).to_string(), fmt.to_owned())?
        .mark_done()
        .send()
        .await?;

    let _assigned_event_id = task_1.assign_self().await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), || async {
        if task_1_updater.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let task_1 = task_1.refresh().await?;
    // Update has been applied properly
    assert_eq!(task_1.title(), title);
    let assignees = task_1.assignees();
    assert_eq!(assignees, vec![user_id]);
    assert!(task_1.is_done());
    assert_ne!(
        task_1.utc_start().map(|d| d.to_rfc2822()),
        Some(someday.to_rfc2822())
    );
    assert_ne!(
        task_1.utc_start().map(|d| d.to_rfc3339()),
        Some(someday.to_rfc3339())
    );
    assert_eq!(
        task_1.utc_start().map(|d| d.format(fmt).to_string()),
        Some(otherday.format(fmt).to_string())
    );

    let task_list_listener = task_list.subscribe();

    let name = "Setup";
    let body = "All done now";
    task_list
        .update_builder()?
        .name(name.to_owned())
        .description_text(body.to_owned())
        .send()
        .await?;

    Retry::spawn(retry_strategy, || async {
        if task_list_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let task_list = task_list.refresh().await?;

    assert_eq!(task_list.name(), name);
    assert_eq!(
        task_list.description().map(|c| c.body()).as_deref(),
        Some(body)
    );

    Ok(())
}

#[tokio::test]
async fn task_lists_comments_smoketests() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, room_id) = random_user_with_random_space("tasklist_comments_smoketest").await?;

    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    Retry::spawn(retry_strategy, || async {
        user.space(room_id.to_string()).await
    })
    .await?;

    let space = user.space(room_id.to_string()).await?;

    assert_eq!(
        space.task_lists().await?.len(),
        0,
        "Why are there tasks in our fresh space!?!"
    );

    let name = "Comments test";
    let task_list_id = space
        .task_list_draft()?
        .name(name.to_owned())
        .send()
        .await?;

    let task_list_key = task_list_id.clone();

    let wait_for_space = space.clone();
    let task_list = wait_for(move || {
        let space = wait_for_space.clone();
        let task_list_key = task_list_key.clone();
        async move { Ok(space.task_list(task_list_key).await.ok()) }
    })
    .await?
    .expect("freshly created Task List couldn’t be found");

    let comments_manager = task_list.comments().await?;

    assert_eq!(task_list.name(), name);
    assert_eq!(task_list.tasks().await?.len(), 0);
    assert!(!comments_manager.stats().has_comments());

    // ---- let’s make a comment

    let comments_listener = comments_manager.subscribe();
    let initial_body = "I think this is very important";
    let comment_id = comments_manager
        .comment_draft()?
        .content_text(initial_body.to_owned())
        .send()
        .await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), || async {
        if comments_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let comments = comments_manager.comments().await?;
    assert_eq!(comments.len(), 1);
    let comment = &comments[0];
    assert_eq!(comment.event_id(), comment_id);
    assert_eq!(comment.content().body, initial_body);

    let updated_body = "Sorry, this is not important";
    comment
        .update_builder()?
        .content_text(updated_body.to_owned())
        .send()
        .await?;

    Retry::spawn(retry_strategy.clone(), || async {
        if comments_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let comments = comments_manager.comments().await?;
    assert_eq!(comments.len(), 1);
    let comment = &comments[0];

    Retry::spawn(retry_strategy.clone(), || async {
        let edited_comment = comment.refresh().await?;
        if edited_comment.content().body != updated_body {
            bail!("Update not yet received");
        }
        Ok(())
    })
    .await?;

    let reply_body = "Okay, I will do it";
    let replied_id = comment
        .reply_draft()?
        .content_text(reply_body.to_owned())
        .send()
        .await?;

    let reply_comment = Retry::spawn(retry_strategy, || async {
        let comments = comments_manager.comments().await?;
        if comments.len() < 2 {
            bail!("Expected 2 comments, got {}", comments.len());
        }
        match comments.iter().find(|c| c.event_id() == replied_id) {
            Some(comment) => Ok(comment.clone()),
            None => bail!("Expected comment with id {replied_id} not found"),
        }
    })
    .await?;

    assert_eq!(reply_comment.content().body, reply_body);

    Ok(())
}

#[tokio::test]
async fn task_comment_smoketests() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, room_id) = random_user_with_random_space("tasks_smoketest").await?;

    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    Retry::spawn(retry_strategy, || async {
        user.space(room_id.to_string()).await
    })
    .await?;

    let space = user.space(room_id.to_string()).await?;

    assert_eq!(
        space.task_lists().await?.len(),
        0,
        "Why are there tasks in our fresh space!?!"
    );

    let name = "Starting up";
    let task_list_id = space
        .task_list_draft()?
        .name(name.to_owned())
        .send()
        .await?;

    let task_list_key = task_list_id.clone();

    let wait_for_space = space.clone();
    let task_list = wait_for(move || {
        let space = wait_for_space.clone();
        let task_list_key = task_list_key.clone();
        async move { Ok(space.task_list(task_list_key).await.ok()) }
    })
    .await?
    .expect("freshly created Task List couldn’t be found");

    assert_eq!(task_list.name(), name);
    assert_eq!(task_list.tasks().await?.len(), 0);

    let task_list_listener = task_list.subscribe();

    let title = "Testing 1";
    let task_1_id = task_list
        .task_builder()?
        .title(title.to_owned())
        .send()
        .await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), || async {
        if task_list_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let task_list = task_list.refresh().await?;
    let mut tasks = task_list.tasks().await?;
    assert_eq!(tasks.len(), 1);
    assert_eq!(tasks[0].event_id(), task_1_id);

    let task = tasks.pop().expect("first task should be available");
    assert_eq!(task.room_id_str(), space.room_id_str());

    // START actual comment on task

    let comments_manager = task.comments().await?;
    assert!(!comments_manager.stats().has_comments());
    let initial_ts: u64 = MilliSecondsSinceUnixEpoch::now().get().into();

    // ---- let’s make a comment

    let comments_listener = comments_manager.subscribe();
    let body = "I think this is very important";
    let comment_id = comments_manager
        .comment_draft()?
        .content_text(body.to_owned())
        .send()
        .await?;

    Retry::spawn(retry_strategy.clone(), || async {
        if comments_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let comments = comments_manager.comments().await?;
    assert_eq!(comments.len(), 1);

    let comment = &comments[0];
    assert_eq!(comment.event_id(), comment_id);
    assert_eq!(comment.content().body, body);
    assert_eq!(comment.msg_content().body(), body);
    assert!(initial_ts < comment.origin_server_ts());

    let updated_body = "Sorry, this is not important";
    let updated_html = "**Sorry, this is not important**";
    comment
        .update_builder()?
        .content_formatted(updated_body.to_owned(), updated_html.to_owned())
        .send()
        .await?;

    Retry::spawn(retry_strategy.clone(), || async {
        if comments_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let comments = comments_manager.comments().await?;
    assert_eq!(comments.len(), 1);
    let comment = &comments[0];

    Retry::spawn(retry_strategy.clone(), || async {
        let edited_comment = comment.refresh().await?;
        if edited_comment.content().body != updated_body {
            bail!("Update not yet received");
        }
        Ok(())
    })
    .await?;

    let deletable = comment.can_redact().await?;
    assert!(deletable, "my comment should be deletable");
    let reason = "This is test redaction";
    let redact_id = space
        .redact_content(comment_id.to_string(), Some(reason.to_owned()))
        .await?;

    Retry::spawn(retry_strategy, || async {
        if comments_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let ev = space.event(&redact_id, None).await?;
    let event_content = ev.kind.raw().deserialize_as::<RoomRedactionEvent>()?;
    let original = event_content
        .as_original()
        .context("Redaction event should get original event")?;
    assert_eq!(original.redacts, Some(comment_id));
    assert_eq!(original.content.reason.as_deref(), Some(reason));

    Ok(())
}

#[tokio::test]
async fn task_list_external_link() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, room_id) = random_user_with_random_space("tasks_smoketest").await?;

    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    Retry::spawn(retry_strategy, || async {
        user.space(room_id.to_string()).await
    })
    .await?;

    let space = user.space(room_id.to_string()).await?;

    assert_eq!(
        space.task_lists().await?.len(),
        0,
        "Why are there tasks in our fresh space!?!"
    );

    let task_list_id = space
        .task_list_draft()?
        .name("Starting up".to_owned())
        .send()
        .await?;

    let task_list_key = task_list_id.clone();

    let wait_for_space = space.clone();
    let task_list = wait_for(move || {
        let space = wait_for_space.clone();
        let task_list_key = task_list_key.clone();
        async move { Ok(space.task_list(task_list_key).await.ok()) }
    })
    .await?
    .expect("freshly created Task List couldn’t be found");

    // generate the external and internal links

    let ref_details = task_list.ref_details().await?;

    let internal_link = ref_details.generate_internal_link(false)?;
    let external_link = ref_details.generate_external_link().await?;

    let room_id = &task_list.room_id().to_string()[1..];
    let task_list_id = &task_list.event_id().to_string()[1..];

    let path = format!("o/{room_id}/taskList/{task_list_id}");

    assert_eq!(internal_link, format!("acter:{path}?via=localhost"));

    let ext_url = url::Url::parse(&external_link)?;
    assert_eq!(ext_url.fragment().expect("must have fragment"), &path);
    Ok(())
}
