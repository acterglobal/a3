use acter::testing::wait_for;
use anyhow::{bail, Result};
use futures::stream::StreamExt;
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
async fn rsvp_smoketest() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, _sync_state, _engine) = random_user_with_template("rsvp-smoke-", TMPL).await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        async move {
            if client.calendar_events().await?.len() != 3 {
                bail!("not all calendar_events found");
            } else {
                Ok(())
            }
        }
    })
    .await?;

    let events = user.calendar_events().await?;
    assert_eq!(events.len(), 3);

    let rsvp_manager = events[0].rsvp_manager().await?;
    let rsvp_listener = rsvp_manager.subscribe();
    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);

    let rsvp_1_id = rsvp_manager
        .rsvp_draft()?
        .status("Yes".to_string())
        .send()
        .await?;

    Retry::spawn(retry_strategy.clone(), || async {
        if rsvp_listener.is_empty() {
            bail!("all still empty");
        };
        Ok(())
    })
    .await?;

    let entries = rsvp_manager.entries().await?;
    assert_eq!(entries.len(), 1);
    assert_eq!(entries[0].status(), "Yes");

    let rsvp_listener = rsvp_manager.subscribe();
    let rsvp_2_id = rsvp_manager
        .rsvp_draft()?
        .status("No".to_string())
        .send()
        .await?;

    Retry::spawn(retry_strategy.clone(), || async {
        if rsvp_listener.is_empty() {
            bail!("all still empty");
        };
        Ok(())
    })
    .await?;

    let entries = rsvp_manager.entries().await?;
    assert_eq!(entries.len(), 2);
    assert_eq!(entries[1].status(), "No");

    Ok(())
}
