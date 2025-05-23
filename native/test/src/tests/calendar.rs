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
    let (user, sync_state, _engine) = random_user_with_template("calendar_smoke", TMPL).await?;
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
    let (user, sync_state, _engine) = random_user_with_template("calendar_smoke", TMPL).await?;
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

    let mut builder = main_event.update_builder()?;
    builder.title("Onboarding on Acter1".to_owned());
    builder.send().await?;

    let cal_event = main_event.clone();

    Retry::spawn(retry_strategy.clone(), || async {
        if subscriber.is_empty() {
            bail!("not been alerted to reload");
        }
        Ok(())
    })
    .await?;

    Retry::spawn(retry_strategy.clone(), move || {
        let cal_event = cal_event.clone();
        async move {
            let edited_event = cal_event.refresh().await?;
            if edited_event.title() != "Onboarding on Acter1" {
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
    let (user, sync_state, _engine) = random_user_with_template("calendar_links", TMPL).await?;
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
