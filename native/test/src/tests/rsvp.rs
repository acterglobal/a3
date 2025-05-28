use acter_core::events::rsvp::RsvpStatus;
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
main_space = { type = "space", is-default = true, name = "{{ main.display_name }}’s RSVP test space" }

[objects.acter-event-1]
type = "calendar-event"
title = "Onboarding on Acter"
utc_start = "{{ future(add_mins=1).as_rfc3339 }}"
utc_end = "{{ future(add_mins=60).as_rfc3339 }}"

[objects.acter-event-2]
type = "calendar-event"
title = "Onboarding on Acter"
utc_start = "{{ future(add_days=1).as_rfc3339 }}"
utc_end = "{{ future(add_days=7).as_rfc3339 }}"

[objects.acter-event-3]
type = "calendar-event"
title = "Onboarding on Acter"
utc_start = "{{ future(add_days=20).as_rfc3339 }}"
utc_end = "{{ future(add_days=25).as_rfc3339 }}"
"#;

#[tokio::test]
async fn rsvp_last_status() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) = random_user_with_template("rsvp_last_status", TMPL).await?;
    sync_state.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        async move {
            if client.calendar_events().await?.len() != 3 {
                bail!("not all calendar_events found");
            }
            Ok(())
        }
    })
    .await?;

    let events = user.calendar_events().await?;
    assert_eq!(events.len(), 3);

    let rsvp_manager = events[0].rsvps().await?;
    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);

    // send 1st RSVP
    let rsvp_listener = rsvp_manager.subscribe(); // call subscribe to get rsvp entries properly
    let _rsvp_1_id = rsvp_manager
        .rsvp_draft()?
        .status("yes".to_owned())
        .send()
        .await?;

    Retry::spawn(retry_strategy.clone(), || async {
        if rsvp_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let entries = rsvp_manager.rsvp_entries().await?;
    assert_eq!(entries.len(), 1);
    assert_eq!(entries[0].status(), "yes");

    // send 2nd RSVP
    let rsvp_listener = rsvp_manager.subscribe(); // call subscribe to get rsvp entries properly
    let _rsvp_2_id = rsvp_manager
        .rsvp_draft()?
        .status("no".to_owned())
        .send()
        .await?;

    Retry::spawn(retry_strategy, || async {
        if rsvp_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    // only last rsvp status of user is kept in hash map
    // all older statuses are ignored
    // user sent 2 rsvp responses, but only one entry will be kept
    let entries = rsvp_manager.rsvp_entries().await?;
    assert_eq!(entries.len(), 1);
    assert_eq!(entries[0].status(), "no");

    Ok(())
}

#[tokio::test]
async fn rsvp_my_status() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) = random_user_with_template("rsvp_my_status", TMPL).await?;
    sync_state.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        async move {
            if client.calendar_events().await?.len() != 3 {
                bail!("not all calendar_events found");
            }
            Ok(())
        }
    })
    .await?;

    let events = user.calendar_events().await?;
    assert_eq!(events.len(), 3);

    let rsvp_manager = events[0].rsvps().await?;
    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);

    // send 1st RSVP
    let rsvp_listener = rsvp_manager.subscribe(); // call subscribe to get rsvp entries properly
    let _rsvp_1_id = rsvp_manager
        .rsvp_draft()?
        .status("yes".to_owned())
        .send()
        .await?;

    Retry::spawn(retry_strategy.clone(), || async {
        if rsvp_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let entries = rsvp_manager.rsvp_entries().await?;
    assert_eq!(entries.len(), 1);
    assert_eq!(entries[0].status(), "yes");

    // send 2nd RSVP
    let rsvp_listener = rsvp_manager.subscribe(); // call subscribe to get rsvp entries properly
    let _rsvp_2_id = rsvp_manager
        .rsvp_draft()?
        .status("no".to_owned())
        .send()
        .await?;

    Retry::spawn(retry_strategy, || async {
        if rsvp_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    // only last rsvp status of user is kept in hash map
    // all older statuses are ignored
    // user sent 2 rsvp responses, but only one entry will be kept
    let entries = rsvp_manager.rsvp_entries().await?;
    assert_eq!(entries.len(), 1);
    assert_eq!(entries[0].status(), "no");

    // get last RSVP
    let last_status = rsvp_manager.responded_by_me().await?;
    assert_eq!(last_status.status(), Some(RsvpStatus::No));

    Ok(())
}

#[tokio::test]
async fn rsvp_count_at_status() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) =
        random_user_with_template("rsvp_count_at_status", TMPL).await?;
    sync_state.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        async move {
            if client.calendar_events().await?.len() != 3 {
                bail!("not all calendar_events found");
            }
            Ok(())
        }
    })
    .await?;

    let events = user.calendar_events().await?;
    assert_eq!(events.len(), 3);

    let rsvp_manager = events[0].rsvps().await?;
    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);

    // send 1st RSVP
    let rsvp_listener = rsvp_manager.subscribe(); // call subscribe to get rsvp entries properly
    let _rsvp_1_id = rsvp_manager
        .rsvp_draft()?
        .status("yes".to_owned())
        .send()
        .await?;

    Retry::spawn(retry_strategy.clone(), || async {
        if rsvp_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let entries = rsvp_manager.rsvp_entries().await?;
    assert_eq!(entries.len(), 1);
    assert_eq!(entries[0].status(), "yes");

    // send 2nd RSVP
    let rsvp_listener = rsvp_manager.subscribe(); // call subscribe to get rsvp entries properly
    let _rsvp_2_id = rsvp_manager
        .rsvp_draft()?
        .status("no".to_owned())
        .send()
        .await?;

    Retry::spawn(retry_strategy, || async {
        if rsvp_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    // only last rsvp status of user is kept in hash map
    // all older statuses are ignored
    // user sent 2 rsvp responses, but only one entry will be kept
    let entries = rsvp_manager.rsvp_entries().await?;
    assert_eq!(entries.len(), 1);
    assert_eq!(entries[0].status(), "no");

    // older rsvp would be ignored
    let count = rsvp_manager.count_at_status("yes".to_owned()).await?;
    assert_eq!(count, 0);

    Ok(())
}

#[tokio::test]
async fn rsvp_users_at_status() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) =
        random_user_with_template("rsvp-users-at-status-", TMPL).await?;
    sync_state.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        async move {
            if client.calendar_events().await?.len() != 3 {
                bail!("not all calendar_events found");
            }
            Ok(())
        }
    })
    .await?;

    let events = user.calendar_events().await?;
    assert_eq!(events.len(), 3);

    let rsvp_manager = events[0].rsvps().await?;
    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);

    // send 1st RSVP
    let rsvp_listener = rsvp_manager.subscribe(); // call subscribe to get rsvp entries properly
    let _rsvp_1_id = rsvp_manager
        .rsvp_draft()?
        .status("yes".to_owned())
        .send()
        .await?;

    Retry::spawn(retry_strategy.clone(), || async {
        if rsvp_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let entries = rsvp_manager.rsvp_entries().await?;
    assert_eq!(entries.len(), 1);
    assert_eq!(entries[0].status(), "yes");

    // send 2nd RSVP
    let rsvp_listener = rsvp_manager.subscribe(); // call subscribe to get rsvp entries properly
    let _rsvp_2_id = rsvp_manager
        .rsvp_draft()?
        .status("no".to_owned())
        .send()
        .await?;

    Retry::spawn(retry_strategy, || async {
        if rsvp_listener.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    // only last rsvp status of user is kept in hash map
    // all older statuses are ignored
    // user sent 2 rsvp responses, but only one entry will be kept
    let entries = rsvp_manager.rsvp_entries().await?;
    assert_eq!(entries.len(), 1);
    assert_eq!(entries[0].status(), "no");

    // get users at status
    let users = rsvp_manager.users_at_status("maybe".to_owned()).await?;
    assert_eq!(users.len(), 0);

    Ok(())
}
