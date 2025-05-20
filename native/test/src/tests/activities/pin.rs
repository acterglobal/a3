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
main_space = { type = "space", is-default = true, name = "{{ main.display_name }}’s pins test space" }

[objects.acter-website-pin]
type = "pin"
title = "Acter Website"
url = "https://acter.global"

"#;

#[tokio::test]
async fn pin_update_activity() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, sync_state, _engine) = random_user_with_template("pin_update", TMPL).await?;
    sync_state.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(30);
    let fetcher_client = user.clone();
    let pins = Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        async move {
            let pins = client.pins().await?;
            if pins.len() != 1 {
                bail!("not all pins found");
            }
            Ok(pins)
        }
    })
    .await?;

    assert_eq!(pins.len(), 1);

    let pin = pins.first().unwrap();

    let pin_updater = pin.subscribe();

    let desc_text = "This is test content of task".to_owned();
    let event_id = pin
        .update_builder()?
        .content_text(desc_text.clone())
        .send()
        .await?;

    let retry_strategy = FibonacciBackoff::from_millis(500).map(jitter).take(10);
    Retry::spawn(retry_strategy, || async {
        if pin_updater.is_empty() {
            bail!("all still empty");
        }
        Ok(())
    })
    .await?;

    let activity = user.activity(event_id.to_string()).await?;
    assert_eq!(activity.type_str(), "descriptionChange");
    assert_eq!(
        activity.description_content().and_then(|c| c.new_val()),
        Some(desc_text.clone())
    );

    let object = activity.object().expect("we have an object");
    assert_eq!(object.type_str(), "pin");
    assert_eq!(object.description().map(|c| c.body), Some(desc_text));
    assert!(object.utc_start().is_none());
    assert!(object.utc_end().is_none());
    assert!(object.due_date().is_none());

    Ok(())
}
