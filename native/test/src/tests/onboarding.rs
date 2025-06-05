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
    Retry::spawn(retry_strategy.clone(), || async {
        user.space(room_id.to_string()).await
    })
    .await?;

    let space = user.space(room_id.to_string()).await?;

    assert_eq!(
        space.task_lists().await?.len(),
        0,
        "Why are there tasks in our fresh space!?!"
    );

    space.create_onboarding_data().await?;

    Retry::spawn(retry_strategy.clone(), || async {
        let task_lists = user.task_lists().await?;
        let Some(tk) = task_lists.first() else {
            bail!("task list not found")
        };
        if tk.tasks().await?.len() != 2 {
            bail!("not all tasks found yet");
        }
        Ok(())
    })
    .await?;

    Retry::spawn(retry_strategy.clone(), || async {
        if user.pins().await?.len() != 3 {
            bail!("not all pins found");
        }
        Ok(())
    })
    .await?;

    Retry::spawn(retry_strategy.clone(), || async {
        if user.calendar_events().await?.len() != 1 {
            bail!("not all calendar_events found");
        }
        Ok(())
    })
    .await?;

    Retry::spawn(retry_strategy, || async {
        if user.latest_news_entries(10).await?.len() != 1 {
            bail!("not all news found");
        }
        Ok(())
    })
    .await?;

    Ok(())
}
