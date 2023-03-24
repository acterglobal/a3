use anyhow::Result;
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

[objects.acter-website-pin]
type = "pin"
title = "Acter Website"
url = "https://acter.global"

[objects.acter-source-pin]
type = "pin"
title = "Acter Source Code"
url = "https://github.com/acterglobal/a3"

[objects.example-data-pin]
type = "pin"
title = "Acter example pin"
content = { body = "example pin data" }
"#;

#[tokio::test]
async fn pins_smoketest() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, _sync_state, _engine) = random_user_with_template("pins-smoke-", TMPL).await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        async move {
            if client.pins().await?.len() != 3 {
                anyhow::bail!("not all pins found");
            } else {
                Ok(())
            }
        }
    })
    .await?;

    assert_eq!(user.pins().await?.len(), 3);
    assert_eq!(user.pinned_links().await?.len(), 2);

    let spaces = user.spaces().await?;
    assert_eq!(spaces.len(), 1);

    let main_space = spaces.first().unwrap();
    assert_eq!(main_space.pins().await?.len(), 3);
    assert_eq!(main_space.pinned_links().await?.len(), 2);
    Ok(())
}
