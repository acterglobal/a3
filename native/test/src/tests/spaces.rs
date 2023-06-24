use anyhow::{bail, Result};
use async_broadcast::TryRecvError;
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

[objects.main_space]
type = "space"
name = "{{ main.display_name }}'s main test space"

[objects.second_space]
type = "space"
name = "{{ main.display_name }}'s first test space"

[objects.third_space]
type = "space"
name = "{{ main.display_name }}'s second test space"
"#;

#[tokio::test]
async fn spaces_deleted() -> Result<()> {
    let _ = env_logger::try_init();
    let (user, _sync_state, _engine) = random_user_with_template("spaces-deleted-", TMPL).await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            if client.spaces().await?.len() != 3 {
                bail!("not all spaces found");
            } else {
                Ok(())
            }
        }
    })
    .await?;

    let mut spaces = user.spaces().await?;

    assert_eq!(spaces.len(), 3);

    let first = spaces.pop().unwrap();
    let second = spaces.pop().unwrap();
    let last = spaces.pop().unwrap();

    let mut all_listener = user.subscribe("SPACES".to_owned());
    let mut first_listener = user.subscribe(format!("SPACE::{}", first.room_id()));
    let mut second_listener = user.subscribe(format!("SPACE::{}", second.room_id()));
    let mut last_listener = user.subscribe(format!("SPACE::{}", last.room_id()));

    first.leave().await?;
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            if client.spaces().await?.len() != 2 {
                bail!("not the right number of  spaces found");
            } else {
                Ok(())
            }
        }
    })
    .await?;

    assert_eq!(all_listener.try_recv(), Ok(()));
    assert_eq!(first_listener.try_recv(), Ok(()));
    assert_eq!(second_listener.try_recv(), Err(TryRecvError::Empty));
    assert_eq!(last_listener.try_recv(), Err(TryRecvError::Empty));

    second.leave().await?;
    let fetcher_client = user.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        async move {
            if client.spaces().await?.len() != 1 {
                bail!("not the right number of  spaces found");
            } else {
                Ok(())
            }
        }
    })
    .await?;

    assert_eq!(all_listener.try_recv(), Ok(()));
    assert_eq!(first_listener.try_recv(), Err(TryRecvError::Empty));
    assert_eq!(second_listener.try_recv(), Ok(()));
    assert_eq!(last_listener.try_recv(), Err(TryRecvError::Empty));

    Ok(())
}
