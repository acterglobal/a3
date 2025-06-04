use anyhow::{bail, Result};
use tokio_retry::{
    strategy::{jitter, FibonacciBackoff},
    Retry,
};

use crate::utils::random_user_with_random_space;

#[tokio::test]
async fn onboarding_is_created() -> Result<()> {
    let _ = env_logger::try_init();
    let (mut user, room_id) = random_user_with_random_space("onboarding").await?;
    let state_sync = user.start_sync();
    state_sync.await_has_synced_history().await?;

    // wait for sync to catch up
    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let fetcher_client = user.clone();
    let target_id = room_id.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = fetcher_client.clone();
        let room_id = target_id.clone();
        async move { client.space(room_id.to_string()).await }
    })
    .await?;

    let space = user.space(room_id.to_string()).await?;

    assert_eq!(
        space.task_lists().await?.len(),
        0,
        "Why are there tasks in our fresh space!?!"
    );

    space.create_onboarding_data().await?;

    let calendar_client = user.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = calendar_client.clone();
        async move {
            let task_lists = client.task_lists().await?;
            let Some(tk) = task_lists.first() else {
                bail!("task list not found")
            };
            if tk.tasks().await?.len() != 2 {
                bail!("not all tasks found yet");
            }
            Ok(())
        }
    })
    .await?;

    let pin_client = user.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = pin_client.clone();
        async move {
            if client.pins().await?.len() != 3 {
                bail!("not all pins found");
            }
            Ok(())
        }
    })
    .await?;

    let calendar_client = user.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = calendar_client.clone();
        async move {
            if client.calendar_events().await?.len() != 1 {
                bail!("not all calendar_events found");
            }
            Ok(())
        }
    })
    .await?;

    let news_client = user.clone();
    Retry::spawn(retry_strategy, move || {
        let client = news_client.clone();
        async move {
            if client.latest_news_entries(10).await?.len() != 1 {
                bail!("not all news found");
            }
            Ok(())
        }
    })
    .await?;

    Ok(())
}
