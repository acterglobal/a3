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
title = "Onboarding on Acter1"
utc_start = "{{ future(add_mins=1).as_rfc3339 }}"
utc_end = "{{ future(add_mins=60).as_rfc3339 }}"

[objects.acter-event-2]
type = "calendar-event"
title = "Onboarding on Acter2"
utc_start = "{{ future(add_days=1).as_rfc3339 }}"
utc_end = "{{ future(add_days=7).as_rfc3339 }}"

[objects.acter-event-3]
type = "calendar-event"
title = "Onboarding on Acter3"
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
    Retry::spawn(retry_strategy, || async {
        if user.calendar_events().await?.len() != 3 {
            bail!("not all calendar_events found");
        }
        Ok(())
    })
    .await?;

    assert_eq!(user.calendar_events().await?.len(), 3);

    let spaces = user.spaces().await?;
    assert_eq!(spaces.len(), 1);
    let main_space = spaces.first().expect("main space should be available");

    let cal_events = main_space.calendar_events().await?;
    assert_eq!(cal_events.len(), 3);
    let main_event = cal_events.first().expect("main event should be available");
    assert_eq!(main_event.title(), "Onboarding on Acter3");

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
    Retry::spawn(retry_strategy.clone(), || async {
        if user.calendar_events().await?.len() != 3 {
            bail!("not all calendar_events found");
        }
        Ok(())
    })
    .await?;

    let cal_events = user.calendar_events().await?;
    assert_eq!(cal_events.len(), 3);

    let main_event = cal_events.last().expect("main event should be available");
    assert_eq!(main_event.title(), "Onboarding on Acter1");
    assert!(main_event.description().is_none());
    assert!(main_event.locations().is_empty());
    assert!(main_event.physical_locations().is_empty());
    assert!(main_event.virtual_locations().is_empty());

    let subscriber = main_event.subscribe();

    // will add title & locations
    let title = "Onboarding on Acter1 - new";

    let loc_name = "Test Location";
    let loc_desc_text = "Philadelphia Office";
    let loc_desc_html = "**Here is our office**";
    let loc_coord = "geo:51.5074,-0.1278";
    let loc_uri = "https://example.com/location";
    let loc_addr = "123 Test St, Philadelphia, PA 19103";
    let loc_notes = "Please bring your laptop.";

    main_event
        .update_builder()?
        .title(title.to_owned())
        .description_text("Here is the description".to_owned())
        .unset_description_update()
        .add_physical_location(
            Some(loc_name.to_owned()),
            Some(loc_desc_text.to_owned()),
            Some(loc_desc_html.to_owned()),
            Some(loc_coord.to_owned()),
            Some(loc_uri.to_owned()),
            Some(loc_addr.to_owned()),
            Some(loc_notes.to_owned()),
        )
        .add_virtual_location(
            Some(loc_name.to_owned()),
            Some(loc_desc_text.to_owned()),
            Some(loc_desc_html.to_owned()),
            loc_uri.to_owned(),
            Some(loc_notes.to_owned()),
        )
        .send()
        .await?;

    Retry::spawn(retry_strategy.clone(), || async {
        if subscriber.is_empty() {
            bail!("not been alerted to reload");
        }
        Ok(())
    })
    .await?;

    let edited_event =
        Retry::spawn(retry_strategy, || async { main_event.refresh().await }).await?;

    assert!(edited_event.description().is_none());
    assert_eq!(edited_event.locations().len(), 2);

    let phy_loc = edited_event.physical_locations();
    assert_eq!(phy_loc.len(), 1);
    assert_eq!(phy_loc[0].name().as_deref(), Some(loc_name));
    assert_eq!(
        phy_loc[0].description().map(|c| c.body()).as_deref(),
        Some(loc_desc_text)
    );
    assert_eq!(
        phy_loc[0]
            .description()
            .and_then(|c| c.formatted())
            .as_deref(),
        Some(loc_desc_html)
    );
    assert_eq!(phy_loc[0].coordinates().as_deref(), Some(loc_coord));
    assert_eq!(phy_loc[0].uri().as_deref(), Some(loc_uri));
    assert_eq!(phy_loc[0].address().as_deref(), Some(loc_addr));
    assert_eq!(phy_loc[0].notes().as_deref(), Some(loc_notes));

    let vir_loc = edited_event.virtual_locations();
    assert_eq!(vir_loc.len(), 1);
    assert_eq!(vir_loc[0].name().as_deref(), Some(loc_name));
    assert_eq!(
        vir_loc[0].description().map(|c| c.body()).as_deref(),
        Some(loc_desc_text)
    );
    assert_eq!(
        vir_loc[0]
            .description()
            .and_then(|c| c.formatted())
            .as_deref(),
        Some(loc_desc_html)
    );
    assert_eq!(vir_loc[0].uri().as_deref(), Some(loc_uri));
    assert_eq!(vir_loc[0].notes().as_deref(), Some(loc_notes));

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
    Retry::spawn(retry_strategy, || async {
        if user.calendar_events().await?.len() != 3 {
            bail!("not all calendar_events found");
        }
        Ok(())
    })
    .await?;

    let cal_events = user.calendar_events().await?;
    assert_eq!(cal_events.len(), 3);

    let event = cal_events.first().expect("first event should be available");
    assert_eq!(event.title(), "Onboarding on Acter3");

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

    let user = users[0].clone();

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let space = Retry::spawn(retry_strategy, || async {
        user.space(space_id.to_string()).await
    })
    .await?;

    let title = "First meeting";
    let description = "This is tech channel";
    let now = Utc::now();
    let tomorrow = now + Duration::days(1);
    let overmorrow = now + Duration::days(2);

    let loc_name = "Test Location";
    let loc_desc_text = "Philadelphia Office";
    let loc_desc_html = "**Here is our office**";
    let loc_coord = "geo:51.5074,-0.1278";
    let loc_uri = "https://example.com/location";
    let loc_addr = "123 Test St, Philadelphia, PA 19103";
    let loc_notes = "Please bring your laptop.";

    let event_id = space
        .calendar_event_draft()?
        .title(title.to_owned())
        .description_text(description.to_owned())
        .utc_start_from_rfc3339(tomorrow.to_rfc3339())?
        .utc_end_from_rfc3339(overmorrow.to_rfc3339())?
        .add_physical_location(
            Some(loc_name.to_owned()),
            Some(loc_desc_text.to_owned()),
            Some(loc_desc_html.to_owned()),
            Some(loc_coord.to_owned()),
            Some(loc_uri.to_owned()),
            Some(loc_addr.to_owned()),
            Some(loc_notes.to_owned()),
        )
        .add_virtual_location(
            Some(loc_name.to_owned()),
            Some(loc_desc_text.to_owned()),
            Some(loc_desc_html.to_owned()),
            loc_uri.to_owned(),
            Some(loc_notes.to_owned()),
        )
        .send()
        .await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    let cal_events = Retry::spawn(retry_strategy.clone(), || async {
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
    assert_eq!(
        main_event.description().map(|c| c.body()).as_deref(),
        Some(description)
    );
    assert_eq!(main_event.utc_start().to_rfc3339(), tomorrow.to_rfc3339()); // truncate the decimal part from the timestamp so that assertion works
    assert_eq!(main_event.utc_end().to_rfc3339(), overmorrow.to_rfc3339()); // truncate the decimal part from the timestamp so that assertion works
    let locations = main_event.locations();
    assert_eq!(locations.len(), 2);

    assert_eq!(locations[0].location_type(), "Physical");
    assert_eq!(locations[0].name().as_deref(), Some(loc_name));
    assert_eq!(
        locations[0].description().map(|d| d.body()).as_deref(),
        Some(loc_desc_text)
    );
    assert_eq!(
        locations[0]
            .description()
            .and_then(|d| d.formatted())
            .as_deref(),
        Some(loc_desc_html)
    );
    assert_eq!(locations[0].coordinates().as_deref(), Some(loc_coord));
    assert_eq!(locations[0].uri().as_deref(), Some(loc_uri));
    assert_eq!(locations[0].address().as_deref(), Some(loc_addr));
    assert_eq!(locations[0].notes().as_deref(), Some(loc_notes));

    assert_eq!(locations[1].location_type(), "Virtual");
    assert_eq!(locations[1].name().as_deref(), Some(loc_name));
    assert_eq!(
        locations[1].description().map(|d| d.body()).as_deref(),
        Some(loc_desc_text)
    );
    assert_eq!(
        locations[1]
            .description()
            .and_then(|d| d.formatted())
            .as_deref(),
        Some(loc_desc_html)
    );
    assert_eq!(locations[1].uri().as_deref(), Some(loc_uri));
    assert_eq!(locations[1].address(), None);
    assert_eq!(locations[1].notes().as_deref(), Some(loc_notes));

    let subscriber = main_event.subscribe();

    let someday = now + Duration::days(10);

    // clear locations
    main_event
        .update_builder()?
        .unset_description()
        .utc_end_from_rfc3339(someday.to_rfc3339())?
        .unset_utc_end_update()
        .unset_locations()
        .send()
        .await?;

    Retry::spawn(retry_strategy.clone(), || async {
        if subscriber.is_empty() {
            bail!("not been alerted to reload");
        }
        Ok(())
    })
    .await?;

    let edited_event =
        Retry::spawn(retry_strategy, || async { main_event.refresh().await }).await?;

    assert!(edited_event.description().is_none());
    assert_ne!(edited_event.utc_end().to_rfc3339(), someday.to_rfc3339()); // truncate the decimal part from the timestamp so that assertion works
    assert_eq!(edited_event.utc_end().to_rfc3339(), overmorrow.to_rfc3339()); // truncate the decimal part from the timestamp so that assertion works
    assert!(edited_event.locations().is_empty());

    Ok(())
}

#[tokio::test]
async fn calendar_event_rfc2822() -> Result<()> {
    let _ = env_logger::try_init();
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("calendar_rfc2822", 1, TMPL).await?;

    let user = users[0].clone();

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let space = Retry::spawn(retry_strategy, || async {
        user.space(space_id.to_string()).await
    })
    .await?;

    let title = "First meeting";
    let now = Utc::now();
    let tomorrow = now + Duration::days(1);
    let overmorrow = now + Duration::days(2);

    let event_id = space
        .calendar_event_draft()?
        .title(title.to_owned())
        .utc_start_from_rfc2822(tomorrow.to_rfc2822())?
        .utc_end_from_rfc2822(overmorrow.to_rfc2822())?
        .send()
        .await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    let cal_events = Retry::spawn(retry_strategy.clone(), || async {
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
    assert_eq!(main_event.utc_start().to_rfc2822(), tomorrow.to_rfc2822()); // truncate the decimal part from the timestamp so that assertion works
    assert_eq!(main_event.utc_end().to_rfc2822(), overmorrow.to_rfc2822()); // truncate the decimal part from the timestamp so that assertion works

    let subscriber = main_event.subscribe();

    let someday = now + Duration::days(10);
    let otherday = now + Duration::days(15);

    main_event
        .update_builder()?
        .utc_start_from_rfc2822(someday.to_rfc2822())?
        .utc_end_from_rfc2822(otherday.to_rfc2822())?
        .send()
        .await?;

    Retry::spawn(retry_strategy.clone(), || async {
        if subscriber.is_empty() {
            bail!("not been alerted to reload");
        }
        Ok(())
    })
    .await?;

    let edited_event =
        Retry::spawn(retry_strategy, || async { main_event.refresh().await }).await?;

    assert_eq!(edited_event.utc_start().to_rfc2822(), someday.to_rfc2822()); // truncate the decimal part from the timestamp so that assertion works
    assert_eq!(edited_event.utc_end().to_rfc2822(), otherday.to_rfc2822()); // truncate the decimal part from the timestamp so that assertion works

    Ok(())
}

#[tokio::test]
async fn calendar_event_format() -> Result<()> {
    let _ = env_logger::try_init();
    let (users, _sync_states, space_id, _engine) =
        random_users_with_random_space_under_template("calendar_format", 1, TMPL).await?;

    let user = users[0].clone();

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let space = Retry::spawn(retry_strategy, || async {
        user.space(space_id.to_string()).await
    })
    .await?;

    let title = "First meeting";
    let fmt = "%Y-%m-%dT%H:%M:%S%:z"; // ISO 8601 format with timezone
    let now = Utc::now();
    let tomorrow = (now + Duration::days(1)).format(fmt).to_string();
    let overmorrow = (now + Duration::days(2)).format(fmt).to_string();

    let event_id = space
        .calendar_event_draft()?
        .title(title.to_owned())
        .utc_start_from_format(tomorrow.clone(), fmt.to_owned())?
        .utc_end_from_format(overmorrow.clone(), fmt.to_owned())?
        .send()
        .await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    let cal_events = Retry::spawn(retry_strategy.clone(), || async {
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
    assert_eq!(main_event.utc_start().format(fmt).to_string(), tomorrow);
    assert_eq!(main_event.utc_end().format(fmt).to_string(), overmorrow);

    let subscriber = main_event.subscribe();

    let someday = (now + Duration::days(10)).format(fmt).to_string();
    let otherday = (now + Duration::days(15)).format(fmt).to_string();

    main_event
        .update_builder()?
        .utc_start_from_format(someday.clone(), fmt.to_owned())?
        .utc_end_from_format(otherday.clone(), fmt.to_owned())?
        .send()
        .await?;

    Retry::spawn(retry_strategy.clone(), || async {
        if subscriber.is_empty() {
            bail!("not been alerted to reload");
        }
        Ok(())
    })
    .await?;

    let edited_event =
        Retry::spawn(retry_strategy, || async { main_event.refresh().await }).await?;

    assert_eq!(edited_event.utc_start().format(fmt).to_string(), someday); // truncate the decimal part from the timestamp so that assertion works
    assert_eq!(edited_event.utc_end().format(fmt).to_string(), otherday); // truncate the decimal part from the timestamp so that assertion works

    Ok(())
}
