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
main_space = { type = "space", is-default = true, name = "{{ main.display_name }}'s test space"}
start_list = { type = "task-list", name = "{{ main.display_name }}'s Acter onboarding list" }

[objects.task_1]
type = "task"
title = "Scroll through the news"
assignees = ["{{ main.user_id }}"]
"m.relates_to" = { event_id = "{{ start_list.id }}" } 
utc_due = "{{ now().as_rfc3339 }}"

[objects.acter-website-pin]
type = "pin"
title = "Acter Website"
url = "https://acter.global"

[objects.acter-source-pin]
type = "pin"
title = "Acter Source Code"
url = "https://github.com/acterglobal/a3"

        "#;

#[tokio::test]
#[ignore = "test failed in github runner, it works well in local synapse :("]
async fn template_creates_space() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, _sync_state, _engine) = random_user_with_template("create-space-", TMPL).await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy, move || {
        let client = fetcher_client.clone();
        async move {
            if client.pins().await?.is_empty() {
                bail!("no pins found");
            } else {
                Ok(())
            }
        }
    })
    .await?;
    assert_eq!(user.pins().await?.len(), 2);
    assert_eq!(user.task_lists().await?.len(), 1);

    let spaces = user.spaces().await?;
    assert_eq!(spaces.len(), 1);

    let main_space = spaces.first().unwrap();
    assert_eq!(main_space.pins().await?.len(), 2);
    assert_eq!(main_space.task_lists().await?.len(), 1);
    Ok(())
}
