use anyhow::Result;
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
    let group = user.get_group(room_id.to_string()).await?;

    assert_eq!(
        group.task_lists().await?.len(),
        0,
        "Why are there tasks in our fresh space!?!"
    );

    group.create_onboarding_data().await?;

    let retry_strategy = FibonacciBackoff::from_millis(100).map(jitter).take(10);
    let calendar_client = user.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = calendar_client.clone();
        async move {
            let task_lists = client.task_lists().await?;
            if let Some(tk) = task_lists.first() {
                if tk.tasks().await?.len() != 2 {
                    anyhow::bail!("not all tasks found yet");
                }
                Ok(())
            } else {
                anyhow::bail!("task list not found");
            }
        }
    })
    .await?;

    let pin_client = user.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = pin_client.clone();
        async move {
            if client.pins().await?.len() != 3 {
                anyhow::bail!("not all pins found");
            } else {
                Ok(())
            }
        }
    })
    .await?;

    let calendar_client = user.clone();
    Retry::spawn(retry_strategy.clone(), move || {
        let client = calendar_client.clone();
        async move {
            if client.calendar_events().await?.len() != 1 {
                anyhow::bail!("not all calendar_events found");
            } else {
                Ok(())
            }
        }
    })
    .await?;

    Ok(())
}
