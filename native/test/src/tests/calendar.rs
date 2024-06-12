use anyhow::{bail, Result};
use tokio::time::{sleep, Duration};
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
main_space = { type = "space", is-default = true, name = "{{ main.display_name }}'s pins test space"}

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
async fn calendar_smoketest() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, _sync_state, _engine) = random_user_with_template("calendar_smoke", TMPL).await?;

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

    assert_eq!(user.calendar_events().await?.len(), 3);

    let spaces = user.spaces().await?;
    assert_eq!(spaces.len(), 1);

    let main_space = spaces.first().unwrap();
    assert_eq!(main_space.calendar_events().await?.len(), 3);
    Ok(())
}

#[tokio::test]
async fn edit_calendar_event() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, _sync_state, _engine) = random_user_with_template("calendar_smoke", TMPL).await?;

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

    let cal_events = user.calendar_events().await?;
    assert_eq!(cal_events.len(), 3);

    let mut cal_update = cal_events[0].subscribe();

    let mut builder = cal_events[0].update_builder()?;
    builder.title("Onboarding on Acter1".to_owned());
    builder.send().await?;

    let mut remaining = 4;
    loop {
        if remaining == 0 {
            bail!("even after 3 seconds, no calendar event update has been reported");
        }
        remaining -= 1;

        if cal_update.try_recv().is_ok() {
            break;
        }

        sleep(Duration::from_secs(1)).await;
    }

    let edited_event = cal_events[0].refresh().await?;
    assert_eq!(edited_event.title(), "Onboarding on Acter1");

    Ok(())
}
