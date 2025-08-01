use anyhow::{bail, Result};
use chrono::{Duration, Utc};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use super::{assert_latest_activity, get_latest_activity};
use crate::utils::random_user_with_template;

const TMPL: &str = r#"
version = "0.1"
name = "Smoketest Template"

[inputs]
main = { type = "user", is-default = true, required = true, description = "The starting user" }

[objects]
main_space = { type = "space", is-default = true, name = "{{ main.display_name }}’s calendar event test space" }

[objects.acter-event-1]
type = "calendar-event"
title = "Onboarding on Acter"
utc_start = "{{ future(add_mins=1).as_rfc3339 }}"
utc_end = "{{ future(add_mins=60).as_rfc3339 }}"
"#;

#[tokio::test]
async fn calendar_creation_activity() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) = random_user_with_template("cal_event_creation", TMPL).await?;
    sync_state.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    Retry::spawn(retry_strategy, || async {
        if user.calendar_events().await?.len() != 1 {
            bail!("not all calendar_events found");
        }
        Ok(())
    })
    .await?;

    assert_eq!(user.calendar_events().await?.len(), 1);
    let activities = user.all_activities()?;

    let spaces = user.spaces().await?;
    assert_eq!(spaces.len(), 1);

    let main_space = spaces.first().expect("main space should be available");
    assert_eq!(main_space.calendar_events().await?.len(), 1);

    let activity = get_latest_activity(&user, main_space.room_id().to_string(), "creation").await?;
    assert_eq!(activity.type_str(), "creation");
    let object = activity.object().expect("we have an object");
    assert_eq!(object.type_str(), "event");
    assert_eq!(object.title().as_deref(), Some("Onboarding on Acter"));

    assert_latest_activity(&activities, activity.event_id_str()).await?;

    Ok(())
}

#[tokio::test]
async fn calendar_update_start_activity() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) =
        random_user_with_template("cal_event_update_start", TMPL).await?;
    sync_state.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = user.clone();
    let cal_events = Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        async move {
            let cal_events = client.calendar_events().await?;
            if cal_events.len() != 1 {
                bail!("not all calendar_events found");
            }
            Ok(cal_events)
        }
    })
    .await?;

    assert_eq!(cal_events.len(), 1);
    let activities = user.all_activities()?;

    let cal_event = cal_events.first().unwrap();
    let cal_updater = cal_event.subscribe();

    let now = Utc::now();
    let utc_start = now + Duration::minutes(10);
    let mut builder = cal_event.update_builder()?;
    builder.utc_start_from_rfc3339(utc_start.to_rfc3339())?;
    let event_id = builder.send().await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy, || async {
        if cal_updater.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let activity = user.activity(event_id.to_string()).await?;
    assert_eq!(activity.type_str(), "eventDateChange");
    assert_eq!(
        activity
            .date_time_range_content()
            .and_then(|c| c.start_new_val()),
        Some(utc_start.clone())
    );
    assert_eq!(
        activity
            .date_time_range_content()
            .and_then(|c| c.end_new_val()),
        None
    );

    let object = activity.object().expect("we have an object");
    assert_eq!(object.type_str(), "event");
    assert_eq!(object.utc_start(), Some(utc_start));

    assert_latest_activity(&activities, activity.event_id_str()).await?;

    Ok(())
}

#[tokio::test]
async fn calendar_update_end_activity() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) =
        random_user_with_template("cal_event_update_end", TMPL).await?;
    sync_state.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = user.clone();
    let cal_events = Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        async move {
            let cal_events = client.calendar_events().await?;
            if cal_events.len() != 1 {
                bail!("not all calendar_events found");
            }
            Ok(cal_events)
        }
    })
    .await?;

    assert_eq!(cal_events.len(), 1);
    let activities = user.all_activities()?;

    let cal_event = cal_events.first().unwrap();
    let cal_updater = cal_event.subscribe();

    let now = Utc::now();
    let utc_end = now + Duration::days(1);
    let mut builder = cal_event.update_builder()?;
    builder.utc_end_from_rfc3339(utc_end.to_rfc3339())?;
    let event_id = builder.send().await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy, || async {
        if cal_updater.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let activity = user.activity(event_id.to_string()).await?;
    assert_eq!(activity.type_str(), "eventDateChange");
    assert_eq!(
        activity
            .date_time_range_content()
            .and_then(|c| c.start_new_val()),
        None
    );
    assert_eq!(
        activity
            .date_time_range_content()
            .and_then(|c| c.end_new_val()),
        Some(utc_end.clone())
    );

    let object = activity.object().expect("we have an object");
    assert_eq!(object.type_str(), "event");
    assert_eq!(object.utc_end(), Some(utc_end));

    assert_latest_activity(&activities, activity.event_id_str()).await?;

    Ok(())
}

#[tokio::test]
async fn calendar_update_start_end_activity() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) =
        random_user_with_template("cal_event_update_start_end", TMPL).await?;
    sync_state.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = user.clone();
    let cal_events = Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        async move {
            let cal_events = client.calendar_events().await?;
            if cal_events.len() != 1 {
                bail!("not all calendar_events found");
            }
            Ok(cal_events)
        }
    })
    .await?;

    assert_eq!(cal_events.len(), 1);
    let activities = user.all_activities()?;

    let cal_event = cal_events.first().unwrap();
    let cal_updater = cal_event.subscribe();

    let now = Utc::now();
    let utc_start = now + Duration::days(1);
    let utc_end = now + Duration::days(2);
    let mut builder = cal_event.update_builder()?;
    builder.utc_start_from_rfc3339(utc_start.to_rfc3339())?;
    builder.utc_end_from_rfc3339(utc_end.to_rfc3339())?;
    let event_id = builder.send().await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy, || async {
        if cal_updater.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let activity = user.activity(event_id.to_string()).await?;
    assert_eq!(activity.type_str(), "eventDateChange");
    assert_eq!(
        activity
            .date_time_range_content()
            .and_then(|c| c.start_new_val()),
        Some(utc_start.clone())
    );
    assert_eq!(
        activity
            .date_time_range_content()
            .and_then(|c| c.end_new_val()),
        Some(utc_end.clone())
    );

    let object = activity.object().expect("we have an object");
    assert_eq!(object.type_str(), "event");
    assert!(object.description().is_none());
    assert_eq!(object.utc_start(), Some(utc_start));
    assert_eq!(object.utc_end(), Some(utc_end));
    assert!(object.due_date().is_none());

    assert_latest_activity(&activities, activity.event_id_str()).await?;

    Ok(())
}

#[tokio::test]
async fn calendar_update_description() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) =
        random_user_with_template("cal_event_update_description", TMPL).await?;
    sync_state.await_has_synced_history().await?;

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
    let cal_events = Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        async move {
            let cal_events = client.calendar_events().await?;
            if cal_events.len() != 1 {
                bail!("not all calendar_events found");
            }
            Ok(cal_events)
        }
    })
    .await?;

    assert_eq!(cal_events.len(), 1);
    let activities = user.all_activities()?;

    let cal_event = cal_events.first().unwrap();
    let cal_updater = cal_event.subscribe();

    // set up the description
    let desc_text = "This is test calendar event";
    cal_event
        .update_builder()?
        .description_text(desc_text.to_owned())
        .send()
        .await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy.clone(), || async {
        if cal_updater.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let activity =
        get_latest_activity(&user, main_space.room_id().to_string(), "descriptionChange").await?;
    assert_eq!(activity.type_str(), "descriptionChange");
    assert_eq!(
        activity
            .description_content()
            .map(|c| c.change())
            .as_deref(),
        Some("Changed")
    );

    let object = activity.object().expect("we have an object");
    assert_eq!(object.type_str(), "event");
    assert_eq!(
        object.description().map(|c| c.body).as_deref(),
        Some(desc_text)
    );

    // again, acquire cal event updater so that we can check for description deletion
    let cal_events = user.calendar_events().await?;
    let cal_event = cal_events.first().unwrap();
    let cal_updater = cal_event.subscribe();

    // delete the description
    cal_event
        .update_builder()?
        .unset_description()
        .send()
        .await?;

    Retry::spawn(retry_strategy, || async {
        if cal_updater.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let activity =
        get_latest_activity(&user, main_space.room_id().to_string(), "descriptionChange").await?;
    assert_eq!(activity.type_str(), "descriptionChange");
    assert_eq!(
        activity
            .description_content()
            .map(|c| c.change())
            .as_deref(),
        Some("Unset")
    );

    let object = activity.object().expect("we have an object");
    assert_eq!(object.type_str(), "event");
    assert_eq!(object.description().map(|c| c.body).as_deref(), None);

    assert_latest_activity(&activities, activity.event_id_str()).await?;

    Ok(())
}
