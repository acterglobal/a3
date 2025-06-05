use anyhow::{bail, Result};
use chrono::{Duration, Utc};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::{random_users_with_random_space, random_users_with_random_space_under_template};

const TMPL: &str = r#"
version = "0.1"
name = "Event Notifications Setup Template"

[inputs]
main = { type = "user", is-default = true, required = true, description = "The starting user" }
space = { type = "space", is-default = true, required = true, description = "The main user" }

[objects.acter-event-1]
type = "calendar-event"
title = "First meeting"
utc_start = "{{ future(add_mins=1).as_rfc3339 }}"
utc_end = "{{ future(add_mins=60).as_rfc3339 }}"

"#;

#[tokio::test]
async fn event_creation_notification() -> Result<()> {
    let _ = env_logger::try_init();
    let (users, room_id) =
        random_users_with_random_space("event_creation_notifications", 1).await?;

    let mut user = users[0].clone();
    let mut second = users[1].clone();

    second.install_default_acter_push_rules().await?;

    let sync_state1 = user.start_sync();
    sync_state1.await_has_synced_history().await?;

    let sync_state2 = second.start_sync();
    sync_state2.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let main_space = Retry::spawn(retry_strategy, || async {
        let spaces = user.spaces().await?;
        if spaces.len() != 1 {
            bail!("space not found");
        }
        Ok(spaces.first().cloned().expect("space found"))
    })
    .await?;

    let space_on_second = second.room(main_space.room_id_str()).await?;
    space_on_second
        .set_notification_mode(Some("all".to_owned()))
        .await?; // we want to see push for everything;

    let mut draft = main_space.calendar_event_draft()?;
    draft.title("First meeting".to_owned());
    let now = Utc::now();
    let utc_start = now + Duration::days(1);
    let utc_end = now + Duration::days(2);
    draft.utc_start_from_rfc3339(utc_start.to_rfc3339())?;
    draft.utc_end_from_rfc3339(utc_end.to_rfc3339())?;
    let event_id = draft.send().await?;
    tracing::trace!("draft sent event id: {}", event_id);

    let notifications = second
        .get_notification_item(room_id.to_string(), event_id.to_string())
        .await?;

    assert_eq!(notifications.push_style(), "creation");
    assert_eq!(notifications.target_url(), format!("/events/{event_id}"));
    let parent = notifications.parent().expect("parent should be available");
    assert_eq!(parent.type_str(), "event");
    assert_eq!(parent.title().as_deref(), Some("First meeting"));
    assert_eq!(parent.emoji(), "🗓️"); // calendar icon
    assert_eq!(parent.object_id_str(), event_id);

    Ok(())
}

#[tokio::test]
async fn event_title_update() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("eventTitleUpdate", 1, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let obj_entry = Retry::spawn(retry_strategy, || async {
        let entries = second_user.calendar_events().await?;
        if entries.is_empty() {
            bail!("entries not found");
        }
        Ok(entries[0].clone())
    })
    .await?;

    // we want to see push for everything;
    first
        .room(obj_entry.room_id_str())
        .await?
        .set_notification_mode(Some("all".to_owned()))
        .await?;

    let mut update = obj_entry.update_builder()?;
    update.title("Renamed Event".to_owned());
    let notification_ev = update.send().await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "titleChange");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in change"),
        obj_entry.event_id()
    );

    assert_eq!(notification_item.title(), "Renamed Event"); // new title
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!("/events/{}", obj_entry.event_id())
    );
    assert_eq!(parent.type_str(), "event");
    // assert_eq!(parent.title().as_deref(), Some("First Meeting")); // old name
    assert_eq!(parent.emoji(), "🗓️"); // calendar icon
    assert_eq!(parent.object_id_str(), obj_entry.event_id());

    Ok(())
}

#[tokio::test]
async fn event_desc_update() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("eventDescUpdate", 1, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let obj_entry = Retry::spawn(retry_strategy, || async {
        let entries = second_user.calendar_events().await?;
        if entries.is_empty() {
            bail!("entries not found");
        }
        Ok(entries[0].clone())
    })
    .await?;

    // we want to see push for everything;
    first
        .room(obj_entry.room_id_str())
        .await?
        .set_notification_mode(Some("all".to_owned()))
        .await?;

    let mut update = obj_entry.update_builder()?;
    update.description_text("Added content".to_owned());
    let notification_ev = update.send().await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "descriptionChange");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in event"),
        obj_entry.event_id()
    );

    let content = notification_item.body().expect("found content");
    assert_eq!(content.body(), "Added content"); // new description
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!("/events/{}", obj_entry.event_id())
    );
    assert_eq!(parent.type_str(), "event");
    assert_eq!(parent.title().as_deref(), Some("First meeting"));
    assert_eq!(parent.emoji(), "🗓️"); // calendar icon
    assert_eq!(parent.object_id_str(), obj_entry.event_id());

    Ok(())
}

#[tokio::test]
async fn event_rescheduled() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("eventDescUpdate", 1, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let obj_entry = Retry::spawn(retry_strategy, || async {
        let entries = second_user.calendar_events().await?;
        if entries.is_empty() {
            bail!("entries not found");
        }
        Ok(entries[0].clone())
    })
    .await?;

    // we want to see push for everything;
    first
        .room(obj_entry.room_id_str())
        .await?
        .set_notification_mode(Some("all".to_owned()))
        .await?;

    let now = Utc::now();
    let utc_start = now + Duration::days(1);
    let utc_end = now + Duration::days(2);
    let mut update = obj_entry.update_builder()?;
    update.utc_start_from_rfc3339(utc_start.to_rfc3339())?;
    update.utc_end_from_rfc3339(utc_end.to_rfc3339())?;
    let notification_ev = update.send().await?;

    let notification_item = first
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "eventDateChange");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in event"),
        obj_entry.event_id()
    );

    assert_eq!(notification_item.new_date(), Some(utc_start));
    assert_eq!(notification_item.title(), utc_start.to_rfc3339());
    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(
        notification_item.target_url(),
        format!("/events/{}", obj_entry.event_id())
    );
    assert_eq!(parent.type_str(), "event");
    assert_eq!(parent.title().as_deref(), Some("First meeting"));
    assert_eq!(parent.emoji(), "🗓️"); // calendar icon
    assert_eq!(parent.object_id_str(), obj_entry.event_id());

    Ok(())
}

#[tokio::test]
async fn event_rsvp() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("eventDescUpdate", 1, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let obj_entry = Retry::spawn(retry_strategy, || async {
        let entries = second_user.calendar_events().await?;
        if entries.is_empty() {
            bail!("entries not found");
        }
        Ok(entries[0].clone())
    })
    .await?;

    // we want to see push for everything;
    first
        .room(obj_entry.room_id_str())
        .await?
        .set_notification_mode(Some("all".to_owned()))
        .await?;

    let rsvp_manager = obj_entry.rsvps().await?;
    // test yes
    {
        let mut rsvp = rsvp_manager.rsvp_draft()?;
        rsvp.status("yes".to_owned());

        let notification_ev = rsvp.send().await?;

        let notification_item = first
            .get_notification_item(space_id.to_string(), notification_ev.to_string())
            .await?;
        assert_eq!(notification_item.push_style(), "rsvpYes");
        assert_eq!(
            notification_item
                .parent_id_str()
                .expect("parent is in event"),
            obj_entry.event_id()
        );

        let parent = notification_item.parent().expect("parent was found");
        assert_eq!(
            notification_item.target_url(),
            format!("/events/{}", obj_entry.event_id())
        );
        assert_eq!(parent.type_str(), "event");
        assert_eq!(parent.title().as_deref(), Some("First meeting"));
        assert_eq!(parent.emoji(), "🗓️"); // calendar icon
        assert_eq!(parent.object_id_str(), obj_entry.event_id());
    }

    // test no
    {
        let mut rsvp = rsvp_manager.rsvp_draft()?;
        rsvp.status("no".to_owned());

        let notification_ev = rsvp.send().await?;

        let notification_item = first
            .get_notification_item(space_id.to_string(), notification_ev.to_string())
            .await?;
        assert_eq!(notification_item.push_style(), "rsvpNo");
        assert_eq!(
            notification_item
                .parent_id_str()
                .expect("parent is in event"),
            obj_entry.event_id()
        );

        let parent = notification_item.parent().expect("parent was found");
        assert_eq!(
            notification_item.target_url(),
            format!("/events/{}", obj_entry.event_id())
        );
        assert_eq!(parent.type_str(), "event");
        assert_eq!(parent.title().as_deref(), Some("First meeting"));
        assert_eq!(parent.emoji(), "🗓️"); // calendar icon
        assert_eq!(parent.object_id_str(), obj_entry.event_id());
    }

    // test no
    {
        let mut rsvp = rsvp_manager.rsvp_draft()?;
        rsvp.status("maybe".to_owned());

        let notification_ev = rsvp.send().await?;

        let notification_item = first
            .get_notification_item(space_id.to_string(), notification_ev.to_string())
            .await?;
        assert_eq!(notification_item.push_style(), "rsvpMaybe");
        assert_eq!(
            notification_item
                .parent_id_str()
                .expect("parent is in event"),
            obj_entry.event_id()
        );

        let parent = notification_item.parent().expect("parent was found");
        assert_eq!(
            notification_item.target_url(),
            format!("/events/{}", obj_entry.event_id())
        );
        assert_eq!(parent.type_str(), "event");
        assert_eq!(parent.title().as_deref(), Some("First meeting"));
        assert_eq!(parent.emoji(), "🗓️"); // calendar icon
        assert_eq!(parent.object_id_str(), obj_entry.event_id());
    }

    Ok(())
}

#[ignore]
#[tokio::test]
async fn event_redaction() -> Result<()> {
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("eventRedaction", 1, TMPL).await?;

    let first = users.first().expect("exists");
    let second_user = &users[1];

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let event = Retry::spawn(retry_strategy, || async {
        let entries = first.calendar_events().await?;
        if entries.is_empty() {
            bail!("entries not found");
        }
        Ok(entries[0].clone())
    })
    .await?;

    // we want to see push for everything;
    second_user
        .room(event.room_id_str())
        .await?
        .set_notification_mode(Some("all".to_owned()))
        .await?;

    let space = first.space(event.room_id().to_string()).await?;
    let notification_ev = space.redact(&event.event_id(), None, None).await?.event_id;

    let notification_item = second_user
        .get_notification_item(space_id.to_string(), notification_ev.to_string())
        .await?;
    assert_eq!(notification_item.push_style(), "redaction");
    assert_eq!(
        notification_item
            .parent_id_str()
            .expect("parent is in redaction"),
        event.event_id()
    );

    let parent = notification_item.parent().expect("parent was found");
    assert_eq!(notification_item.target_url(), "/events/");
    assert_eq!(parent.type_str(), "event");
    assert_eq!(parent.title().as_deref(), Some("First Meeting"));
    assert_eq!(parent.emoji(), "🗓️"); // calendar icon
    assert_eq!(parent.object_id_str(), event.event_id());

    Ok(())
}
