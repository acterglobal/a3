use anyhow::{bail, Result};
use chrono::{Duration, Utc};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::{random_user_with_template, random_users_with_random_space_under_template};

const THREE_EVENTS_TMPL: &str = r#"
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
locations = [
  { type = "Physical", name = "Denver University" },
  { type = "Virtual", uri = "mxc://acter.global/test", name = "Tech Test Channel" }
]
"#;

#[tokio::test]
async fn calendar_smoketest() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) =
        random_user_with_template("calendar_smoke", THREE_EVENTS_TMPL).await?;
    sync_state.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
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

    assert_eq!(user.calendar_events().await?.len(), 3);

    let spaces = user.spaces().await?;
    assert_eq!(spaces.len(), 1);
    let main_space = spaces.first().expect("main space should be available");

    let cal_events = main_space.calendar_events().await?;
    assert_eq!(cal_events.len(), 3);
    let main_event = cal_events.first().expect("main event should be available");

    let locations = main_event.locations();
    assert_eq!(locations.len(), 2);
    assert_eq!(locations[0].location_type(), "Physical");
    assert_eq!(locations[0].name().as_deref(), Some("Denver University"));
    assert_eq!(locations[1].location_type(), "Virtual");
    assert_eq!(locations[1].name().as_deref(), Some("Tech Test Channel"));

    Ok(())
}

#[tokio::test]
async fn edit_calendar_event() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) =
        random_user_with_template("calendar_smoke", THREE_EVENTS_TMPL).await?;
    sync_state.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            if client.calendar_events().await?.len() != 3 {
                bail!("not all calendar_events found");
            }
            Ok(())
        }
    })
    .await?;

    let cal_events = user.calendar_events().await?;
    assert_eq!(cal_events.len(), 3);

    let main_event = cal_events.first().expect("main event should be available");

    let subscriber = main_event.subscribe();

    let title = "Onboarding on Acter1";
    main_event
        .update_builder()?
        .title(title.to_owned())
        .send()
        .await?;

    let cal_event = main_event.clone();

    Retry::spawn(retry_strategy.clone(), || async {
        if subscriber.is_empty() {
            bail!("not been alerted to reload");
        }
        Ok(())
    })
    .await?;

    Retry::spawn(retry_strategy, move || {
        let cal_event = cal_event.clone();
        async move {
            let edited_event = cal_event.refresh().await?;
            if edited_event.title() != title {
                bail!("Update not yet received");
            }
            Ok(())
        }
    })
    .await?;

    Ok(())
}

#[tokio::test]
async fn calendar_event_external_link() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) =
        random_user_with_template("calendar_links", THREE_EVENTS_TMPL).await?;
    sync_state.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
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

    let cal_events = user.calendar_events().await?;
    assert_eq!(cal_events.len(), 3);

    let event = cal_events.first().expect("first event should be available");

    // generate the external and internal links

    let ref_details = event.ref_details().await?;

    let internal_link = ref_details.generate_internal_link(false)?;
    let external_link = ref_details.generate_external_link().await?;

    let room_id = &event.room_id().to_string()[1..];
    let event_id = &event.event_id().to_string()[1..];

    let path = format!("o/{room_id}/calendarEvent/{event_id}");

    assert_eq!(internal_link, format!("acter:{path}?via=localhost"));

    let ext_url = url::Url::parse(&external_link)?;
    assert_eq!(ext_url.fragment().expect("must have fragment"), &path);
    Ok(())
}

const TMPL: &str = r#"
version = "0.1"
name = "Smoketest Template"

[inputs]
main = { type = "user", is-default = true, required = true, description = "The starting user" }

[objects.main_space]
type = "space"
name = "{{ main.display_name }}’s main test space"
"#;

#[tokio::test]
async fn calendar_event_create() -> Result<()> {
    let _ = env_logger::try_init();
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("calendar_create", 1, TMPL).await?;

    let user = users.first().expect("exists");

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = user.clone();
    let target_id = space_id.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.space(room_id.to_string()).await }
    })
    .await?;

    let space = user.space(space_id.to_string()).await?;
    let mut draft = space.calendar_event_draft()?;
    let title = "First meeting";
    draft.title(title.to_owned());
    let now = Utc::now();
    let utc_start = now + Duration::days(1);
    let utc_end = now + Duration::days(2);
    draft.utc_start_from_rfc3339(utc_start.to_rfc3339())?;
    draft.utc_end_from_rfc3339(utc_end.to_rfc3339())?;

    let name = "Test Location";
    let description = "Philadelphia Office";
    let description_html = "**Here is our office**";
    let coordinates = "geo:51.5074,-0.1278";
    let uri = "https://example.com/location";
    let address = "123 Test St, Philadelphia, PA 19103";
    let notes = "Please bring your laptop.";
    draft.physical_location(
        Some(name.to_owned()),
        Some(description.to_owned()),
        Some(description_html.to_owned()),
        Some(coordinates.to_owned()),
        Some(uri.to_owned()),
        Some(address.to_owned()),
        Some(notes.to_owned()),
    )?;
    draft.virtual_location(
        Some(name.to_owned()),
        Some(description.to_owned()),
        Some(description_html.to_owned()),
        uri.to_owned(),
        Some(address.to_owned()),
        Some(notes.to_owned()),
    )?;

    let event_id = draft.send().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    let cal_events = Retry::spawn(retry_strategy, || async {
        let cal_events = space.calendar_events().await?;
        if cal_events.len() != 1 {
            bail!("not all calendar_events found");
        }
        Ok(cal_events)
    })
    .await?;
    assert_eq!(cal_events.len(), 1);
    let main_event = cal_events.first().expect("main event should be available");

    assert_eq!(main_event.event_id(), event_id);
    assert_eq!(main_event.title(), title);
    let locations = main_event.locations();
    assert_eq!(locations.len(), 2);

    assert_eq!(locations[0].location_type(), "Physical");
    assert_eq!(locations[0].name().as_deref(), Some(name));
    assert_eq!(
        locations[0].description().map(|d| d.body()).as_deref(),
        Some(description)
    );
    assert_eq!(
        locations[0]
            .description()
            .and_then(|d| d.formatted())
            .as_deref(),
        Some(description_html)
    );
    assert_eq!(locations[0].coordinates().as_deref(), Some(coordinates));
    assert_eq!(locations[0].uri().as_deref(), Some(uri));
    assert_eq!(locations[0].address().as_deref(), Some(address));
    assert_eq!(locations[0].notes().as_deref(), Some(notes));

    assert_eq!(locations[1].location_type(), "Virtual");
    assert_eq!(locations[1].name().as_deref(), Some(name));
    assert_eq!(
        locations[1].description().map(|d| d.body()).as_deref(),
        Some(description)
    );
    assert_eq!(
        locations[1]
            .description()
            .and_then(|d| d.formatted())
            .as_deref(),
        Some(description_html)
    );
    assert_eq!(locations[1].uri().as_deref(), Some(uri));
    assert_eq!(locations[1].address().as_deref(), Some(address));
    assert_eq!(locations[1].notes().as_deref(), Some(notes));

    Ok(())
}
